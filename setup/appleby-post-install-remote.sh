#!/bin/bash

instanceUrl=${1:?Must specify instance URL.}
jupyter_nb_sha=${2:?Must specify jupyter notebookapp password sha.}
jupyter_nb_config=~/.jupyter/jupyter_notebook_config.py
certfile=~/.jupyter/notebook.pem
keyfile=~/.jupyter/notebook.key

set -e

rm -rf ~/git

echo "  > setting up jupyter notebook"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/C=US/ST=OR/L=Somewhere/O=Fastai/CN=$instanceUrl" \
	-keyout "$keyfile" -out "$certfile" \
	> /dev/null 2>&1
sed -i -e "s/\(c.NotebookApp.password = u\)'\([^']*\)'/\1'$jupyter_nb_sha'/" "$jupyter_nb_config"
echo "c.NotebookApp.certfile = u'$certfile'" >> "$jupyter_nb_config"
echo "c.NotebookApp.keyfile = u'$keyfile'" >> "$jupyter_nb_config"

echo "  > setting up ssh keys"
mv ~/.ssh/fastai_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/aws-t2micro.pem

echo "  > cloning appleby/fastai-courses"
ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null
chmod 600 ~/.ssh/known_hosts
git clone git@github.com:appleby/fastai-courses.git > /dev/null 2>&1

echo "  > copying data from t2micro"
t2micro=ec2-52-88-41-54.us-west-2.compute.amazonaws.com
jupyter_nb_startup_dir=fastai-courses/deeplearning1/nbs
ssh-keyscan -H "$t2micro" >> ~/.ssh/known_hosts 2>/dev/null
scp -i ~/.ssh/aws-t2micro.pem "ec2-user@$t2micro:data.tgz" /dev/stdout 2>/dev/null \
    | tar -C "$jupyter_nb_startup_dir" -xzf -

echo "  > creating nbs symlink and run-nb.sh"
rm -rf ~/nbs
ln -s "$jupyter_nb_startup_dir" ~/nbs
cat > run-nb.sh <<EOF
#!/bin/bash
cd "$jupyter_nb_startup_dir"
jupyter notebook
EOF
chmod u+x run-nb.sh

echo "  > installing kaggle-cli"
/home/ubuntu/anaconda2/bin/pip install kaggle-cli > /dev/null 2>&1
/home/ubuntu/anaconda2/bin/kg config -g -u mappleby > /dev/null 2>&1

echo "  > installing unzip"
sudo apt install unzip > /dev/null 2>&1

echo "  > remote setup finished."
