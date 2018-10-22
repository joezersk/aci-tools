#!/usr/bin/python

""" Script to SSH into APIC and each leaf and spine via OOB management port and factory reset and reload
    Original script by Palm 2016-04-29 - Yes/No function from Active State recipe 577058 (Trent Mick)
    Modifications for an ACI Fabric Reset by J.Ezerski 2016-05-02 and 07-07-2016, Updated to v2 Jan 2018
"""
import spur
import os
import sys

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

# List with the host names or IP addresses.  APIC list uses a dictionary method
# Don't forget to enter your own IP addresses and creds - these are just dummy placeholders
# Add or remove Apic and hosts to fit your own setup

myApic = {"1":"1.1.1.1","2":"1.1.1.2","3":"1.1.1.3"}
myHost = ["10.1.1.10","10.1.1.11","10.1.1.12","10.1.1.13","10.1.1.14","10.1.1.15","10.1.1.16"]
myName = "admin"
myPassword = "cisco123"

def sshLogin(myHost,myName,myPassword):
    """ Open a connection to myHost using name myName and password myPassword and return the shell.
    Uses spur.ssh.MissingHostKey.accept to accept any host key.
    """

    shell = spur.SshShell(hostname=myHost,
                          username=myName,
                          password=myPassword,
                          missing_host_key=spur.ssh.MissingHostKey.accept,
                          shell_type=spur.ssh.ShellTypes.minimal)
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
                result = shell.run(["acidiag", "touch", "setup"])
                result = shell.spawn(["reload", "controller", key])
                result.stdin_write("Y")
                print "\nErasing and reloading this APIC now..."
                continue
            except spur.ssh.ConnectionError as error:
                print ("\nAPIC is pingable but I cannot seem to SSH succesfully.  Moving on...")
        else:
            print "\n" + value + " - APIC is not reachable, moving on..."
main()

# Iterate through the list myHost

def node():
    for i in range(len(myHost)):
        response2 = os.system("ping -c 1 -t 1 " + myHost[i] + " > /dev/null 2>&1")
        if response2 == 0:
            try:
                shell = sshLogin(myHost[i],myName, myPassword)
                shell.run(["true"])
                print("\nLogged on to node " + myHost[i])
                result = shell.spawn(["acidiag", "touch", "clean"])
                result.stdin_write("y")
                result = shell.spawn(["reload"])
                result.stdin_write("y")
                print("\nerasing and reloading node " + myHost[i] + " now....\n")

            except spur.ssh.ConnectionError as error:
                print ("ALERT! " + myHost[i] + " - Node is pingable but I cannot seem to SSH succesfully.  Moving on...")
                continue

        else:
            print "\nLeaf or Spine at " + myHost[i] + " is not reachable, moving on..."
node()

print "\nAll Done!"
