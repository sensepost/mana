The MANA toolkit
by singe & ian de villiers @ sensepost (research@sensepost.com)

A toolkit for rogue access point (evilAP) attacks presented at Defcon 22.

This is a placeholder readme until we get more time to write a proper one :)

It contains:
* slides - an explanation of what we're doing here
* run-mana - the controller scripts
* hostapd-manna - modified hostapd that implements our new karma attacks
* crackapd - a tool for offloading the cracking of EAP creds to an external tool and re-adding them to the hostapd EAP config (auto crack 'n add)
* sslstrip-hsts - our modifications to LeonardoNVE's & moxie's cool tools
* apache - the apache vhosts for the noupstream hacks; deploy to /etc/apache2/ and /var/www/ respectivley

