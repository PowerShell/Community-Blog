---
post_title: How to Update or Add a Registry Key Value with PowerShell
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, registry, provider
Summary: How you can update or add registry keys or registry key value entries.
---
**Q:** I am having a problem trying to update the registry. 
I am using the New-ItemProperty cmdlet, but it fails if the registry key does not exist. 
I added the –Force parameter, but it still does not create the registry key. 
The error message says that it cannot find the path because it does not exist. 
Is there something I am not doing? I include my script so you can see what is going on. Help me, please?

**A:** Let's look at how you can use PowerShell to add or update any registry key value.

## The Registry

Before answering the query, let me cover some of the background basics.
You probably already know this but I start with a look at the Registry and how PowerShell providers relate to the query.
I hope this is not _too_ basic!

In Windows the Registry is a database of configurations information used by Windows and Windows applications.
The registry is critical to the operation of Windows - I learned that long ago (and got practice reinstalling Windows NT).
Using the registry editor can be dangerous, so be careful!

The registry is a set of hierarchical keys - a registry key can have zero, or more sub-keys, and so on.
Each key or sub-key can have zero or more value entries.
Each value entry has a data type and a data value.
Any registry key can have values of any data type.
The registry allows you to create any key and to put pretty much any kind of data into a value entry.

The registry is implemented in Windows as a set of registry hives.
A hive is a logical group of keys, sub-keys, and values in the registry.
Each hive has a set of supporting files that Windows loads into memory when the operating system starts up or a user logs in.
For more details about registry hives see [the Registry Hives on-line help text](https://docs.microsoft.com/windows/win32/sysinfo/registry-hives). 

Ever since Windows NT 3.1, it is easy to edit the registry using the built in registry editor - **regedit.exe**.
Windows NT also had the **reg.exe** command that allowed you to manage the registry programatically and you can still usew it today.
You can also use the WMI to access WMI, as shown in this excerpt from [Richard Siddaway's book **PowerShell and WMI**](Https://livebook.manning.com/book/powershell-and-wmi/chapter-7/).

For IT Pros using PowerShell, the Windows PowerShell team, created a very simple way through the use of the Registry provider which is the focus of this article.

## Providers and the Registry Provider

Windows contains a number of data stores that are critical to the operation of Windows and Windows applications.
These data stores include the registry, as well as the file store, the certificate store, and more.
The developers of PowerShell, when faced with the challenge of enabling IT Pros to access all this information had two main options.

The first option was to create a huge number unique cmdlets for each data store
This would be a lot of work and would be almost certain to introduce inconsistencies.
The second option was to use an intermediate layer, the provider, which converted the data store into something resembling the file store.
With the provider you use the same command(s) to get access the registry, access files and folders, etc.

To discover the providers on your system, you use the `Get-PSProvider` cmdlet like this:

```powershell-console
PS> Get-PSProvider

Name         Capabilities                         Drives
----         ------------                         ------
Registry     ShouldProcess                        {HKLM, HKCU}
Alias        ShouldProcess                        {Alias}
Environment  ShouldProcess                        {Env}
FileSystem   Filter, ShouldProcess, Credentials   {C, D, H, I, M, N, Temp, db…
Function     ShouldProcess                        {Function}
Variable     ShouldProcess                        {Variable}
Certificate  ShouldProcess                        {Cert}
```

## Provider Drives

With a provider, you can create a drive that allows access to part of one of the provider-based data stores.
For the filestore provider, PowerShell provides you with provider drives pointing to the Windows volumes in your system, such as **C:**, **D:**, etc.
You can also create a provider drive called `DB:` that points to `D:\\Dropbox` by using the `New-PSDrive` cmdlet.
You can persist the drive name by adding the statement to your profile should this be useful.

With the registry provider, PowerShell provides you with two built-in drives: `HKLM:` and `HKCU:`.
The **HKLM:** drive exposes the local machine registry hive - which you (and Windows) use for system wide settings.
You use the **HKCU:** drive to access the current user's registry hive.

You can discover the provider based drives by using the `Get-PSProvider` cmdlet, like this:

```powershell-console
PS> Get-PSDrive

Name     Used (GB)   Free (GB) Provider      Root
----     ---------   --------- --------      ----
Alias                          Alias
C           262.51      714.58 FileSystem    C:\\
Cert                           Certificate   \\
D          1312.83      596.76 FileSystem    D:\\
db         1312.83      596.76 FileSystem    D:\\DropBox
docs       1312.83      596.76 FileSystem    D:\\Dropbox\\PACKT…
Env                            Environment
F                              FileSystem    F:\\
Function                       Function
G             2.68       56.79 FileSystem    G:\\
gd         3169.18      556.84 FileSystem    M:\\gd
H          2860.16      865.85 FileSystem    H:\\
HKCU                           Registry      HKEY_CURRENT_USER
HKLM                           Registry      HKEY_LOCAL_MACHINE..
```
Some Windows features come with additional providers, such as the the **ActiveDirectory** RSAT module.
This feature includes an AD provider:

```powershell-console
PS> Import-Module -Name ActiveDirectory
PS> Get-PSProvider -Name ActiveDirectory

Name             Capabilities                                          Drives
----             ------------                                          ------
ActiveDirectory  Include, Exclude, Filter, ShouldProcess, Credentials  {AD}
```

## Registry Value Entries

As I mentioned above, a registry key can contain value entries.
You can think of each value entry as an attribute of a registry key.
You use the `*-ItemProperty` cmdlets to manage individual registry values. 
But how does this relate to the question?
Let's begin by looking at the script in question:

```powershell-console
$RegistryPath = 'HKCU:\\Software\\CommunityBlog\\Scripts'
$Name         = 'Version'
$Value        = '42'
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force 

New-ItemProperty: Cannot find path 'HKCU:\\Software\\CommunityBlog\\Scripts' because it does not exist.
```

The script used the `New-ItemProperty` to create a **Version** value entry to a specific key.
This script, however, fails since the registry key, specified in `$RegistryPath` variable does not exist.

A better approach is to test the registry key path first, creating it if needed, then setting the value entry, like this:

```powershell
# Set variables to indicate value and key to set
$RegistryPath = 'HKCU:\\Software\\CommunityBlog\\Scripts'
$Name         = 'Version'
$Value        = '42'
# Create the key if it does not exist
If (-NOT (Test-Path $RegistryPath)) {
  New-Item -Path $RegistryPath -Force | Out-Null
}  
# Now set the value
New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force 
```
## A small word of warning

Playing with the registry can be dangerous.
This is true when using both the Registry Editor and the PowerShell commands.
Be careful!

## Summary

It is easy to change add registry keys and values.
You can use the `New-Item` cmdlet to create any key in any registry hive. 
Once you create the key, you can use `New-ItemProperty` to set a registry value entry.



## Tip of the Hat

I based this article on one written for the earlier Scripting Guys blog [Update or Add Registry Key Value with PowerShell](https://devblogs.microsoft.com/scripting/update-or-add-registry-key-value-with-powershell/).
It was written by Ed Wilson.
