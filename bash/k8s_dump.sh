#!/bin/bash

kubectl version

kubectl cluster-info

# get all k8s resources in all the namespaces in the k8s cluster
kubectl get 2>&1 >/dev/null | \
  grep -v 'specify the type of resource\|  for a detailed description of\|for help and examples\|Required resource not specified' | awk '{print $2}' | sed '/^\s*$/d' | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo kubectl get % --all-namespaces --show-labels -o wide && echo \"================\n\" && kubectl get % --all-namespaces --show-labels -o wide"

# describe all k8s resources in all the namespaces in the k8s cluster
kubectl get 2>&1 >/dev/null | \
  grep -v 'specify the type of resource\|  for a detailed description of\|for help and examples\|Required resource not specified' | awk '{print $2}' | sed '/^\s*$/d' | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo kubectl describe % --all-namespaces && echo \"================\n\" && kubectl describe % --all-namespaces"

# get all k8s resources' YAML manifest specs in all the namespaces in the k8s cluster
kubectl get 2>&1 >/dev/null | \
  grep -v 'specify the type of resource\|  for a detailed description of\|for help and examples\|Required resource not specified' | awk '{print $2}' | sed '/^\s*$/d' | xargs -n 1 -d '\n' -I % -- \
  sh -c "echo \"\n================\" && echo kubectl get % --all-namespaces -o yaml && echo \"================\n\" && kubectl get % --all-namespaces -o yaml"
