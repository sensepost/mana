#!/usr/bin/env bash

echo SensePost Mana Installer
echo [+] This is not a very good installer, it makes a lot of assumptions
echo [+] It assumes you are running Kali
echo [+] If you are worried about that, hit Ctl-C now, or hit Enter to continue
read

# Install build dependencies
apt-get install libnl-dev libssl-dev
make

# Install dependencies
apt-get install apache2 dsniff isc-dhcp-server macchanger \
    metasploit-framework python-dnspython python-pcapy python-scapy \
    sslsplit stunnel4 tinyproxy procps iptables asleap scapy
make install

#Disable the default apache site on Kali as it is replaced by mana's
a2dissite 000-default

echo "[+] All done, I think, run one of the run-mana/start-*.sh scripts now"
