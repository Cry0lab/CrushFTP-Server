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
cd ~
mkdir Backup-Network-Configs
cp /etc/sysconfig/network-scripts/ifcfg-$eth_interface ~/Backup-Network-Configs/ifcfg-$eth_interface.txt


#Gather user Preferences
echo "What would you like your static IP ADDRESS to be?"
read IP

validIP()
{
I=$IP
if [ "$(ipcalc -cs $I && echo 1 || echo 0)" == 0 ]; then
echo "Please enter a valid IP Address:"
read IP
validIP
return 0
fi
}

validIP

echo 
echo "$IP is a valid IP ADDRESS"
echo

echo "What is the SUBNET MASK of the network?"
read SUBNET

echo "What is the default gateway?"
read GATE

echo "What is the Primary DNS Server?"
read DNS1

echo "What is the Secondary DNS Server?"
read DNS2

echo "What is the Hostname of this server?"
read HOST

#Configure static IP
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-$eth_interface
TYPE=Ethernet
BOOTPROTO=static
IPADDR=$IP
NETMASK=$SUBNET
NM_CONTROLLED=no
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=$eth_interface
DEVICE=$eth_interface
ONBOOT=yes
EOF

service network restart

#Edit the network file to configure hostname and Gateway
cat <<EOF > /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=$HOST
GATEWAY=$GATE
EOF

service network restart

#Add dns nameservers
cat <<EOF > /etc/resolv.conf
nameserver $DNS1
nameserver $DNS2
EOF

service network restart
echo 
echo
echo "CrushFTP is now installed. Default admin login is crushadmin and password. "
echo
echo "Open a browser and go to https://$IP to start setting up CrushFTP."
echo
