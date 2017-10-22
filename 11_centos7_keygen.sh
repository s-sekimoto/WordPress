#!/bin/bash
USER_NAME=testuser
SERVER_NAME=server
mkdir .ssh
chmod 700 .ssh
cd .ssh
ssh-keygen -t ecdsa -b 521 -C "${SERVER_NAME}_${USER_NAME}_id_ecdsa" -f "${SERVER_NAME}_${USER_NAME}_id_ecdsa" -N "P@ssw0rd" -q
mv ${SERVER_NAME}_${USER_NAME}_id_ecdsa.pub authorized_keys
chmod 600 authorized_keys
echo "${SERVER_NAME}_${USER_NAME}_id_ecdsa"
cat ${SERVER_NAME}_${USER_NAME}_id_ecdsa
