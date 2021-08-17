#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to HAss OS servers |----------##
## Author: TheCodeWithin                               |----------##
## E-Mail: thecodewithin@protonmail.com                |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

SSH_HOST=certmanager.yourdomain.tld
SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=/root/.ssh/id_rsa
SSH_PUBLIC_KEY=/root/.ssh/id_rsa.pub

DOMAIN=yourdomain.tld
TEMP_CERT_DIR=/home/$SSH_USER/certs/$DOMAIN
TEMP_CERT_FILE=$TEMP_CERT_DIR/fullchain.pem
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem

HASSOS_CHAIN_FILE=/ssl/fullchain.pem
HASSOS_PRIVATE_KEY=/ssl/privkey.pem

LOG=/addons/TLS_everywhere/log/hassos_certs.log


# Remove previous certificate
echo -e " Remove previous certificate " | tee -a $LOG

rm -f $HASSOS_CHAIN_FILE $HASSOS_PRIVATE_KEY | tee -a $LOG

# Upload new certificate
echo -e " Upload new certificate" | tee -a $LOG

scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CERT_FILE" "$HASSOS_CHAIN_FILE" | tee -a $LOG
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_PRIVATE_KEY" "$HASSOS_PRIVATE_KEY" | tee -a $LOG

echo -e "Certs for $DOMAIN installed." | tee -a $LOG

exit 0
