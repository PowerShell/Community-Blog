---
post_title: Update XML File using PowerShell
username: sorastog
categories: PowerShell
tags: PowerShell, XML, Configuration
summary: This posts explains how to update XML file using PowerShell
---

# Update XML File using PowerShell

There are many blogs on internet already speaking about updating XML files in PowerShell, but I felt need of one consolidated blog where complex XML files can also be updated with long complex Hierarchy of XML nodes and attributes.
Below is an XML example which we will try in this blog to update at various level of node Hierarchy.

## Sample Code

```PowerShell
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

## Steps to Follow
We will target to update Roles, Variables and VMName etc in this XML file. Below are the steps given separately on how we can update nodes and their attributes at various levels.
1. Define the variable which are required to be modified:-

```PowerShell
    $path = 'C:\Users\sorastog\Desktop\blog\Variable.xml'
     
    $ManagementServer = 'NewManagementServer'
    $SQLServer = 'NewSQLServer'
    $SQLAdmin = 'Domain\NewSQlAdmin'
    $DNSServerVMName = 'NewDNSServer'
```

2. Reading the content of XML file.

```PowerShell
    $xml = [xml](Get-Content $path)
```

3.  Update ‘ManagementServer’: Changing Attribute value of node at level 3 based on ‘Name’ attribute on same level.

```PowerShell
    $node = $xml.Data.Roles.Role | where {$_.Name -eq 'ManagementServer'}
    $node.Value = $ManagementServer
```

4. Update ‘SQLServer’: Changing Attribute value of node at level 3.

```PowerShell
    $node = $xml.Data.SQL.Instance
    $node.Server = $SQLServer
```
5. Update ‘SQLAdmin’: Changing Attribute value of node at level 4 based on ‘Name’ attribute on same level.

```PowerShell
    $node = $xml.Data.SQL.Instance.Variable | where {$_.Name -eq 'SQLAdmin'}
    $node.Value = $SQLAdmin
```

6. Update ‘DNSServerVM’: Changing Attribute value of node at level 4 based on ‘VMType’ attribute at above level.

```PowerShell
    $node = $xml.Data.VMs.VM | where {$_.Type -eq 'DNSServerVM'}
    $node.VMName = $DNSServerVMName    $node.Server = $SQLServer
```

7. Saving changes to XML file.

```PowerShell
    $xml.Save($path)
```

## Output
The final PowerShell script would look like below:-

```PowerShell
    $path = 'C:\Data.xml'     


    $ManagementServer = 'NewManagementServer'

    $SQLServer = 'NewSQLServer'

    $SQLAdmin = 'Domain\NewSQlAdmin'

    $DNSServerVMName = 'NewDNSServer'
     

    $xml = [xml](Get-Content $path)

       

   $node = $xml.Data.Roles.Role | where {$_.Name -eq 'ManagementServer'}

   $node.Value = $ManagementServer
       

   $node = $xml.Data.SQL.Instance

   $node.Server = $SQLServer
    

   $node = $xml.Data.SQL.Instance.Variable | where {$_.Name -eq 'SQLAdmin'}

   $node.Value = $SQLAdmin
    

   $node = $xml.Data.VMs.VM | where {$_.Type -eq 'DNSServerVM'}

   $node.VMName = $DNSServerVMName
    

   $xml.Save($path)
```

Hope this will help you to update even complex XML files with multiple nodes and complex Hierarchy. If there are some XML nodes that you would like to update and the category is not included in this blog, please reply to this post and I will add it.
Till Then, Happy Scripting :)
