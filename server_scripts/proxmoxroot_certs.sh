#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to Proxmox servers |----------##
## Author: TheCodeWithin			       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

SSH_HOST=certmanager
SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=/root/.ssh/id_rsa
SSH_PUBLIC_KEY=/root/.ssh/id_rsa.pub

DOMAIN=yourdomain.tld
TEMP_CERT_DIR=/home/$SSH_USER/certs/$DOMAIN
TEMP_CERT_FILE=$TEMP_CERT_DIR/fullchain.pem
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem

PRXMX_CERT_FILE=/etc/pve/local/pveproxy-ssl.pem
PRXMX_PRIVATE_KEY=/etc/pve/local/pveproxy-ssl.key

LOG=/opt/certs_distrib/log/proxmox_certs.log


# Remove previous certificate
echo -e " Remove previous certificate " | tee -a $LOG

rm -f $PRXMX_CERT_FILE $PRXMX_PRIVATE_KEY | tee -a $LOG

# Upload new certificate
echo -e " Upload new certificate" | tee -a $LOG

scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CERT_FILE" "$PRXMX_CERT_FILE" | tee -a $LOG
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_PRIVATE_KEY" "$PRXMX_PRIVATE_KEY" | tee -a $LOG

chown root:www-data "$PRXMX_CERT_FILE" | tee -a $LOG
chown root:www-data "$PRXMX_PRIVATE_KEY" | tee -a $LOG

systemctl restart pveproxy | tee -a $LOG

echo -e "Certs for $DOMAIN installed." | tee -a $LOG

exit 0
