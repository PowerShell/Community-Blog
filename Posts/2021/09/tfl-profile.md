---
post_title: How to Make Use Of PowerShell Profile Files
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, profile
Summary: Using Profile files with PowerShell 7
---

**Q:** would like to personalize the way that PowerShell works. 
I have been hearing that I can use a thing called a profile to do this, but when I try to find information about profiles, I come up blank. There is no ``New-Profile`` cmdlet, so I do not see how to create such a thing. Can you help me please?

**A:** Profile files are a powerful part of PowerShell and allow you to customize PowerShell for your environment.
They are easy to create and support a range a deployment scenairos.

## What is a Profile File?

Before explaining the profile file, lets first examine the PowerShell host
A PowerShell host is a program that hosts PowerShell to allow you to use it.
Common PowerShell hosts include thw Windows PowerShell console, the Windows PowerShell ISE, the PowerShell 7 console, and VS Code.
Each host support the use of profile files.

A profile file is a PowerShell script that your PowerSHell hosts load and execuates automatically every time you start that PowerShell host.
The script is, in effect, dot-sourced, so any variables, functions, etc that you define in a profile file remain available in the PowerShell session.
This is incredibly handy.
I use profiles to create PowerShell drives, a variety of variables, as well as a few useful (for me!) functions. 

Each PowerShell host has 4 seperate profile files as folllows:
* This host, this user
* This host, all users
* All hosts, this user
* All hosts, all users

Why so many, you might ask.
Basically, these four profile files for each host allow you numerous deployment opportunitied.
You could, for example, have ine profile file for every PowerShell host on a machine for all users that defined corporate aliases or PS drives.
You could have 'this host' profiles that define host specific customisations; ones that might differ depending on the host.
Like so many things in PowerShell, profiles are engineered for every scenairo you might come across in deploying PowerShell and PowerShell hosts.

In practice, the "this host, this user" profile is the one you most commonly use, but having all four allows considerable deployment flexibility.
You have options!

## The **$Profile** variable

Another frequently asked qauestion is: where are these files and how are they named?
It turns out, like many things PowerShell, you can find the answer to the question inside PowerShell itself.
In this case, inside a PowerShell automatic variable, **$Profile**. 
Automatic variables, in PowerShell, are variables created by PowerShell itself and are available for use.
For more details on automatic variablds see the [automatic variable help text](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_automatic_variables).

To determine the location and fill script name for the four PowerShell scripts, you can do something like this:

```powershell-console
PS C:\Foo> # what host?   
PS C:\Foo> $host.Name
ConsoleHost
PS C:\Foo> # Where are the profiles?
PS C:\Foo> $Profile | Get-Member -MemberType NoteProperty 
C:\Users\tfl.COOKHAM\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

   TypeName: System.String

Name                   MemberType   Definition
----                   ----------   ----------
AllUsersAllHosts       NoteProperty string AllUsersAllHosts=C:\Program Files\PowerShell\7\profile.ps1
AllUsersCurrentHost    NoteProperty string AllUsersCurrentHost=C:\Program Files\PowerShell\7\Microsoft.PowerShell_profile.ps1
CurrentUserAllHosts    NoteProperty string CurrentUserAllHosts=C:\Users\tfl.COOKHAM\Documents\PowerShell\profile.ps1
CurrentUserCurrentHost NoteProperty string CurrentUserCurrentHost=C:\Users\tfl.COOKHAM\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

PS C:\Foo> # What does $profile variable itself contain?
C:\Foo> $profile
```

This example is from a Windows 10 client, running PowerShell 7 inside VS Code. 
In the example, you can see that the **$Profile** variable contains four note properties that contain the location of each 
Also, you can see that **$Profile** variable's value is the name of the 'Current User-Current Host' profile file.
For simplicity you can run ``Notepad $Profile`` to bring up the profile file inside Notepad (or use VS Code!)

## What can you do in a profile file?
You can pretty much do anything you want in profile file to create the environment that works best for you.
As an example, I have published two sample profile files to GitHub:
* A [profile for the PowerShell 7 console](https://github.com/doctordns/PACKT-PS7/blob/master/scripts/goodies/Microsoft.PowerShell_Profile.ps1)
* A [profile for VSCode](https://github.com/doctordns/PACKT-PS7/blob/master/scripts/goodies/Microsoft.VSCode_profile.ps1)

These samples do a lot of useful things including:
* Over-riding some default parameter values
* Updating the Format enumeration limit 
* Setting the 'home' directory to a non-standard location
* Creating personal aliases
* Creating a PowerShell credential object

These are all things that make the environment customized to your liking.
I use some personal aliases as alternatives to standard aliass - if only to save typing.
Creating personal variables or updating automatic variables can be useful.
While creating a credcential object can be useful, It is arguable whether it is a good thing.
In this case, the credential is for a set of VMs I used in my [most recent PowerShell book](https://smile.amazon.co.uk/Windows-Server-Automation-PowerShell-Cookbook-ebook/dp/B0977JDL7K/ref=sr_1_1?dchild=1&keywords=Windows+Server+Automation+with+PowerShell+Cookbook+-+Fourth+Edition&qid=1624277697&s=books&sr=1-1)to illustrate using PowerShell in an Enterprise.
As they are all local VMs and are only for testing, creating a much used credential object is something to consider.

## Be Careful

It is easy to get carried away with profile files. 
At one point in the PowerShell 3.0 days, my profile files were over 700 lines long.
I'd just chucked all these cool things I'd found on the Internet (and never used them again)
It is so easy to see some cool bits of code and then add it to your profile.
I suggest you look carefully at each Profile file


## Summary

Profile files are PowerShell scripts you can use to customize yoru PowerShell host.
There are 4 profile files for each host as you can see by examining the $Profile automatic variable.



## Tip of the Hat

I based this article on one written for the earlier Scripting Guys blog [How Can I Use Profiles With Windows PowserSHell](https://devblogs.microsoft.com/scripting/hey-scripting-guy-how-can-i-use-profiles-with-windows-powershell/).

****
It was written by Ed Wilson.
