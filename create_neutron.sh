#!/bin/bash

neutron quota-update --network -1 --subnet -1 --port -1 --router -1

for i in {1..10} ; do neutron net-create net$i ; done

for i in {1..10}
do
    neutron subnet-create --name subnet$i net$i 20.20.$i.0/24
done

for i in {1..9} ; do neutron router-create router$i ; done

ext_net_id=`neutron net-list | grep PUBLIC | awk '{print $2}'`

for i in {1..9}
do
    neutron router-gateway-set router$i $ext_net_id
done

for i in {1..9}
do
    subnet_id=`neutron subnet-show subnet$i | grep " id " | awk '{print $4}'`
    neutron router-interface-add router$i $subnet_id
done

subnet_id=`neutron subnet-show subnet10 | grep " id " | awk '{print $4}'`
neutron router-interface-add "External router" $subnet_id

## wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
## glance image-create --name "cirros-0.3.4-x86_64" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility public --progress
## glance image-list

for i in {1..10}
do
    net_id=`neutron net-show net$i | grep " id " | awk '{print $4}'`
    nova boot --image cirros-0.3.4-x86_64 --flavor m1.tiny --nic net-id=$net_id vm$i
done

nova list
