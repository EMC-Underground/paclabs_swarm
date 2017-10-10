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
curl -sSL https://dl.bintray.com/emccode/rexray/install | sh
tar -xvf /tmp/EMC-ScaleIO-sdc-2.0-10000.2072.Ubuntu.16.04.x86_64.tar -C /tmp
cd /tmp
/tmp/siob_extract /tmp/EMC-ScaleIO-sdc-2.0-10000.2072.Ubuntu.16.04.x86_64.siob
MDM_IP=192.168.0.120,192.168.0.129 dpkg -i /tmp/EMC-ScaleIO-sdc-2.0-10000.2072.Ubuntu.16.04.x86_64.deb
mv /tmp/driver_sync.conf /bin/emc/scaleio/scini_sync/
/bin/emc/scaleio/scini_sync/driver_sync.sh scini retrieve Ubuntu/2.0.10000.2072/`uname -r`
service scini restart
/opt/emc/scaleio/sdc/bin/drv_cfg --add_mdm --ip "192.168.0.129,192.168.0.120" --file /bin/emc/scaleio/drv_cfg.txt
