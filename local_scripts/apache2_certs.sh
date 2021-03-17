#!/bin/bash


## ---------------------------------------------------------------##
## Script to apply TLS certificates to apache2 servers |----------##
## Author: TheCodeWithin			       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

DIR=/opt/certs_distrib
APACHES=$DIR/apaches

SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=$DIR/id_rsa
SSH_PUBLIC_KEY=$DIR/id_rsa.pub

LOG=/var/log/letsencrypt/apache2_certs.log

for apache in $(grep -v "#" $APACHES)
do
  APACHE_HOST=$apache

  echo "Initiate conection to $apache" | tee -a $LOG

  ssh -i $SSH_PRIVATE_KEY $SSH_USER@$APACHE_HOST -p $SSH_PORT 2>&1 | tee -a $LOG

  echo -e "Connection to $APACHE_HOST closed" | tee -a $LOG
done

exit 0
