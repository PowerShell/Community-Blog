---
post_title: Invoking SQL Scripts using PowerShell
username: sorastog
categories: PowerShell
tags: PowerShell,SQL,Automation
summary: This posts explains how to invoke SQL Scripts using PowerShell
---

Hi Readers,

We will see in this blog post on how we can run large SQL scripts file through PowerShell.
Invoke-Sqlcmd cmdlet is used to run sql commands.

## Steps to follow

This script assumes that you already have "CreateMyDBTables.sql" file created and stored in your local machine.

1. Read SQL Script in a variable.

```powershell
   $sql = [Io.File]::ReadAllText('.\CreateMyDBTables.sql');
```

1. Import SQLPS module

```powershell
   Import-Module 'SQLPS' -DisableNameChecking;
```

1. Invoke the script. Specify Server Instance, I have specified local instance in below example

```powershell
   Invoke-Sqlcmd -Query $sql -ServerInstance '.';
```

## Output

The combined code will look like below:-

```powershell
   $sql = [Io.File]::ReadAllText('.\InstallPortalDB.sql');
   Import-Module 'SQLPS' -DisableNameChecking;
   Invoke-Sqlcmd -Query $sql -ServerInstance '.';
```

See you in my next blog post 🙂. Happy Scripting!!!