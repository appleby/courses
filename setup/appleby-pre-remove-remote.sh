#!/bin/bash

set -e
cd ~/nbs

echo "  > saving changes to git"
branch=p2-auto-commit
git checkout -q "$branch"
git commit -aqm "auto-commit on $(date)"
git push -q origin "$branch"

echo "  > copying data to t2micro"
t2micro=ec2-52-88-41-54.us-west-2.compute.amazonaws.com
tarball=data.tgz
tar -czf "$tarball" data
scp -qi ~/.ssh/aws-t2micro.pem "$tarball" "ec2-user@$t2micro:$tarball"

echo "  > remote-pre-remove finished"
