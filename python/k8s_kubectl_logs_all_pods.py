#! /usr/bin/python3

# python script to get logs of all containers of all pods in all
# namespaces in kubernetes

import subprocess

cmd = "kubectl get pods --all-namespaces | awk '{print $1,$2}' | grep -v 'NAMESPACE NAME'"
print("====", cmd)
p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
output,err = p.communicate()

for pod in output.splitlines():
    pod = pod.decode('utf-8').split()
    cmd = "kubectl get pods " + pod[1] + " -n=" + pod[0] + \
          " -o jsonpath='{.spec.containers[*].name}'"
    print("\n====", cmd)
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    output,err = p.communicate()
    containers_in_pod = output.decode('utf-8').split()
    print(containers_in_pod)
    for container in containers_in_pod:
        cmd = "kubectl logs " + pod[1] + " -n=" + pod[0] + \
              " -c=" + container
        print("\n====", cmd)
        p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        output,err = p.communicate()
        print(output.decode('utf-8'))
