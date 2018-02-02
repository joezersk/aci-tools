# DEPRECATED USE v3 INSTEAD
<#
.SYNOPSIS

Automates the steps necessary to generate, copy and install a cert for APIC to SCVMM Communication.

Script by Joseph Ezerski (joezersk@cisco.com), INSBU - No guarantees on operation! New v2.0 July 2016.
Now with more cowbell!
  
Special thanks to Chris Paggen for the APIC cookie code.

.DESCRIPTION

A quick way to generate a new cert for SCVMM and ACI Integration without the need to remember all the powershell commands. 
Accepts interactive user input to generate the cert on the SCVMM server, check for all installed ACI agents, 
copy the cert to a list of HyperV Hosts and place the cert into the ACI Admin account.

New in v2.0:
-More efficient and streamlined user input flow
-APIC password now masked on entry
-Better error checking by looking for the presence of needed ACI agents on SCVMM and HyperV hosts
-Prompt to install SCVMM Agent if it is missing
-Connection to APIC now using default HTTPS (TLSv1.2)
#>

#Begin Script

#Gather User Inputs all up front
param (
   [string] $description = $(Write-Host -ForegroundColor Green "
This script will set up the required certificate to build communication between APIC and SCVMM.  

After user provided input it will:
    -Create the certificate
    -Install it on the SCVMM Server
    -Copy it to the APIC admin X.509 cert store
    -Copy it to a list of hyperv hosts

It does provide some basic error checking to see if the SCVMM and HyperV agents are installed and running."),
   [string] $pfxpasswordinput = $(Read-Host -AsSecureString "
We need a password for the PFX Certifcate for SCVMM to speak to APIC securely. Please type it in"),

#Ask user for input required to generate the cert
   [string] $email = $( Read-Host "What is the email address you want to associate to the certificate?"),
   [string] $country = $( Read-Host "What is the country where this certificate will be deployed? (ISO Notation)"),
   [string] $state = $(Read-Host "What is the two-letter state or province for this cert?"),
   [string] $locality = $(Read-Host "What is the locality or city?"),
   [string] $myorg = $(Read-Host "What is the the Organization Name?"),
   [string] $username = $(Read-Host "
Enter the APIC admin username"),
   [Security.SecureString] $passwordsec = $(Read-Host -AsSecureString "Enter APIC admin password"),          
   [string] $apic = $(Read-Host "Enter APIC IP address or FQDN"),
   [string[]] $HyperHost = $((Read-Host "
Enter the MACHINE NAMEs of the HYPER-V hosts (comma separated) you want to copy the cert to. Example HYPERV-1,HYPERV-2").split(',') | % {$_.trim()})
)

#Function to convert secure password string into plaintext so login to APIC works
Function ConvertTo-PlainText( [security.securestring]$passwordsec ) {
    $marshal = [Runtime.InteropServices.Marshal]
    $marshal::PtrToStringAuto( $marshal::SecureStringToBSTR($passwordsec) )
}
$password = ConvertTo-PlainText $passwordsec
$pfxpassword = ConvertTo-SecureString "$pfxpasswordinput" -AsPlainText -Force

#Make REST API call to APIC to get the login cookie established
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$creds = '<aaaUser name="' + $username + '" pwd="' + $password + '"/>'
$baseurl = "https://" + $apic
$url = $baseurl + "/api/aaaLogin.xml"
$r = Invoke-RestMethod -Uri $url -Method Post -SessionVariable s -Body $creds
$cookies = $s.Cookies.GetCookies($url)

# Get APIC Version and Print it to screen
$web = new-object net.webclient
$web.Headers.add("Cookie", $cookies)
$urlversion = $web.DownloadString($baseurl + "/api/node/class/topology/pod-1/node-1/firmwareCtrlrRunning.json?") | ConvertFrom-Json
$apicver = $urlversion.imdata
write-host -ForegroundColor Yellow "
Your APIC is running version" $apicver.firmwareCtrlrRunning.attributes.version "- Please make sure your installed Agents are the same version."

#Check for presence of SCVMM Agent installed on the local machine and prompt to install if missing
Write-Host "
Ok, checking if you already installed the SCVMM Agent on this machine..." -ForegroundColor Green

$Service = "APICVMMSERVICE"

if ($AgentVer = Get-Process -Name $Service -FileVersionInfo -ErrorAction SilentlyContinue)
{

Write-Host -ForegroundColor Green "Service $Service Exists with version:"
$AgentVer | Format-Table FileVersion -HideTableHeaders
}
Else
{Write-Host "
Service $Service does not exist and we need to install it....
" -ForegroundColor YELLOW

$SCVMM_MSI = Read-Host "Provide Location of 'APIC SCVMM Agent.msi' file location e.g C:\Users\Administrator\'APIC SCVMM Agent.msi'.  
You can also just drag/drop the file to the command line here
"

Start-Process $SCVMM_MSI  -Wait
Get-Service -Name $Service -ErrorAction Stop}

cd 'C:\Program Files (x86)\ApicVMMService'
Import-Module .\ACIScvmmPsCmdlets.dll

#Check for stale, local machine existing Opflex certifcate, and if found, remove it
$pc = "."
$cert_store = "My"
 
$store = New-Object system.security.cryptography.X509Certificates.X509Store (".\My"),'LocalMachine' #LocalMachine could also be LocalUser
$store.Open('ReadWrite')
## Find all certs that have an Issuer of my old CA
$certs = $store.Certificates | ? {$_.Issuer -like "CN=OpflexAgent*"}
#$certs | Format-Table Subject, FriendlyName, Thumbprint -AutoSize
Write-Host "Removing any stale older certs if they exist....and generating a new one.
" -foreground "yellow"

$certs | % {$store.Remove($_)}

#Actually generate and import the cert into the local SCVMM Host certstore
New-ApicOpflexCert -ValidNotBefore 1/1/2015 -ValidNotAfter 1/1/2021 -Email $email -Country $country -State $state -Locality "$locality" -Organization $myorg -PfxPassword $pfxpassword

#Display and copy into the clipboard the output of the cert for APIC
$certdata = Read-ApicOpflexCert -PfxFile "C:\Program Files (x86)\ApicVMMService\OpflexAgent.pfx" -PfxPassword $pfxpassword
$certdata

Write-Host "
Here is the cert output.  I will copy this into the APIC admin account's x.509 certificate object for you." -foreground "yellow"

#Add Opflex cert to APIC user admin x.509 object

$web = new-object net.webclient
$web.Headers.add("Cookie", $cookies)
$newtenanturl = $baseurl + "/api/node/mo/uni/userext/user-admin/usercert-OpflexAgent.json"
$jsonpayload = @"
{"aaaUserCert":{"attributes":{"dn":"uni/userext/user-admin/usercert-OpflexAgent","data":"$certdata","name":"OpflexAgent","rn":"usercert-OpflexAgent","status":"created,modified"},"children":[]}}
"@
#$jsonpayload
$response = $web.UploadString($newtenanturl,$jsonpayload)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null

Write-Host "Ok, the cert is now copied over to APIC.  Now let's copy the PFX file over to your Hyper-V hosts.
" -ForegroundColor Green

#Check for presence of HyperV service at remote Hosts

ForEach ($h in $HyperHost)
{
Try 
    {
    $reachable = $true
    Invoke-Command -ComputerName $h -ErrorAction Stop -ScriptBlock {Get-Process "Cisco.ACI.Opflex.HyperV.Agent" | Out-Null}
    }
Catch 
    {
    $reachable = $false
    Write-Host "
    ############ WARNING ################

    For the HyperV Host called $h....
    You don't have the ACI Hyper-V Agent Installed or Running.  
    I will copy the certificate anyway...
    but you need to go back and manually install/start the HyperV agent on the host for APIC communication to work.
    
    ############ WARNING ################
    " -ForegroundColor Red
    }
if ($reachable) {write-host "Checking $h for the presence of the HyperV Agent Service...
APIC HyperV Service Exists and is running!
" -ForegroundColor Green
    }

}

#Copy Cert to user input HyperV remote Hosts
foreach ($h in $HyperHost)

{$cert_store = "My"
 
$store = New-Object system.security.cryptography.X509Certificates.X509Store ("$h\My"),'LocalMachine' #LocalMachine could also be LocalUser
$store.Open('ReadWrite')

## Find old certs that have an Issuer of OpflexAgent and Remove them
$certs = $store.Certificates | ? {$_.Issuer -like "CN=OpflexAgent*"}
#$certs
$certs | % {$store.Remove($_)}

#Copy the cert and mark for export
Set-Location C:\Windows\System32
Copy-Item C:\'Program Files (x86)'\ApicVMMService\OpflexAgent.pfx -Destination \\$h\C$\OpflexAgent.pfx -Force
Invoke-Command -ComputerName $h -ScriptBlock {param($pfxpasswordinput) Import-PfxCertificate -Exportable -FilePath C:\OpflexAgent.pfx cert:\LocalMachine\My -Password (ConvertTo-SecureString $pfxpasswordinput -AsPlainText -Force)|Out-Null} -ArgumentList $pfxpasswordinput

Write-Host "DONE COPYING THIS CERT to $h!" -ForegroundColor Green
}
#Check if APIC and SCVMM are connected
Write-Host ""
Set-ApicConnInfo -ApicNameOrIPAddress $apic -CertificateSubjectName OpflexAgent
Get-ApicConnInfo | Format-Table ApicAddresses, ConnectionStatus

Write-Host "Ok, the whole process is now complete if you see the Connection Status as CONNECTED." -ForegroundColor Yellow

#End Script
