---
post_title: Is a User A Local Administrator
username: tfl@psp.co.uk
Catagories: PowerShell
tags: local users, security, logon scripts
Summary: In a logon script, how you can tell if the user is a local administrator
---

**Q:** Some of the things we do in our logon scripts require the user to be a local administrator. How can the script tell if the user is a local administrator or not, using PowerShell 7.

**A:**  Easy using PowerShell 7 and the LocalAccounts module

## Local Users and Groups

The simple answer is of course, easily.
And since you ask, with PowerShell 7!
But let's begin lets begin by reviewing local users and groups in Windows.

Every Windows system, except for Domain Controllers, maintains a set of local accounts - local users and local groups.
Domain controllers use the AD and do not really have local accounts as such.
You use these local accounts in addition to domain users and domain groups on domain-joined hosts when setting permissions.
You can logon to a given server using a local account or a domain account.
On Domain Controllers you can only login using a domain account.

As with AD groups, local groups and local users each have a unique Security ID (SID).
When you give a local user or group access to a file or folder, Windows adds that SID to the object's Access Control List.
This is the same way Windows enables you to give permissions to a local file or folder to any Active DIrectory user or group.

Additionally, Windows and some Windows features create "well known" local groups.
The intention is that you add users to these groups to enable those users to perform specific administrative functions on just those servers.

Traditionally, you might have used the `Wscript.Network` COM object, in conjunction with ADSI.
You can, of course, use the older approach in side PowerShell 7, but why bother?
The good news with PowerShell 7, you can use the `Microsoft.PowerShell.LocalAccounts` module to manage local accounts.
At the time of writing, this is a Windows only module.

## The Microsoft.PowerShell.LocalAccounts module

In PowerShell 7 for Windows, you can use the `Microsoft.PowerShell.LocalAccounts` module to manage local users and group.
This module is a Windows PowerShell module which PowerShell 7 loads from `C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\Microsoft.PowerShell.LocalAccounts`.

This module contains 15 cmdlets, which you can view like this:

```powershell-console
PS> Get-Command -Module Microsoft.PowerShell.LocalAccounts

CommandType     Name                       Version    Source
-----------     ----                       -------    ------
Cmdlet          Add-LocalGroupMember       1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Disable-LocalUser          1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Enable-LocalUser           1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Get-LocalGroup             1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Get-LocalGroupMember       1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Get-LocalUser              1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          New-LocalGroup             1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          New-LocalUser              1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Remove-LocalGroup          1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Remove-LocalGroupMember    1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Remove-LocalUser           1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Rename-LocalGroup          1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Rename-LocalUser           1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Set-LocalGroup             1.0.0.0    Microsoft.PowerShell.LocalAccounts
Cmdlet          Set-LocalUser              1.0.0.0    Microsoft.PowerShell.LocalAccounts
```

As you can tell, these cmdlets allow you to add, remove, change, enable and disable a local user or local group
And they allow you to add, remove and get the local group's members.
These cmdlets are broadly similar to the ActiveDirectory cmdlets, but work on local users.
And as noted above, you can use domain users/groups as a member of a local group should you wish or need to.

You use the `Get-LocalGroupMember` command to view the members of a local group, like this:

```powershell-console
PS> Get-LocalGroupMember -Group 'Administrators'

ObjectClass Name                     PrincipalSource
----------- ----                     ---------------
Group       COOKHAM\Domain Admins    ActiveDirectory
User        COOKHAM24\Administrator  Local
User        COOKHAM\JerryG           ActiveDirectory
User        COOKHAM24\Dave           Local
```

As you can see in this output, the local Administrators group on this host contains domain users and groups as well as local users

## Is the User an Administrator?

It's easy to get membership of any local group, as you saw above.
But what if you want to find out if a given user is a member of some local administrative group?
That too is pretty easy and take a couple of steps.
One way you can get the name of the current user is by using `whoami.exe`.
Then you can get the members of the local administrator's group.
Finally, you check to see if the currently logged on user is a member of the group.
All of which looks like this:

```powershell-console
PS> # Get who I am
PS> $Me = whoami.exe
PS> $Me 
Cookham\JerryG

PS> # Get members of administrators group
PS> $Admins = Get-LocalGroupMember -Name Administrators | 
       Select-Object -ExpandProperty name

PS> # Check to see if this user is an administrator and act accordingly
PS> if ($Admins -Contains $Me) {
      "$Me is a local administrator"} 
    else {
     "$Me is NOT a local administrator"}
Cookham\JerryG is a local administrator
```

If the administrative group contains user running the script, then `$Me` is a user in that local admin group.

In this snippet, we just echo the fact that the user is, ir is not, a member of the local administrators group.
You can adapt it to ensure a user is a member of the appropriate group before attempting to run certain commands.
And you can also adapt it to check for membership in other local groups such as **Backup Operators** or **Hyper-V Users** which may be relevant.

In your logon script, once you know that the user is a member of a local administrative group, you can carry out any tasks that require that membership.
And if the user is not a member of the group, you could echo that fact, and avoid using the relevant cmdlets.

## Summary

Using the Local Accounts module in PowerShell 7, it's easy to manage local groups!
You can, of course, manage the groups the same way in Windows PowerShell.

## Tip of the Hat

This article was originally a VBS based solution as described in (an earlier blog post)[https://devblogs.microsoft.com/scripting/how-can-i-determine-if-a-user-is-a-local-administrator/].
I am not sure who the author of the original post was - but thanks.
