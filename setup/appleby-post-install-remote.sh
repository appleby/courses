#!/bin/bash

instanceUrl=${1:?Must specify instance URL.}
jupyter_nb_sha=${2:?Must specify jupyter notebookapp password sha.}
jupyter_nb_config=~/.jupyter/jupyter_notebook_config.py
certfile=~/.jupyter/notebook.pem
keyfile=~/.jupyter/notebook.key

exec 3>&1 4>&2 > ~/post-install.log 2>&1

echo3() {
    echo "$@" >&3
}

set -e

rm -rf ~/git

echo3 "  > setting up jupyter notebook"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/C=US/ST=OR/L=Somewhere/O=Fastai/CN=$instanceUrl" \
	-keyout "$keyfile" -out "$certfile"
sed -i -e "s/\(c.NotebookApp.password = u\)'\([^']*\)'/\1'$jupyter_nb_sha'/" "$jupyter_nb_config"
echo "c.NotebookApp.certfile = u'$certfile'" >> "$jupyter_nb_config"
echo "c.NotebookApp.keyfile = u'$keyfile'" >> "$jupyter_nb_config"

echo3 "  > setting up ssh keys"
mv ~/.ssh/fastai_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
chmod 600 ~/.ssh/aws-t2micro.pem

echo3 "  > configuring git"
git config --global user.name "Mike Appleby"
git config --global user.email "mike@app.leby.org"

echo3 "  > cloning appleby/fastai-courses"
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
git clone git@github.com:appleby/fastai-courses.git

echo3 "  > copying data from t2micro"
t2micro=ec2-52-88-41-54.us-west-2.compute.amazonaws.com
jupyter_nb_startup_dir=fastai-courses/deeplearning1/nbs
data_tgz=data.tgz
ssh-keyscan -H "$t2micro" >> ~/.ssh/known_hosts
scp -i ~/.ssh/aws-t2micro.pem "ec2-user@$t2micro:$data_tgz" "$data_tgz"
tar -C "$jupyter_nb_startup_dir" -xzf "$data_tgz"
rm "$data_tgz"

echo3 "  > creating nbs symlink and run-nb.sh"
rm -rf ~/nbs
ln -s "$jupyter_nb_startup_dir" ~/nbs
cat > run-nb.sh <<EOF
#!/bin/bash
cd "$jupyter_nb_startup_dir"
nohup jupyter notebook > $HOME/nohup.out 2>&1 &
EOF
chmod u+x run-nb.sh

echo3 "  > installing kaggle-cli"
/home/ubuntu/anaconda2/bin/pip install kaggle-cli
/home/ubuntu/anaconda2/bin/kg config -g -u mappleby

echo3 "  > installing unzip"
sudo apt-get update -y
sudo apt install -y unzip

echo3 "  > remote setup finished."
