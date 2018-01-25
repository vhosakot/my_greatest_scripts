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

cd $GOPATH/src/github.com/contiv/netplugin

CONTIV_K8S_USE_KUBEADM=1 CONTIV_NODES=3 go test -v -timeout 540m ./test/systemtests -check.v -check.abort -check.f "00SSH|Basic|Network"

cd
echo "done!!"

# use the k8s+contiv cluster
#
# cd /root/go/src/github.com/contiv/netplugin/vagrant/k8s
# vagrant status
# vagrant ssh k8master
#
#   kubectl get all --all-namespaces
#   kubectl get svc
#   kubectl describe svc kubernetes
#   kubectl get configmaps --all-namespaces
#   kubectl get serviceaccounts --all-namespaces
#   kubectl get namespaces
#
#   kubectl run -i --tty busybox1 --image=busybox
#      exit
#
#   kubectl run -i --tty busybox2 --image=busybox
#      exit
#
#   kubectl run -i --tty busybox3 --image=busybox
#      exit
#
#   kubectl attach busybox1-84b586b4d7-7cq4w -c busybox1 -i -t
#      nslookup localhost
#      nslookup kubernetes.default
#      nslookup kubernetes.default.svc.cluster.local
#      cat /etc/hosts
#      cat /etc/resolv.conf
#      ip a
#      ifconfig
#      ip route
#      netstat -pan
#      lsof
#
#   kubectl attach busybox2-7749f79cbc-m4zpc -c busybox2 -i -t
#   kubectl attach busybox3-5bb6d954d7-vlsnr -c busybox3 -i -t
#
#   kubectl get pods -o wide
#   kubectl get all -o wide
#   kubectl get all -o wide | grep busybox
#
#   netctl network ls
#   netctl network inspect default-net
#   netctl network inspect default-net | grep -i end
#   netctl global info
#   netctl global inspect
#   
#   inspect each endpointID
#      netctl endpoint inspect dae532ba1d80092e2d070fa63ea1b8678011a1e82306f7636303dc3753b6e264
#      netctl endpoint inspect 260aa746df4bda78887aabb7d718a353866d0af89614265acd63a6a0fcb83a58
#      netctl endpoint inspect 663fbba80cf8c92a49ca3e949547d5675dfc1a9ed7b3c308187f710d1395e60e
#
#   netctl tenant ls
#   netctl tenant inspect default
#   netctl version
#
#
#
####################################
#  on each node, do the following  #
####################################
#
# sudo docker images
# sudo docker ps -a
#
# in the below command, the container ID will have the first few
# characters of endpointID seen in the output of
# "netctl network inspect default-net | grep -i end"
#
#    sudo docker ps -a | grep busybox
#
# sudo docker volume ls
# sudo docker info
#
# cat /etc/hosts
# cat /etc/resolv.conf
# ip a
# ifconfig
# ip route
# sudo iptables -L -n -v
# sudo netstat -pan | grep kube
# sudo lsof | grep kube
# ls -lR /var/contiv
# ls -l /usr/bin/contiv-compose
# sudo /opt/gopath/bin/contivk8s -version
# sudo /opt/gopath/bin/netcontiv -version
# sudo /opt/cni/bin/contivk8s -version
# ls -l /shared/contiv.yaml
# ls -l /vagrant/export/contiv.yaml
# ls -lR /var/log/contiv
# ls -lR /proc/sys/net/ipv4/conf/contivh0
# sudo find /proc/sys/net | grep -i contiv
# ls -lR /run/contiv
# ls -lR /run/openvswitch
# sudo find /sys/devices/virtual/net | grep -i contiv
# ls -l /sys/class/net/contivh0
# cat /etc/cni/net.d/1-contiv.conf
# ls -l /var/log/netcontiv.log
#
# sudo find / | grep -i contiv
#
# sudo ovs-vsctl show
# sudo ovs-vsctl list-br
# sudo ovs-vsctl list-ports contivVlanBridge
# sudo ovs-vsctl list-ports contivVxlanBridge
# sudo ovs-vsctl list-ifaces contivVlanBridge
# sudo ovs-vsctl list-ifaces contivVxlanBridge
# sudo ovs-vsctl port-to-br eth2
# sudo ovs-vsctl port-to-br contivh0
# sudo ovs-vsctl get-controller contivVlanBridge
# sudo ovs-vsctl get-controller contivVxlanBridge
# sudo ovs-vsctl find Port name=eth2
# sudo ovs-vsctl find Interface name=eth2
# sudo ovs-vsctl find Port name=contivh0
# sudo ovs-vsctl find Interface name=contivh0
# sudo ovs-vsctl --help | grep print
#
# sudo ovs-ofctl -O openflow13 dump-flows contivVlanBridge 
# sudo ovs-ofctl -O openflow13 dump-flows contivVxlanBridge 
# sudo ovs-ofctl --protocols=OpenFlow13 dump-flows contivVlanBridge
# sudo ovs-ofctl --protocols=OpenFlow13 dump-ports contivVlanBridge
# sudo ovs-ofctl --protocols=OpenFlow13 dump-flows contivVxlanBridge
# sudo ovs-ofctl --protocols=OpenFlow13 dump-ports contivVxlanBridge
# sudo ovs-ofctl --protocols=OpenFlow13 --help | grep print
#
#
#
#############################
#  delete the busybox pods  #
#############################
# cd /root/go/src/github.com/contiv/netplugin/vagrant/k8s
# vagrant status
# vagrant ssh k8master
#
#   kubectl get all | grep busybox
#   kubectl delete deployment busybox1
#   kubectl delete deployment busybox2
#   kubectl delete deployment busybox3
