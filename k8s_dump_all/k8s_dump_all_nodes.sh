#!/bin/bash

#
# Usage:
#  Pass the IP address of the kubernetes master node to this script like:
#    ./k8s_dump_all_nodes.sh 10.20.30.40
#

if [ "$#" -ne 1 ]; then
    echo -e "\n Pass the IP address of the kubernetes master node to this script like:\n"
    echo -e "   ./k8s_dump_all_nodes.sh 10.20.30.40\n"
    exit 1
fi

set -x

user="ccpuser"

ssh $user@$1 "rm -rf ~/k8s_kubectl_logs_all_pods.py"
scp k8s_kubectl_logs_all_pods.py $user@$1:~/
cat k8s_dump.sh | ssh $user@$1
