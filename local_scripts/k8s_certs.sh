#!/bin/bash


## ---------------------------------------------------------------##
## Script to apply TLS certificates to Kubernetes      |----------##
## Author: TheCodeWithin			       |----------##
## E-Mail: thecodewithin@protonmail.com		       |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

DIR=/opt/certs_distrib
K8S_MAN=$DIR/k8s_mans

SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=$DIR/id_rsa
SSH_PUBLIC_KEY=$DIR/id_rsa.pub

LOG=/var/log/letsencrypt/k8s_man_certs.log

for k8s_man in $(grep -v "#" $K8S_MAN)
do
  K8S_MAN_HOST=$k8s_man

  echo "Initiate conection to $k8s_man" | tee -a $LOG

  ssh -i $SSH_PRIVATE_KEY $SSH_USER@$K8S_MAN_HOST -p $SSH_PORT 2>&1 | tee -a $LOG

  echo -e "Connection to $K8S_MAN_HOST closed" | tee -a $LOG
done

exit 0
