#!/bin/bash

# bash script on Mac to open multiple SSH terminal windows at the same time and stream pod logs on
# each opened window using "kubectl logs -f ..." from all the pods in the namespace at the same,
# number of windows opened by this script will be equal to the number of pods in the namespace
#
# for example, if there are 10 pods in the namespace, each of these 10 pods will stream its logs
# using "kubectl logs -f ..." to a separate window opened by this script - so, this script will open
# 10 windows in this case
#
# after running this script, use command+k on Mac to clear screen of each window if needed
#
# if no need to SSH, this script can be easily modified to not SSH and just run kubectl commands
# locally on Mac
#
# after using this script, each opened window should be exited manually

rm -rf pods

ssh -q -i ~/.ssh/eti_vhosakot ubuntu@eti-vhosakot-1 \
  "export KUBECONFIG=/home/ubuntu/vhosakot-aws1.yaml && kubectl get pods -n smm-system | awk '{print \$1}' | grep -v NAME" \
  > pods

while IFS= read -r line
do
  osascript -e 'tell app "Terminal"
    do script "ssh -q -i ~/.ssh/eti_vhosakot ubuntu@eti-vhosakot-1
export KUBECONFIG=/home/ubuntu/vhosakot-aws1.yaml
kubectl logs -f \"'$line'\" -n smm-system --all-containers=true
    "
  end tell'
done < ./pods

rm -rf pods
