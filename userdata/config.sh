#!/bin/sh
# Configure application below
sudo yum install -y wget
wget -O bitnami-mean-linux-installer.run https://bitnami.com/stack/mean/download_latest/linux-x64
chmod 755 bitnami-mean-linux-installer.run
./bitnami-mean-linux-installer.run << EOF
Y
Y
Y
Y
Y
/home/opc/meanstack-3.6.5-1
Oracle123
Oracle123
Y
Y
EOF
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
