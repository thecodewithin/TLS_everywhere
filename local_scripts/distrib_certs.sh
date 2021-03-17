#!/bin/bash

## ---------------------------------------------------------------##
## Script to initiate distribution of TLS certificates  |----------##
## Can be called manually or through certbot's   |----------##
## --deploy-hook parameter to automate it        |----------##
##                      				       |----------##
## Author: TheCodeWithin				       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

DIR=/opt/certs_distrib
DESTINS=$DIR/destins

DOMAIN=yourdomain.tld
LETSENCRYPT_CERT_FILE=/etc/letsencrypt/live/$DOMAIN/cert.pem
LETSENCRYPT_FULL_FILE=/etc/letsencrypt/live/$DOMAIN/fullchain.pem
LETSENCRYPT_PRIVATE_KEY=/etc/letsencrypt/live/$DOMAIN/privkey.pem
LETSENCRYPT_CHAIN_FILE=/etc/letsencrypt/live/$DOMAIN/chain.pem

SSH_USER=mailman
TEMP_CERT_DIR=/home/$SSH_USER/certs/$DOMAIN
TEMP_CERT_FILE=$TEMP_CERT_DIR/cert.pem
TEMP_FULL_FILE=$TEMP_CERT_DIR/fullchain.pem
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem
TEMP_CHAIN_FILE=$TEMP_CERT_DIR/chain.pem

LOG=/var/log/letsencrypt/distrib_certs.log

# Copy certs where $SSH_USER can read them
echo "Copy certs where $SSH_USER can read them" | tee -a $LOG

if [ ! -d "$TEMP_CERT_DIR" ]
then
  mkdir -p $TEMP_CERT_DIR
  chown $SSH_USER:$SSH_USER $TEMP_CERT_DIR
fi

cp -p "$LETSENCRYPT_CERT_FILE" "$TEMP_CERT_FILE" | tee -a $LOG
cp -p "$LETSENCRYPT_FULL_FILE" "$TEMP_FULL_FILE" | tee -a $LOG
cp -p "$LETSENCRYPT_PRIVATE_KEY" "$TEMP_PRIVATE_KEY" | tee -a $LOG
cp -p "$LETSENCRYPT_CHAIN_FILE" "$TEMP_CHAIN_FILE" | tee -a $LOG
chown -R $SSH_USER:$SSH_USER $TEMP_CERT_DIR | tee -a $LOG

for desti in $(grep -v "#" $DESTINS)
do
  echo "==========================================" | tee -a $LOG
  echo "Initiate deployment: $desti" | tee -a $LOG
  echo "==========================================" | tee -a $LOG

  $desti | tee -a $LOG

  echo "==========================================" | tee -a $LOG
  echo -e "Certs for $DOMAIN deployed: $desti" | tee -a $LOG
  echo "==========================================" | tee -a $LOG
  echo " "
done

# Delete temporary files
# echo "Cleaning up" | tee -a $LOG
# sleep 30
# rm -rf $TEMP_CERT_DIR/* | tee -a $LOG
echo "Done" | tee -a $LOG

exit 0
