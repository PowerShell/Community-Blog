---
post_title: How to Make Use Of PowerShell Profile Files
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, profile
Summary: Using Profile files with PowerShell 7
---

**Q:** I would like to personalize the way that PowerShell works. 
I have heard that I can use a thing called a profile to do this, but when I try to find information about profiles, I come up blank. There is no `New-Profile` cmdlet, so I do not see how to create such a thing. Can you help me, please?

**A:** Profiles are a powerful part of PowerShell and allow you to customize PowerShell for your environment.
They are easy to create and support a range of deployment scenarios.

## What is a Profile?

Before explaining the profile, let's first examine the PowerShell host.
A PowerShell host is a program that hosts PowerShell to allow you to use it.
Common PowerShell hosts include the Windows PowerShell console, the Windows PowerShell ISE, the PowerShell 7 console, and VS Code.
Each host supports the use of profile files.

A profile is a PowerShell script file that a PowerShell host loads and executes automatically every time you start that PowerShell host.
The script is, in effect, dot-sourced, so any variables, functions, and the like that you define in a profile script remain available in the PowerShell session, which is incredibly handy.
I use profiles to create PowerShell drives, various useful variables, and a few useful (for me!) functions.

Each PowerShell host has 4 separate profile files as follows:

* This host, this user
* This host, all users
* All hosts, this user
* All hosts, all users

Why so many, you might ask.
Because having these four profile files allows you numerous deployment opportunities.
You could, for example, have one profile that defines corporate aliases or standard PS drives for every PowerShell host and user on a machine.
You could have 'this host' profiles that define host-specific customizations that could differ depending on the PowerShell host.
For example, in my profile file for VS code, I use `Set-PSReadLineOption` to set token colours depending on which color theme I am using.
Like so many things in PowerShell, the PowerShell team engineered profiles for every scenario you might come across in deploying PowerShell and PowerShell hosts.

In practice, the "this host, this user" profile is the one you most commonly use, but having all four allows considerable deployment flexibility.
You have options!

## Where do I find them?

Another frequently asked question is: where are these files and how are they named?
It turns out, like many things PowerShell, you can find the answer to the question inside PowerShell itself.
In this case, inside a PowerShell automatic variable, `$PROFILE`.

Automatic variables in PowerShell, are variables created by PowerShell itself and are available for use.
These variables are created by PowerShell when you start the host.
For more details on automatic variables see the [automatic variable help text](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_automatic_variables).

## The `$PROFILE` variable

The `$PROFILE` variable is an automatic variable that PowerShell creates within each session during startup.
This variable has both a **ToString()** method and four additional note properties that tell you where _this_ host finds its profile files.

To determine the location and fill script name for the four PowerShell scripts, you can do something like this:

```powershell-console
PS> # what host?   
PS> $host.Name
ConsoleHost
PS> # Where are the profiles?
PS> $PROFILE | Get-Member -MemberType NoteProperty 
   TypeName: System.String
Name                   MemberType   Definition
----                   ----------   ----------
AllUsersAllHosts       NoteProperty string AllUsersAllHosts=C:\\Program Files\\PowerShell\\7\\profile.ps1
AllUsersCurrentHost    NoteProperty string AllUsersCurrentHost=C:\\Program Files\\PowerShell\\7\\Microsoft.PowerShell_profile.ps1
CurrentUserAllHosts    NoteProperty string CurrentUserAllHosts=C:\\Users\doctordns\\Documents\\PowerShell\\profile.ps1
CurrentUserCurrentHost NoteProperty string CurrentUserCurrentHost=C:\\Users\\doctordns\\Documents\\PowerShell\\Microsoft.PowerShell_profile.ps1

PS> # What does the $PROFILE variable itself contain?
PS> $PROFILE
C:\\Users\\doctordns\\Documents\\PowerShell\\Microsoft.PowerShell_profile.ps1
```

This example is from a Windows 10 client running PowerShell 7 inside VS Code.
In the example, you can see that the `$PROFILE` variable contains four note properties that contain the location of each profile
Also, you can see that the `$PROFILE` variable's value is the name of the **CurrentUserCurrentHost** profile.
For simplicity you can run `Notepad $Profile` to bring up the profile file inside Notepad (or use VS Code!)

## What can you do in a profile script?

You can pretty much do anything you want in profile file to create the environment that works best for you.
I find the profile useful for creating variables and short aliases, PS Drives, and more as you can see below.
As an example of what you can do in a profile, and to get you started, I have published two sample profile files to GitHub:

* A [profile for the PowerShell 7 console](https://github.com/doctordns/PACKT-PS7/blob/master/scripts/goodies/Microsoft.PowerShell_Profile.ps1)
* A [profile for VSCode](https://github.com/doctordns/PACKT-PS7/blob/master/scripts/goodies/Microsoft.VSCode_profile.ps1)

These samples do a lot of useful things, including:

* Over-ride some default parameter values
* Update the Format enumeration limit
* Set the 'home' directory to a non-standard location
* Create personal aliases
* Create a PowerShell credential object

These are all things that make the environment customized to your liking.
I use some personal aliases as alternatives to standard aliases - if only to save typing.
Creating personal variables or updating automatic variables can be useful.

While creating a credential object can be useful, it is arguable whether it is a good thing.
In this case, the credential is for a set of VMs I used in my [most recent PowerShell book](https://smile.amazon.co.uk/Windows-Server-Automation-PowerShell-Cookbook-ebook/dp/B0977JDL7K/ref=sr_1_1?dchild=1&keywords=Windows+Server+Automation+with+PowerShell+Cookbook+-+Fourth+Edition&qid=1624277697&s=books&sr=1-1) to illustrate using PowerShell in an Enterprise.
As they are all local VMs and are only for testing, creating a much used credential object is useful. 

## Be Careful

It is easy to get carried away with profile files.
At one point in the PowerShell 3.0 days, my profile file was over 700 lines long.
I'd just chucked all these cool things I'd found on the Internet (and never used them again)
As a result, starting PowerShell or the ISE took some time.
It is so easy to see some cool bits of code and then add it to your profile.
I suggest you look carefully at each profile on a regular basis and trim it when possible.

## Summary

Profile are PowerShell scripts you can use to customize your PowerShell environment.
There are 4 profile files for each host as you can see by examining the `$Profile` automatic variable.

## Tip of the Hat

I based this article on one written for the earlier Scripting Guys blog [How Can I Use Profiles With Windows PowerShell](https://devblogs.microsoft.com/scripting/hey-scripting-guy-how-can-i-use-profiles-with-windows-powershell/).
It was written by Ed Wilson.
