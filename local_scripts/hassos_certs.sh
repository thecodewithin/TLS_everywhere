#!/bin/bash


## ---------------------------------------------------------------##
## Script to apply TLS certificates to HomeAssistant   |----------##
## Author: TheCodeWithin			       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

DIR=/opt/certs_distrib
HASSOS=$DIR/hassos

SSH_PORT=22
SSH_USER=mailmań
SSH_PRIVATE_KEY=$DIR/id_rsa
SSH_PUBLIC_KEY=$DIR/id_rsa.pub

DOMAIN=danarper.casa
TEMP_CERT_DIR=/home/$SSH_USER/certs/$DOMAIN
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem
TEMP_CHAIN_FILE=$TEMP_CERT_DIR/fullchain.pem

HASSOS_USER=root

LOG=/var/log/letsencrypt/hassos_certs.log

for hassos in $(grep -v "#" $HASSOS)
do
  HASSOS_HOST=$hassos

  echo "Initiate conection to $hassos" | tee -a $LOG

  ssh -i $SSH_PRIVATE_KEY $HASSOS_USER@$HASSOS_HOST -p $SSH_PORT 2>&1 | tee -a $LOG

  echo -e "Connection to $HASSOS_HOST closed" | tee -a $LOG
done

exit 0
