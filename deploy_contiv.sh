#!/bin/bash

set -x

# cleanup

find /root/VirtualBox\ VMs/ | grep -i snap | xargs rm -rf
rm -rf /root/.ansible/
cd /root/go/src/github.com/contiv/netplugin/vagrant/k8s/
vagrant destroy -f
vagrant destroy -f
cd
rm -rf /root/VirtualBox\ VMs/*
rm -rf /root/.vagrant /root/.vagrant.d/
cd /var/log/
rm -rf boot.log-* secure-* spooler-* messages-*
rm -rf maillog-* cron-* yum.log-* btmp-*
cd
yum clean all
rm -rf /var/cache/yum
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi -f $(docker images -q)

# deploy contiv/netplugin (make k8s-test)

cd /root/go/src/github.com/contiv/
rm -rf netplugin/
git clone https://github.com/contiv/netplugin.git
cd netplugin
# git checkout <release branch>
export GOPATH="/root/go"
make checks-with-docker
make compile-with-docker
make binaries-from-container
CONTIV_TEST="sys" make k8s-cluster

cd $GOPATH/src/github.com/contiv/netplugin/scripts/python && PYTHONIOENCODING=utf-8 ./createcfg.py -scheduler 'k8s' -binpath contiv/bin -install_mode 'kubeadm'

CONTIV_K8S_USE_KUBEADM=1 CONTIV_NODES=3 go test -v -timeout 540m ./test/systemtests -check.v -check.abort -check.f "00SSH|Basic|Network"

cd
echo "done!!"
