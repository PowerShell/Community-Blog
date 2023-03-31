---
post_title: Request, Export and Import Certificates using PowerShell
username: sorastog
categories: PowerShell
tags: PowerShell, Certificates, Automation
summary: This posts explains how to Request, Export and Import Certificates using PowerShell
---

Hi Readers,
I am targeting to create a personal certificate in this blog post, configure the certificate, export it in local machine and then import it in another remote machine.

## Steps to follow

1. Request new Certificate

```powershell
Set-Location 'Cert:\LocalMachine\My'
$cert = Get-Certificate -Template Machine -Url ldap:///CN=contoso-PKI-CA -DnsName MyVM01.contoso.com -CertStoreLocation Cert:\LocalMachine\My
$thumbprint = $cert.Certificate.Thumbprint
```

1. Manage Private Keys

```powershell
   #manage private keys
   $cert = Get-ChildItem -Recurse "Cert:\LocalMachine\My\$thumbprint"
   $stub = "\Microsoft\Crypto\RSA\MachineKeys\"
   $programData = $Env:ProgramData
   $keypath = $programData + $stub
   $certHash = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
   $certFullPath = $keypath + $certHash
   $certAcl = Get-Acl -Path $certFullPath
   $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule 'contoso\cloud_pack_setup', 'ReadData,FullControl', 'Allow'
   $certAcl.AddAccessRule($accessRule)
   Set-Acl $certFullPath $certAcl
```

1. Copy Certificate from one store to another store

```powershell
   #Copy certificate from personal to intermediate certification authorities
   Export-Certificate -Type CERT -FilePath C:\OrchCert.cer -Cert "Cert:\LocalMachine\My\$thumbprint"
   Import-Certificate -CertStoreLocation Cert:\LocalMachine\CA -FilePath C:\OrchCert.cer
```

1.Export Certificate

```powershell
   #export certificate (Orch)
   Export-Certificate -Type CERT -FilePath C:\OrchCert.cer -Cert "Cert:\LocalMachine\CA\$thumbprint"
```

1. Copy Certificate from local machine to remote Machine

```powershell
   #copy certificate from Orch VM to Portal VM
   Set-Location C:\Windows\System32
   Copy-Item C:\OrchCert.cer -Destination \\CPPortal01\C$\OrchCert.cer -Force
```

1. Import Certificate in remote machine after it is copied

```powershell
   #import certificate in portal vm (asp portal)
   Import-Certificate -CertStoreLocation Cert:\LocalMachine\CA -FilePath C:\OrchCert.cer
```

The above steps can be merged to create a whole PowerShell script that creates , exports and imports a certificate.

See you in my next post. Till Then, Happy Scripting :)