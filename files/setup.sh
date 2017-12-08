#!/bin/bash

> /etc/machine-id

mkdir -p ~/.ssh
cat /tmp/keys >> ~/.ssh/authorized_keys
yum -y update

sudo yum -y install ftp

mv /tmp/*.pem /etc/pki/ca-trust/source/anchors
sudo update-ca-trust

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce
sudo systemctl start docker
sudo systemctl enable docker

sudo useradd -p $(echo "password" | openssl passwd -1 -stdin) -g docker docker
sudo gpasswd -a docker wheel

firewall-cmd --permanent --add-port=2375-2376/tcp  # API ports
firewall-cmd --permanent --add-port=2377/tcp  # management communication
firewall-cmd --permanent --add-port=7946/tcp  # node communication
firewall-cmd --permanent --add-port=7946/udp  # node communication
firewall-cmd --permanent --add-port=4789/udp  # overlay network traffic
firewall-cmd --reload

cd /tmp
unzip /tmp/ScaleIO_2.0.1.4_RHEL_OEL7_Download
cd /tmp/ScaleIO_2.0.1.4_RHEL_OEL7_Download
MDM_IP=$1 rpm -i EMC-ScaleIO-sdc-2.0-14000.231.el7.x86_64.rpm

echo 'y' | docker plugin install rexray/scaleio:latest SCALEIO_ENDPOINT=https://$2/api SCALEIO_USERNAME=$3 SCALEIO_PASSWORD=$4 SCALEIO_PROTECTIONDOMAINNAME=$5 SCALEIO_STORAGEPOOLNAME=$6 REXRAY_LOGLEVEL=debug
