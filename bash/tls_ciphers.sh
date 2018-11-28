#!/usr/bin/env bash

################
#
# Script to check all TLS ciphers supported by a server
#
# Usage:
#   ./tls_ciphers.sh <server's IP address:server's port>
#
# To check all TLS ciphers supported by etcd server
#   ./tls_ciphers.sh 127.0.0.1:12379
#
################

SERVER=$1
DELAY=1
ciphers=$(openssl ciphers 'ALL:eNULL:@STRENGTH' | sed -e 's/:/ /g')

echo Obtaining cipher list from $(openssl version).

for cipher in ${ciphers[@]}
do
  echo ""
  echo "Testing cipher suite $cipher..." 
  openssl s_client -cipher "$cipher" -connect $SERVER 2>/dev/null | grep 'Secure Renegotiation\|Cipher.*:'
  sleep $DELAY
done
