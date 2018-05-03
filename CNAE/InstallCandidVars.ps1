# A simple script to auto-deploy Candid OVAs in vCenter.  Note you must run this in PowerCLI
# While I could set up params to prompt you, I wanted something quick and dirty and automatic ;)
# Joseph Ezerski (joezersk@cisco.com), INSBU, Sept-2017, May-2018

#Import Variables File
. ./CandidVars.ps1

#Set the path where the OVA file is stored in your local/remote filesystem
Set-Location $OVAFolder

#Pick the file ending with .OVA.  Be careful if you have more than one OVA here, it will choose the latest one by date
$ovapath = Get-ChildItem -Path $OVAFolder –File -Filter "*.ova" | Sort-Object CreationTime | Select -Last 1
$ovaconfig = Get-OvfConfiguration –Ovf $ovapath

#### Set up variables for OVA #1 ####

#Set the OVA Variables before deployment for OVA#1
$ovaconfig.NetworkMapping.VM_Network.value = “$VMnetwork”
$ovaconfig.Common.Gateway.value = “$VMGateway”
$ovaconfig.Common.Netmask.value = “$VMMask”
$ovaconfig.Common.IP_Address.value = “$VMAddress1”

#Pick any host that is powered on and in a connected state on a specific Cluster
$myhost = get-cluster “$VMWCluster” | Get-VMHost | Where {$_.PowerState –eq “PoweredOn” –and $_.ConnectionState –eq “Connected”} | Get-Random

#Choose a specific datastore by name.  Note the first commented line alternatively allows you to simply list all datastores and pick the one with the most freespace.

#$datastore = $myhost | get-Datastore | Sort FreeSpaceGB –Descending | Select –first 1
$datastore = $myhost | get-Datastore -Name "$MyDStore"

#Deploy OVA #1
$task1 = Import-VApp –Source $ovapath –OvfConfiguration $ovaconfig –Name "$ovapath-1" –VMHost $myhost –Datastore $datastore –DiskStorageFormat Thin -Runasync
sleep 2

#### Set up variables for OVA #2 ####

#Set the OVA Variables before deployment for OVA#2
$ovaconfig.Common.IP_Address.value = “$VMAddress2”

#Pick any host that is powered on and in a connected state on a specific Cluster
$myhost = get-cluster “$VMWCluster” | Get-VMHost | Where {$_.PowerState –eq “PoweredOn” –and $_.ConnectionState –eq “Connected”} | Get-Random

#Choose a specific datastore by name.  Note the commented line alternatively allows you to simply list all datastores and pick the one with the most freespace

#$datastore = $myhost | get-Datastore | Sort FreeSpaceGB –Descending | Select –first 1
$datastore = $myhost | get-Datastore -Name "$MyDStore"

#Deploy OVA #2
$task2 = Import-VApp –Source $ovapath –OvfConfiguration $ovaconfig –Name "$ovapath-2" –VMHost $myhost –Datastore $datastore –DiskStorageFormat Thin -Runasync
sleep 2

#### Set up variables for OVA #3 ####

#Set the OVA Variables before deployment for OVA#2
$ovaconfig.Common.IP_Address.value = “$VMAddress3”

#Pick any host that is powered on and in a connected state on a specific Cluster
$myhost = get-cluster “$VMWCluster” | Get-VMHost | Where {$_.PowerState –eq “PoweredOn” –and $_.ConnectionState –eq “Connected”} | Get-Random

#Choose a specific datastore by name.  Note the commented line alternatively allows you to simply list all datastores and pick the one with the most freespace

#$datastore = $myhost | get-Datastore | Sort FreeSpaceGB –Descending | Select –first 1
$datastore = $myhost | get-Datastore -Name "$MyDStore"

#Deploy OVA #3
$task3 = Import-VApp –Source $ovapath –OvfConfiguration $ovaconfig –Name "$ovapath-3" –VMHost $myhost –Datastore $datastore –DiskStorageFormat Thin -Runasync

#Check that each OVA finished being deployed and start them up!

Wait-Task -Task $task1
get-vm $ovapath-1 | Start-VM

Wait-Task -Task $task2
get-vm $ovapath-2 | Start-VM

Wait-Task -Task $task3
get-vm $ovapath-3 | Start-VM