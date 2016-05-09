<#

.SYNOPSIS

Automates the steps necessary to generate, copy and install a cert for APIC to SCVMM Communication.

Script by Joseph Ezerski (joezersk@cisco.com), INSBU - No guarantees on operation! v1.0 Dec 2015
Special thanks to Chris Paggen for the APIC cookie code.

.DESCRIPTION

A quick way to generate a new cert for SCVMM and ACI Integration without the need to remember all the powershell commands. 
Accepts interactive user input to generate the cert on the SCVMM server, and put a copy in the SCVMM Agent folder.  
Also imports the cert into the local machine personal certstore on the SCVMM system you run it on and mark for export.
It will file-copy and import the cert to a list of HYPER-V hosts you specify.

Finally, it will log into APIC and paste the contents of the cert into the admin account's x.509 object

#>

#Begin Script

Write-Host "
## APIC to SCVMM Certificate Generation Script v1.0 - No Guarantees on perfect Operation ##
This script is designed to be run on the server where SCVMM is installed.

You should be running Powershell as an adminstrator.  Please quit and relaunch if you have not done this.
Please also make sure you have installed the APIC SCVMM Agent on the Windows Server before running this script.

This script will ask for some basic input to generate a local cert for use in communication with APIC.
" -foreground "yellow"

cd 'C:\Program Files (x86)\ApicVMMService'
Import-Module .\ACIScvmmPsCmdlets.dll
Get-Command -Module ACIScvmmPsCmdlets

Write-Host "
Ok, if you see a list of APIC specific cmdlets above, then we know the SCVMM Agent has been installed.
" -foreground "yellow"

#Check for local machine existing Opflex certifcate, and if found, remove it

$pc = "."
$cert_store = "My"
 
$store = New-Object system.security.cryptography.X509Certificates.X509Store (".\My"),'LocalMachine' #LocalMachine could also be LocalUser
$store.Open('ReadWrite')
## Find all certs that have an Issuer of my old CA
$certs = $store.Certificates | ? {$_.Issuer -like "CN=OpflexAgent*"}
$certs | Format-Table Subject, FriendlyName, Thumbprint -AutoSize
Write-Host "
If you see the OpflexAgent cert & serial# above, it means I found an existing cert and removed it to avoid redundancy." -foreground "yellow"
Write-Host "
If you see nothing, it means there was no prior OpflexAgent certificate generated and we are good to go.
" -foreground "yellow"
$certs | % {$store.Remove($_)}

#Ask user to generate a certifcate password
$pfxpasswordinput = Read-Host -AsSecureString "We need a password for the PFX Certifcate for SCVMM to speak to APIC securely. Please type it in"
$pfxpassword = ConvertTo-SecureString "$pfxpasswordinput" -AsPlainText -Force

#Ask user for input required to generate the cert
$email = Read-Host "What is the email address you want to associate to the certificate?"
$country = Read-Host "What is the country where this certificate will be deployed? (ISO Notation)"
$state = Read-Host "What is the two-letter state or province for this cert?"
$locality = Read-Host "What is the locality or city?"
$myorg = Read-Host "What is the the Organization Name?"

Write-Host "Generate the cert!
" -ForegroundColor Green

#Actually generate and import the cert into the local certstore with a copy in SCVMM Agent folder
New-ApicOpflexCert -ValidNotBefore 1/1/2015 -ValidNotAfter 1/1/2021 -Email $email -Country $country -State $state -Locality "$locality" -Organization $myorg -PfxPassword $pfxpassword

#Display and copy into the clipboard the output of the cert for APIC
$certdata = Read-ApicOpflexCert -PfxFile "C:\Program Files (x86)\ApicVMMService\OpflexAgent.pfx" -PfxPassword $pfxpassword
$certdata

Write-Host "
OK, here is the cert output above.  I will now copy this into the APIC admin account's x.509 certificate object for you.  
There is no need to do this manually.  For this to work you must use HTTP to talk to APIC versus the default HTTPS."
" -foreground "yellow"

#Make REST API call to APIC to get the login cookie established
$username = Read-Host "
Enter the APIC admin username"
$password = Read-Host "Enter APIC admin password"
$apic = Read-Host "Enter APIC IP address"

$creds = '<aaaUser name="' + $username + '" pwd="' + $password + '"/>'
$baseurl = "http://" + $apic
$url = $baseurl + "/api/aaaLogin.xml"
$r = Invoke-RestMethod -Uri $url -Method Post -SessionVariable s -Body $creds
$cookies = $s.Cookies.GetCookies($url)

$web = new-object net.webclient
$web.Headers.add("Cookie", $cookies)

#Add Opflex cert to APIC user admin x.509 object

$newtenanturl = $baseurl + "/api/node/mo/uni/userext/user-admin/usercert-OpflexAgent.json"
$jsonpayload = @"
{"aaaUserCert":{"attributes":{"dn":"uni/userext/user-admin/usercert-OpflexAgent","data":"$certdata","name":"OpflexAgent","rn":"usercert-OpflexAgent","status":"created,modified"},"children":[]}}
"@
#$jsonpayload
$response = $web.UploadString($newtenanturl,$jsonpayload)
Write-Host "
Ok, the cert is now copied over to APIC.  Now let's copy the PFX file over to your Hyper-V hosts.
" -ForegroundColor Green


#Copy Cert to user input HyperV remote Hosts
$HyperHost = [string[]](Read-Host "Enter the MACHINE NAMEs of the HYPER-V hosts (comma separated) you want me to copy the cert to.  Example HYPERV-1,HYPERV-2").split(',') | % {$_.trim()}

#Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$HyperHost"

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
Invoke-Command -ComputerName $h -ScriptBlock {param($pfxpasswordinput) Import-PfxCertificate -Exportable -FilePath C:\OpflexAgent.pfx cert:\LocalMachine\My -Password (ConvertTo-SecureString $pfxpasswordinput -AsPlainText -Force)|Format-Table Subject, FriendlyName, Thumbprint -AutoSize} -ArgumentList $pfxpasswordinput

Write-Host "DONE COPYING THIS CERT to $h!
" -ForegroundColor Green
}
Write-Host "Ok, let's test the connection to APIC" -ForegroundColor Green

Set-ApicConnInfo -ApicNameOrIPAddress $apic -CertificateSubjectName OpflexAgent
Get-ApicConnInfo | Format-Table ApicAddresses, ConnectionStatus

Write-Host "Ok, the whole process is now complete if you see the Connection Status as CONNECTED.
" -ForegroundColor Yellow

#End Script
