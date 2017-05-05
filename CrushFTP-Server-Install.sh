#!/bin/bash

#installs necessary programs
yum update -y
yum install wget nano unzip java sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y
 
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
echo
echo
echo "Configuring Network settings:"
echo
echo

#Ask for an IP ADDRESS
echo "What would you like your static IP ADDRESS to be?"
read IP

#Check to see if a valid IP ADDRESS was entered
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


#Ask for a SUBNET MASK
echo "What is the SUBNET MASK of the network?"
read SUBNET

#Check to see if a valid SUBNET MASK was entered
validSUBNET()
{
I=$SUBNET
if [ "$(ipcalc -cs $I && echo 1 || echo 0)" == 0 ]; then
echo "Please enter a valid SUBNET MASK:"
read SUBNET
validSUBNET
return 0
fi
}

validSUBNET

echo 
echo "$SUBNET is a valid SUBNET MASK"
echo

#Ask for a Default Gateway
echo "What is the default gateway?"
read GATE

#Check to see if a valid Default Gateway was entered
validGATE()
{
I=$GATE
if [ "$(ipcalc -cs $I && echo 1 || echo 0)" == 0 ]; then
echo "Please enter a valid Default Gateway:"
read GATE
validGATE
return 0
fi
}

validGATE

echo 
echo "$GATE is a valid Default Gateway"
echo

#Ask for a Primary DNS Server
echo "What is the Primary DNS Server? (If you plan on joining a Domain, use the Primary DNS server of the Domain Controller.)"
read DNS1

#Check to see if a valid Primary DNS Server was entered
validDNS1()
{
I=$DNS1
if [ "$(ipcalc -cs $I && echo 1 || echo 0)" == 0 ]; then
echo "Please enter a valid Primary DNS Server:"
read DNS1
validDNS1
return 0
fi
}

validDNS1

echo 
echo "$DNS1 is a valid Primary DNS Server"
echo

#Ask for a Secondary DNS Server
echo "What is the Secondary DNS Server?"
read DNS2

#Check to see if a valid Secondary DNS Server was entered
validDNS2()
{
I=$DNS2
if [ "$(ipcalc -cs $I && echo 1 || echo 0)" == 0 ]; then
echo "Please enter a valid Secondary DNS Server:"
read DNS2
validDNS2
return 0
fi
}

validDNS2

echo 
echo "$DNS2 is a valid Secondary DNS Server"
echo

#Ask for a Hostname
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

#Join the server to a Domain
echo "What Domain would you like to join?"
read DOM
echo
echo "What is the username for the Domain Administrator? (Leave out the 'Domain\' part)"
read DOMADMIN
realm join --user=$DOMADMIN $DOM
echo

echo "CrushFTP is now installed. Default admin login is crushadmin and password. "
echo
echo "Open a browser and go to https://$IP to start setting up CrushFTP."
echo
