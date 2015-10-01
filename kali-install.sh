#!/usr/bin/env bash

echo SensePost Mana Installer
echo [+] This is not a very good installer, it makes a lot of assumptions
echo [+] It assumes you are running Kali
echo [+] If you are worried about that, hit Ctl-C now, or hit Enter to continue
read

# Install build dependencies
# Checking for Kali 2, since libnl1 is not prebuild any longer
if grep "Kali GNU/Linux 2" /etc/lsb-release &>/dev/null; then
	# Running Kali Linux 2.x
	# Changing the config file to use libnl 3.2
	sed -i 's/#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/' hostapd-mana/hostapd/.config
	apt-get --yes install libnl-genl-3-dev libssl-dev
else
	apt-get --yes install libnl-dev libssl-dev
fi


make

# Install dependencies
apt-get --yes install apache2 dsniff isc-dhcp-server macchanger \
    metasploit-framework python-dnspython python-pcapy python-scapy \
    sslsplit stunnel4 tinyproxy procps iptables asleap scapy
make install

echo "[+] All done, I think, run one of the run-mana/start-*.sh scripts now"
