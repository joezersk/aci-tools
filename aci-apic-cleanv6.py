#!/usr/bin/python

""" Script to SSH into APIC and each leaf and spine via OOB management port and factory reset and reload
    Original script by Palm 2016-04-29 - Yes/No function from Active State recipe 577058 (Trent Mick)
    Modifications for an ACI Fabric Reset by J.Ezerski 2016-05-02 and 07-07-2016, v2 Jan 2018, v6 Mar 2019
"""
import spur
import os
import sys


class bcolors:
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

try:
    from credentials import APIC_ADMIN, APIC_PASSWORD
except ImportError:
    sys.exit("Error: please verify credentials file format.")

print('\nThis script will log into APIC and each node, erase it, and auto reload it.')

def query_yes_no(question, default="yes"):
    valid = {"yes": "yes", "y": "yes", "ye": "yes",
             "no": "no", "n": "no"}
    if default == None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while 1:
        sys.stdout.write(question + prompt)
        choice = raw_input().lower()
        if default is not None and choice == '':
            return default
        elif choice in valid.keys():
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' " \
                             "(or 'y' or 'n').\n")
answer = query_yes_no("This is a destructive process.  Sure you want to continue?")
if answer == "no":
    quit()

# List with the node names or IP addresses.  APIC list uses a dictionary method.
# You should change the IP addresses of myApic to whatever your APICs use for OOB Management.  I assume a cluster of 3.
myApic = {"1":"10.50.129.241","2":"10.50.129.111","3":"1.1.1.1"}

# You should change the IP addresses of myNode to match the OOB IPs of all your leafs and spines.
# This example shows a seven node setup.  Feel free to add more to suit your own setup.
myNode = ["10.50.129.242","10.50.129.243","10.50.129.244","10.50.129.245","10.50.129.246","10.50.129.247","10.50.129.248"]

myName = APIC_ADMIN
myPassword = APIC_PASSWORD

def sshLogin(myNode,myName,myPassword):
    """ Open a connection to myNode using name myName and password myPassword and return the shell.
    Uses spur.ssh.MissingHostKey.accept to accept any host key.
    """

    shell = spur.SshShell(hostname=myNode,
                          username=myName,
                          password=myPassword,
                          connect_timeout=5,
                          missing_host_key=spur.ssh.MissingHostKey.accept,
                          shell_type=spur.ssh.ShellTypes.sh)
    return shell

def main():
    """ Call sshLogin to open a connection and the use the provided shell to issue a command
    """
    for key, value in myApic.iteritems():
        response = os.system("ping -c 1 -t 1 " + value + " > /dev/null 2>&1")
        if response == 0:
            try:
                shell = sshLogin(value, myName, myPassword)
                shell.run(["true"])
                print("\nLogged on to APIC controller " + value)
                result = shell.spawn(["acidiag", "touch", "setup"])
                result.stdin_write("y")
#                result = shell.run(["acidiag", "touch", "setup"])
                result = shell.spawn(["reload", "controller", key])
                result.stdin_write("Y")
                print (bcolors.OKGREEN + "\nErasing and reloading this APIC now..." + bcolors.ENDC)
                continue
            except spur.ssh.ConnectionError as error:
                print (bcolors.FAIL + "\nAPIC " + value + " is pingable but I cannot seem to SSH succesfully.  Moving on..." + bcolors.ENDC)
        else:
            print (bcolors.FAIL +  "\n" + value + " - APIC is not reachable, moving on..." + bcolors.ENDC)
main()

# Iterate through the list myNode

def node():
    for i in range(len(myNode)):
        response2 = os.system("ping -c 1 -t 1 " + myNode[i] + " > /dev/null 2>&1")
        if response2 == 0:
            try:
                shell = sshLogin(myNode[i],myName, myPassword)
                shell.run(["true"])
                print("\nLogged on to node " + myNode[i])
                result = shell.spawn(["acidiag", "touch", "clean"])
                result.stdin_write("y")
                result = shell.spawn(["reload"])
                result.stdin_write("y")
                print (bcolors.OKGREEN + "\nerasing and reloading node " + myNode[i] + " now....\n" + bcolors.ENDC)

            except spur.ssh.ConnectionError as error:
                print (bcolors.FAIL + "ALERT! " + myNode[i] + " - Node is pingable but I cannot seem to SSH succesfully.  Moving on..." + bcolors.ENDC)
                continue

        else:
            print (bcolors.FAIL + "\nLeaf or Spine at " + myNode[i] + " is not reachable, moving on..." + bcolors.ENDC)
node()

print ("\nAll Done!")