#!/bin/bash

cd /yv-at-pytn.ru/

echo "
ATTENTION: 
* Make sure AWS_KEY_ID has EC2 all privileges
* Make sure AWS_KEYPAIR_NAME exists in your key pair list for AWS Region us-east-1 (N.Virginia)
* Make sure you have a security group \"default\" in AWS Region us-east-1 (N.Virginia) with allowed 3389 (RDP) 5985 (HTTP) 5986 (HTTPS) 5433 (PGSQL).

All credentials you will find in TAGs of EC2 instance named PgWinServer-1 in N.Virginia region

For more information contact: yv@pytn.ru

Press [ENTER] to confirm
"
read ANS

echo "List of available ENV..."
env

if [ -z $AWS_KEY_ID ]; then
	echo "
ERROR: You need to specify env to docker with -e AWS_KEY_ID=<...>  -e AWS_ACCESS_KEY=<...>  -e AWS_KEYPAIR_NAME=<...> ";
	exit 1
fi
if [ -z $AWS_ACCESS_KEY ]; then
	echo "
ERROR: You need to specify env to docker with -e AWS_KEY_ID=<...>  -e AWS_ACCESS_KEY=<...>  -e AWS_KEYPAIR_NAME=<...> ";
	exit 1
fi
if [ -z $AWS_KEYPAIR_NAME ]; then
	echo "
ERROR: You need to specify env to docker with -e AWS_KEY_ID=<...>  -e AWS_ACCESS_KEY=<...>  -e AWS_KEYPAIR_NAME=<...> ";
	exit 1
fi

cp Vagrantfile.tmpl Vagrantfile

sed -i -e "s/AWS_KEY_ID/"${AWS_KEY_ID}"/g" Vagrantfile
sed -i -e "s/AWS_ACCESS_KEY/"${AWS_ACCESS_KEY}"/g" Vagrantfile
sed -i -e "s/AWS_KEYPAIR_NAME/"${AWS_KEYPAIR_NAME}"/g" Vagrantfile

vagrant up --provider=aws

rm -f Vagrantfile