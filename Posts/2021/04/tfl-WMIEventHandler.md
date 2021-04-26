****---
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
WMI is an infrastructure of both management data and management operations on Windows-based computers.
You can use PowerShell to retrieve information about your host, such as the BIOS Serial number.
Additionally, you can perform management actions, such as creating an SMB share.

WMI is, in many cases, just another way to do things.
For example, you can use WMI to create an SMB share by using the `Create` method of the `Win32_Share` class.
In most case, you use PowerShell cmdlets, such as the SMB cmdlets, to manage your SMB shares.
The value of WMI is that it can provide you access to more information and features that are not available using cmdlets. 

In writing this article, I assume you have an understanding of WMI.
In specific, I assume you understand WMI namespaces, classes, properties, and methods.
If not, you might like to look at the [WMI Documentation](https://docs.microsoft.com/windows/win32/wmisdk/wmi-start-page)
And for some more details on using WMI and Powershell, look at using PowerShell 7 and WMI, look at [my recently published PowerShell 7 book](https://www.wiley.com/en-gb/PowerShell+7+for+IT+Professionals-p-9781119644705).
In chapter 9, I devote a chapter to WMI and using the CIM cmdlets.
To see just the scripts for that chapter, see my [GitHub repository](https://github.com/doctordns/Wiley20/tree/master/09%20-%20WMI).
The scripts show you the basics of WMI and PowerShell 7.

## WMI Eventing

A cool and very powerful feature of WMI is eventing.
With WMI eventing, you can subscribe to an event, such as the change of an AD group's membership.
If and when that event occurs, you can take some action, such as writing to a log file or sending an email.
WMI event handling is fairly straightforward and very powerful - if you know what classes to use and how to use them!

There are two broad types of eventing within WMI.
With temporary eventing, you use PowerShell inside a PowerShell session to subscribe to the events and process them.
If you close that session, the event subscriptions and event handlers are lost.
To enable temporary WMI event monitoring to continue, you must leave the host turned on and logged in, which may be a suboptimal situation.
Temporary event handling can be great for troubleshooting but not ideal for longer-term monitoring.

With permanent event handling, you also tell WMI what events to do and what to do when they occur.
To do that, you add the details of event handling to the WMI repository.
By doing so, WMI can continue to monitor the event after close your session, logoff, or even reboot your host.
And with PowerShell and PowerShell remoting, it is pretty easy to deploy WMI event detection on multiple servers.

I warn you that the documentation for eventing may not be great in all cases.
Some documentation is focused on developers and thus lacks good PowerShell examples.

## Permanent Event Consumers

Within WMI, a permanent event consumer is a built-in COM component that does something when any given event occurs.
In theory, I suppose you could develop a private WMI event consumer, but I have never seen one developed.
I am not suggesting that someone has not done it, of course.
If you have seen this - please comment as I'd love to see the code and understand the details.

There are five key WMI permanent event consumers which Microsoft provides within Windows:

* **Active Script Consumer**: You use this to run a specific VBS script.
* **Log File Consumer**: This handler writes strings of customisable text to a text file.
* **NT Event Log Consumer**: This consumer writes event details into the Windows Application event log.
* **SMTP Event Consumer**: You use this consumer to send an SMTP email message when an event occurs
* **Command Line Consumer**:  This consumer runs a program with parameters, for example, run PowerShell 7 and specific a script to run.

The Active Script consumer _only_ runs VBS scripts.
Short of redeveloping the COM component, you can not use this consumer with Powershell scripts.
The Log File Consumer is excellent for writing short highly-customised messages to a text file but can take some time and effort to implement.
For most IT Pros, the Command Line consumer is the one to choose.
With this consumer, you get WMI to run a PowerShell script any time an event occurs, such as a change to an AD group.
Let's look at how you use this permanent event consumer to discover changes to the membership of the Enterprise Admins group.

## Creating a permanent event handler

With WMI permanent event handling, you need to create three objects within the CIM database

* Event filter - the filter tells WMI which event to detect, such as a change in the change to an AD group.
* Event consumer - this tells WMI which permanent event consumer to run and how to invoke the consumer, such as to run the Command Line consumer and run ``Monitor.ps1``.
* Event binding - this binds the filter (what event to look out for) to the consumer (what to do when the event occurs happens)

To carry out these three operations, you inserting new objects into three specific WMI system classes.
The WMI system class instances enable WMI to continue to process events after you stop your PowerShell session, log off, or restart your host.

In the code below, you use the Command Line consumer to detect changes to the AD's Enterprise Admins group.
Every time the change event occurs, you want WMI to run a specific script, namely ``Monitor.ps1``.
This script displays a list of the current members of the Enterprise Admins group to a log file and reports whether the membership now contains unauthorised users.
If the script finds that an unauthorised user is now a group member, it writes details to a text file for you to review later.

## The Code

Here is a PowerShell code snippet that demonstrates how to set up and test a permanent event handler:

```powershell

# 1. Create a list of valid users for the Enterprise Admins group
$OKUsersFile = 'C:\Foo\OKUsers.Txt'
$OKUsers  =  @'
Administrator
JerryG
'@
$OKUsers | 
  Out-File -FilePath $OKUsersFile

# 2. Define two helper functions to get/remove permanent events
Function Get-WMIPE {
  '*** Event Filters Defined ***'
  Get-CimInstance -Namespace root\subscription -ClassName __EventFilter  |
    Where-Object Name -eq "EventFilter1" |
     Format-Table Name, Query
  '***Consumer Defined ***'
  $NS = 'ROOT\subscription'
  $CN = 'CommandLineEventConsumer'
  Get-CimInstance -Namespace $ns -Classname  $CN |
    Where-Object {$_.name -eq "EventConsumer1"}  |
     Format-Table Name, CommandLineTemplate
  '***Bindings Defined ***'
  Get-CimInstance -Namespace root\subscription -ClassName __FilterToConsumerBinding |
    Where-Object -FilterScript {$_.Filter.Name -eq "EventFilter1"} |
      Format-Table Filter, Consumer
}
Function Remove-WMIPE {
  Get-CimInstance -Namespace root\subscription __EventFilter | 
    Where-Object Name -eq "EventFilter1" |
      Remove-CimInstance
  Get-CimInstance -Namespace root\subscription CommandLineEventConsumer | 
    Where-Object Name -eq 'EventConsumer1' |
      Remove-CimInstance
  Get-CimInstance -Namespace root\subscription __FilterToConsumerBinding  |
    Where-Object -FilterScript {$_.Filter.Name -eq 'EventFilter1'}   |
      Remove-CimInstance
}

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
  Name           =  "EventFilter1"
  EventNameSpace =  "root/directory/LDAP"
}
$IHT = @{
  ClassName = '__EventFilter'
  Namespace = 'root/subscription'
  Property  = $Param
}        
$InstanceFilter = New-CimInstance @IHT

# 5. Create Monitor.ps1
$MONITOR = @'
$LogFile   = 'C:\Foo\Grouplog.Txt'
$Group     = 'Enterprise Admins'
"On:  [$(Get-Date)]  Group [$Group] was changed" | 
  Out-File -Force $LogFile -Append -Encoding Ascii
$ADGM = Get-ADGroupMember -Identity $Group
# Display who's in the group
"Group Membership"
$ADGM | Format-Table Name, DistinguishedName |
  Out-File -Force $LogFile -Append  -Encoding Ascii
$OKUsers = Get-Content -Path C:\Foo\OKUsers.txt
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
$MONITOR | Out-File -Path C:\Foo\Monitor.ps1

# 6. Create a WMI event consumer
#    The consumer runs PowerShell 7 to execute C:\Foo\Monitor.ps1
$CLT = 'Pwsh.exe -File C:\Foo\Monitor.ps1'
$Param =[ordered] @{
  Name                = 'EventConsumer1'
  CommandLineTemplate = $CLT
}
$ECHT = @{
  Namespace = 'root/subscription'
  ClassName = "CommandLineEventConsumer"
  Property  = $param
}        
$InstanceConsumer = New-CimInstance @ECHT

# 7. Bind the filter and consumer
$Param = @{
  Filter   = [ref]$InstanceFilter     
  Consumer = [ref]$InstanceConsumer
}
$IBHT = @{
  Namespace = 'root/subscription'
  ClassName = '__FilterToConsumerBinding'
  Property  = $Param
}
$InstanceBinding = New-CimInstance   @IBHT

# 8. View the event registration details
Get-WMIPE  

# 9. Adding a user to the Enterprise Admins group
Add-ADGroupMember -Identity 'Enterprise admins' -Members Malcolm

# 10. Viewing Grouplog.txt file
Get-Content -Path C:\Foo\Grouplog.txt

# 11. Tidying up
Remove-WMIPE    # invoke this function you defined above
$RGMHT = @{
  Identity = 'Enterprise admins'
  Member   = 'Malcolm'
  Confirm  = $false
}
Remove-ADGroupMember @RGMHT
Get-WMIPE       # ensure you have removed the event handling
```

## How Does This Work?

That is a considerable amount of code in this snippet, so let's break it down.

In step 1, you create a file of authorised members of the Enterprise Admins AD group.
The file is a set of SAM Account names of authorised members, one per line.
This example assumes you have two AD users (JerryG and Malcolm) and that JerryG is currently a member of the Enterprise Admins group.

In step 2, you see two helper functions.
The `Get-WMIPE` function displays the details of this specific permanent event handling configuration by displaying the instances within the three related WMI event handling classes.
The `Remove-WMIPE` function removes the relevant WMI **class occurrences which effectively removes the event handling configuration.
If you plan to test WMI permanent eventing, you should create an easy way to see the filter details in place and an easy way to remove the filter when you are finished with your testing.
These two functions are not needed, but they can be helpful as you develop event handling scripts.

In step 3, you create a WQL event query.
This query tells WMI to look for any change to the AD group named Enterprise Admins.

In step 4, you create a permanent event filter.
You do this by adding an occurrence to the ``__EventFilter`` class ``ROOT/subscription' namespace. 
The occurrence provides WMI with the details of the event query you created in step 3.

When the event occurs, you want WMI to run a script to handle the change to the AD group.
In step 5, you create a PowerShell script called ``Monitor.ps1``.
This script first gets the current membership of the Enterprise Admins group and displays it to the log file.
Next, the script retrieves the file of authorised members to the group, checks to see if any current member is unauthorised and reports the fact.

In production, you could no doubt make many improvements to this script to reflect your organisation.
But this sample should give you a place from which you can start.

In step 6, you define a WMI event consumer.
This event consumer definition tells WMI to invoke the Command Line Event Consumer to invoke PowerShell 7 and run the Monitor.ps1 script.
Note that this step does not specify which query you wish to respond to, only what you want WMI to do eventually.

In step 7, you bind the event filter to the event consumer.
In effect, this step tells WMI both to look for a particular event and run a specific event consumer when the event occurs.
To achieve this, you create an instance in the ``__FilterToConsumerBinding`` class in the ``ROOT/subscription`` namespace.
This class tells WMI which events to filter and what to do when they occur.

In step 8, as a sanity check, you run ``Get-WMIPE`` to review the three new instances you just created.
As soon as you have created these instances, WMI begins to monitor changes in the AD group.
And when a change occurs, WMI runs the permanent event consumer and, therefore, your script.
And remember: WMI continues to monitor the group and run the script until you remove the binding details (at a minimum)!

You should see something like this:

```powershell-console
PS C:\Foo> # 8. Viewing the event registration details
PS C:\Foo> Get-WMIPE  
*** Event Filters Defined ***

Name         Query
----         -----
EventFilter1   SELECT * From __InstanceModificationEvent Within 10
                WHERE TargetInstance ISA 'ds_group' AND
                      TargetInstance.ds_name = 'Enterprise Admins'

***Consumer Defined ***

Name           CommandLineTemplate
----           -------------------
EventConsumer1 Pwsh.exe -File C:\Foo\Monitor.ps1

***Bindings Defined ***

Filter                                Consumer
------                                --------
__EventFilter (Name = "EventFilter1") CommandLineEventConsumer (Name = "EventConsumer1")

```

## Testing your event handler

With the permanent event handler now installed into WMI, you need to test it.
A simple way to do that is to change the AD group and observe the results.

In step 9, you add a user, Malcolm, to the Enterprise admins group.
This step generates no output.

Next, in step 10, you take a look at the log file, with output like this:

```powershell-console
PS C:\Foo> # 10. Viewing the Grouplog.txt file
PS C:\Foo> Get-Content -Path C:\Foo\Grouplog.txt
On:  [04/20/2021 15:41:49]  Group [Enterprise Admins] was changed

Name          DistinguishedName
----          -----------------
Malcolm       CN=Malcolm,OU=IT,DC=Reskit,DC=Org
Jerry Garcia  CN=Jerry Garcia,OU=IT,DC=Reskit,DC=Org
Administrator CN=Administrator,CN=Users,DC=Reskit,DC=Org

Unauthorized user [Malcolm] added to Enterprise Admins
**********************************
```

## Cleaning up

Unless you intend to continue monitoring the Enterprise Admins group, it is a good idea to tidy up. 
In the final step, you remove the WMI filter details and remove Malcolm from the Enterprise admins group.

## Summary

WMI eventing is very powerful and straightforward to implement.
There are thousands of WMI events you could subscribe to and which may help troubleshooting activities.
In this case, you are examining unauthorised changers to an AD group.
The WMI documentation does not provide a definitive guide to the events you might be interested in - at least that I can find.
