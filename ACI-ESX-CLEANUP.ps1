#BEGIN SCRIPT
# Written by Joseph Ezerski (joezersk@cisco.com) Dec 2016. Not an official Cisco supported script. Use at your own risk.  
# This is a Powercli script meant to help you quickly move VMs off of one or more DVS networks and onto a local vSwitch.
# It will also offer to remove the physical ESX host from the DVS(s)
# This is useful when you want to quickly remove a VMM Domain from your APIC and not spend hours right clicking to move VMs off

#Set up an empty array to store user choices which becomes important later when we try to remove the DVS from hosts
$MakeArray = @()
#Save default text color to do fancy stuff later
$t = $host.ui.RawUI.ForegroundColor

#Get a list of physical VM hosts after login
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

#Get available vswitch portgroups from the chosen ESX host
    [array]$VMNets = Get-VMHost -Name $ChosenVMHost | Get-VirtualPortGroup -Standard

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
Write-Host "`n I also found the presence of at least one DVS.  Here is the list. `n" -foregroundcolor yellow
$VDS = Get-VDSwitch

Write-Host "$VDS" -ForegroundColor Green

$host.ui.RawUI.ForegroundColor = “White”
$DelDVS = Read-Host "`n `nWhich DVS do you want me to remove? If you want me to remove everything, just use * (asterisk).
If none, then just hit enter and the script will gently error out "
$host.ui.RawUI.ForegroundColor = $t
try 
    {
ForEach ($VD in $DelDVS)

{
Write-Host -ForegroundColor Yellow "`n I am removing $VD from host $MakeArray"

if ($DelDVS -ne [string]::Empty)  {Get-VMHostNetworkAdapter -VMHost $MakeArray -VMKernel | where {$_.PortgroupName -match 'vtep'} | Remove-VMHostNetworkAdapter -Confirm:$false -ErrorAction:SilentlyContinue | out-null}

Get-VDSwitch -Name $VD | Remove-VDSwitchVMHost -VMHost $MakeArray -Confirm:$false -ErrorAction:SilentlyContinue | out-null

#Commented out delete of folder commands due to possibility of trying to delete ALL folders if you use a wildcard like "*"
#Get-VDSwitch -Name $VD | Remove-VDSwitch -Confirm:$false
#Get-Folder -Type Network -Name $VD | Remove-Folder -Confirm:$false
}
}
catch
    {
    Write-Host "`n If you just hit enter, everything is fine.  Otherwise something went wrong and I could not remove the DVS. `n Perhaps you still have VMs connected there or you typed the name wrong. Check for these before running the script again." -ForegroundColor Red
    }
finally
    {
Write-Host "`n All Done!  I will now exit. `n" -ForegroundColor Green
    }

#######





