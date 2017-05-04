#!/bin/bash

#installs necessary programs
yum update -y
yum install wget nano unzip java -y
 
#Disables firewall
systemctl disable firewalld
systemctl stop firewalld

#Installation of CrushFTP
cd /var/opt/
wget https://www.crushftp.com/early8/CrushFTP8_PC.zip
unzip CrushFTP8_PC.zip
rm CrushFTP8_PC.zip
cd CrushFTP8_PC
chmod +x crushftp_init.sh
java -jar CrushFTP.jar -a "crushadmin" "password"
./crushftp_init.sh install


#Get the name First ethernet interface listed in ifconfig
eth_interface=$(ifconfig | egrep -o -m 1 '^[^\t:]+')

#Backup the network config
cp /etc/sysconfig/network-scripts/ifcfg-$eth_interface /etc/sysconfig/network-scripts/ifcfg-$eth_interface.bk


#Set static IP
echo "What would you like your static IP ADDRESS to be?"
read IP

echo "What is the SUBNET MASK of the network?"
read SUBNET

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$eth_interface
DEVICE=$eth_interface
BOOTPROTO=static
IPADDR=$IP
NETMASK=$SUBNET
ONBOOT=yes
EOF

service network restart

echo "CrushFTP is now installed. Default admin login is crushadmin and password. "
echo "Open a browser and go to https://$IP to start setting up CrushFTP."
