---
post_title: Using Get-Service in PowerShell 7 vs. Windows PowerShell 5.1
username: farisnt@gmail.com
Catagories: PowerShell, Windows Services
Summary: Show how to get services information using both Windows PowerShell 5.1 and PowerShell 7
---

# Get-Services, PowerShell 7 VS Windows PowerShell 5.1

**Q**: How can I get the Username, and StartType for a Windows Service?

**A**: Quick answer is PowerShell 7.

Microsoft is doing a great job on PowerShell with each version they release. The simple answer to this question is a command called `Get-Service`. But there is a big update that makes getting the required information much easier with PowerShell 7. I will show the result of this command using both **PowerShell 7** and **Windows PowerShell 5.1**.

Let's start by typing the simple command `Get-Service Workstation`. This command return basic details for a service called **Workstation**. The result is the same for both PowerShell 7 and Windows PowerShell 5.1.

```powershell
Status   Name               DisplayName
------   ----               -----------
Running  LanmanWorkstation  Workstation
```

To drill-down and get a more detailed result, we need to see all the associated _properties_ and _methods_ for this service, which can be achieved using the following command.

## Getting Windows Services using Get-Service

```powershell
Get-Service Workstation | Get-Member | Select-Object Name, MemberType
```

The output returns a list of members that can be invoked in the command line. Here is the output in PowerShell 7.

```powershell
Name                         MemberType
----                         ----------
Name                      AliasProperty
RequiredServices          AliasProperty
Disposed                          Event
Close                            Method
Continue                         Method
Dispose                          Method
Equals                           Method
ExecuteCommand                   Method
GetHashCode                      Method
GetLifetimeService               Method
GetType                          Method
InitializeLifetimeService        Method
Pause                            Method
Refresh                          Method
Start                            Method
Stop                             Method
WaitForStatus                    Method
BinaryPathName                 Property
CanPauseAndContinue            Property
CanShutdown                    Property
CanStop                        Property
Container                      Property
DelayedAutoStart               Property
DependentServices              Property
Description                    Property
DisplayName                    Property
MachineName                    Property
ServiceHandle                  Property
ServiceName                    Property
ServicesDependedOn             Property
ServiceType                    Property
Site                           Property
StartType                      Property
StartupType                    Property
Status                         Property
UserName                       Property
ToString                   ScriptMethod
```

Here is the output in Windows PowerShell 5.1.

```powershell
Name                         MemberType
----                         ----------
Name                      AliasProperty
RequiredServices          AliasProperty
Disposed                          Event
Close                            Method
Continue                         Method
CreateObjRef                     Method
Dispose                          Method
Equals                           Method
ExecuteCommand                   Method
GetHashCode                      Method
GetLifetimeService               Method
GetType                          Method
InitializeLifetimeService        Method
Pause                            Method
Refresh                          Method
Start                            Method
Stop                             Method
WaitForStatus                    Method
CanPauseAndContinue            Property
CanShutdown                    Property
CanStop                        Property
Container                      Property
DependentServices              Property
DisplayName                    Property
MachineName                    Property
ServiceHandle                  Property
ServiceName                    Property
ServicesDependedOn             Property
ServiceType                    Property
Site                           Property
StartType                      Property
Status                         Property
ToString                   ScriptMethod
```

## PowerShell 7

The big difference is in the **Property** members. Now, in PowerShell 7, it's possible to read some additional properties that were not available in Windows PowerShell 5.1, such as **UserName**, **BinaryPathName**, **StartType**. So let's see how to read these properties using PowerShell 7.

```powershell
PS 7> Get-Service workstation | select  Username,Starttype,BinaryPathName
```

The output is a clear, with all the required results using a native one-liner command.

```powershell
UserName                    StartType BinaryPathName
--------                    --------- --------------
NT AUTHORITY\NetworkService Automatic C:\WINDOWS\System32\svchost.exe -k NetworkService -p
```

## Windows Powershell 5.1

For Windows PowerShell 5.1, the operation is not as simple as in PowerShell. We need to use the `Get-CimInstance` and pass the required WQL query. So, in Windows PowerShell 5.1, run the following command:

```powershell
WPS 5.1> Get-CimInstance -Query 'select * from Win32_Service where caption like "Workstation"' | select StartName,StartMode,PathName
```

```powershell
StartName                   StartMode PathName
---------                   --------- --------
NT AUTHORITY\NetworkService Auto      C:\WINDOWS\System32\svchost.exe -k NetworkService -p
```

In this example, we invoke `Get-CimInstance` with a query to get the service name and then select the required properties, which is a long way and requires you to know extra information related to the original service name and some basic WMI query language.

## Summary

More and more to come with PowerShell 7, ease of use, backward compatibility much rich experience. This post shows a small portion of a small change in PowerShell which will help a lot of admin in their day-to-day tasks.
