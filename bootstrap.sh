#!/usr/bin/env bash

apt-get update
apt-get install -y vim htop
apt-get clean

TARGET_DIR=/home/vagrant/shared
HOSTNAME=$(hostname -f)
OS_RELEASE=$(lsb_release -sd)
IP_ADDRESS=$(/sbin/ifconfig eth1 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')

echo $OS_RELEASE '-' $IP_ADDRESS > $TARGET_DIR/$HOSTNAME-$IP_ADDRESS.txt

echo '************************ Basic SysInfo ************************'

ruby -v
echo python `python -c 'import sys; print(sys.version[:5])'`
df -h /

exit 0
