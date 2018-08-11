#!/bin/bash

set -x

kubectl version

kubectl cluster-info

kubectl cluster-info dump

# get all k8s resources in all namespaces in the k8s cluster
kubectl get 2>&1 >/dev/null | \
  grep -v 'specify the type of resource\|for a detailed description of\|for help and examples\|Required resource not specified' | awk '{print $2}' | sed '/^\s*$/d' | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo kubectl get % --all-namespaces --show-labels -o wide && echo \"================\n\" && kubectl get % --all-namespaces --show-labels -o wide"

# describe all k8s resources in all namespaces in the k8s cluster
kubectl get 2>&1 >/dev/null | \
  grep -v 'specify the type of resource\|for a detailed description of\|for help and examples\|Required resource not specified' | awk '{print $2}' | sed '/^\s*$/d' | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo kubectl describe % --all-namespaces && echo \"================\n\" && kubectl describe % --all-namespaces"

# get all k8s resources' YAML manifest specs in all namespaces in the k8s cluster
kubectl get 2>&1 >/dev/null | \
  grep -v 'specify the type of resource\|for a detailed description of\|for help and examples\|Required resource not specified' | awk '{print $2}' | sed '/^\s*$/d' | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo kubectl get % --all-namespaces -o yaml && echo \"================\n\" && kubectl get % --all-namespaces -o yaml"

# helm commands
helm version
helm list --all
helm repo list
helm list --all | awk '{print $1}' | grep -v NAME | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo helm status % && echo \"================\n\" && helm status %"

# print all processes
ps aux
ps -eLf

# cat important files
find ~/.kube -type f -print -exec cat {} \; -printf "\n\n"
find ~/.helm -type f -print -exec cat {} \; -printf "\n\n"
sudo find /ccp_related_files/ -type f -print -exec cat {} \; -printf "\n\n"
sudo find /var/lib/cloud -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/kubernetes/ -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/cni -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/cloud -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/dnsmasq.d -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/docker -type f -print -exec cat {} \; -printf "\n\n"
sudo cat /etc/ntp.conf

# get all containers of all pods in all namespaces
kubectl get pods --all-namespaces | awk '{print $1,$2}' | grep -v 'NAMESPACE NAME' | \
  xargs -n2 sh -c 'echo "====$1 -n=$0 ====" && kubectl get pods $1 -n=$0 -o jsonpath='{.spec.containers[*].name}' && echo "\n"'

# get logs of all containers of all pods in all namespaces
~/k8s_kubectl_logs_all_pods.py

lsmod

# dump iptables rules and chains
sudo iptables -S
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
sudo iptables -t filter -L -n -v
sudo iptables -t mangle -L -n -v
sudo iptables -t raw -L -n -v
sudo iptables -t security -L -n -v

# networking configs
ip a
ip -d a
ifconfig
ip route
netstat -r
ip neigh
arp -n
cat /etc/resolv.conf
cat /etc/hosts
cat /etc/networks
sudo find /etc/network -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/dhcp -type f -print -exec cat {} \; -printf "\n\n"
sudo find /var/lib/dhcp -type f -print -exec cat {} \; -printf "\n\n"

# open ports
sudo netstat -pan

# systemctl commands
systemctl --no-pager
systemctl --no-pager --failed
systemctl --no-pager list-unit-files
systemctl --no-pager status -l kubelet.service
systemctl --no-pager status -l ccp_prevalidation.service
systemctl --no-pager status *
systemctl --no-pager status -l cloud-init.service
systemctl --no-pager status -l cloud-final.service
systemctl --no-pager status -l cloud-init-local.service
systemctl --no-pager status -l cloud-config.service
systemctl --no-pager status -l mastervip.service
sudo find /etc/systemd/system/ -type f -print -exec cat {} \; -printf "\n\n"
sudo cat /usr/local/bin/mastervip.sh

# docker commands
sudo docker images
sudo docker ps -a
sudo docker network ls
sudo docker volume ls
sudo docker info
