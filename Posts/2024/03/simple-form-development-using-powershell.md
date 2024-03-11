---
post_title: 'Simple form development using PowerShell'
username: rod-meaney
categories: PowerShell
post_slug: simple-form-development-using-powershell
tags: PowerShell, Automation, Toolmaking, User Experience
summary: Create .NET forms without all the .NET.
---

PowerShell is a tool for the command line. Most people who use it are comfortable with the command
line. But sometimes, there are valid use cases to provide Graphical User Interface (GUI).

[alert type="important" heading="Important caveat"]
As PowerShell developers we need to be careful. We can do insanely complicated things with GUI's
(and the .NET classes), and that is not a rod we want to make for our own back!
[/alert]

Forms are based on .NET classes, but I have implemented a _framework_, so you do nothing more than
create a JSON configuration and write simple functions in PowerShell. These functions are event
based functions contained in PowerShell cmdlets.

I am going to break this post into 3 parts:

- Lets just get some forms up and running
- How does all that work
- Use cases for forms and PowerShell

## Lets just get some forms up and running

1. Download my [ps-community-blog][01] repository.
1. If you know about PowerShell modules, add all the modules, or ALL the `ps1` files to your current
   setup. If you don't, that is OK, have a quick read of
   [Creating a scalable, customised running environment][02], which shows you how to set up your
   PowerShell environment. The instructions in that post are actually for the same repository that
   this post uses, so it should be pretty helpful.
1. Restart your current PowerShell session, which should load all the new modules.
1. In the PS terminal window, run the cmdlet.

   ```powershell
   New-SampleForm
   ```

   ![launching-a-simple-form][03]

   The PS terminal window that you launch the form from is now a slave to the form you have opened.
   I basically use this as an output for the user, so put it next to the opened form. If you have
   made it this far, thats it! If not, review your `Profile.ps1` as suggested in
   [Creating a scalable, customised running environment][02].

1. Press the buttons and see what happens. You should see responses appear in the PS terminal
   window. The tram buttons call an API to get trams approaching stops in Melbourne, Australia for
   the current time. The other two buttons are just some fun ones I found when searching for
   functionality to show in the forms.

### How do I create my own forms

Rather than following documentation (which, lets be honest, I have not written), understanding the
basics, and copying the examples is really the quickest way. Lets look at the SampleForm and work it
through. You need a matching json and ps1 form.

![json-and-cmdlet][04]

I am not going to go into all the specifics, they should be obvious from the examples. But
basically, a form has a list of elements, and they are placed at an x-y coordinate based on the x-y
attribute in the element. When creating elements, the following is important:

- Create a base json file of the right form size, with nothing in it.
- Create base matching cmdlet with only `# == TOP ==` and `# == BOTTOM ==` sections in it. These 2
  sections are identical in all form cmdlets.
- Restart your PowerShell session to pick up the new cmdlet.
- Add in elements 1 by 1 to the json file, getting them in the right position. You run the cmdlet
  after making changes to the json file.
- `Important`: follow a naming convention, **type_form_specificElement**, for two reasons.
  1. Firstly you can't have the same name for an element on the form
  1. Secondly, if you start getting fancy and having tabs, including the form in the name is going
     to help you immensely. (I had to do a lot of refactoring when I added in tabs!)
- Add in the `Add_Click` functions for your buttons. In keeping it simple, most of your
  functionality will be driven by your buttons. After updating your cmdlets, you will need to
  restart your PowerShell session to pick up the changes. I have found that using VS Code and
  PowerShell plugins and restarting PowerShell sessions is much cleaner than trying to unload, and
  load modules when you update/add cmdlets.

And that is it. As a good friend/co-worker of mine says, it sounds easy when you say it quick, but
the devil is in the detail. It can also be hard to debug.

> An easy way to debug is to create a `ps1` file with 1 line, the `New-Form` cmdlet. Running this in
> debug with breakpoints is the easiest way to debug.

With just this, and some diving into the other examples, you will be surprised the amount of
functionality you can expose through your own GUI.

## How does all that work

PowerShell has access to all the .NET classes sitting underneath it and it has a rich and well
developed set of widgets to add to forms. Now I am not a .NET developer, but it is pretty intuitive.

### Load the Assemblies and look at the base cmdlets

Inside `GeneralUtilities.psm1` you will see:

```powershell
Get-ChildItem -Path "$PSScriptRoot\*.ps1" | ForEach-Object{
    . $PSScriptRoot\$($_.Name)
}
Add-Type -assembly System.Windows.Forms
Add-Type -AssemblyName System.Drawing
```

- The first lines are my standard practice to load all the cmdlets in the module
- The `Add-Type` lines here are the crucial ones. They tell the PowerShell session to load the .NET
  classes required for forms to function.
- Inside the `GeneralUtilities` module are 3 important cmdlets
  - `Set-FormFromJson` is sort of the driver, reads the json file, and iterates over all the
    elements, loading them onto the form by calling..
  - `Set-FormElementsFromJson` which is where all the heavy .NET lifting is done. .NET Forms have
    been around so long, and are so consistent (and trust me, coming from an early 2000's web
    developer, this is wonderful), that with a basic switch, you can implement them all very easily
    and expose the features easily through our JSON configuration. This could be developed
    infinitely more, but see the caveat at the start of this post - KISS is very important.
  - `ConvertTo-HashtableV5` One of the most useful techniques in PowerShell is to always use the
    native objects (hashes and lists) so that the operations are consistent. I have found this
    particularly relevant for JSON files. I have included this as I rely on it heavily due to
    PowerShell 5 having some deficiencies in this area. I like to have all my stuff work in
    PowerShell 5 AND 7. It is based on a post [Convert JSON to a PowerShell hash table][05].

### Creating a form

```powershell
function New-SampleForm {
    [CmdletBinding()]
    param ()
    # ===== TOP =====
    $FormJson =  $PSCommandPath.Replace(".ps1",".json")
    $NewForm, $FormElements = Set-FormFromJson $FormJson

    # ===== Single Tab =====
    # All your button clicks etc.

    # ===== BOTTOM =====
    $NewForm.ShowDialog()
}
Export-ModuleMember -Function New-SampleForm
```

The above is a template for creating any form. I am a firm believer of convention over
configuration. It makes for less code and simpler design. With that in mind:

- `New-Sample` cmdlet should be in file `NewSample.ps1`.
- `NewSample.json` will be the configuration file for the form.
- The **TOP** section finds the json file for the cmdlet based on convention, then loads all the
  elements.
- The **BOTTOM** section makes the form appear.
- **TOP** and **BOTTOM** sections will not change between different forms.

Everything else in between is where the fun happens. Copy and paste `Add_Click` functions, rename
them following your JSON configuration, and you are away.

## Use cases for forms and PowerShell

### Quick access to common support tasks

The support team I am involved with have gone through a maturation of using PowerShell for support
tasks over the last couple of years. We started just writing small cmdlets to do repeatable tasks.
Stuff to do with file movement, Active Directory changes, data manipulation. Next we made some
cmdlets to access vendors API's that helped us do tasks quickly instead of through the vendor GUI
application.

All this functionality is now available through a tool that all the support guys use daily, and have
even started contributing to.

### Postman for 'one thing'

If you don't know Postman, it is a tool used to test API's / Web Services and is one of a modern
developers most useful tools. But we have some very technically savvy users, that are not
developers, and the ability for them to use some complex API's dramatically improves their
productivity (especially in non-production). Its too easy to make mistakes in Postman, and for
repeatable tasks with half dozen inputs, we now have a tool that does some basic validation, and
hits the API endpoint with consistent and useful data.

## Conclusion

You can get some big bang for minimal effort with the .NET Forms and help your fellow workers in an
environment that may just be a bit easier for some of them than native cmdlets. Sooooo...

> Lets break some stuff!

<!-- link references -->
[01]: https://github.com/rod-meaney/ps-community-blog
[02]: https://devblogs.microsoft.com/powershell-community/creating-a-scalable-customised-running-environment/
[03]: ./Media/simple-form-development-using-powershell/LaunchingASimpleForm.png
[04]: ./Media/simple-form-development-using-powershell/JsonAndCmdlet.png
[05]: https://4sysops.com/archives/convert-json-to-a-powershell-hash-table/
