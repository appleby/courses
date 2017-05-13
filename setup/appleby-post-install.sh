#!/bin/bash

instanceUrl=${1:?Must specify instance url.}
user=ubuntu
postinstall=appleby-post-install-remote.sh
awskey=~/.ssh/aws-key-fast-ai.pem

set -e

echo "Copying files to $instanceUrl..."
ssh-keyscan -H "$instanceUrl" >> ~/.ssh/known_hosts 2>/dev/null
scp -i "$awskey" ~/.ssh/aws-t2micro.pem ./secrets/fastai_rsa "$user@$instanceUrl:.ssh" > /dev/null 2>&1
scp -i "$awskey" "$postinstall" "$user@$instanceUrl:" > /dev/null 2>&1

echo "Running remote post-install on $instanceUrl..."
sha1="$(cat ./secrets/jupyter-notebookapp-password-sha1)"
ssh -i "$awskey" "$user@$instanceUrl" "bash $postinstall $instanceUrl $sha1"
