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

# List with the host names or IP addresses
myHost = ["10.50.129.242","10.50.129.243","10.50.129.244","10.50.129.245","10.50.129.246","10.50.129.247","10.50.129.248"]
myApic = ["10.50.129.241","10.50.129.231","1.1.1.1"]
myName = "admin"
myPassword = "cisco123"

if myApic[0]:
    x = '1'
elif myApic[1]:
    x = "2"
elif myApic[2]:
    x = "3"

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
    for i in range(len(myApic)):
        response = os.system("ping -c 1 -t 1 " + myApic[i] + " > /dev/null 2>&1")
        if response == 0:
            try:
                shell = sshLogin(myApic[i], myName, myPassword)
                shell.run(["true"])
                print("\nLogged on to APIC controller " + myApic[i])
                result = shell.run(["acidiag", "touch", "setup"])
                result = shell.spawn(["reload", "controller", x])
                result.stdin_write("Y")
                print "\nErasing and reloading this APIC now..."
                continue
            except spur.ssh.ConnectionError as error:
                print ("\nAPIC is pingable but I cannot seem to SSH succesfully.  Moving on...")
        else:
            print "\n" + myApic[i] + " - APIC is not reachable, moving on..."
main()

# Iterate through the list myHost

def node():
    for i in range(len(myHost)):
        response2 = os.system("ping -c 1 -t 1 " + myHost[i] + " > /dev/null 2>&1")
        if response2 == 0:
            try:
                shell = sshLogin(myHost[i],myName, myPassword)
                shell.run(["true"])
                print("\nLogged on to host " + myHost[i])
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
