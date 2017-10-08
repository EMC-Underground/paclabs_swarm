#!/bin/bash

mkdir -p ~/.ssh
cat /tmp/keys >> ~/.ssh/authorized_keys
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    ntp \
    ntpdate
service ntp stop
ntpdate -s minnie.lss.emc.com
service ntp start
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt update -y
apt install -y docker-ce
sed -i '/ExecStart/c\ExecStart=/usr/bin/dockerd -H 0.0.0.0:2375 -H fd://' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker
usermod -a -G docker $USER
