---
post_title: How can I be notified any time a service goes down?
username: farisnt@gmail.com
Categories: PowerShell
tags: PowerShell, WMI, Events
Summary: Using Powershell to create temporary event monitoring using WMI

---

Q: How can I be notified any time a service goes down?

A: The short quick answer to utilizing WMI and PowerShell 7.

You use PowerShell to create temporary event monitoring using WMI.
Then WMI monitors any service changes and generates an alert once it detects a change.

## Basic Requirement

To achieve this, you need Windows PowerShell 5.1 and above.

This post uses the latest version of PowerShell 7.
So if you are don't yet have PowerShell 7, see the Microsoft documentation on how to [Install PowerShell 7 on Windows](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-core-on-windows).

Also, make sure that PowerShell is running as administrator.

## Finding the Required Class

Before going into details, you need to find the required class to monitor.
To get a list of all available classes, use the following code.

```powershell-console
PS> Get-CimClass -Namespace root\\cimv2

   NameSpace: ROOT/CIMV2

CimClassName                        CimClassMethods      CimClassProperties
------------                        ---------------      ------------------
__SystemClass                       {}                   {}
__thisNAMESPACE                     {}                   {SECURITY_DESCRIPTOR}
__Provider                          {}                   {Name}
__Win32Provider                     {}                   {Name, ClientLoadableCLSID, CLSID, Concurrency…}
__ProviderRegistration              {}                   {provider}
__EventProviderRegistration         {}                   {provider, EventQueryList}
__ObjectProviderRegistration        {}                   {provider, InteractionType, QuerySupportLevels, SupportsBatch…
__ClassProviderRegistration         {}                   {provider, InteractionType, QuerySupportLevels, SupportsBatch…
__InstanceProviderRegistration      {}                   {provider, InteractionType, QuerySupportLevels, SupportsBatch…
__MethodProviderRegistration        {}                   {provider}
__PropertyProviderRegistration      {}                   {provider, SupportsGet, SupportsPut}
__EventConsumerProviderRegistration {}                   {provider, ConsumerClassNames}
```

The returned result represents all the available classes in the namespace.
For this tutorial, the focus is on Windows services, which is represented by **Win32_Service**.

To Enumerate the **Win32_Services** WMI class and get all the available services using PowerShell run the following code.

```powershell-console
PS> Get-CimInstance -Namespace root\\CIMV2 -ClassName win32_service

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

There are three steps you need to follow to create a temporary WMI Event Subscription:

- Create a WMI query language query.
- Register this query.
- Obtain any events generated.

## Creating WMI Query

WMI has many special classes that you can use to detect changes to other WMI classes.
For example, you can use the **CIM_InstModification** class to monitor the targeted class, in this case **Win32_Service**

You have to create a WMI query using [WMI Query Language](https://docs.microsoft.com/windows/win32/wmisdk/wql-sql-for-wmi).

The WQL syntex structure looks like this:

```
Select * from <WMI System Class> within <Number of Seconds> where TargetInstance ISA <WMI Class name>
```

Let apply the same to **Win32_Serivce**. Start by creating a PowerShell variable, in our case, you construct the query as follows:

```powershell-console
$query = "Select * from CIM_InstModification within 10 where TargetInstance ISA 'Win32_Service'"
```

A full explanation for the WQL query is available in [Your Goto Guide for Working with Windows WMI Events and PowerShell](https://adamtheautomator.com/your-goto-guide-for-working-with-windows-wmi-events-and-powershell/).

## Registering The Query

We have the WQL query, let's move to the next and register the query to the WMI events by using the [Register-CimIndicationEvent](https://docs.microsoft.com/powershell/module/cimcmdlets/register-cimindicationevent).
The `Register-CimIndicationEvent` is used to subscribe to events generated from the system.
And in our case, it subscribes to events generated from the `$query`.

```powershell-console
Register-CimIndicationEvent -Namespace 'ROOT\\CIMv2' -Query $query -SourceIdentifier 'WindowsServices' -MessageData 'Service Status Change'
```

To confirm the successful registration, type the following cmdlet `Get-EventSubscriber`, the output looks like the following

```powershell-console
PS> Get-EventSubscriber

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
PS> Get-Service wuauserv

Status   Name               DisplayName
------   ----               -----------
Running  wuauserv           Windows Update
```

So the service is running, let stop it by typing the following

```powershell
PS> Stop-Service wuauserv
```

To see the newly created events, type `Get-Event`
Look at the **MessageData**, it's the same message used in the `Register-CimIndicationEvent`.

```powershell-console
PS> $EventVariable=Get-Event
PS> $EventVariable

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
PS> $EventVariable.SourceEventArgs.NewEvent.PreviousInstance

ProcessId Name     StartMode State   Status ExitCode
--------- ----     --------- -----   ------ --------
16508     wuauserv Manual    Running OK     0
```

This WMI monitoring remains active as long as the PowerShell console.
It creates such a temporary job which runs in the background to monitor the services class.
You can also end this process by rebooting the computer.
Hope you learned something new today.
