---
post_title: How Can I Be Notified Any Time a Service Goes Down?
username: farisnt@gmail.com
Categories: PowerShell
tags: PowerShell, WMI, Events
Summary: Using Powershell to create temporary event monitoring in the WMI classes
---

**How Can I Be Notified Any Time a Service Goes Down?**

Q: How Can I Be Notified Any Time a Service Goes Down?

A: The short quick answer to utilizing WMI and PowerShell 7.

Using Powershell to create temporary event monitoring in the WMI classes,
which keeps on monitoring any services changes and generates an alert once it detects a change.

## Basic Requirement

To achieve this, you need PowerShell 5.1 and above.
This post uses the latest version of PowerShell 7.
So if you are don't yet have PowerShell 7, get it for free from [Microsoft.com](http://microsoft.com/).

Also, make sure that PowerShell is running as administrator.

## Finding the Required Class

Before going into details, you need to find the required class to monitor.
To get a list of all available classes, use the following code.

```powershell-console
Get-CimClass -Namespace root\cimv2
```

The returned result represents all the available classes in the namespace.
To monitor Windows services, the WMI class name is *Win32_Service*.

To Enumerate the *Win32_Services* WMI class and get all the available services using PowerShell run the following code.

```powershell-console
PS C:\> Get-CimInstance -Namespace root\CIMV2 -ClassName win32_service
```

The result looks like the following.

```powershell-console
PS C:\> Get-CimInstance -Namespace root\CIMV2 -ClassName win32_service
```

```powershell
PS C:\> Get-CimInstance -Namespace root\CIMV2 -ClassName win32_service

ProcessId Name                                     StartMode State   Status  ExitCode
--------- ----                                     --------- -----   ------  --------
3784      AdobeARMservice                          Auto      Running OK      0
3792      AdobeUpdateService                       Auto      Running OK      0
3800      AGMService                               Auto      Running OK      0
3824      AGSService                               Auto      Running OK      0
0         AJRouter                                 Manual    Stopped OK      1077
0         ALG                                      Manual    Stopped OK      1077
0         AppIDSvc                                 Manual    Stopped OK      1077
6708      Appinfo                                  Manual    Running OK      0
21444     AppMgmt                                  Manual    Running OK      0
0         AppReadiness                             Manual    Stopped OK      1077
0         AppVClient                               Disabled  Stopped OK      1077
0         AppXSvc                                  Manual    Stopped OK      0
0         AssignedAccessManagerSvc                 Manual    Stopped OK      1077
```

For now, you can use PowerShell to find the required class, and enumerate it to get the available services.
Let's go deeper now and start creating the WMI Event Subscription.

There are three steps you need to follow to create a WMI Event Subscription:

- Create the WMI query
- Registering the query
- Reading the events.

## Creating WMI Query

WMI database has several system WMI Classes.
For instance, the *CIM_InstModification* monitors the targeted class for any changes.
So, in this case, *Win32_Service*.

The query syntax looks like

```powershell-console
Select * from <WMI System Class> within <Number of Seconds> where TargetInstance ISA <WMI Class name>
```

Let apply the same to *Win32_Serivce.* Start by Creating a PowerShell variable name it $Query and type the following query

```powershell-console
PS C:\> $query = "Select * from CIM_InstModification within 10 where TargetInstance ISA 'Win32_Service'"
```

> A full explanation for the WQL query is available in [Your Goto Guide for Working with Windows WMI Events and PowerShell](https://adamtheautomator.com/your-goto-guide-for-working-with-windows-wmi-events-and-powershell/)

## Registering The Query

We have the WQL query, let move to the next step and register the query to the WMI events by using the **Register-CimIndicationEvent**

```powershell-console
PS C:\> Register-CimIndicationEvent -Namespace 'ROOT\CIMv2' -Query $query -SourceIdentifier 'WindowsServices' -MessageData 'Service Status Change'
```

To confirm the successful registration, type the following cmdlet *Get-EventSubscriber,* the output looks like the following

```powershell-console
PS C:\> Get-EventSubscriber
```

```powershell
PS C:\> Get-EventSubscriber

SubscriptionId   : 1
SourceObject     : Microsoft.Management.Infrastructure.CimCmdlets.CimIndicationWatcher
EventName        : CimIndicationArrived
SourceIdentifier : **WindowsServices**
Action           :
HandlerDelegate  :
SupportEvent     : False
ForwardEvent     : False
```

And that's all that we need, simple as that.

## Reading the events

Now the event is registered and active.
Next, create an event, and by that, I mean stopping or starting a service.

Try *Windows Update* service (wuauserv), run the following cmdlet to see the status of the bits service.

```powershell-console
PS C:\> Get-Service wuauserv
```

```powershell
PS C:\> Get-Service wuauserv

Status   Name               DisplayName
------   ----               -----------
Running  wuauserv           Windows Update
```

So the service is running, let stop it by typing the following

```powershell-console
PS C:\> Stop-Service wuauserv
```

To see the newly created events, type

```powershell-console
PS C:\> $EventVariable=Get-Event
```

Look at the **MessageData**, it's the same message used in the Register-CimIndicationEvent

```powershell
PS C:\> $EventVariable

ComputerName     :
RunspaceId       : 91c6b6fb-cda9-4b15-983f-d7af1f639358
EventIdentifier  : 1
Sender           : Microsoft.Management.Infrastructure.CimCmdlets.CimIndicationWatcher
SourceEventArgs  : Microsoft.Management.Infrastructure.CimCmdlets.CimIndicationEventExceptionEventArgs
SourceArgs       : {Microsoft.Management.Infrastructure.CimCmdlets.CimIndicationWatcher,
                   Microsoft.Management.Infrastructure.CimCmdlets.CimIndicationEventExceptionEventArgs}
SourceIdentifier : WindowsServices
TimeGenerated    : 30-Jul-21 12:08:06 AM
MessageData      : Service Status Change
```

To find the current state of this event

```powershell-console
PS C:\> $EventVariable.SourceEventArgs.NewEvent.SourceInstance
```

And the output looks like

```powershell
PS C:\> $EventVariable.SourceEventArgs.NewEvent.SourceInstance

ProcessId Name     StartMode State   Status ExitCode
--------- ----     --------- -----   ------ --------
0         wuauserv Manual    Stopped OK     0
```

To see the previous event state

```powershell-console
PS C:\> $EventVariable.SourceEventArgs.NewEvent.PreviousInstance
```

```powershell
PS C:\> $EventVariable.SourceEventArgs.NewEvent.PreviousInstance

ProcessId Name     StartMode State   Status ExitCode
--------- ----     --------- -----   ------ --------
16508     wuauserv Manual    Running OK     0
```

This monitoring remains active as long as PowerShell console is active.
It creates such a temporary job which runs in the background to monitor the services class.
You can also end this process by rebooting the computer.
Hope you learn something new today.
