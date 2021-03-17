#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to apache2 servers |----------##
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
TEMP_CERT_FILE=$TEMP_CERT_DIR/cert.pem
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem
TEMP_CHAIN_FILE=$TEMP_CERT_DIR/chain.pem

APACHE_CERT_FILE=/etc/ssl/certs/cert.pem
APACHE_PRIVATE_KEY=/etc/ssl/private/privkey.key
APACHE_CHAIN_FILE=/etc/apache2/ssl.crt/chain.pem

LOG=/opt/certs_distrib/log/backuppc_certs.log


# Remove previous certificate
echo -e " Remove previous certificate " | tee -a $LOG

rm -f $APACHE_CERT_FILE $APACHE_PRIVATE_KEY $APACHE_CHAIN_FILE | tee -a $LOG

# Upload new certificate
echo -e " Upload new certificate" | tee -a $LOG

scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CERT_FILE" "$APACHE_CERT_FILE" | tee -a $LOG
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_PRIVATE_KEY" "$APACHE_PRIVATE_KEY" | tee -a $LOG
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CHAIN_FILE" "$APACHE_CHAIN_FILE" | tee -a $LOG

chown root:ssl-cert "$APACHE_PRIVATE_KEY" | tee -a $LOG

systemctl restart apache2 | tee -a $LOG

echo -e "Certs for $DOMAIN installed." | tee -a $LOG

exit 0
