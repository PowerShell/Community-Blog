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

# 4. Discover commands in the secrets module
$FormatEnumerationLimit = 99
Get-Command -Module $Names |
  Group-Object -Property Source |
    Format-Table -Wrap

    