#!/usr/bin/env python

# Python module to get running-config from N9k

DOCUMENTATION = '''
---
module: nxos_command
options:
    command:
        required: false
    host:
        required: true
'''

EXAMPLES = '''
# Get raw text output of CLI "show run"
- nxos_command: command='show run' host={{ inventory_hostname }}
'''

RETURN = '''
commands:
    returned: always
'''

import socket
import xmltodict
try:
    HAS_PYCSCO = True
    from pycsco.nxos.device import Device
    from pycsco.nxos.device import Auth
    from pycsco.nxos.error import CLIError
except ImportError as ie:
    HAS_PYCSCO = False


def normalize_to_list(output):
    if isinstance(output, dict):
        return [output]
    else:
        return output


def send_show_command(device, command, module):
    try:
        data = device.show(command)
    except CLIError as clie:
        module.fail_json(msg='Error sending {0}'.format(command),
                         error=str(clie))

    data_dict = xmltodict.parse(data[1])
    output = normalize_to_list(data_dict['ins_api']['outputs']['output'])

    return output


def command_list_to_string(command_list):
    if command_list:
        command = ' ; '.join(command_list)
        return command
    else:
        return ''


def main():
    module = AnsibleModule(
        argument_spec=dict(
            command=dict(required=False),
            protocol=dict(choices=['http', 'https'], default='http'),
            port=dict(required=False, type='int', default=None),
            host=dict(required=True),
            username=dict(type='str'),
            password=dict(no_log=True, type='str')
        ),
        required_one_of=[['command']],
        mutually_exclusive=[['command']],
        supports_check_mode=False
    )
    if not HAS_PYCSCO:
        module.fail_json(msg='There was a problem loading pycsco')

    auth = Auth(vendor='cisco', model='nexus')
    username = module.params['username'] or auth.username
    password = module.params['password'] or auth.password
    protocol = module.params['protocol']
    port = module.params['port']
    host = socket.gethostbyname(module.params['host'])

    command = module.params['command']

    device = Device(ip=host, username=username, password=password,
                    protocol=protocol, port=port)

    changed = False
    cmds = ''

    if isinstance(command, str):
        cmds = command_list_to_string([command])
    else:
        module.fail_json(msg='Only strings are supported with "command"')

    proposed = dict(commands=cmds)

    if cmds:
        response = send_show_command(device, cmds, module)
    else:
        module.fail_json(msg='no commands to send. check format')

    results = {}
    results['changed'] = changed
    results['proposed'] = proposed
    results['commands'] = cmds
    results['response'] = response

    module.exit_json(**results)

from ansible.module_utils.basic import *
if __name__ == "__main__":
    main()
