
# Script to set all the VM Network Interfaces in a given HyperV Host to NOT CONNECTED and remove the ACI vSwitch components
# This is useful for quick clean up when resetting the lab from scratch
# Joseph Ezerski, joezersk@cisco.com

$hname = Read-Host "
What is the name of the hyper-v host you want me to work on?
"
#Set all VM virtual NICs to a state of NOT CONNNECTED

Write-Host "Ok, I will set all the virtual machine interfaces to a state of Not Connected." -ForegroundColor Yellow
Get-SCVirtualMachine -VMHost "$hname" | Get-SCVirtualNetworkAdapter | Set-SCVirtualNetworkAdapter -NoConnection | Format-List -Property Name

#Remove the VTEP Interface for specified HYPER-V Host

Write-Host "
Now I will remove the VTEP Virtual Adapter...
" -ForegroundColor Yellow
$Adapter = Get-SCVirtualNetworkAdapter -VMHost $hname
Remove-SCVirtualNetworkAdapter -VirtualNetworkAdapter $Adapter -Confirm | Format-List -Property Name
Write-Host "Removed!" -ForegroundColor Green

#Remove the Logical Interface for the specific HYPER-V Host
Write-Host "
Now I will remove the logical switch from the specified host $hname ... This may take a minute as I need to wait for the NIC Team to clean itself up.
" -ForegroundColor Yellow
$apicsw = Get-SCLogicalSwitch | where { $_.Name -match  "apic" }
$virtualSwitch = Get-SCVirtualNetwork -Name $apicsw  -VMHost $hname
Remove-SCVirtualNetwork -VirtualNetwork $virtualSwitch -Confirm | Format-List -Property Name
Write-Host "Removed!" -ForegroundColor Green

#Refresh HYPER-V Host to avoid any inconsistencies
Write-Host "
Just going to refresh the HYPER-V host in SCVMM to keep things up to date.  This is going to take a minute." -ForegroundColor Yellow
Read-SCVMHost -VMHost hyper1 | Format-List -Property OverallState
Write-Host "I'm done!  Now go get a coffee!
" -ForegroundColor Green
