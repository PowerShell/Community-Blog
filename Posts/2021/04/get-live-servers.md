---
post_title: Testing the connection to computers in the Active Directory
username: tfl@psp.co.uk
Catagories: PowerShell
tags: Active Directory, networking
Summary: How can I get AD computers check to see they are online?
---

**Q:** As an administrator, I often have to do a lot of reporting on the servers in my domain.
Is there a simple way to test the connection to every server in my domain or every server or client host in a specific OU?

**A:**  Of course you can do this with PowerShell! You can use the Active Directory cmdlets and `Test-Connection`, although it is not as simple as one might like.

## Using the `ActiveDirectory` module

Microsoft has developed several modules to help you deploy and manage AD in your organisation or via Azure.
The `ActiveDirectory` module is one which Microsoft ships with Windows Server (although not installed by default).
You can also load the Remote Server Administration (RSAT) module for AD on a Windows 10 host.
The RSAT module allows you to manage the AD using PowerShell from a remote machine.
For more details on the `ActiveDirectory` module, see the [ActiveDirectory](https://docs.microsoft.com/powershell/module/addsadministration/) module documentation.

Use the `Get-ADComputer` account to return details about some or all computers within the AD.
There are several ways to use `Get-ADComputer` to get just the computer accounts you want with any property you need.
These include using the **Identity** and **Filter** parameters.  
Every computer account returned by `Get-ADComputer` contains two important properties: **Name** and **DNSHostName**.
The **Name** property is the single-label name of the computer (aka the NetBIOS name).
The **DNSHostName** property is the fully qualified DNS name for the computer.
Like this:

```powershell-console
PS> Get-ADComputer -Filter * | Format-Table -Property Name, DNSHostName

Name         DNSHostName
----         -----------
COOKHAM1     Cookham1.cookham.net
win10lt      Win10LT.cookham.net
cookham24    cookham24.cookham.net
SLTPC        sltpc.cookham.net
COOKHAM4LTDC Cookham4LTDC.cookham.net
```

So you might be tempted to think it simple to test connections to each computer.
You pipe the output of `Get-ADComputer` to `Test-Connection`, and it just works.
Sadly, it's not quite so simple.

If you try this, here is what you would see:

```powershell-console
PS> Get-ADComputer -Filter * | Test-Connection
Test-Connection: Cannot validate argument on parameter 'TargetName'. The argument is null, empty, or an element of the argument collection contains a null value. Supply a collection that does not contain any null values and then try the command again.
Test-Connection: Cannot validate argument on parameter 'TargetName'. The argument is null, empty, or an element of the argument collection contains a null value. Supply a collection that does not contain any null values and then try the command again.
Test-Connection: Cannot validate argument on parameter 'TargetName'. The argument is null, empty, or an element of the argument collection contains a null value. Supply a collection that does not contain any null values and then try the command again.
Test-Connection: Cannot validate argument on parameter 'TargetName'. The argument is null, empty, or an element of the argument collection contains a null value. Supply a collection that does not contain any null values and then try the command again.
Test-Connection: Cannot validate argument on parameter 'TargetName'. The argument is null, empty, or an element of the argument collection contains a null value. Supply a collection that does not contain any null values and then try the command again.
```

What is going on here?

## Property/Parameter misalignment

What we have here is a classic, albeit relatively uncommon, situation.
The `Test-Connection` cmdlet uses the parameter name **Target** to indicate the computer to which you are testing a connection.
However, in this pipelined command, the objects produced by `Get-ADComputer` do not contain properties of that name.
Instead, these objects have properties named **Name** and **DNSHostName**.

[alert type="note" heading="Note"]With Windows PowerShell, you used the parameter **ComputerName** to indicate the computer you are investigating.
With PowerShell 7, the developers have changed this parameter name to **TargetName**.
For best compatibility, the cmdlet defines the**`ComputerName** alias to this parameter.
This cmdlet lets you use either **TargetName** or **Computername** with `Test-Connection`.[/alert]

## ForEach-Object to the rescue

It is pretty easy to get around this parameter/property alignment challenge.
You use the `Foreach-Object` cmdlet, like this:

```powershell-console
PS> Get-ADComputer -Filter * | 
             ForEach-Object {"$_";Test-Connection -TargetName $_.Name;""}

CN=COOKHAM1,OU=Domain Controllers,DC=cookham,DC=net
   Destination: COOKHAM1
Ping Source      Address      Latency BufferSize Status
                                 (ms)        (B)
---- ------      -------      ------- ---------- ------
   1 cookham24   10.10.10.9         0         32 Success
   2 cookham24   10.10.10.9         0         32 Success
   3 cookham24   10.10.10.9         0         32 Success
   4 cookham24   10.10.10.9         0         32 Success

CN=win10lt,OU=CookhamHQ,DC=cookham,DC=net
   Destination: win10lt
Ping Source      Address          Latency BufferSize Status
                                     (ms)        (B)
---- ------      -------          ------- ---------- ------
   1 cookham24   *                      0         32 DestinationHost…
   2 cookham24   *                      0         32 DestinationHost…
   3 cookham24   *                      0         32 DestinationHost…
   4 cookham24   *                      0         32 DestinationHost…

CN=SLTPC,CN=Computers,DC=cookham,DC=net
   Destination: SLTPC
Ping Source      Address                   Latency BufferSize Status
                                              (ms)        (B)
|---- ------      -------                   ------- ---------- ------
   1 cookham24   2a02:8010:6386:0:f810:2b…       1         32 Success
   2 cookham24   2a02:8010:6386:0:f810:2b…       0         32 Success
   3 cookham24   2a02:8010:6386:0:f810:2b…       0         32 Success
   4 cookham24   2a02:8010:6386:0:f810:2b…       3         32 Success
etc
```

## Using the Extensible Type System

If you plan to do a lot of this sort of work, there is a more straightforward way to get around this property/parameter alignment issue.
You can use the Extensible Type System (ETS) to extend any AD Computer object to contain an alias to the `Name` or `DNSHostName` property.
You define this extension via a small XML file which you then import, like this:

```powershell-console
PS> Get-Content '.\aaatypes.types.ps1xml'
<Types>
 <Type>
    <Name>Microsoft.ActiveDirectory.Management.ADComputer</Name>
    <Members>
       <AliasProperty>
          <Name>TargetName</Name>
          <ReferencedMemberName>DNSHostName</ReferencedMemberName>
         </AliasProperty>
    </Members>
  </Type>

</Types>

PS> Update-TypeData -PrependPath .\aaatypes.types.ps1xml
PS> Get-ADComputer -Identity Cookham1 | Test-Connection

   Destination: Cookham1.cookham.net

Ping Source           Address                   Latency BufferSize Status
                                                   (ms)        (B)
---- ------           -------                   ------- ---------- ------
   1 cookham24        10.10.10.9                      0         32 Success
   2 cookham24        10.10.10.9                      0         32 Success
   3 cookham24        10.10.10.9                      0         32 Success
   4 cookham24        10.10.10.9                      0         32 Success
```

You can persist this ETS extension by adding the `Update-TypeData` to your PowerShell profile.
That way, every time you start a PowerShell session, that ETS extension is in place and ready to assist you.

For details of and background to the ETS, see the [Extended Type System Overview](https://docs.microsoft.com/powershell/scripting/developer/ets/overview).

## Summary

The `Get-ADComputer` cmdlet produces objects whose properties the object developers have not aligned, pipeline wise, with `Test-Connection`.
There is a simple way around that, using `For-EachObject`, although it takes a bit more typing.
You can also use the ETS to extend the **ADComputer** object to have a more friendly alias.

## Tip of the Hat

This article was based on a request in this blog's issue queue
See the post [Request - How to get all the alive servers in the domain?](https://github.com/PowerShell/Community-Blog/issues/21)
