#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to Proxmox servers |----------##
## Author: TheCodeWithin			       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

DIR=/opt/certs_distrib
PRXMXS=$DIR/prxmxs

SSH_PORT=22
SSH_USER=root
SSH_PRIVATE_KEY=$DIR/id_rsa
SSH_PUBLIC_KEY=$DIR/id_rsa.pub

LOG=/var/log/letsencrypt/proxmox_certs.log

for prxmx in $(grep -v "#" $PRXMXS)
do
  PRXMX_HOST=$prxmx

  echo "Initiate conection to $prxmx" | tee -a $LOG

  ssh -i $SSH_PRIVATE_KEY $SSH_USER@$PRXMX_HOST -p $SSH_PORT 2>&1 | tee -a $LOG

  echo -e "Connection to $PRXMX_HOST closed" | tee -a $LOG
done

exit 0
