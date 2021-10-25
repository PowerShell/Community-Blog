---
post_title: How to Use The Secrets Module
username: tfl@psp.co.uk
Categories: PowerShell
tags: SecretManagement, passwords, credentials
Summary: Using The Secrets Modules
---

**Q:** I have a bunch of scripts we use in production that make use of Windows credentials.
In some cases, these scripts have an actual password in plain text, while others read the password from an XML file.
Is there a better way?

**A:** Scripts with high-privilege account passwords in plain text is not a good idea.
There are several methods you can use to improve the security of credentials handling.
One great way is to use the SecretManagement and SecretStore modules from the PowerShell Gallery.

## What are Secrets?

Secrets are, in general, passwords you need to access some resource.
It might be the password for a domain administrator that you use to run a command on a remote host.
You want to keep secrets secret, yet you want a great way to use them as needed.

In my PowerShell books, I use a domain (Reskit.Org) for all my examples.
The password for this mythical domain's Enterprise and Domain administrator is "Pa$$W0rd".
I am not too worried about exposing this password as it is only the password to a few dozen VMs.
This means many of the scripts from my books contain the password in clear text.
While great for books, this is not a best practice in production.

Over the years there have been numerous attempts at handling secrets.
You could store the secrets in an XML file and import the file when you needed those secrets.
Or, you could force the user to just retype the password every time they want to use it.
Speaking personally - I get tired real fast of typing a long, complex, password time and time again!

## What are the Secrets Module?

The developers of this module recognized the challenge that users wanted consistency
in managing secrets with flexibility over which secret store to use.
The solution involves separating secrets management from secrets storage.
So there there are _two_ modules involved:

* SecretManagement - you use this module in your scripts to make use of secrets.
* SecretStore - this module contains the commands to manage a specific secret storage.

You also need a vault-specific module which the SecretsStore module accesses. 
This layered approach allows you to use any secret store you wish, manage the secrets independently of the physical storage mechanism.
You could, in theory, change the secret store and not need to change your scripts that use the secrets.

## Installing the Modules

If you want to follow along with the code and do not fancy cut/paste, I have created a GitHub Gist for the code you see in this article.
You can find it [here](https://gist.github.com/doctordns/b1a06f7002675ec2bf8f710d3c066182). 

```powershell-console
PS> # 1. Discover the modules
PS> Find-Module -Name 'Microsoft.PowerShell.Secret*' |
      Format-Table -Wrap -AutoSize

Version Name                                  Repository Description
------- ----                                  ---------- -----------
1.1.0   Microsoft.PowerShell.SecretManagement PSGallery  This module provides a convenient way for a user
                                                         to store and retrieve secrets. The secrets are
                                                         stored in registered extension vaults. An 
                                                         extension vault can store secrets locally or remotely.
                                                         SecretManagement coordinates access to the secrets
                                                         through the registered vaults.
                                                         Go to GitHub for more information about the module
                                                         and to submit issues:https://github.com/powershell/SecretManagement

1.0.4   Microsoft.PowerShell.SecretStore      PSGallery  This PowerShell module is an extension vault for the
                                                         PowerShell SecretManagement module.
                                                         As an extension vault, this module stores secrets to the local
                                                         machine based on the current user account context. 
                                                         The secrets are encrypted on file using .NETCrypto APIs. 
                                                         A password is required in the default configuration. 
                                                         The configuration can be changed with the provided cmdlets.
                                                         Go to GitHub for more information about this module 
                                                         and to submit issues: https:////github.com//powershell//SecretStore

PS> # 2. Install both modules
PS> Install-Module -Name $Names -Force -AllowClobber
```
When you install the module using `Install-Module` you see no output (unless you use the `-Verbose` switch).
You can always use `Get-Module` to check that you have installed these new (to you) modules.

## Discovering the commands available to you
Once you have thess two modules installed, you can discover the commands in each module:

```powershell-console

PS> # 3. Examine them
PS>PS> Get-Module -Name Microsoft*.Secret* -ListAvailable |
       Format-Table -Property ModuleType, Version, Name, ExportedCmdlets

ModuleType Version Name                                  ExportedCmdlets
---------- ------- ----                                  ---------------
    Binary 1.1.0   Microsoft.PowerShell.SecretManagement {[Register-SecretVault, Register-SecretVault],
                                                         [Unregister-SecretVault, Unregister-SecretVault], [Get-SecretVault,   
                                                         Get-SecretVault], [Set-SecretVaultDefault, Set-SecretVaultDefault],   
                                                         [Test-SecretVault, Test-SecretVault], [Set-Secret, Set-Secret],       
                                                         [Set-SecretInfo, Set-SecretInfo], [Get-Secret, Get-Secret],
                                                         [Get-SecretInfo, Get-SecretInfo], [Remove-Secret, Remove-Secret],
                                                         [Unlock-SecretVault, Unlock-SecretVault]}
    Binary 1.0.5   Microsoft.PowerShell.SecretStore      {[Unlock-SecretStore, Unlock-SecretStore], [Set-SecretStorePassword,  
                                                         Set-SecretStorePassword], [Get-SecretStoreConfiguration,
                                                         Get-SecretStoreConfiguration], [Set-SecretStoreConfiguration,
                                                         Set-SecretStoreConfiguration], [Reset-SecretStore,
                                                         Reset-SecretStore]}

```

As you can see, both modules have a number of commands you may need to use to manage secrets for your environment.
Also - depending on your screen width you may find your output is slightly diffetrent although it should contain the same information.

## Registering and viewing a secret vault

After you have the two modules installed, your next step is to register a secret vault.
There are several vault options you can take advantage of, for this post, I'll use the built-in default vault.
You configure the default vault like this:

```powershell-console
PS> # 4. Register the default secrets provider
PS> $Mod = 'Microsoft.PowerShell.SecretStore'
PS> Register-SecretVault -Name RKSecrets -ModuleName $Mod -DefaultVault
PS> Get-SecretVault

Name      ModuleName                       IsDefaultVault
----      ----------                       --------------
RKSecrets Microsoft.PowerShell.SecretStore True
```
Like the previous step, registering the vault does not create any output by default.
You can view the vault you just created by using the `Get-SecretVault` command.

## Setting a secret

To create a new secret in your secret vault, you use the `Set-Secret` command, like this:

```powershell-console

PS> # 4. Register the default secrets provider
PS> Import-Module -Name 'Microsoft.PowerShell.SecretManagement'
PS> Import-Module -Name 'Microsoft.PowerShell.SecretStore'
PS> $Mod = 'Microsoft.PowerShell.SecretStore'
PS> Register-SecretVault -Name RKSecrets -ModuleName $Mod -DefaultVault
PS> # 5. View Secret vault
PS> Get-SecretVault

Name      ModuleName                       IsDefaultVault
----      ----------                       --------------
RKSecrets Microsoft.PowerShell.SecretStore True

PS C:\Foo> # 6. Set the Admin password secret for Reskit forest
PS C:\Foo> Set-Secret -Name ReskitAdmin -Secret 'Pa$$w0rd'
Creating a new RKSecrets vault. A password is required by the current store configuration.
Enter password:
**********
Enter password again for verification:
**********
```

This code fragment explicitly loads both of the downloaded modules. 
If you use PowerShell module automatic loading, this is unnecessary.

Also, the first time you use `Set-Secret` to create a secret, the cmdlet prompts for a vault password.
Note this password isd NOT stored in the AD - so don't forget it!!!

As an aside - I hope you noticed the bad practice in the above code - using a clear text password in a script file.
A better approach to this _for production coding_ would be to use `Read-Host` to have the password passed in. 
In this case, you see the actual password I set, and later see that this password was indeed saved and retreived correctly.

## Using secrets stored in your secret vault

Now that you have set a password in the RKSecrets vault, you can use the `Get-Secret` cmdlet to retrieve the secret.
As you can see here, although you set a plain text password, `Get-Secret` returns the secret as a secure string.

```powershell-console
PS> # 7. Create a credential object using the secet
PS> $User = 'Reskit\\Administrator'
PS> $PwSS = Get-Secret ReskitAdmin
PS> $Cred = [System.Management.Automation.PSCredential]::New($User,$PwSS)
PS> # 8. Let's cheat and see what the password is first.
PS> $PW = $Cred.GetNetworkCredential().Password
PS> "Password for this credential is [$PW]"
Password for this credential is [Pa$$w0rd]
PS> # 9. Using the credential against DC1
PS> $Cmd = {hostname.exe}
PS> Invoke-Command -ComputerName DC1 -Credential $Cred -ScriptBlock $Cmd
DC1
```

As you can see, it is straightforward to create a new credential object using a password retrieved from the vault.
This code creates a new PSCredential object, because that is what PowerShell cmdlets use to authenticate remoting sessions.
You can use the credential object's `GetNetworkCredential()` method to retrieve the plain text password.

If you are running this code, the first time you create a vault, the secrets module requires you to specify a vault password.
Depending on what sequence of commands you enter and how quickly, you may be asked to re-enter your vault password.

## Using Metadata

If you have a large numbers of secrets to manage, you can add additional metadata to help you keep track of the secrets you set.
Metadata is a simple hash table containing the metadata you wish to apply to a secret.
Each item in the hash table is a key-value pair.
The keys can be anything you wish such as the purpose of the script and the script author.
You use `Set-Secret` to add metadata to an existing (or new) secret.
To set the metadata, you can use the `Get-SecretInfo` cmdlet.
Creating and using metadata looks like this:

```powershell-console
PS> # 10. Setting metadata
PS> Set-Secret -Name ReskitAdmin -Secret 'Pa$$w0rd' -Metadata @{Purpose="Reskit.Org Enterprise\\Domain Admin PW"}
PS> Get-SecretInfo -Name ReskitAdmin | Select-Object -Property Name, Metadata

Name        Metadata
----        --------
ReskitAdmin {[Purpose, Reskit.Org Enterprise/Domain Admin PW]}

PS> # 11. Updating the metadata
PS> Set-SecretInfo -Name ReskitAdmin -Metadata @{Author = 'DoctorDNS@Gmail.Com';
                                             Purpose="Reskit.Org Enterprise\\Domain Admin PW"}
PS> # 12. View secret information with metadata
PS> Get-SecretInfo -Name ReskitAdmin | Select-Object -Property Name, Metadata

Name        Metadata
----        --------
ReskitAdmin {[Purpose, Reskit.Org Enterprise\\Domain Admin PW], 
             [Author, DoctorDNS@Gmail.Com]}
```

As noted, Metadata can be any key-value pair you wish to add to the secret.
In this case, the code set two metadata items: the purpose of the secret and its author.
Feel free to add whatever metadata makes sense to you and your organization.


## Summary

The two secrets modules provide a great way to use secrets in your PowerShell scripts and keep the secrets secure.
These two modules work both with Windows PowerShell and PowerShell 7. 
The default secrets vault works well enough for most cases, but you have options.
If there is an interest, I can create a further blog post to look at using different secret vaults.

So stop using plain text secrets in your PowerShell scripts and use the secrets modules.
