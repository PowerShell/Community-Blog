---
post_title: 'Get Services that are Running as a User or Service Account'
user_login: David Knapp
post_slug: get-services-not-running-as-local-system-or-network-service
categories: Get services
tags: Get-Service
summary: Get a listing of the operating systems services that are not running as Local Service, Local System, or Network Service.
---

The following script can be used to return the operating system services that are not running as Local Service, Local System, or as the Network Service.  In other words, this can be used to provide a listing of all the services that can be configured to run as a user account or as a service account.

# Requirements

To run this script, we just need PowerShell.

It can also be run from within VS Code.

# How to Run the Script

1.  Open PowerShell and run the following command.
Or,
Open VS Code, create a new .ps1 file, and enter the following command.
1.  Review the output

```powershell
Get-Service | Where-Object {$_.username -ne "NT AUTHORITY\LocalService" -and $_.username -ne "localsystem" -and $_.username -ne "NT AUTHORITY\NetworkService" -and $_.username -ne ""} | Select -Property Name,DisplayName,UserName
```
