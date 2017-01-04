""" Script to SSH into APIC and each leaf and spine via OOB management port and factory reset and reload
    Original script by Palm 2016-04-29
    Modifications for an ACI Fabric Reset by J.Ezerski 2016-05-02 and 07-07-2016

"""
import spur

# List with the leaf and spine host names or IP addresses
myHost = ["1.1.1.242","1.1.1.243","1.1.1.244","1.1.1.245","1.1.1.246"]
myApic = "1.1.1.1"
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
    shell = sshLogin(myApic,myName,myPassword)
    print("\nLogged on to APIC controller " + myApic)
    result = shell.run(["acidiag", "touch", "setup"])
    result = shell.spawn(["reload", "controller", "1"])
    result.stdin_write("Y")
    print("reloading APIC now....")
main()

# Iterate through the list myHost
def main():
    for i in range (len(myHost)):
        shell = sshLogin(myHost[i],myName,myPassword)
        print("\nLogged on to host " + myHost[i])
        # Run the command, separate the command and options with ""
        result = shell.run(["acidiag", "touch", "clean"])
        result = shell.spawn(["reload"])
        result.stdin_write("y")
        print("reloading node " + myHost[i] + " now....")

main()
