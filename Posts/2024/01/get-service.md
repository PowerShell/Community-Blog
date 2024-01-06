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

1.  Open PowerShell and run the following command.  Or, open VS Code, create a new PowerShell file, and enter the following command.
1.  The output will be a listing of the services that are configured to run as a user account.

```powershell
Get-Service | Where-Object {$_.username -ne "NT AUTHORITY\LocalService" -and $_.username -ne "localsystem" -and $_.username -ne "NT AUTHORITY\NetworkService" -and $_.username -ne ""} | Select -Property Name,DisplayName,UserName
```
