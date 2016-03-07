# ACI

<HR>
<B>ACI-SCVMM Powershell Script</B>

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
Finally, it will log into APIC and paste the contents of the cert into the admin account's x.509 object

<HR>
<B>ACI-SCVMM Clean Up Script</B>

Automates the steps necessary to remove the APIC deployed vSwitch and related components on a Hyperv host(s) (via SCVMM).
<BR>

<B>Description:</B>

For those times when you want to reset your ACI SCVMM HyoerV host to a state before ACI integration.  This script tries to help with clean up.  
<BR>
Run it in Powershell from the SCVMM server.  
<BR>
It effectively will move all VM Network Interfaces on a given host to a state of non-connected, so it can then remove the vSwitch and VTEP interfaces from the host itself.  It does not try to delete or remove any logical networks pushed by APIC. 


