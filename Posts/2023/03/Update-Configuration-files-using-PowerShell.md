---
post_title: Update Configuration files using PowerShell
username: sorastog
categories: PowerShell
tags: PowerShell,XML,Configuration
summary: This posts explains how to update Configuration files using PowerShell
---

Hi Readers,
We will see in this post on how we can edit web.config or other configuration files using PowerShell. There are already several posts available on internet which shows this functionality, however I faced difficulties in updating connection string in the configuration file as they are not direct. Below steps will help you in updating the connection strings as well.

## Sample Code

Sample configuration file is shown below. Other sections of web.config file are not shown in this blog for simplicity.

```xml
   <configuration>
     <connectionStrings>
       <add name="TestDBEntities" connectionString="metadata=res://*/TestProject.csdl|res://*/TestProject.ssdl|res://*/TestProject.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=SQL01;initial catalog=TestDB;integrated security=True;MultipleActiveResultSets=True;App=EntityFramework&quot;" providerName="System.Data.EntityClient" />
     </connectionStrings>
     <appSettings>
       <add key="SCVMMServerName" value="VMM01" />
       <add key="SCVMMServerPort" value="8100" />
     </appSettings>
   </configuration>
```

We will try to update ‘appSettings’ section and connectionStrings section of this configuration file.

## Steps to follow

1. Read configuration file in a XML variable

```powershell
   $webConfig = 'C:\inetpub\wwwroot\VMMService\Web.config'
   $doc = (Get-Content $webConfig) -as [Xml]
```

1. Update ‘appSettings’ Section

```powershell
   $obj = $doc.configuration.appSettings.add | where {$_.Key -eq 'SCVMMServerName'}
   $obj.value = 'CPVMM02'
```

1. Add new ‘appSetting’. You will need to create an XmlElement and append it as a child node to ‘appSettings’

```powershell
   $newAppSetting = $doc.CreateElement(“add”)
   $doc.configuration.appSettings.AppendChild($newAppSetting)
   $newAppSetting.SetAttribute(“key”,”SCVMMIPAdress”);
   $newAppSetting.SetAttribute(“value”,”10.10.10.10″);
```

1. Update ‘connectionStrings’ section. Here is the tweak, you have to read the root element and then modify the connection string as shown below:-

```powershell
   $root = $doc.get_DocumentElement();
   $newCon = $root.connectionStrings.add.connectionString.Replace('data source=SQL01','data source=SQL02');
   $root.connectionStrings.add.connectionString = $newCon
```

1. Save the configuration file

```powershell
   1: $doc.Save($webConfig)
```

## Output

The combined code will look like below:-

```powershell
   $webConfig = 'C:\inetpub\wwwroot\TestService\Web.config'
   $doc = (Get-Content $webConfig) -as [Xml]
   $obj = $doc.configuration.appSettings.add | where {$_.Key -eq 'SCVMMServerName'}
   $obj.value = 'CPVMM02'

   $newAppSetting = $doc.CreateElement("add")
   $doc.configuration.appSettings.AppendChild($newAppSetting)
   $newAppSetting.SetAttribute("key","SCVMMIPAdress");
   $newAppSetting.SetAttribute("value","10.10.10.10");
 
   $root = $doc.get_DocumentElement();
   $newCon = $root.connectionStrings.add.connectionString.Replace('data source=SQL01','data source=SQL02');
   $root.connectionStrings.add.connectionString = $newCon
 
   $doc.Save($webConfig)
```

The updated XML will contain modified values as shown below:-

```xml
    <configuration>
     <connectionStrings>
         <add name="TestDBEntities" connectionString="metadata=res://*/TestProject.csdl|res://*/TestProject.ssdl|res://*/TestProject.msl;provider=System.Data.SqlClient;provider connection string=&quot;data source=SQL02;initial catalog=TestDB;integrated security=True;MultipleActiveResultSets=True;App=EntityFramework&quot;" providerName="System.Data.EntityClient" />
     </connectionStrings>
     <appSettings>
         <add key="SCVMMServerName" value="CPVMM02" />
         <add key="SCVMMServerPort" value="8100" />
         <add key="SCVMMIPAdress" value="10.10.10.10" />
     </appSettings>
    </configuration>
```

Let me know if there are some sections of configuration file which you are finding difficult to update and I will add them here in this blog 🙂 Happy Scripting!!!