#!/bin/bash

user=ubuntu
awskey=~/.ssh/aws-key-fast-ai.pem
preremove=appleby-pre-remove-remote.sh

set -e
shopt -s expand_aliases

echo "getting p2 instanceUrl"
source aws-alias.sh
aws-get-p2 > /dev/null
aws-dns > /dev/null

echo "running pre-remove on $instanceUrl"
scp -qi "$awskey" "$preremove" "$user@$instanceUrl:"
ssh -i "$awskey" "$user@$instanceUrl" "bash $preremove"

echo " calling fast-ai-remove.sh"
./fast-ai-remove.sh


