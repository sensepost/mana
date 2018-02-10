#!/usr/bin/python2

import argparse
import sys
import os


parser = argparse.ArgumentParser(
                    description='Mana script wrapper',
                    epilog='*** Making Mana great again! ***', 
                    formatter_class=argparse.RawTextHelpFormatter)
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument("-snf", action='store_true', help="Will fire up MANA in NAT mode (you'll need an upstream link) with all the MitM bells and whistles")
group.add_argument("-sns", action='store_true', help="Will fire up MANA in NAT mode, but without any of the firelamb, sslstrip, sslsplit etc")
group.add_argument("-snos", action='store_true', help="Will start MANA in a 'fake Internet' mode. Useful for places where people leave their\n" + 
                                                        "wifi on, but there is no upstream Internet. Also containsthe captive portal.")
group.add_argument("-snoseap", action='store_true', help="Will start MANA with the EAP attack and noupstream mode")
#parser.add_argument("hash_file", help="File containing NTLM hashes", type=str)
#parser.add_argument("working_directory", help="Directory where files will be written to.")
#parser.add_argument("-l", "--level", type=int, choices=[0, 1, 2],default=0, help="0-> Default" + '\n' + "1-> GPU Cracking" + '\n' + "2-> Mask Cracking")
#parser.add_argument("-l", "--level", type=int, choices=[0, 1, 2], help="0-> Default" + '\n' + "1-> Default + GPU Cracking" + '\n' + "2-> Default + GPU Cracking + Mask Cracking")

args = parser.parse_args()

#quick_Cracking = False
#gpu_Cracking = False
#mask_Cracking = False

if args.snf:
    os.system("bash start-nat-full.sh")
elif args.sns:
   os.system("bash start-nat-simple.sh")
elif args.snos:
   os.system("bash start-noupstream.sh")
elif args.snoseap:
   os.system("bash start-noupstream-eap.sh")
