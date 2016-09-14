#! /usr/bin/python

##################################################################################
# 
# Author:  Vikram Hosakote (vhosakot@cisco.com)
#
# This script searches a regular expression in OpenStack Kolla's IRC logs
# in a multi-threaded manner.
#
# The "link" variable in this script can be changed to search any 
# OpenStack project's IRC logs.
#
# For example:  To search OpenStack Neutron IRC logs, set
# link = "http://eavesdrop.openstack.org/irclogs/%23openstack-neutron/"
#
# Usage:   ./search_openstack_irc.py <Regular expression to search in quotes>
#
# Examples:
#
# To search a whole word, escape \b as \\b
#
# $ ./search_openstack_irc.py "\\bvhosakot\\b"
# [u'vhosakot']
# 
# $ ./search_openstack_irc.py "\\bvho\\b"
# 
# $ ./search_openstack_irc.py "vhosakot"
# [u'vhosakot']
# 
# $ ./search_openstack_irc.py "vhosakot.*"
# [u'vhosakot has joined #openstack-kolla15:30']
# 
# $ ./search_openstack_irc.py ".*akot"
# [u'*** vhosakot']
# 
# $ ./search_openstack_irc.py ".*akot.*"
# [u'*** vhosakot has joined #openstack-kolla15:30']
#
##################################################################################

from bs4 import BeautifulSoup
from multiprocessing import Pool
import re
import sys
import urllib

def print_usage():
    print "\
        $ ./search_openstack_irc.py \"\\\\bvhosakot\\\\b\"  \n\
        [u'vhosakot']  \n\
          \n\
        $ ./search_openstack_irc.py \"\\\\bvho\\\\b\"  \n\
          \n\
        $ ./search_openstack_irc.py \"vhosakot\"  \n\
        [u'vhosakot']  \n\
          \n\
        $ ./search_openstack_irc.py \"vhosakot.*\"  \n\
        [u'vhosakot has joined #openstack-kolla15:30']  \n\
          \n\
        $ ./search_openstack_irc.py \".*akot\"  \n\
        [u'*** vhosakot']  \n\
          \n\
        $ ./search_openstack_irc.py \".*akot.*\"  \n\
        [u'*** vhosakot has joined #openstack-kolla15:30']  \n\
    "

if len(sys.argv) < 2:
    print "\nNothing to search."
    print "\nUsage:   ./search_openstack_irc.py <Regular expression to search in quotes>\n"
    print "Examples:"
    print_usage()
    sys.exit()

if len(sys.argv) > 2:
    print "\nEnter the regular expression to search in quotes."
    print "\nUsage:   ./search_openstack_irc.py <Regular expression to search in quotes>\n"
    print "Examples:"
    print_usage()
    sys.exit()

regexp_to_search = sys.argv[1]

# The link below can be changed to search any OpenStack project's IRC logs
# For example:  To search OpenStack Neutron IRC logs, set
# link = "http://eavesdrop.openstack.org/irclogs/%23openstack-neutron/"

link = "http://eavesdrop.openstack.org/irclogs/%23openstack-kolla/"
f = urllib.urlopen(link)
irc_page = f.read()

def t_search_in_each_irc_link(irc_link, regexp_to_search):
    f = urllib.urlopen(irc_link)
    html_page = f.read()
    soup = BeautifulSoup(html_page, "lxml")
    irc_logs = soup.text
    r = re.findall(regexp_to_search, irc_logs, re.IGNORECASE)
    if r != []:
        print "Found in ", irc_link

pool = Pool(processes=100)

for line in irc_page.splitlines():
    if ".html" in line and "href" in line:
        link_suffix = re.findall(r'"([^"]*)"', line)[0]
        irc_link = link + link_suffix
        pool.apply_async(t_search_in_each_irc_link, (irc_link, regexp_to_search))

pool.close()
pool.join()
