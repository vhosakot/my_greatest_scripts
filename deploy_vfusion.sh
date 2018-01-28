#!/bin/bash

#####################################
#
# This script clones ansible-systems and deploys Metapod vFusion.
#
# Before running this script, make sure that:
#
#   1) Your SSH key is added to GitHub at https://github.com/settings/keys
#      and ansible-systems repo can be cloned without password being asked.
#
#   2) Add "ansible-systems proxmox inventory vault password" from your
#      passpack account to ~/.config/ansible-systems/vault-proxmox.pass.
#
#####################################

set -e

DIR=vFusion
SSH_GIT_REPO=git@github.com:metacloud/ansible-systems.git
GIT_BRANCH=master

axion_proxmox_destroy_CMD="ansible-playbook -i inventory/fusion/metapod/proxmox/ playbooks/openstack/axion_proxmox_destroy.yml -e \"slot=7 proxmox=9 proxmox_user=vhosakot force=yes\""

axion_proxmox_provision_CMD="ansible-playbook -i inventory/fusion/metapod/proxmox/ playbooks/openstack/axion_proxmox_provision.yml -e \"slot=7 proxmox=9 deploy_model=ha network_model=csr proxmox_user=vhosakot provision_util=False proxmox_vpp_enabled=True\""

ext_networks_CMD="ansible-playbook playbooks/openstack/proxmox_create_ext_networks_csr.yml --become"

rm -rf $DIR
mkdir $DIR
cd $DIR
git clone $SSH_GIT_REPO -b $GIT_BRANCH
cd ansible-systems
git branch
make clean
make
source venv/bin/activate
cat ~/.config/ansible-systems/vault-proxmox.pass
export ANSIBLE_VAULT_PASSWORD_FILE="~/.config/ansible-systems/vault-proxmox.pass"

# Run axion_proxmox_destroy.yml
set +e ; source ${PROXMOX_AXION_DIR:-~/.axion}/env ; set -e
bash -c "$axion_proxmox_destroy_CMD"

# Run axion_proxmox_provision.yml
bash -c "$axion_proxmox_provision_CMD"

# Run metapod playbook ansible-systems/playbooks/openstack/metapod.yml
source ${PROXMOX_AXION_DIR:-~/.axion}/env
ansible-playbook $PROXMOX_DEPLOY_PLAYBOOK --become

# Create external networks
source ${PROXMOX_AXION_DIR:-~/.axion}/env
bash -c "$ext_networks_CMD"

set +e ; source ${PROXMOX_AXION_DIR:-~/.axion}/unenv ; set -e
deactivate
cd ../..

# Test OpenStack CLIs and pcs status on mcp1
ssh -t -F ~/.axion/ssh_config mcp1 'sudo su -c "set -x ; source /etc/metacloud/openrc.sh ; openstack user list --domain default ; openstack endpoint list ; neutron net-list ; neutron agent-list ; nova-manage service list ; nova availability-zone-list ; pcs status ; set +x"'

set +e
