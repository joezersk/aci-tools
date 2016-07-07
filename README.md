# Useful ACI Scripts in an Operational Environment
Script 1.  Automate most of the SCVMM Integration
<BR>
Script 2.  Automate the removal of the APIC generated networking in SCVMM
<BR>
Script 3.  Automated Factory Reset a full ACI Fabric
<HR>
<B>Integrate ACI-SCVMM Powershell Script</B>

Automates the steps necessary to generate, copy and install a cert for APIC to SCVMM Communication.
<BR>
Scripts by Joseph Ezerski (joezersk@cisco.com), INSBU - No guarantees on operation! v1.0 Dec 2015
<BR>
Special thanks to Chris Paggen for the APIC cookie code.

<B>Description:</B>

A quick way to generate a new cert for SCVMM and ACI Integration without the need to remember all the powershell commands. 
Accepts interactive user input to generate the cert on the SCVMM server, and put a copy in the SCVMM Agent folder.  
<BR>
Also imports the cert into the local machine personal certstore on the SCVMM system you run it on and mark for export.
It will file-copy and import the cert to a list of HYPER-V hosts you specify.
Finally, it will log into APIC and paste the contents of the cert into the admin account's x.509 object.
<BR><BR>
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
