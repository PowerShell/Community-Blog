---
post_title: How to Use $PSDefaultParameterValues
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, Default Parameter values, parameters
Summary: Using The $PSDefaultParameterValues automatic variable
---

**Q:** When I use cmdlets like `Receive-Job` and `Format-Table`, how do I change default values of the **Keep** and **Wrap** parameters?

**A:** Use the `$PSDefaultValues` automatic variable.

When I first discovered PowerShell's background jobs feature, I would use `Receive-Job` to view job output - only to discover it's no longer there.
And almost too often to count, I pipe objects to `Format-Table` cmdlet only to get truncated output because I forgot to use `-Wrap`.
I'm sure you all have parameters whose default value you would gladly change - at least for your environment.

I'm sure you have seen this (and know how to use **Wrap**), like this:

```powershell-console
PS> # Default output in a narrow terminal window.
PS> Get-Service | Format-Table -Property Name, Status, Description

Name              Status Description
----              ------ -----------
AarSvc_f88db     Running Runtime for activating conversational …
AJRouter         Stopped Routes AllJoyn messages for the local …
ALG              Stopped Provides support for 3rd party protoco…
AppHostSvc       Running Provides administrative services for I…
...
PS > # Versus this using -Wrap
PS > Get-Service | Format-Table -Property Name, Status, Description -Wrap

Name             Status Description
----             ------ -----------
AarSvc_f88db    Running Runtime for activating conversational agent
                        applications
AJRouter        Stopped Routes AllJoyn messages for the local
                        AllJoyn clients. If this service is stopped
                        the AllJoyn clients that do not have their
                        own bundled routers will be unable to run.
ALG             Stopped Provides support for 3rd party protocol
                        plug-ins for Internet Connection Sharing
AppHostSvc      Running Provides administrative services for IIS,
                        for example configuration history and
                        Application Pool account mapping. If this
                        service is stopped, configuration history
                        and locking down files or directories with
                        Application Pool specific Access Control
                        Entries will not work.

```

So, the question is: how to tell PowerShell to always use `-Wrap` when using `Format-Table` or `Format-List`?
It turns out there is a very simple way: use the `$PSDefaultParameters` automatic variable.

## The `$PSDefaultParameters` automatic variable

When PowerShell (and Windows PowerShell) starts, it creates the `$PSDefaultParameters` automatic variable.
The variable has a type: **System.Management.Automation.DefaultParameterDictionary**.
In other words, the variable is a Powershell hash table.
By default, the variable is empty when you start PowerShell.

Each entry in this hash table defines a cmdlet, a parameter and a default value for that parameter.
The hash table key is the name of the cmdlet, followed by a colon (`:`), and then the name of the parameter.
The hash table value for this key is the new default value for the parameter.

If you wanted, for example, to always use **-Wrap** for the `Format-*` cmdlets, you could do this:

```PowerShell
$PSDefaultParameterValues.Add('Format-*:Wrap', $True)
```
## Persist the change in your profile
Any change you make to the `$PSDefaultParameterValues` variable is only applicable for the current session.
And the variable is subject to normal scoping rules - so changing the value in a script does not affect the session as a whole.
That means that if you want these changes to occur every time you start a PowerShell console, then you add the appropriate statements in your profile.

On my development box, I use the following snippet inside my `$PROFILE` script:

```powerShell
$PSDefaultParameterValues.Add('Format-*:AutoSize', $true)
$PSDefaultParameterValues.Add('Format-*:Wrap', $true)
$PSDefaultParameterValues.Add('Receive-Job:Keep', $true)
```

## Summary

The `$PSDefaultParameterValues` automatic variable is a great tool to help you specify specific values for cmdlet parameters.
You can specify one or more cmdlets by using wild cards in the hash table's key.
Remember that the hash table key is the name of the cmdlet(s), a colon, and then the parameter's name.
Also, the hash table value is the new "default" value for that parameter (and for the specified cmdlet(s)).

You can read more about `$PSDefaultParameterValues`, and other preference variables in [about_Preference_Variables](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_preference_variables#psdefaultparametervalues). 
And for more details of parameter default values, see the [about_Parameters_Default_Values help file](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_parameters_default_values).

