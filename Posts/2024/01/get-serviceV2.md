---
post_title: 'Get Services that are Running as a User or Service Account'
user_login: David Knapp
post_slug: get-services-not-running-as-local-system-or-network-service
categories: Get services
tags: Get-Service
summary: Get a listing of the operating systems services that are not running as Local Service, Local System, or Network Service.
---

The following script can be used to return the operating system services that are not running as Local Service, Local System, or as the Network Service.  In other words, this can be used to provide a listing of the services that are configured to run as a user account or as a service account.

# Requirements

To run this script, we just need a Windows host that has PowerShell.

It can also be run from within VS Code.

# How to Run the Script

1.  Open PowerShell, and copy \ paste the following script.  Or, open VS Code, create a new PowerShell file, and copy \ paste the following script.
1.  The output will be a listing of the services that are configured to run as a user account.

```powershell
# Define the variables that represent a list of usernames that can be associated to a service, that we want to skip and not return in the output.
$UsernameOne = "localsystem"
$UsernameTwo = "NT AUTHORITY\LocalService"
$UsernameThree = "NT AUTHORITY\NetworkService"
$UsernameFour = ""

# Get a collection of all the services on the host.
$colServices = Get-Service

# Write the output header to the display.
Write-Host "Service Name,Service Display Name,Service Username"

# Iterate through the collection of services, looking for any that are not running as one of the username variables defined above.
Foreach ($strService in $colServices)
{
  $ServiceSecurityContext = $strService.UserName
  If ($ServiceSecurityContext -ne $UsernameOne -and $ServiceSecurityContext -ne $UsernameTwo -and $ServiceSecurityContext -ne $UsernameThree -and $ServiceSecurityContext -ne $UsernameFour)
  {
    $ServiceName = $strService.Name
    $ServiceDisplayName = $strService.DisplayName
    $Result = "$ServiceName,$ServiceDisplayName,$ServiceSecurityContext"
    Write-Host $Result
  }
}
```
