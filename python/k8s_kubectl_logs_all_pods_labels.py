#! /usr/bin/python3

import os
import shutil
import subprocess
import threading
import time

logs_dir = "./HS-k8s-all-pods-logs"
ns_label_list = []
thread_list = []
if os.path.exists(logs_dir):
    shutil.rmtree(logs_dir)

os.mkdir(logs_dir)
os.chdir(logs_dir)
print("\nInside", logs_dir, "directory\n")
cmd = "kubectl get pods -A -o custom-columns=NAMESPACE:.metadata.namespace,LABELS:.metadata.labels.app | grep '^hs' | grep -v \"<none>\""
p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
output,err = p.communicate()
for line in output.splitlines():
    parts = line.decode('utf-8').split()
    ns_label_list.append(parts[0] + "++++" + parts[1])
    ns_label_list = list(set(ns_label_list))

# Run this function in a separate thread
def task_get_k8s_pods_logs(namespace, label):
    logfile_name = label.split("=")[1] + ".txt"
    if os.path.exists("./" + logfile_name):
        os.remove("./" + logfile_name)
    cmd = "kubectl logs -f -l " + label + " -n " + namespace + " --all-containers=true --max-log-requests 20 > " + logfile_name
    print(cmd)
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    output, err = p.communicate(timeout=3600)
    print("\n  This command ended: ", cmd, "\n")

print("Running the commands below in separate threads:\n")
for ns_label in ns_label_list:
    ns = ns_label.split("++++")[0]
    label = "app=" + ns_label.split("++++")[1]
    k8s_pod_logs_thread = threading.Thread(target=task_get_k8s_pods_logs, args=(ns, label), daemon=True)
    thread_list.append(k8s_pod_logs_thread)
    k8s_pod_logs_thread.start()
    time.sleep(2)

print("\nWaiting for all threads to finish ... Press CTRL+C to exit\n")
try:
    for thread in thread_list:
        thread.join()
except KeyboardInterrupt:
    print("\nThe logs from all the xxxx pods in all the xxxx namespaces in")
    print("the k8s cluster are collected in the \"HS-k8s-all-pods-logs\" directory in")
    print("the current directory.\n")
