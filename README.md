# Useful ACI Scripts in an Operational Environment
Script 1.  Automate most of the SCVMM Integration (Powershell)
<BR>
Script 2.  Automate the removal of the APIC generated networking in SCVMM (Powershell)
<BR>
Script 3.  Automated Factory Reset a full ACI Fabric (Python)
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
YouTube Video of the integration script in action:  https://www.youtube.com/watch?v=8JWBOcorAjA


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

Using the Python Spur module, this script simply uses SSH to log into a defined set of Cisco ACI APICs, Leafs and Spines and issues a factory reset and reload.  This is useful when you want or need to start over from scratch.
<BR><BR>
You will have to edit the script to use your own IP addresses and login credentials
<BR><BR>
Please note the requirement to install the Python Spur module first.
