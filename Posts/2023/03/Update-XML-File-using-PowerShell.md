---
post_title: Update XML files using PowerShell
username: sorastog
categories: PowerShell
tags: PowerShell, XML, Configuration
summary: This posts explains how to update XML files using PowerShell
---

There are many blogs on internet already speaking about updating XML files in PowerShell, but I
felt need of one consolidated blog where complex XML files can also be updated with long complex
hierarchy of XML nodes and attributes.

Below is an XML example which we will try in this blog to update at various level of node hierarchy.

## Sample Code

```xml
<?xml version="1.0" encoding="utf-8"?>
<Data version="2.0">
  <Roles>
    <Role Name="ManagementServer" Value="OldManagementServer" />
  </Roles>
  <SQL>
    <Instance Server="OldSQLServer" Instance="MSSQLSERVER" Version="SQL Server 2012">
      <Variable Name="SQLAdmin" Value="Domain\OldSQlAdmin" />
      <Variable Name="SQLUser" Value="domain\sqluser" />
    </Instance>
  </SQL>
  <VMs>
    <VM Type="ClientVM">
      <VMName>ClientVM</VMName>
    </VM>
    <VM Type="DNSServerVM">
      <VMName>OldDNSServer</VMName>
    </VM>
  </VMs>
</Data>
```

## Steps to follow

We will update the nodes in this XML file to use a new management, SQL, and DNS servers. Below are
the steps given separately on how we can update the nodes and their attributes at various levels.

1. Define the variables which need to be modified:

   ```powershell
   $path             = 'C:\Users\sorastog\Desktop\blog\Variable.xml'
   $ManagementServer = 'NewManagementServer'
   $SQLServer        = 'NewSQLServer'
   $SQLAdmin         = 'Domain\NewSQlAdmin'
   $DNSServerVMName  = 'NewDNSServer'
   ```

1. Reading the content of XML file.

   ```powershell
   $xml = [xml](Get-Content -Path $path)
   ```

1. Update `ManagementServer`: Change the attribute **Value** of nodes at level 3 based on the
   **Name** attribute on the same level.

   ```powershell
   $node = $xml.Data.Roles.Role | 
       Where-Object -Process { $_.Name -eq 'ManagementServer' }
   $node.Value = $ManagementServer
   ```

1. Update `SQLServer`: Change the attribute **Value** of a node at level 3.

   ```powershell
   $node        = $xml.Data.SQL.Instance
   $node.Server = $SQLServer
   ```

1. Update `SQLAdmin`: Change the attribute **Value** of nodes at level 4 based on the **Name**
   attribute on the same level.

   ```powershell
   $node = $xml.Data.SQL.Instance.Variable |
       Where-Object -Process { $_.Name -eq 'SQLAdmin' }
   $node.Value = $SQLAdmin
   ```

1. Update `DNSServerVM`: Change the attribute **Value** of nodes at level 4 based on the **VMType**
   attribute at the level above.

   ```powershell
   $node = $xml.Data.VMs.VM |
       Where-Object -Process { $_.Type -eq 'DNSServerVM' }
   $node.VMName = $DNSServerVMName
   ```

1. Save changes to the XML file.

   ```powershell
   $xml.Save($path)
   ```

## Output

The final PowerShell script would look like below:

```powershell
$path             = 'C:\Data.xml'
$ManagementServer = 'NewManagementServer'
$SQLServer        = 'NewSQLServer'
$SQLAdmin         = 'Domain\NewSQlAdmin'
$DNSServerVMName  = 'NewDNSServer'

$xml = [xml](Get-Content $path)

$node = $xml.Data.Roles.Role |
    Where-Object -Process  { $_.Name -eq 'ManagementServer' }
$node.Value = $ManagementServer

$node        = $xml.Data.SQL.Instance
$node.Server = $SQLServer

$node = $xml.Data.SQL.Instance.Variable |
    Where-Object -Process  { $_.Name -eq 'SQLAdmin' }
$node.Value = $SQLAdmin

$node = $xml.Data.VMs.VM |
    Where-Object -Process  { $_.Type -eq 'DNSServerVM' }
$node.VMName = $DNSServerVMName

$xml.Save($path)
```

Hope this will help you to update even complex XML files with multiple nodes and deep hierarchies.
If there are some XML nodes that you would like to update and the category is not included in this
blog, please reply to this post and I will add it.

Till Then, Happy Scripting :)
