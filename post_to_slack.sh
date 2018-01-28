#!/bin/bash

# This script posts messages to Slack using curl.
# This script, generate_ansible_task_report.py and ansible_output must
# be in the same directory.
#
# Steps to run this script:
#
#   1) The user must first create the required incoming webhook for this
#      script in Slack.
#   2) Make sure that this script, generate_ansible_task_report.py and
#      ansible_output exist in the same directory.
#   3) ./post_to_slack.sh

data=`./generate_ansible_task_report.py`
cd vFusion/ansible-systems/
git_log="git log:\n\`\`\`"`git log --pretty=format:"%an%x09%ad%x09%s" --date=short | head -2`"\`\`\`"
cd ../..
data=$data\\n$git_log

curl -X POST --data-urlencode \
    'payload={"channel": "#testtest", "username": "Metacloud VPP CI bot", "text": "'"$data"'", "icon_emoji": ":whisky:"}' \
    https://hooks.slack.com/services/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

#curl -X POST --data-urlencode \
#    'payload={"channel": "#eng-lunar", "username": "Metacloud VPP CI bot", "text": "Hi! This is Metacloud VPP CI bot!\nEveryday, I will deploy the latest vFusion with VPP, test VPP, and send the test results to this channel so that we can monitor the health of VPP in vFusion everyday.", "icon_emoji": ":vpp:"}' \
#    https://hooks.slack.com/services/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

#curl -X POST --data-urlencode \
#    'payload={"channel": "#eng-lunar", "username": "Metacloud VPP CI bot", "text": "'"$data"'", "icon_emoji": ":vpp:"}' \
#    https://hooks.slack.com/services/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
