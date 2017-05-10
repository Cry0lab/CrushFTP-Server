# CrushFTP-Server
This script can be run from a fresh install or an already running install of CENTOS 7. In theory, this should work in RHEL, but that has not been tested. This will not run inside of Debian based systems.


#Must be run as root.#



How to run this script:

cd ~

yum install git -y

git clone git://github.com/YankeeForty2/CrushFTP-Server.git

cd CrushFTP-Server/

chmod +x CrushFTP-Server-Install.sh

./CrushFTP-Server-Install.sh



The script will do the following in this order:

1: Install dependencies (wget nano unzip java)

2: Stop and Disable the OS Firewall

3: Set static network settings. It will prompt you if you would like to keep the current settings for IP ADDRESS, SUBNET MASK, and DEFAULT GATEWAY. DNS and Hostname will always need to be set statically. The network service will restart 3 times.

4: Install the CrushFTP server and set the default admin credentials.

############################################################
#                      WARNING                             #
############################################################

The installation of CrushFTP is contigent upon a wget command. Specifically wget https://www.crushftp.com/early8/CrushFTP8_PC.zip
Should the installation fail due to a wget error, edit the script to account for the change in download link found on CrushFTP.com
