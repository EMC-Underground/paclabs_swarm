#!/bin/bash

mkdir -p ~/.ssh
cat /tmp/keys >> ~/.ssh/authorized_keys
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    ntp \
    libaio1

# Install and update Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt update -y
apt install -y docker-ce

# Enable remote access to the docker daemon
sed -i '/ExecStart/c\ExecStart=/usr/bin/dockerd -H 0.0.0.0:2375 -H fd://' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker

# Don't require sudo to run docker commands
usermod -a -G docker $USER

# Install ScaleIO SDC
tar -xvf /tmp/EMC-ScaleIO-sdc-2.0-13000.211.Ubuntu.16.04.x86_64.tar -C /tmp
cd /tmp
/tmp/siob_extract /tmp/EMC-ScaleIO-sdc-2.0-13000.211.Ubuntu.16.04.x86_64.siob
dpkg -i /tmp/EMC-ScaleIO-sdc-2.0-13000.211.Ubuntu.16.04.x86_64.deb
mv /tmp/driver_sync.conf /bin/emc/scaleio/scini_sync/
/bin/emc/scaleio/scini_sync/driver_sync.sh scini retrieve Ubuntu/2.0.13000.211/`uname -r`
service scini restart

# This is for elastic search containers
echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf
sysctl -w vm.max_map_count=262144

# Install the root ca.crt
mv /tmp/ca.crt /usr/local/share/ca-certificates
update-ca-certificates
