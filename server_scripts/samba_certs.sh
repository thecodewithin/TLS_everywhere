#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to samba DC servers|----------##
## Author: TheCodeWithin                               |----------##
## E-Mail: thecodewithin@protonmail.com                |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

SSH_HOST=certmanager
SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=/root/.ssh/id_rsa
SSH_PUBLIC_KEY=/root/.ssh/id_rsa.pub

DOMAIN=subdomain.yourdomain.tld
TEMP_CERT_DIR=/home/$SSH_USER/certs/$DOMAIN
TEMP_CERT_FILE=$TEMP_CERT_DIR/fullchain.pem
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem

SAMBA_CERT_FILE=/var/lib/samba/private/tls/fullchain.pem
SAMBA_PRIVATE_KEY=/var/lib/samba/private/tls/privkey.pem

LOG=/opt/certs_distrib/log/samba_certs.log

# Remove previous certificate
echo -e " Remove previous certificate " | tee -a $LOG

rm -f $SAMBA_CERT_FILE $SAMBA_PRIVATE_KEY | tee -a $LOG

# Upload new certificate
echo -e " Upload new certificate" | tee -a $LOG

scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CERT_FILE" "$SAMBA_CERT_FILE" | tee -a $LOG
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_PRIVATE_KEY" "$SAMBA_PRIVATE_KEY" | tee -a $LOG

chown root:root "$SAMBA_CERT_FILE" | tee -a $LOG
chown root:root "$SAMBA_PRIVATE_KEY" | tee -a $LOG

systemctl restart samba-ad-dc.service | tee -a $LOG

echo -e "Certs for $DOMAIN installed." | tee -a $LOG

exit 0
