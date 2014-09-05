The MANA Toolkit
================
by Dominic White (singe) & Ian de Villiers @ sensepost (research@sensepost.com)

Overview
--------
A toolkit for rogue access point (evilAP) attacks first presented at Defcon 22.

More specifically, it contains the improvements to KARMA attacks we implemented into hostapd, as well as some useful configs for conducting MitM once you've managed to get a victim to connect.

Contents
--------

It contains:
* install.sh - a simple installer for Kali 1.0.8 
* slides - an explanation of what we're doing here
* run-mana - the controller scripts
* hostapd-manna - modified hostapd that implements our new karma attacks
* crackapd - a tool for offloading the cracking of EAP creds to an external tool and re-adding them to the hostapd EAP config (auto crack 'n add)
* sslstrip-hsts - our modifications to LeonardoNVE's & moxie's cool tools
* apache - the apache vhosts for the noupstream hacks; deploy to /etc/apache2/ and /var/www/ respectivley

Installation
------------

To get up and running setup a Kali 1.0.8 box (VM or otherwise), update it, then run install.sh from /root/mana/

Installers for ubuntu on their way.

Running
-------

Change to the run-mana directory. Edit the start script you'd like to run, then fire it up. The different start script are:

* start-nat-full.sh - Will fire up MANA in NAT mode (you'll need an upstream link) with all the MitM bells and whistles.
* start-nat-simple.sh - Will fire up MANA in NAT mode, but without any of the firelamb, sslstrip, sslsplit etc.
* start-noupstream.sh - Will start MANA in a "fake Internet" mode. Useful for places where people leave their wifi on, but there is no upstream Internet. Also contains the captive portal.
* start-noupstream-eap.sh - Will start MANA with the EAP attack and noupstream mode.

While these should all work, it's advisable that you craft your own based on your specific needs.
