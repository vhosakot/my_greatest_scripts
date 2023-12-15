#!/usr/bin/env python3

# python script to clone all repos of a github org
#
# before running this script, first:
# - refer https://github.com/cli/cli#installation and install gh (github CLI)
# - refer https://cli.github.com/manual/gh_auth_login and do "gh auth login" to
#   login into github using gh
#
# usage: ./gh_clone_all_repos_in_org.py <GitHub org>

import sys
import subprocess
import json
import os

if len(sys.argv) < 2:
    print("\nPass GitHub org as command line arg to this script.\n")
    print("  Usage: ./gh_clone_all_repos_in_org.py <GitHub org>\n")
    sys.exit(0)

print("GitHub org:", sys.argv[1])
cmd = "gh repo list " + sys.argv[1] + " --limit 10000 --json name"
print("running cmd:", cmd)
output = subprocess.check_output(cmd.split(" "))
repo_names = json.loads(output.decode('utf-8'))
os.system("rm -rf temp_dir_gh_list_repos")
os.system("mkdir temp_dir_gh_list_repos")
os.chdir("temp_dir_gh_list_repos")

for repo_name in repo_names:
    print("\ncloning repo:", repo_name['name'])
    cmd = "git clone git@wwwin-github.cisco.com:" + sys.argv[1] + "/" + repo_name['name'] + ".git"
    print("running cmd:", cmd)
    os.system(cmd)
    os.chdir(repo_name['name'])
    print("==== files in " + sys.argv[1] + "/" + repo_name['name'] + " repo: ====")
    os.system("ls -l")
    os.chdir("..")
