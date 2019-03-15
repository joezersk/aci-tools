# Useful ACI Scripts in an Operational Environment
Script 1.  Automate most of the SCVMM Integration (Powershell) - _New and Improved v3 in Feb 2018!_
<BR>
Script 2.  Automate the removal of the APIC generated networking in SCVMM (Powershell)
<BR>
Script 3.  Automated Factory Reset a full ACI Fabric (Python) - New and Improved v2 with sanity check! Jan 2018
<BR>
Script 4.  Automated clean up of ACI-vCenter DVS Networkingv2 (PowerCLI)
<HR>
<B>Integrate ACI-SCVMM Powershell Script v3</B>


<B>Description:</B>
Automates the steps necessary to generate, copy and install a cert for APIC to SCVMM Communication.
<BR><BR>
Not an officially Cisco supported script - No guarantees on operation! New v3.0 Feb 2018.
<P>
Special thanks to Chris Paggen for the APIC cookie code.
<P>
A quick way to generate a new cert for SCVMM and ACI Integration without the need to remember all the powershell commands.
Accepts interactive user input to generate the cert on the SCVMM server, check for all installed ACI agents, copy the cert to a list of HyperV Hosts and place the cert into the ACI Admin account.

<B>New in v3.0:</B>
<ul type="square">
    <li>Much improved error checking and feedback for APIC Login process</li>
    <li>Better checking of reachability of hyper-v hosts before trying cert</li>
    <li>Added final check of SCVMM Agent Comm Channel with better messaging if it failed</li>
</ul>
<P>

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
It effectively will move all VM Network Interfaces on a given host to a state of non-connected, so it can then remove the vSwitch and VTEP interfaces from the host itself.  It does not try to delete or remove any logical networks pushed by APIC.  It is probably best that after you run this script and want to remove all traces of the VMM Domain, that you do that manually from APIC.  APIC will take care to clean up all the needed SCVMM objects for you, as there are many. 

<HR>
<B>ACI Factory Reset Script - Now v6 Mar 2019</B>

Using the Python Spur module, this script simply uses SSH to log into a defined set of Cisco ACI APICs, Leafs and Spines and issues a factory reset and reload.  This is useful when you want or need to start over from scratch.  

Version 6 (March 2019) is a much better version.  It adds a failsafe check by asking a y/n question before running.  It also adds error checking by first pinging the nodes, then trying to SSH.  If either one fails it will bypass, let you know, and move on to the next node.  This is useful for when you have wiped a node but it still keeps its OOB IP address (which is default ACI behavior).  I also added some colors to serve as a better way to visually verify if you missed a node or anything.  Toss older versions, you want the latest!
<BR><BR>
You will have to edit the script to use your own ACI IP addresses (OOB for all APICs and Nodes) and login credentials.  This is done in the variables called *'MyApic'* and *'MyNode'*.
<BR><BR>
Please note the requirement to install the Python Spur module first.

<HR>
<B>ACI-vCenter Network Integration Clean Up Scriptv2 July 2017</B>

<I>(December 2016, July 2017)</I>
<BR>
    <B>Update: (October 2018)</B><I> Use v3 of this script if you are running Powershell 6.x and later</I>
<BR><BR>
I got tired of always having to manually move my VMs when I erase and rebuild my ACI Lab.

This is a PowerCLI script that automates moving vCenter virtual machines off of a DVS or AVS and onto a local vSwitch portgroup.  It also offers to detach the physical ESX host from the DVS/AVS.  This is useful for those times when you want to rebuild or tear down your ACI lab and don't want to spend a lot of time manually moving off the virtual machines and hosts from the DVS.  This script is not specific to ACI integration, as you can use with it with any DVS in vCenter.  
<P>
You must run this in PowerCLI that is also logged into your vCenter server.  
<P>
 Note that you can now natively run Powershell and PowerCLI on a Mac or Linux machine!
    <P>
