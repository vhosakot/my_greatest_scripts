#!/bin/bash

for i in {1..10}
do
    nova delete vm$i
done

for i in {1..9}
do
    subnet_id=`neutron subnet-show subnet$i | grep " id " | awk '{print $4}'`
    neutron router-interface-delete router$i $subnet_id
done

subnet_id=`neutron subnet-show subnet10 | grep " id " | awk '{print $4}'`
neutron router-interface-delete "External router" $subnet_id

for i in {1..9}
do
    neutron router-gateway-clear router$i
done

for i in {1..9}
do
    neutron router-delete router$i
done

for i in {1..10} ; do neutron net-delete net$i ; done
