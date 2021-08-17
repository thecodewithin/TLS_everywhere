#!/bin/bash

## ---------------------------------------------------------------##
## Script to apply TLS certificates to kubernetes      |----------##
## Author: $K8S_USER                               |----------##
## E-Mail: $K8S_USER@protonmail.com                |----------##
## ---------------------------------------------------------------##
#
# Modify variables to fit your needs

SSH_HOST=certmanager
SSH_PORT=22
SSH_USER=mailman
SSH_PRIVATE_KEY=/home/$SSH_USER/.ssh/id_rsa
SSH_PUBLIC_KEY=/home/$SSH_USER/.ssh/id_rsa.pub

DOMAIN=yourdomain.tld
TEMP_CERT_DIR=/home/$SSH_USER/certs/$DOMAIN
TEMP_CERT_FILE=$TEMP_CERT_DIR/cert.pem
TEMP_CHAIN_FILE=$TEMP_CERT_DIR/fullchain.pem
TEMP_PRIVATE_KEY=$TEMP_CERT_DIR/privkey.pem

K8S_USER=thecodewithin
K8S_CERT_FILE=/opt/certs_distrib/cert.pem
K8S_CHAIN_FILE=/opt/certs_distrib/certs/tls.crt
K8S_PRIVATE_KEY=/opt/certs_distrib/certs/tls.key

LOG=/opt/certs_distrib/log/k8s_certs.log

# Remove previous certificate
echo -e " Remove previous certificate " | tee -a $LOG

rm -f $K8S_CERT_FILE $K8S_CHAIN_FILE $K8S_PRIVATE_KEY | tee -a $LOG

# Upload new certificate
echo -e " Upload new certificate" | tee -a $LOG

scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CERT_FILE" "$K8S_CERT_FILE" | tee -a $LO
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_CHAIN_FILE" "$K8S_CHAIN_FILE" | tee -a $LOG
scp -q -P $SSH_PORT -i "$SSH_PRIVATE_KEY" "$SSH_USER"@"$SSH_HOST":"$TEMP_PRIVATE_KEY" "$K8S_PRIVATE_KEY" | tee -a $LOG

chown $K8S_USER:$K8S_USER "$K8S_CERT_FILE" | tee -a $LOG
chown $K8S_USER:$K8S_USER "$K8S_CHAIN_FILE" | tee -a $LOG
chown $K8S_USER:$K8S_USER "$K8S_PRIVATE_KEY" | tee -a $LOG

# Rancher
echo "Rancher" | tee -a $LOG
#su - $K8S_USER -c "kubectl -n cattle-system delete secret tls-rancher-ingress" | tee -a $LOG
su - $K8S_USER -c "kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=$K8S_CHAIN_FILE --key=$K8S_PRIVATE_KEY --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG
su - $K8S_USER -c "kubectl -n cattle-system create secret generic tls-ca --from-file=cacerts.pem=$K8S_CERT_FILE --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG

# Traefik
echo "Traefik" | tee -a $LOG
#su - $K8S_USER -c "kubectl -n networking delete secret tls-traefik-ingress" | tee -a $LOG
su - $K8S_USER -c "kubectl -n networking create secret tls tls-traefik-ingress --cert=$K8S_CHAIN_FILE --key=$K8S_PRIVATE_KEY --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG

# Harbor
echo "Harbor" | tee -a $LOG
#su - $K8S_USER -c "kubectl -n harbor delete secret tls-wildcard-secret" | tee -a $LOG
su - $K8S_USER -c "kubectl -n harbor create secret tls tls-wildcard-secret --cert=$K8S_CHAIN_FILE --key=$K8S_PRIVATE_KEY --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG
#su - $K8S_USER -c "kubectl -n harbor delete secret tlsca-wildcard-secret" | tee -a $LOG
su - $K8S_USER -c "kubectl -n harbor create secret generic tlsca-wildcard-secret --from-file=ca.crt=$K8S_CERT_FILE --from-file=tls.crt=$K8S_CHAIN_FILE --from-file=tls.key=$K8S_PRIVATE_KEY --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG

# Nextcloud
echo "Nextcloud" | tee -a $LOG
#su - $K8S_USER -c "kubectl -n nextcloud delete secret tls-wildcard-secret" | tee -a $LOG
su - $K8S_USER -c "kubectl -n nextcloud create secret tls tls-wildcard-secret --cert=$K8S_CHAIN_FILE --key=$K8S_PRIVATE_KEY --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG
#su - $K8S_USER -c "kubectl -n nextcloud delete secret tlsca-wildcard-secret" | tee -a $LOG
su - $K8S_USER -c "kubectl -n nextcloud create secret generic tlsca-wildcard-secret --from-file=ca.crt=$K8S_CERT_FILE --from-file=tls.crt=$K8S_CHAIN_FILE --from-file=tls.key=$K8S_PRIVATE_KEY --dry-run=client --save-config -o yaml | kubectl apply -f -" | tee -a $LOG

echo -e "Certs for $DOMAIN installed." | tee -a $LOG

exit 0
