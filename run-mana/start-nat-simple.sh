#!/bin/bash
# Original script by Dominic White and Ian de Villiers
# Changes made by John & Daniel Cuthbert 

# Other Useful variables defined
upstream=eth0
# phy=wlan0
conf=/etc/mana-toolkit/hostapd-karma.conf
hostapd=/usr/lib/mana-toolkit/hostapd
ifwl="(ifconfig | grep wlan*)"
S1='y'
S2='n'

clear

echo -e "\033[38;5;220m--------------------------------------------------\033[39m"
echo -e "\033[38;5;220m Welcome to SensePost's MANA \033[39m"
echo -e "\033[38;5;220m Making Rogue Access Points fun for all \033[39m"
echo -e "\033[38;5;220m @SensePost / http://sensepost.com \033[39m"
echo 
echo -e "\033[38;5;220m This script starts up will start MANA \033[39m"
echo -e "\033[38;5;220m in NAT mode, but without the following: \033[39m"
echo 
echo -e "\033[38;5;160m	[+] Firelamb \033[39m"
echo -e "\033[38;5;160m [+] sslstrip \033[39m"
echo -e "\033[38;5;160m	[+] sslsplit \033[39m"
echo -e  
echo -e "\033[38;5;220m You will, however, need an upstream link \033[39m" 

echo -e "\033[38;5;220m Press ENTER to continue \033[39m"
echo -e
echo -e "\033[38;5;220m--------------------------------------------------\033[39m"


read

# Prompts the user to ensure their hardware is compatable and properly configured
echo -e "\033[38;5;220mFor this system to work you will need to ensure you have the follwing:\033[39m"
echo -e
echo -e "\033[38;5;220m1. An active network connection for your 'upstream' traffic on eth0\033[39m"
echo -e "\033[38;5;220m2. A wireless network interface that supports 'Master Mode' (For best results use a device with an AR9271 chipset)\033[39m"
echo -e

# Confirmation to continue
function confirm()
{
echo -e "\033[38;5;220mWould you like to proceed?\033[39m"
echo -e
echo -e "\033[38;5;220mENTER y/n\033[39m"
read yn
if [ $yn == "$S1" ]
then
	echo -e "\033[38;5;120m Checking for an active network connection on eth0\033[39m"

elif [ $yn == "$S2" ]
then
	echo -e "\033[38;5;160mEXITING...${nc}\033[39m" && exit

else
	echo -e "Answer must entered as either 'y' or 'n'" && confirm

fi

# This detects wireless interfaces and exits if no suitable interfaces are found

ntst="$(ping 8.8.8.8 -c 1 -I eth0 | grep received | cut -f 2 -d ',' | cut -f 2 -d ' ')"  
if [ "${ntst}" = '1' ]
	then
		echo -e "\033[38;5;120m Whoop!! an active network connection has been detected\033[39m"

	else
		echo -e "\033[38;5;160m Arse, no active network connection was detected, You should fix this, I'm going to exit now\033[39m" && exit

fi

}

confirm


function detect()
{
echo -e "\033[38;5;120m Detecting wireless interfaces...\033[39m"

echo -e "\033[38;5;120m I've found the following available:\033[39m"
echo -e
ifconfig | grep wlan*
if [ "${ifwl}" == '' ]
then
	echo -e "\033[38;5;160m No wireless interfaces found. Check your antennas batteries and connectors. I'm going to exit now\033[39m" && exit

fi

}

detect


# prompts user to select their wlan from the list found during ifconfig
function sel()
{
echo -e
echo -e "\033[38;5;120m Which wireless interface would you like to use from those available?\033[39m"
read phy

}

sel


# determining wifi suitability
# Checks to ensure that <master mode> is supported by the wireless interface...exits and restarts network-manager if master mode is not supported
function mstrchk()
{
echo -e "\033[38;5;120m Checking that the wlan card is able to run in master mode.\033[39m"
mast="$(iw list | grep '* AP' | head -n1 | cut -d '*' -f 2 | cut -d ' ' -f 2 )"
if [ "${mast}" != 'AP' ]
then
	echo -e "\033[38;5;160m The current wireless interface does not support master mode, I'm going to exit now\033[39m" && exit # service network-manager start && exit

fi

}

mstrchk

# figure out how to change this back to the orignial hostname when finished...perhaps assign the output of <echo /etc/hostname> to a variable and then run <hostname ${vairable name}>???
function nmchng()
{
echo -e "${grn}[+]${nc} Temporarily changing hostname to ${red}WRT54G${nc}."  # Will this change only affect this terminal session.?"
hostname WRT54G
echo hostname WRT54G
sleep 2
}

nmchng

service network-manager stop
rfkill unblock wlan


ifconfig $phy up

sed -i "s/^interface=.*$/interface=$phy/" $conf
$hostapd $conf&
sleep 5

echo "[+] Setting >$phy< to 10.0.0.1 with a netmask of 255.255.255.0"
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

echo "[+] Configuring dhcpd."
dhcpd -cf /etc/mana-toolkit/dhcpd.conf $phy

echo "[+] Setting iptables to ACCEPT traffic."
echo -e "${red}[!]${nc} iptables will be FLUSHED when complete but we would recommend you check this manually to be sure"
echo "1" > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
iptables -A FORWARD -i $phy -o $upstream -j ACCEPT

echo "Hit enter to kill me"
read
echo "[!] Killing dhcpd"
pkill dhcpd
echo "[!] Killing sslstrip"
pkill sslstrip
echo "[!] Killing sslsplit"
pkill sslsplit
echo "[!] Killing hostapd"
pkill hostapd
echo "[!] Killing python"
pkill python
echo "[!] Flushing iptables"
iptables -t nat -F
echo "[+] Restarting Network Manager"
service network-manager start
echo "EXITING..." && exit
