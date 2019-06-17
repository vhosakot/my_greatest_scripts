#!/usr/bin/env bash

# dump logs of all pods in the default k8s namespace
#
# if different namespace, pass it to the --namespace argument to kubectl

kubectl get pods | grep Run | awk '{print $1}' | xargs -I % sh -c "
  echo ============ kubectl logs % >> all_pods_logs &&
  kubectl logs % >> all_pods_logs &&
  echo >> all_pods_logs"
  
# get logs of all containers in all the istio pods in istio-system namespace

kubectl get pods -n=istio-system | awk '{print $1}' | grep -v '^NAME' | xargs -I % sh -c "
    echo ======== kubectl logs % -n=istio-system --all-containers=true ======== >> all_istio_pods_logs.txt &&
    kubectl logs % -n=istio-system --all-containers=true >> all_istio_pods_logs.txt &&
    echo >> all_istio_pods_logs.txt"
