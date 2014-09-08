#!/usr/bin/env bash

echo SensePost Mana Installer
echo [+] This is not a very good installer, it makes a lot of assumptions
echo [+] It assumes you are running Kali 1.0.8 and mana in in /root/mana
echo [+] If you are worried about that, hit Ctl-C now, or hit Enter to continue
read
apt-get install libnl-dev isc-dhcp-server tinyproxy
cd hostapd-manna/hostapd/
make
cd ../../apache
cp -R . /
a2enmod rewrite
echo "[+] All done, I think, run one of the run-mana/start-*.sh scripts now"
