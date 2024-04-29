---
post_title: 'Encrypting secrets locally'
username: rod-meaney
categories: PowerShell
post_slug: encrypting-secrets-locally
tags: Automation, Toolmaking, Security
summary: Keeping security folks happy (or less upset which is the best we can hope for)
---

If you are involved in support or development, often you need to use secrets, passwords, or
subscription keys in PowerShell scripts. These need to be kept secure, and separate from your
scripts but you also need access to them ALL THE TIME.

So instead of hand entering them every time they should be stored in a key store of some sort that
you can access programmatically. Often off the shelf keystores are not available in your
environment, or are clumsy to access with PowerShell. A simple way to have easy access to these
secrets with PowerShell would be helpful.

You could simply have them in plain text, on your machine only, making it relatively secure.
However, there are many risks with this approach, so adding some additional security is an excellent
idea.

The .NET classes sitting behind PowerShell provide some simple ways to do this. This blog will go
through

- Basic encryption / decryption
- Using it day-to-day
- Your own form-based key store

## Basic encryption / decryption

The [protect][07] and [unprotect][08] methods available as part of the cryptography classes are
easy to use. However they use Byte arrays that we can simplify by wrapping their use in a String.

The following examples can be found at the [MachineAndUserEncryption.ps1][06] module in my
[ps-community-blog][04] repository on GitHub.

### Encryption

```powershell
Function Protect-WithUserKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$secret
    )
    Add-Type -AssemblyName System.Security
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($secret)
    $SecureStr = [Security.Cryptography.ProtectedData]::Protect(
        $bytes,     # contains data to encrypt
        $null,      # optional data to increase entropy
        [Security.Cryptography.DataProtectionScope]::CurrentUser # scope of the encryption
    )
    $SecureStrBase64 = [System.Convert]::ToBase64String($SecureStr)
    return $SecureStrBase64
}
```

Just going through the lines we can see

1. PowerShell needs to know about the .NET classes (I have tested under version 5 & 7 of PowerShell)
1. We need to convert our string into a Byte array
1. Use the .NET class to encrypt
1. Convert the encrypted Byte array to a string for easy storage and retrieval
1. Return that string

### Decryption

```powershell
Function Unprotect-WithUserKey {
    param (
        [Parameter(Mandatory=$true)]
        [string]$enc_secret
    )
    Add-Type -AssemblyName System.Security
    $SecureStr = [System.Convert]::FromBase64String($enc_secret)
    $bytes = [Security.Cryptography.ProtectedData]::Unprotect(
        $SecureStr,     # bytes to decrypt
        $null,          # optional entropy data
        [Security.Cryptography.DataProtectionScope]::CurrentUser) # scope of the decryption
    $secret = [System.Text.Encoding]::Unicode.GetString($bytes)
    return $secret
}
```

Steps are identical for the decryption, using slightly different methods

1. PowerShell needs to know about the .NET classes
1. We need to convert our string into a Byte array
1. Use the .NET class to decrypt
1. Convert the encrypted Byte array to a string
1. Return that string

## Using it day-to-day

This is really useful if you are doing repetitive tasks that need these values. Often in a support
role, investigations using API's can speed up the process of analysis, and also provide you with a
quick way to do fixes that don't require heavy use of a GUI based environment.

Assigning a key to a secret value, and storing that in a hash table format is the simplest way to
have access to these values AND keep them stored locally with a degree of security. Your code can
then dynamically look up these values, and if other support people store the same key locally the
same way (often with different values, think of an API password and or username pair) then your
script can work for everyone.

Again, `MachineAndUserEncryption.ps1` in my repository on my GitHub has functions for persisting and
using this information. For compatibility with version 5 & 7 you also need the function
[ConvertToHashtableV5][05].

I would also recommend using `Protect-WithMachineAndUserKey` and `Unprotect-WithMachineAndUserKey`
when implementing locally, they add another layer of protection.

## Your own form-based key store

If you have followed my other 2 blogs about a [scalable environment][02] and
[simple form development][03] then using the resources from these we can easily create our own form
to manage our secrets. In fact, if you have downloaded and installed the modules for either of those
blogs (they are the same, and this blog references the same as well), you have it ready to go.

Once you have your environment set up, simply run the cmdlet:

```powershell
New-EncryptKeyForm
```

and if all is set up correctly, you should see

![key-value-secret-store][01]

## Conclusion

Balancing the pragmatic ease of use and security concerns around secrets you may need to use all day
every day can be a fine balancing act. Using some simple methods, we can strike that balance and
hopefully be securely productive.

> Lets secure some stuff!

<!-- link references -->
[01]: ./Media/encrypting-secrets-locally/KeyValueStore.png
[02]: https://devblogs.microsoft.com/powershell-community/creating-a-scalable-customised-running-environment/
[03]: https://devblogs.microsoft.com/powershell-community/simple-form-development-using-powershell/
[04]: https://github.com/rod-meaney/ps-community-blog
[05]: https://github.com/rod-meaney/ps-community-blog/blob/main/my-utilities/GeneralUtilities/ConvertToHashtableV5.ps1
[06]: https://github.com/rod-meaney/ps-community-blog/blob/main/my-utilities/GeneralUtilities/MachineAndUserEncryption.ps1
[07]: https://learn.microsoft.com/dotnet/api/system.security.cryptography.protecteddata.protect
[08]: https://learn.microsoft.com/dotnet/api/system.security.cryptography.protecteddata.unprotect
