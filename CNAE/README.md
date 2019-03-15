#### Script to automate the deployment of the OVAs needed to install CNAE (Candid) engine in vCenter.
---
**Prerequisites:**

1. Vmware's PowerCLI installed where you will run this script (*Note, there is now Powershell and PowerCLI for Macintosh!*)
2. Be logged into your vCenter via PowerCLI (*i.e use the Connect-VIServer x.x.x.x command*)
---

**Instructions:**

This is a two file setup.  *CandidVars.ps1* is the **only** file you need to edit.  You will need to change all the values of the variables here to fit your environment.  Note all values should be inside the single quotes.

The other file, *InstallCandidVars.ps* will automatically reference the first file to pull the variables it needs.  You should never need to edit this file (unless you have a way to improve it, in which case, I am your willing student).

The result is three virtual machines appropriately deployed in vCenter, powered on and waiting for your CNAE Day-O setup.

---
Note that the script expects that in your vCenter environment you have already set up things like a **portgroup** to put Candid mgmt interface, **datastore(s)**, and at least one **VMware Cluster** with at least one ESX host inside it.  If you don't have a cluster in ESX, it is trivial to create one and drag-drop any ESX host into it.  Or, I suppose it would be possible to not use a cluster, in which case you will have to edit the Install script to remove the commands that look for it (not tested, not advised).

**Important note to vCenter 6.5 users!** In vCenter 6.5, Vmware's default hashing for OVA files uses SHA256.  Unfortunately, PowerCLI (also from Vmware) does not yet support SHA256 but can use SHA1.  This means you will need to download the free OVFTool from VMware and convert the CNAE OVA.  Don't worry, this is fairly easy to do and just takes a few minutes.  Annoying nonetheless.  **Write your PowerCLI Product Team to get this fixed!**
**2019 Update:  I think PowerCLI 10.1.x can now support SHA256, but I have not tested.**

---
Tested on vCenter 6.0 and 6.5
