#!/usr/bin/env bash

# dump logs of all pods in the default k8s namespace
#
# if different namespace, pass it to the --namespace argument to kubectl

kubectl get pods | grep Run | awk '{print $1}' | xargs -I % sh -c "
  echo ============ kubectl logs % >> all_pods_logs &&
  kubectl logs % >> all_pods_logs &&
  echo >> all_pods_logs"
