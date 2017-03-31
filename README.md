# Useful ACI Scripts in an Operational Environment
Script 1.  Automate most of the SCVMM Integration (Powershell) - New and Improved v2!
<BR>
Script 2.  Automate the removal of the APIC generated networking in SCVMM (Powershell)
<BR>
Script 3.  Automated Factory Reset a full ACI Fabric (Python)
<BR>
Script 4.  Automated clean up of ACI-vCenter DVS Networking (PowerCLI)
<HR>
<B>Integrate ACI-SCVMM Powershell Script v2</B>


<B>Description:</B>
Automates the steps necessary to generate, copy and install a cert for APIC to SCVMM Communication.
<BR><BR>
Script by Joseph Ezerski (joezersk@cisco.com), INSBU - No guarantees on operation! New v2.0 July 2016.
Now with more cowbell!
<P>
Special thanks to Chris Paggen for the APIC cookie code.
<P>
A quick way to generate a new cert for SCVMM and ACI Integration without the need to remember all the powershell commands.
Accepts interactive user input to generate the cert on the SCVMM server, check for all installed ACI agents, copy the cert to a list of HyperV Hosts and place the cert into the ACI Admin account.


<B>New in v2.0:</B>
<ul type="square">
    <li>More efficient and streamlined user input flow</li>
    <li>APIC password now masked on entry</li>
    <li>Better error checking by looking for the presence of needed ACI agents on SCVMM and HyperV hosts</li>
    <li>Prompt to install SCVMM Agent if it is missing</li>
    <li>Connection to APIC now using default HTTPS (TLSv1.2)</li>
</ul>
<P>
YouTube Video of the v2 integration script in action:  https://youtu.be/ZYSaV9Qpz7o


<HR>
<B>ACI-SCVMM HyperV Host Clean Up Script</B>

Automates the steps necessary to remove the APIC deployed vSwitch and related components on a Hyperv host(s) (via SCVMM).
<BR>

<B>Description:</B>

For those times when you want to reset your ACI SCVMM HyperV host to a state before ACI integration.  This script tries to help with clean up.  
<BR>
Run it in Powershell from the SCVMM server.  
<BR>
It effectively will move all VM Network Interfaces on a given host to a state of non-connected, so it can then remove the vSwitch and VTEP interfaces from the host itself.  It does not try to delete or remove any logical networks pushed by APIC.

<HR>
<B>ACI Factory Reset Script</B>

Using the Python Spur module, this script simply uses SSH to log into a defined set of Cisco ACI APICs, Leafs and Spines and issues a factory reset and reload.  This is useful when you want or need to start over from scratch.  Be very aware that this script will start erasing your fabric as soon as you hit enter and without any warning.  It works, but just be sure you are ready!
<BR><BR>
You will have to edit the script to use your own IP addresses and login credentials
<BR><BR>
Please note the requirement to install the Python Spur module first.

<HR>
<B>ACI-vCenter Network Integration Clean Up Script</B>

<I>(December 2016)</I>
<BR>
A PowerCLI script that automates moving vCenter virtual machines off of a DVS or AVS and onto a local vSwitch.  It also offers to detach the physical ESX host from the DVS/AVS.  This is useful for those times when you want to rebuild or tear down your ACI lab and don't want to spend a lot of time manually moving off the virtual machines and hosts from the DVS.  This script is not specific to ACI integration, as you can use with it with any DVS in vCenter.  
<P>
You must run this in PowerCLI that is also logged into your vCenter server.  
