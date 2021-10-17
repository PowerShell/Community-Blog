#  Secret management

# 1. Discover the modules
$Names =  'Microsoft.PowerShell.SecretManagement',
          'Microsoft.PowerShell.SecretStore'
Find-Module -Name $Names | 
  Format-Table -Wrap -AutoSize

# 2. Install both modules
Install-Module -Name $Names -Force -AllowClobber

# 3. Examine them
Get-Module -Name Microsoft*.Secret* -List

# 4. Discover commands in the secret management module
Get-Command -Module Microsoft.PowerShell.SecretManagement

# 5. Use the default provider
Register-SecretVault -Name PSPSecrets -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# 6. View Secret vault
Get-SecretVault

# 7. Set the Admin password secret
Set-Secret -Name ReskitAdmin -Secret 'Pa$$w0rd'

# 8. Create a credential object using the secet
$User = 'Reskit.'
$PwSS = Get-Secret ReskitAdmin
$Cred = [System.Management.Automation.PSCredential]::New($User,$PwSS)

# 9. Let's cheat and see what the password is?
$PW = $Cred.GetNetworkCredential().Password
"Password for this credential is [$PW]"

# 10. Setting a secret with Metadata
Set-Secret -Name ReskitAdmin -Secret 'Pa$$w0rd' -Metadata @{Purpose="Reskit.Org Enterprise/Domain Admin PW"}

# 11. Updating the metadata
Set-SecretInfo -Name ReskitAdmin -Metadata @{Author = 'DoctorDNS@Gmail.Com';
                                             Purpose="Reskit.Org Enterprise/Domain Admin PW"}

# 12. View secret information
Get-SecretInfo -Name ReskitAdmin | Select-Object -Property Name, Metadata
