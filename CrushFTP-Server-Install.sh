#!/bin/bash

#installs necessary programs
yum update -y
yum install wget nano unzip java net-tools open-vm-tools sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y
 
#Disables firewall
systemctl disable firewalld
systemctl stop firewalld

#Get the name First ethernet interface listed in ifconfig and current network settings
eth_interface=$(ifconfig | egrep -o -m 1 '^[^\t:]+')
DHCP_IP=$(ifconfig $eth_interface | grep -w inet | grep -v 127.0.0.1| awk '{print $2}' | cut -d ":" -f 2 )
DHCP_SUBNET=$(ifconfig $eth_interface | grep -w inet |grep -v 127.0.0.1| awk '{print $4}' | cut -d ":" -f 2 )
DHCP_GATEWAY=$(ip route list dev $eth_interface | awk ' /^default/ {print $3}' )
DHCP_UUID=$(cat /etc/sysconfig/network-scripts/ifcfg-$eth_interface | grep UUID )
#Backup the network config
cd ~
mkdir Backup-Network-Configs
cp /etc/sysconfig/network-scripts/ifcfg-$eth_interface ~/Backup-Network-Configs/ifcfg-$eth_interface.txt


###########<<<<<<<<FUNCTIONS>>>>>>>###########

isAlive() #Takes an IP Address and sees if it is alive or not
{
A=$(ping -c 4 $1 | grep Unreach | wc -l )
if [ "$A" != "0" ]; then
 echo "0" #ip is available
else
 echo "1" #Ip is alive
fi
}

realmJoin() #Joins a realm with redundancy. 
{
echo
echo "What is the name of the Domain you wish to join? (something.local usually):"
read Domain
echo
echo "What is the username for a Domain Admin for $Domain?:"
read Admin
realm join --user=$Admin $Domain
if [ $(realm list | less | grep $2 | wc -l) == "0" ]; then
 echo
 echo "Domain join failed."
 echo
 echo "Would you like to attempt to join a Domain again? ([y]/n):"
 
 case "$choice" in
 y|Y|$response ) RealmAgain="y";;
 n|N|* ) RealmAgain="n";;
 esac
 
 if [ "$AUTO_IP" =  "y" ]; then
  realmJoin
 else
  echo
  echo "Domain Join Canceled"
 fi
 
else
echo
echo "$Domain successfully joined!"
echo
fi
}

#Gather user Preferences for the Network
echo
echo
echo "Configuring Static Network settings:"
echo
echo
echo "Current Network Settings:"
echo "IP ADDRESS: $DHCP_IP"
echo "SUBNET MASK: $DHCP_SUBNET"
echo "DEFAULT GATEWAY: $DHCP_GATEWAY"
echo
echo
read -p "Would you like to accept these settings and assign them statically? ([y]/n)" choice
case "$choice" in
 y|Y|$response ) AUTO_IP="y";;
 n|N|* ) AUTO_IP="n";;
esac

#If the response is affirmative, skip to line 116. Otherwise, go to line 49
if [ "$AUTO_IP" =  "y" ]; then
IP=$DHCP_IP
SUBNET=$DHCP_SUBNET
GATE=$DHCP_GATEWAY
#echo $IP $SUBNET $GATE
else
#Ask for an IP ADDRESS
echo
echo
echo "What would you like your static IP ADDRESS to be?"
read IP

#Check to see if a valid IP ADDRESS was entered
validIP()
{
I=$IP

if [ "$(ipcalc -cs $I && echo 1 || echo 0)" == 0 ]; then
echo "That is not a valid IP Address. Please enter a valid IP Address:"
read IP
validIP
return 0
fi

if [ "$(isAlive $I)" == "1" ] && [ "$I" != "$DHCP_IP" ]; then
 echo "That IP ADDRESS is already in use. Please enter a different one:"
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
fi #Line 42


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
echo "Please enter a Hostname for this Server. WARNING: Whatever you enter will be accepted."
read HOST
echo
echo
echo "Applying your settings. The Network Service will now restart 3 times."
echo
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
$DHCP_UUID
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

hostnamectl set-hostname $HOST

service network restart

#Add dns nameservers
cat <<EOF > /etc/resolv.conf
nameserver $DNS1
nameserver $DNS2
EOF
service network restart

echo
realmJoin
echo

echo
echo "Network Configuration Complete. Now Installing CrushFTP"
echo
#Installation of CrushFTP
cd /var/opt/
wget https://www.crushftp.com/early8/CrushFTP8_PC.zip
unzip CrushFTP8_PC.zip
rm CrushFTP8_PC.zip
cd CrushFTP8_PC
chmod +x crushftp_init.sh
java -jar CrushFTP.jar -a "crushadmin" "password"
./crushftp_init.sh install


echo 
echo
echo "CrushFTP is now installed. Default admin login is crushadmin and password. "
echo
echo "Open a browser and go to https://$IP to start setting up CrushFTP."
echo
