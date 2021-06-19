---
post_title: How to rename a NIC
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, network, NIC
Summary: How to rename a NIC using PowerShell
---
**Q:** Is there a simple way to rename a NIC, especially inside a Hyper-V VM?

**A:** You can change the name of any Windows NIC using PowerShell - whether the NIC is in a physical host or a Hyper-V VM.


## NICS and NIC names

One thing that can quickly become confusing when using Hyper-V with multiple VMs and VM Switches is how fast the network adapters seem to proliferate.
You start with a few wired Ethernet Adapters on the host.
Then you install Hyper-V and create a VM farm with loads of virtual NICs.
Before you know it, you have a dozen adapters inside the VM host and an unclear set of adapters in the VM.

To discover the NICs in a host or a VM, you use the `Get-NetAdapter` cmdlet.
Which looks like this inside a Hyper-V VM:

```powershell-Console
PS> Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Ethernet                  Microsoft Hyper-V Network Adapter            22 Up           00-15-5D-01-2A-91        10 Gbps
Ethernet 2                Microsoft Hyper-V Network Adapter #2         14 Up           00-15-5D-01-2A-92        10 Gbps
Ethernet 3                Microsoft Hyper-V Network Adapter #3         15 Up           00-15-5D-01-2A-92        10 Gbps
Ethernet 4                Microsoft Hyper-V Network Adapter #4         16 Up           00-15-5D-01-2A-92        10 Gbps
Local Area Connection     TAP-Windows Adapter V9                       12 Disconnected 00-FF-B6-68-E1-5D         1 Gbps
```

Once you add a few NICs to a VM, each connected to a separate switch, telling them apart can be challenging.
To help you with subsequent maintenance, it can be good to rename the adapter and change the description.
Renaming a VM's NICs is a good habit to get into - and is straightforward to achieve.
Before renaming anything, ensure you determine the purpose for each NIC in your VM.
Once you work out what use each NIC plays in your VM farm, you can use the `Rename-NetAdapter` cmdlet to rename the NIC.

There are two ways you could use `Rename-NetAdapter` to rename one of our NICs, like this:

```powershell
# Using a 'Get-Rename' pattern
Get-NetAdapter -InterfaceIndex 22 | Rename-NetAdapter -NewName 'Reskit Management'
# Just Using Rename-NetAdapter
Rename-NetAdapter  -InterfaceIndex 22 -NewName 'Reskit Management'
```

I rarely, if ever, rename a NIC using a production script since it is usually a one-off operation.
For that reason, I prefer to use the first method.
I can first use `Get-NetAdapter`  on its own to ensure I'm getting the right adapter.
Then, I can hit `Up-Arrow`, and pipe the previous command to `Rename-NetAdapter` and specify a new name for the NIC.

## Admin rights required

There is just one small snag with using `Rename-NetAdapter` - you have to run it in an elevated console.
If, as I often do, forget to run PowerShell as an administrator, you would see the following when attempting to rename the NIC:

```powershell-console
PS> Get-NetAdapter -InterfaceIndex 22 | Rename-NetAdapter -NewName 'Sales iSCSI VLAN'
Rename-NetAdapter: Access is denied.
```

Although it might have been nice to tell you to run the command in an elevated PowerShell console, the error message should be clear enough.
And, interestingly, this fact is not currently mentioned in the help text.

Assuming that you are an administrator with the rights to change a NIC's name, you can open a new elevated PowerShell session and try the command again.
If you are using PSReadLine, when you start up the new console (as an Administrator), the command should be in PSReadLine's command cache.
And that means, once the new console is up and available, you can access that earlier command by hitting up-arrow and then hitting return.

When you do, you see this:

```powershell-console
PS> Get-NetAdapter -InterfaceIndex 16 | Rename-NetAdapter -NewName 'Sales iSCSI VLAN'
PS> Get-NetAdapter -InterfaceIndex 16

Name                InterfaceDescription                 ifIndex Status   MacAddress          LinkSpeed
----                --------------------                 ------- ------   ----------          ---------
Sales iSCSI VLAN    Microsoft Hyper-V Network Adapter         16 Up       00-15-5D-01-2A-91     10 Gbps
```

In this example: `Rename-NetAdapter` did change the name of the adapter but produced no console output.
You use `Get-NetAdapter` to view the new name.

## There are other ways

As ever with PowerShell, there are other ways you could change the name of a NIC.
One more old-fashioned way would be to use the `netsh.exe`  program.
And then there is WMI - you can use the `Set-CimInstance` to perform the name change.
And I look forward to comments suggesting other ways to change a NIC's name.

## Summary

It is easy to change a network adapter's name.
Unfortunately, the Rename-NetAdapter does not allow you to change the interface description.
You need to run the `Rename-NetAdapter` in an elevated console - if you don't, you get an Access Denied error.

## Tip of the Hat

I based this article on one written for the earlier Scripting Guys blog [Renaming Network Adapters by Using PowerShell](https://devblogs.microsoft.com/scripting/renaming-network-adapters-by-using-powershell/).
The author of that article was Ed Wilson.
