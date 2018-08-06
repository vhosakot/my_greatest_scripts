#!/usr/bin/env python3

import json
import requests
# import urllib3
# urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

username = 'admin'
password = 'cisco123!'
apic_fabric = 'https://10.23.231.6'

def get (path):
    # login into ACI fabric first to get cookie
    data = '{"aaaUser":{"attributes":{"name": "' + username + \
           '", "pwd": "' + password + '"}}}'
    login_path = apic_fabric + '/api/aaaLogin.json'
    resp = requests.post(login_path, data=data, verify=False)
    resp = json.loads(resp.text)
    aci_cookie = { 'APIC-Cookie': resp['imdata'][0]["aaaLogin"]["attributes"]["token"] }

    # do http get on path
    path = apic_fabric + path
    resp = requests.request('get', path, verify=False, cookies=aci_cookie)

    # print http response
    print("========response from", path, " = \n\n", resp, "\n", \
          json.dumps(json.loads(resp.text), indent=4, sort_keys=True), "\n")

    resp = json.loads(resp.text)

    # print infra VLAN of aci fabric
    if 'imdata' in resp and len(resp['imdata']) > 0 and \
      'infraRsFuncToEpg' in resp['imdata'][0]:
        encap = resp['imdata'][0]["infraRsFuncToEpg"]["attributes"]["encap"]
        aci_infra_vlan = int(encap.split("-")[1])
        print("\nACI infra vlan =", aci_infra_vlan, "\n")

infra_vlan_path = '/api/node/mo/uni/infra/attentp-default/provacc' + \
                  '/rsfuncToEpg-[uni/tn-infra/ap-access/epg-default].json'
get(infra_vlan_path)

infra_vlan_path = '/api/node/class/infraRsFuncToEpg.json?' + \
                  'query-target-filter=eq(infraRsFuncToEpg.uid, "0")'
get(infra_vlan_path)

infra_vlan_path = '/api/node/class/infraRsFuncToEpg.json'
get(infra_vlan_path)

get('/api/class/topSystem.json')
get('/api/node/class/compProv.json')
get('/api/node/mo/uni/infra.json')
get('/api/node/mo/uni/infra.json?query-target=subtree&target-subtree-class=infraAttEntityP')
get('/api/node/mo/uni/tn-common.json')
get('/api/mo/uni.json')

# get ACI fabric's firmware version
get('/api/node/class/firmwareRunning.json')
