---
post_title: How Do I Discover Changes to an AD Group's Membership
username: tfl@psp.co.uk
Catagories: PowerShell
tags: AD, WMI, WMI Eventing
Summary: How to create a permanent event handler to detect changes in an AD Group
---

**Q:** Is there an easy way to detect and changes to important the membership of AD Groups?

**A:**  Easy using PowerShell 7, WMI, and the CIM Cmdlets.

## WMI

Windows Management Instrumentation (WMI) is an important component of the Windows operating system.
WMI is an infrastructure of both management data and management operations on Windows-based
computers. You can use PowerShell to retrieve information about your host, such as the BIOS Serial
number. Additionally, you can perform management actions, such as creating an SMB share.

WMI is, in many cases, just another way to do things. For example, you can use WMI to create an SMB
share by using the `Create` method of the **Win32_Share** class. For more information, see the
documentation for the
[Win32_Share class](https://docs.microsoft.com/windows/win32/cimwin32prov/win32-share). In most
cases, you use PowerShell cmdlets, such as the SMB cmdlets, to manage your SMB shares. The value of
WMI is that it can provide you access to more information and features that are not available using
cmdlets.

In writing this article, I assume you have an understanding of WMI. In specific, I assume you
understand WMI namespaces, classes, properties, and methods. If not, you might like to look at the
[WMI Documentation](https://docs.microsoft.com/windows/win32/wmisdk/wmi-start-page).

## WMI Eventing

A cool and very powerful feature of WMI is eventing. With WMI eventing, you can subscribe to an
event, such as the change of an AD group's membership. If and when that event occurs, you can take
some action, such as writing to a log file or sending an email. WMI event handling is fairly
straightforward and very powerful - if you know what classes to use and how to use them!

There are two broad types of eventing within WMI. With temporary eventing, you use PowerShell inside
a PowerShell session to subscribe to the events and process them. If you close that session, the
event subscriptions and event handlers are lost. To enable temporary WMI event monitoring to
continue, you must leave the host turned on and logged in, which may be a suboptimal situation.
Temporary event handling can be great for troubleshooting but not ideal for longer-term monitoring.

With permanent event handling, you also tell WMI what events to do and what to do when they occur.
To do that, you add the details of event handling to the WMI repository. By doing so, WMI can
continue to monitor the event after close your session, logoff, or even reboot your host. And with
PowerShell and PowerShell remoting, it is pretty easy to deploy WMI event detection on multiple
servers.

I warn you that the documentation for eventing may not be great in all cases. Some documentation is
focused on developers and thus lacks good PowerShell examples.

## Permanent Event Consumers

Within WMI, a permanent event consumer is a built-in COM component that does something when any
given event occurs. In theory, I suppose you could develop a private WMI event consumer, but I have
never seen one developed. I am not suggesting that someone has not done it, of course. If you have
seen this - please comment as I'd love to see the code and understand the details.

There are five key WMI permanent event consumers which Microsoft provides within Windows:

- **Active Script Consumer**: You use this to run a specific VBS script.
- **Log File Consumer**: This handler writes strings of customizable text to a text file.
- **NT Event Log Consumer**: This consumer writes event details into the Windows Application event
  log.
- **SMTP Event Consumer**: You use this consumer to send an SMTP email message when an event occurs
- **Command Line Consumer**: This consumer runs a program with parameters, for example, run
  PowerShell 7 and specific a script to run.

The Active Script consumer _only_ runs VBS scripts. Short of redeveloping the COM component, you can
not use this consumer with PowerShell scripts. The Log File Consumer is excellent for writing short
highly-customised messages to a text file but can take some time and effort to implement. For most
IT Pros, the Command Line consumer is the one to choose. With this consumer, you get WMI to run a
PowerShell script any time an event occurs, such as a change to an AD group. Let's look at how you
use this permanent event consumer to discover changes to the membership of the Enterprise Admins
group.

## Creating a permanent event handler

With WMI permanent event handling, you need to create three objects within the CIM database

- Event filter - the filter tells WMI which event to detect, such as a change in the change to an AD
  group.
- Event consumer - this tells WMI which permanent event consumer to run and how to invoke the
  consumer, such as to run the Command Line consumer and run `Monitor.ps1`.
- Event binding - this binds the filter (what event to look out for) to the consumer (what to do
  when the event occurs happens)

To carry out these three operations, you inserting new objects into three specific WMI system
classes. The WMI system class instances enable WMI to continue to process events after you stop your
PowerShell session, log off, or restart your host.

In the code below, you use the Command Line consumer to detect changes to the AD's Enterprise Admins
group. Every time the change event occurs, you want WMI to run a specific script, namely
`Monitor.ps1`. This script displays a list of the current members of the **Enterprise Admins** group
to a log file and reports whether the membership now contains unauthorized users. If the script
finds that an unauthorized user is now a group member, it writes details to a text file for you to
review later.

## The Solution

There are several steps in this solution.
So please, fasten your seat belts, and away we go.

### Setting up

In this post, you want to detect whether an unauthorized user is a member of the Enterprise Admins
group. You must first create a file of authorized users. Then you create two helper functions to
assist you in testing the code. The function to delete all aspects of the WMI event filter from your
host is useful unless you plan to keep the filter running forever.

```powershell
# 1. Create a list of valid users for the Enterprise Admins group
$OKUsersFile = 'C:\\Foo\\OKUsers.Txt'
$OKUsers  =  @'
Administrator
JerryG
'@
$OKUsers |
  Out-File -FilePath $OKUsersFile

# 2. Define two helper functions to get/remove permanent events
Function Get-WMIPE {
  '*** Event Filters Defined ***'
  Get-CimInstance -Namespace ROOT\\subscription -ClassName __EventFilter  |
    Where-Object Name -eq "EventFilter1" |
     Format-Table Name, Query
  '***Consumer Defined ***'
  $NS = 'ROOT\\subscription'
  $CN = 'CommandLineEventConsumer'
  Get-CimInstance -Namespace $ns -ClassName  $CN |
    Where-Object {$_.name -eq "EventConsumer1"}  |
     Format-Table Name, CommandLineTemplate
  '***Bindings Defined ***'
  Get-CimInstance -Namespace ROOT\\subscription -ClassName __FilterToConsumerBinding |
    Where-Object -FilterScript {$_.Filter.Name -eq "EventFilter1"} |
      Format-Table Filter, Consumer
}
Function Remove-WMIPE {
  Get-CimInstance -Namespace ROOT\\subscription __EventFilter |
    Where-Object Name -eq "EventFilter1" |
      Remove-CimInstance
  Get-CimInstance -Namespace ROOT\\subscription CommandLineEventConsumer |
    Where-Object Name -eq 'EventConsumer1' |
      Remove-CimInstance
  Get-CimInstance -Namespace ROOT\\subscription __FilterToConsumerBinding  |
    Where-Object -FilterScript {$_.Filter.Name -eq 'EventFilter1'}   |
      Remove-CimInstance
}
```

These two steps produce no output.
When you create the `OkUsers.txt` file - ensure the users in the file are actually in your AD.

### Create a WQL event query and WMI event filter

To tell WMI what event you want WMI to detect, you create a WMI Query Language (WQL) query. In each
WMI namespace, you can find various system classes representing event notification. You can use the
**__InstanceModificationEvent** class, for example, to detect any modification of an instance (in
that namespace). You can likewise use the **__MethodInvocationEvent** class to track WMI method
invocations. If things change anywhere in a Windows host, you can probably use a WMI event to detect
the change.

Here's the code to create the WQL query and the WMI event filter

```powershell
# 3. Create a WQL event filter query
$Group = 'Enterprise Admins'
$Query = @"
  SELECT * From __InstanceModificationEvent Within 10
   WHERE TargetInstance ISA 'ds_group' AND
         TargetInstance.ds_name = '$Group'
"@

# 4. Create the event filter
$Param = @{
  QueryLanguage =  'WQL'
  Query          =  $Query
  Name           =  'EventFilter1'
  EventNameSpace =  'ROOT/directory/LDAP'
}
$IHT = @{
  ClassName = '__EventFilter'
  Namespace = 'ROOT/subscription'
  Property  = $Param
}
$InstanceFilter = New-CimInstance @IHT
```

In this code (which produces no output), the filter query does not state which namespace the query
is looking at, just that there is a target class for WMI to monitor. In the event filter, you create
a new occurrence in the **EventFilter** class in the **ROOT/Subscription** namespace. This
occurrence tells WMI to monitor the **ROOT/directory/LDAP** namespace for the **ds_group** class.

### Creating the Event Consumer

The next step is to create an event consumer - what you want WMI to do when it detects the event has
occurred. In our example, you want the WMI permanent event handler COM object to run a script
`Monitor.ps1` any time the event occurs. So whenever WMI detects a change to the Enterprise admins
group, you want WMI to run the script.

```powershell
# 5. Create Monitor.ps1
$MONITOR = @'
$LogFile   = 'C:\\Foo\\Grouplog.Txt'
$Group     = 'Enterprise Admins'
"On:  [$(Get-Date)]  Group [$Group] was changed" |
  Out-File -Force $LogFile -Append -Encoding Ascii
$ADGM = Get-ADGroupMember -Identity $Group
# Display who's in the group
"Group Membership"
$ADGM | Format-Table Name, DistinguishedName |
  Out-File -Force $LogFile -Append  -Encoding Ascii
$OKUsers = Get-Content -Path C:\\Foo\\OKUsers.txt
# Look at who is not authorized
foreach ($User in $ADGM) {
  if ($User.SamAccountName -notin $OKUsers) {
    "Unauthorized user [$($User.SamAccountName)] added to $Group"  |
      Out-File -Force $LogFile -Append  -Encoding Ascii
  }
}
"**********************************`n`n" |
Out-File -Force $LogFile -Append -Encoding Ascii
'@
$MONITOR | Out-File -Path C:\\Foo\\Monitor.ps1

# 6. Create a WMI event consumer
#    The consumer runs PowerShell 7 to execute C:\\Foo\\Monitor.ps1
$CLT = 'Pwsh.exe -File C:\\Foo\\Monitor.ps1'
$Param =[ordered] @{
  Name                = 'EventConsumer1'
  CommandLineTemplate = $CLT
}
$ECHT = @{
  Namespace = 'ROOT/subscription'
  ClassName = "CommandLineEventConsumer"
  Property  = $param
}
$InstanceConsumer = New-CimInstance @ECHT
```

The monitoring script is fairly simple - each time the event occurs, it prints some information to a
log file. Then it looks to see if the Enterprise Admins group contains unauthorized users - and if
so, the script reports that fact to the log file. This script is fairly simple, and you can
embellish. as needed. You could, for example, remove all unauthorized users.

To create a WMI event consumer, you add a new occurrence to the **CommandLineEventConsumer** class
within the namespace **ROOT/Subscription**.

### Binding the Event Filter and the Event Consumer

With the event filter and event consumer details added to WMI, you need to bind the two - telling
WMI to detect THAT event and when it occurs, run THIS script. You could pre-create, for example,
multiple event filters and event consumers. Once the binding is in place, WMI starts the monitoring
process.

```powershell
# 7. Bind the filter and consumer
$Param = @{
  Filter   = [ref]$InstanceFilter
  Consumer = [ref]$InstanceConsumer
}
$IBHT = @{
  Namespace = 'ROOT/subscription'
  ClassName = '__FilterToConsumerBinding'
  Property  = $Param
}
$InstanceBinding = New-CimInstance @IBHT
```

### Checking your work

A great way to check your work is to call the `Get-WMIPE` function you created earlier. What you
should see is:

```powershell-console
PS > # 8. Viewing the event registration details
PS > Get-WMIPE
*** Event Filters Defined ***

Name         Query
----         -----
EventFilter1   SELECT * From __InstanceModificationEvent Within 10
                WHERE TargetInstance ISA 'ds_group' AND
                      TargetInstance.ds_name = 'Enterprise Admins'

***Consumer Defined ***

Name           CommandLineTemplate
----           -------------------
EventConsumer1 Pwsh.exe -File C:\\Foo\\Monitor.ps1

***Bindings Defined ***

Filter                                Consumer
------                                --------
__EventFilter (Name = "EventFilter1") CommandLineEventConsumer (Name = "EventConsumer1")

```

### Testing your work

So having created the event query, the event filter, the event consumer and the filter to consumer
binding, you can test your work. The easiest way to test this is to add a new user to the group.
Then, wait a few seconds for WMI to process the event, then look at the output. If everything is
working correctly, you should see this output:

```powershell-console
PS > # 9. Adding a user to the Enterprise Admins group
PS > Add-ADGroupMember -Identity 'Enterprise admins' -Members Malcolm
PS >
PS > # 10. Viewing the Grouplog.txt file
PS > Get-Content -Path C:\\Foo\\Grouplog.txt
On:  [04/20/2021 15:41:49]  Group [Enterprise Admins] was changed

Name          DistinguishedName
----          -----------------
Malcolm       CN=Malcolm,OU=IT,DC=Reskit,DC=Org
Jerry Garcia  CN=Jerry Garcia,OU=IT,DC=Reskit,DC=Org
Administrator CN=Administrator,CN=Users,DC=Reskit,DC=Org

Unauthorized user [Malcolm] added to Enterprise Admins
**********************************
```

### Troubleshooting

This code, of course should "just work". If not, you need to perform troubleshooting and here are
three things to look for:

- Is the WQL query correct?
- Are the event and subscriptiong classes in the namespace(s) you think it is in?
- Is the `Monitor.ps1` script doing what you actually wanted?

The **Microsoft-Windows-WMI-Activity/Operational** event log can be useful in tracking down issues.
And if you get stuck, feel free to visit the
[Spiceworks PowerShell forum](https://community.spiceworks.com/programming/powershell).

### Tidying up

After you play with a WMI filter like this, make sure you clean up. You probably don't want the
filter to run forever, so remove it as soon as you can. To remove it, invoke the `Remove-WMIPE`
function. And you should probably remove any inappropriate users from the Enterprise Admins group

```powershell
# 11. Tidying up
Remove-WMIPE    # invoke this function you defined above
$RGMHT = @{
  Identity = 'Enterprise Admins'
  Member   = 'Malcolm'
  Confirm  = $false
}
Remove-ADGroupMember @RGMHT
```

This step creates no output. You might wish to call `Get-WMIPE` again to verify you have removed all
three class occurrences.

## Summary

WMI eventing is very powerful and straightforward to implement. There are thousands of WMI events
you could subscribe to and which may help troubleshooting activities. In this case, you are
examining unauthorized changers to an AD group. The WMI documentation does not provide a definitive
guide to the events you might be interested in - at least that I can find.

For some more details on using WMI in PowerShell 7, see my recently published
[PowerShell 7 book](https://www.wiley.com/en-gb/PowerShell+7+for+IT+Professionals-p-9781119644705).
I devote chapter 9 to WMI and using the CIM cmdlets. You can find the scripts from this blog post
and that chapter in my
[GitHub repository](https://github.com/doctordns/Wiley20/tree/master/09%20-%20WMI).
