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
helm list --all
helm repo list
helm list --all | awk '{print $1}' | grep -v NAME | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo helm status % && echo \"================\n\" && helm status %"

# print important processes
ps aux | grep -i 'kube\|k8\|cni\|calico\|net'

# cat important files
find ~/.kube -type f -print -exec cat {} \; -printf "\n\n"
find ~/.helm -type f -print -exec cat {} \; -printf "\n\n"
sudo find /ccp_related_files/ -type f -print -exec cat {} \; -printf "\n\n"
sudo find /var/lib/cloud -type f -print -exec cat {} \; -printf "\n\n"
sudo find /etc/kubernetes/ -type f -print -exec cat {} \; -printf "\n\n"

# get all containers of all pods in all namespaces
kubectl get pods --all-namespaces | awk '{print $1,$2}' | grep -v 'NAMESPACE NAME' | \
  xargs -n2 sh -c 'echo "====$1 -n=$0 ====" && kubectl get pods $1 -n=$0 -o jsonpath='{.spec.containers[*].name}' && echo "\n"'
