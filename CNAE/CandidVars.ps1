#Note - You must already be authenticated to your vCenter server using "connect-viserver" command

#Replace all variable values inside the single-quotes with ones that fit your setup and save this file.  
#Current values are just examples

#Set Path to where you have saved the CNAE OVA file
$OVAFolder = 'C:\Candid-OVA'

#Port Group For Candid Management Interfaces
$VMnetwork = 'VM_10.50.129.x/24'

#IP Addresses of CNAE Cluster, mask and gateway
$VMAddress1 = '10.50.129.80'
$VMAddress2 = '10.50.129.81'
$VMAddress3 = '10.50.129.82'
$VMMask = '255.255.255.0'
$VMGateway = '10.50.129.254'

#Name of VMware Resource Cluster to use
$VMWCluster = 'Candid'

#Datastore you want to install Candid on
$MyDStore = 'DS_1TB'
