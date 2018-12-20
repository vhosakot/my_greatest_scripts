#!/usr/bin/env bash

# print all containers in a pod in k8s
# kubectl get pod <pod name> -o=jsonpath='{range .spec.containers[*]}{.name}{"\n"}'

# print all containers in all pods in all the namespaces

export json_path_arg="-o=jsonpath='{range .spec.containers[*]}{.name}{\"  \"}'"

kubectl get pods --all-namespaces \
    -o=jsonpath='{range .items[*]}{.metadata.name}{"   "}{.metadata.namespace}{"\n"}' | \
    xargs -l bash -c \
      'echo -e "\npod $0 in namespace $1 has:" && echo -n "    " && kubectl get pod $0 -n=$1 "$json_path_arg" && echo ""'
