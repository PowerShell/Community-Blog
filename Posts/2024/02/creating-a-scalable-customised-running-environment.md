---
post_title: 'Creating a scalable, customised running environment'
username: rod-meaney
categories: PowerShell
post_slug: creating-a-scalable-customised-running-environment
tags: PowerShell, Automation, Toolmaking, User Experience
summary: >-
  This post shows how to create an easy to support environment with all your own cmdlets.
---

Often people come to PoweShell as a developer looking for a simpler life, or as a support person
looking to make their life easier. Either way, we start exploring ways to encapsulate repeatable
functionality, and through PowerShell that is cmdlets.

How to create these is defined well in [Designing PowerShell For End Users][01]. And Microsoft 
obviously have pretty good documention, including  [How to Write a PowerShell Script Module][02]. I
also have a few basic rules I remember wehen creating cmdlets to go along with the above posts:

- Always use cmdlet binding.
- Call the file name the same as the cmdlet, without the dash.

But how do you organise them and ensure that they always load. This post outlines an approach that
has worked well for me across a few different jobs, with a few iterations to get to this point.

## Methods

There are 2 parts to making an effective running environment

- Ensuring all your cmdlets for a specific module will load.
- Ensuring all your modules will load.

### Example setup

![folder-structure][03]

We are aiming high here. Over time your functionality will grow and this shows a structure that 
allows for growth.  There are 3 modules (effectively folders): `Forms`, `BusinessUtilities` and 
`GeneralUtilities`. They are broken up into 2 main groupings, `my-support` and `my-utilities`. 
[ps-community-blog][04] is the GitHub repository where you can find this example.

Inside the `GenreralUtilities` folder you can see the all-important `.psm1`, with the same name as
the folder and a couple of cmdlets I have needed over the years. The `.psm1` file is a requirement
to create a module.

## Ensuring all your cmdlets for a specific module will load

Most descriptions of creating modules will explain that you need to either add the cmdlet into the
`.psm1`, or load the cmdlet files in the `.psm1` file. Instead, put the below in ALL your `.psm1`
module files:

```powershell
Get-ChildItem -Path "$PSScriptRoot\*.ps1" | ForEach-Object {
    . $PSScriptRoot\$($_.Name)
}
```

What does this do and why does it work?

- At a high level, it iterates over the current folder, and runs every `.ps1` file as PowerShell.
- `$PSScriptRoot` is the key here, and tells running session, what the location of the current 
  code is.

This means you can create cmdlets under this structure, and they will automatically load when you
start up a new PowerShell session.

## Ensuring all your modules will load

So, the modules are sorted. How do we make sure the modules themselves load? It's all about the
`Profile.ps1`. You will either find it or need to create it in:

- PowerShell 5 and lower - `$HOME\Documents\WindowsPowerShell\Profile.ps1`.
- PowerShell 7 - `$HOME\Documents\PowerShell\Profile.ps1`.
- For detailed information, see [About Profiles][05].

So this file runs at the start of every session that is opened on your machine. I have included
both 5 and 7, as in a lot of corporate environments, 5 is all that is available, and often people
don't have access to modify their environment. With some simple code we can ensure our modules will
open. Add this into your `Profile.ps1`:

```powershell
Write-Host "Loading Modules for Day-to-Day use"
$ErrorActionPreference = "Stop" # A safeguard for any errors

$MyModuleDef = @{
    Utilities = @{
        Path    = "C:\work\git-personal\ps-community-blog\my-utilities"
        Exclude = @(".git")
    }
    Support = @{
        Path    = "C:\work\git-personal\ps-community-blog\my-support"
        Exclude = @(".git")
    }
}

foreach ($key in $MyModuleDef.Keys) {
    $module  = $MyModuleDef[$key]
    $exclude = $module.Exclude

    $env:PSModulePath = @(
        $env:PSModulePath
        $module.Path
    ) -join [System.IO.Path]::PathSeparator

    Get-ChildItem -Path $module.Path -Directory -Exclude $exclude |
        ForEach-Object {
            Write-Host "Loading Module $($_.Name) in $Key"
            Import-Module $_.Name
        }
}
```

What does this do and why does it work?

- At a high level, it defines your module groupings, then loads your modules into the PowerShell
  session.
- `$MyModuleDef` contains the reference to your module groupings, to make sure all the sub folders
  are loaded as modules.
- `Exclude` is very important. You may load the code directly of your code base, so ignoring those
  as modules is important. I have also put DLL's in folders in module groupings, and ignoring these
  is important as well.

Now, every time you open any PowerShell session on your machine, all your local cmdlets will be
there, ready to use with all the wonderful functionality you have created.

## Conclusion

Having your own PowerShell cmdlets at your fingertips with minimal overhead or thinking makes your
PowerShell experinece so very much more rewarding. It also makes it easier to do as I like to do
and start the day with my favourite mantra: 

> Lets break some stuff!

<!-- link references -->
[01]: https://devblogs.microsoft.com/powershell-community/designing-powershell-for-end-users/
[02]: https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-script-module
[03]: ./Media/creating-a-scalable-customised-running-environment/ModuleSetup.png
[04]: https://github.com/rod-meaney/ps-community-blog
[05]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles
