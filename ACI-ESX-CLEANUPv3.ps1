#BEGIN SCRIPT
# Written by Joseph Ezerski (joezersk@cisco.com) Dec 2016. Not an official Cisco supported script. Use at your own risk.  
# This is a Powercli script meant to help you quickly move VMs off of one or more DVS networks and onto a local vSwitch.
# It will also offer to remove the physical ESX host from the DVS(s).  
# Finally it will log into your APIC and delete the VMM domain, which will remove the DVS from vCenter as well
# This is useful when you want to quickly remove a VMM Domain from your APIC and not spend hours right clicking to move VMs off
# Updated June 2017.  Be aware the DVS removal part at the end might not be perfect...

#Set up an empty array to store user choices which becomes important later when we try to remove the DVS from hosts
$MakeArray = @()
$MakeArrayDVS = @()
#Save default text color to do fancy stuff later
$t = $host.ui.RawUI.ForegroundColor

#Get a list of physical VM hosts after login and present in a menu
do
{
[array]$VMHost = Get-VMHost

If ($VMHost)
{
	Write-Output "`n`nSelect a host from the list (by typing its number and pressing Enter):`n"
	$host.ui.RawUI.ForegroundColor = “Yellow”
    Write-Output "[0] Move on to DVS Removal`n"
	For ($i=0; $i -lt $VMHost.count; $i++)
	{
        $host.ui.RawUI.ForegroundColor = “Green”
        Write-Output "[$($i+1)] $($VMHost[$i].Name)`t$($VMHost[$i].ConnectionState)" 
        $host.ui.RawUI.ForegroundColor = $t
	}
	
    Write-Output '
Select the Host you want to work with :
' 

	$ReadHost		= Read-Host
	$VMHostChoice	= [int]$ReadHost - 1
	$ChosenVMHost	= $VMHost[$VMHostChoice]
	
	If ($VMHostChoice -ne -1)
	{
    #Add this user chosen host to the array for later use
    $MakeArray += $ChosenVMHost

    Write-Host "You chose wisely...`n"

#Get available local vswitch portgroups from the chosen ESX host
    [array]$VMNets = Get-VMHost -Name $ChosenVMHost | Get-VirtualPortGroup -Standard

#Present list of PGs in a menu format
If ($VMNets)
{
	Write-Output "`n`nSelect a local vswitch Portgroup from the list (by typing its number and pressing Enter):`n"
	$host.ui.RawUI.ForegroundColor = “Yellow”
    Write-Output "[0] Cancel`n"
	For ($i=0; $i -lt $VMNets.count; $i++)
	{
		$host.ui.RawUI.ForegroundColor = “Green”
        Write-Output "[$($i+1)] $($VMNets[$i].Name)"
        $host.ui.RawUI.ForegroundColor = $t
	}
	Write-Output `n'Pick a standard port-group network to move all vNICs to:'`n

	$ReadHost		= Read-Host
	$VMNetsChoice	= [int]$ReadHost - 1
	$ChosenNets	= $VMNets[$VMNetsChoice]
	
	If ($VMNetsChoice -ne -1)
	{
		# Your workload goes here, e.g.:
		$myNetworkAdapters = Get-VMHost -Name $ChosenVMHost | Get-VM | Get-NetworkAdapter
        Set-NetworkAdapter -NetworkAdapter $myNetworkAdapters -NetworkName $ChosenNets -Confirm:$false | foreach ($_) {Write-Host -ForegroundColor White "Moving vNIC " $_.Parent.Name "("$_.Name") MAC:" $_.MacAddress}

	}
	Else
	{
		Write-Output "`n Canceling host script execution."
	}
}
Else
{
	Write-Output 'No host found!'
}
}}}
while ($VMHostChoice -ne -1)

#Get a list of running DVS(s) in the vCenter
do
{
Write-Host "`n I also found the presence of at least one DVS.  Here is the list. `n" -foregroundcolor yellow
[array]$VDS = Get-VDSwitch

If ($VDS)
{
	Write-Output "`n`nSelect a VDS/AVS from the list (by typing its number and pressing Enter):`n"
	$host.ui.RawUI.ForegroundColor = “Yellow”
    Write-Output "[0] Move on to DVS removal`n"
	For ($i=0; $i -lt $VDS.count; $i++)
	{
		$host.ui.RawUI.ForegroundColor = “Green”
        Write-Output "[$($i+1)] $($VDS[$i].Name)"
        $host.ui.RawUI.ForegroundColor = $t
	}
	Write-Output `n'Pick a VDS to remove from APIC and vCenter:'`n

	$ReadHost		= Read-Host
	$VDSChoice	= [int]$ReadHost - 1
	$ChosenVDS	= $VDS[$VDSChoice]
	
    $MakeArrayDVS += $ChosenVDS
	If ($VDSChoice -ne -1)
	{
		# Your workload goes here, e.g.:
		if ($ChosenVDS -ne [string]::Empty)  {Get-VMHostNetworkAdapter -VMHost $MakeArray -VMKernel | where {$_.PortgroupName -match 'vtep'} | Remove-VMHostNetworkAdapter -Confirm:$false -ErrorAction:SilentlyContinue | out-null}

        Get-VDSwitch -Name $ChosenVDS | Remove-VDSwitchVMHost -VMHost $MakeArray -Confirm:$false -ErrorAction:SilentlyContinue | out-null
	}

}}
while ($VDSChoice -ne -1)

#Make REST API call to APIC to get the login cookie established
$apic = Read-Host "What is the IP Address of your APIC?"
$username = Read-Host "What is the admin login account to your APIC?"
$password = Read-Host "What is the admin password?"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$creds = '<aaaUser name="' + $username + '" pwd="' + $password + '"/>'
$baseurl = "https://" + $apic
$url = $baseurl + "/api/aaaLogin.xml"
$r = Invoke-RestMethod -Uri $url -Method Post -SessionVariable s -Body $creds -SkipCertificateCheck
$cookies = $s.Cookies.GetCookies($url)

#Using APIC login cookie value saved in the session variable $s, go ahead delete the DVS
ForEach ($DVS in $MakeArrayDVS)
{
$url = $baseurl + "/api/node/mo/uni/vmmp-VMware/dom-$DVS.json"
$r = Invoke-RestMethod -Uri $url -Method Delete -WebSession $s -SkipCertificateCheck
}
Write-Host "Ok, I have removed any selected DVS from both APIC and vCenter.  I will now exit..."

####### END ######
