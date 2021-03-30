#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to Samba DC servers |----------##
## Author: TheCodeWithin			       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

DIR=/opt/certs_distrib
SAMBADCS=$DIR/smbdcs

SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=$DIR/id_rsa
SSH_PUBLIC_KEY=$DIR/id_rsa.pub

LOG=/var/log/letsencrypt/sambaDC_certs.log

for smbdc in $(grep -v "#" $SAMBADCS)
do
  SMBDC_HOST=$smbdc

  echo "Initiate conection to $smbdc" | tee -a $LOG

  ssh -i $SSH_PRIVATE_KEY $SSH_USER@$SMBDC_HOST -p $SSH_PORT 2>&1 | tee -a $LOG

  echo -e "Connection to $SMBDC_HOST closed" | tee -a $LOG
done

exit 0
