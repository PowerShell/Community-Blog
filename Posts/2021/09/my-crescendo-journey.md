---
Categories: PowerShell
post_title: My Crescendo journey
Summary: How I stopped worrying and learned to create a module
tags: Crescendo, module
username: sewhee@microsoft.com
---
In a recent PowerShell Users Group meeting I was thinking that it might be good to talk about the
new [Crescendo][blog1] module and how to use it. I was going to ask [Jason Helmick][jason] if he
would do a presentation for us. Then, in an unrelated conversation, someone mentioned using
`vssadmin.exe` for some project. This got me thinking: `vssadmin` is a perfect candidate for a
Crescendo module and maybe I should just learn it and do the presentation myself.

## What is Crescendo?

Crescendo is an experimental module developed by [Jim Truher][jim], one of the main developers of
PowerShell. Crescendo provides a framework to rapidly develop PowerShell cmdlets that wrap native
commands, regardless of platform. The goal of a Crescendo-based module is to create PowerShell
cmdlets that use a native command-line tool, but unlike the tool, return PowerShell objects instead
of plain text.

## How I got started

When I first heard about Crescendo, I thought:

> _So what. I've written wrapper modules like this before. How is this going to help me?_

But I knew there must be more to it for Jim to invest this much time and effort into it, and I
wanted something to present at the user group meeting.

So, I started by reading the blog posts about Crescendo and looking at some examples in the
[repository][repo].

### How Crescendo works

The to create a module using the Crescendo framework you have to create two main components:

- A JSON configuration file that describes the cmdlets you want
- Output handler functions that parse the output from the native command and return objects

Initially, the parsing code had to be embedded in the JSON file, which made writing and formatting
the code very difficult. But, in the [Preview 3][blog3] release, Jim added the ability to create
your output handler code in a function or a script file, making it much easier to manage.

Alright! Writing the PowerShell functions is something I am more comfortable with, so that was my
next step.

## Writing the output parser functions

To create the parser functions I had to know what the output looked like for all of the possible
command combinations of `vssadmin.exe`. I looked at the help provided by `vssadmin` and captured the
output for each subcommand in a separate file. I used these output files to design and implement a
parsing function for each subcommand.

Now, on to the configuration file.

## Creating the JSON configuration

For this I used the example from the [blog post][blog3] as a template. I also looked at the
`Get-InstalledPackage` example from the [Preview 2][blog2] blog post to see how the native commands
were referenced. For my first cmdlet I started with this JSON configuration:

```json
{
    "$schema": "https://aka.ms/Crescendo/Schema.json",
    "Commands": [
         {
            "Verb": "Get",
            "Noun": "VssProvider",
            "OriginalName": "$env:Windir/system32/vssadmin.exe",
            "OriginalCommandElements": [
                "list",
                "providers"
            ],
            "OutputHandlers": [
                {
                    "ParameterSetName": "Default",
                    "HandlerType": "Function",
                    "Handler": "ParseProvider"
                }
            ],
         }
    ]
}
```

The `ParseProvider` function is one of the functions that I had written to parse the output. I
repeated this pattern to create a new cmdlet for each of the `vssadmin` subcommands.

Notice that the first line of the JSON references a schema file. This file comes with the Crescendo
module. I used Visual Studio Code (VS Code) to do all my development. With this schema file, VS Code
provides IntelliSense for the JSON, making it easy to know which values are required and the type of
information needed.

Eventually, I added properties to the configuration for full help with descriptions and examples.
And I defined parameter sets for the `vssadmin` commands that supported parameters.

## Creating the new module

Crescendo, itself, is a module. It contains cmdlets that help you create your configuration and then
uses that configuration to create the module containing your cmdlets. Once I was happy with the
configuration file, I used the `Export-CrescendoModule` cmdlet to create my module.

```powershell
Export-CrescendoModule -ConfigurationFile .\vssadmin.crescendo.config.json -ModuleName VssAdmin.psm1
```

Crescendo created two new files:

- The module code file `VssAdmin.psm1`
- The module manifest file `VssAdmin.psd1`

These are the only two files that need to be installed. The `VssAdmin.psm1` file contains all the
cmdlets that Crescendo generated from the configuration and the **Output Handler** functions I
wrote to parse the output into objects.

The end result was a well-structured, fully documented module.

I still have one cmdlet left to create and I want to add administrative elevation since `vssadmin`
requires it. But I am happy with the results I have so far.

## Conclusion

After reading all of this you might still be asking "how is this any easier than just writing the
module myself?"

That is a fair question. But here are the conclusions I came to as I went through this process.

- The whole process, starting from nothing, researching both Crescendo and `vssadmin`, writing the
  code, creating the configuration, and generating the module took me about 4 hours. I thought that
  was pretty fast.
- Crescendo lets you separate the logic code (your parsing functions) from the cmdlet definition and
  parameter handling code. I found it easier to describe the cmdlets and their parameters in the
  JSON file rather than having to write that code myself.
- Crescendo handles things like **CommonParameters** and `SupportsShouldProcess` for you. You don't
  have to write that support code in the cmdlets.
- The configuration file also makes it easy to add help to your cmdlets. You don't have to remember
  the comment-based help keywords and structure.
- Separating the declarative code (the JSON configuration) from the logical code (your parsers)
  makes it easier to add functionality to your module if the native command-line tool is updated.

Take a few minutes to read the Crescendo blog posts. Then go and look at the VssAdmin module I
created. I have included the link to it below. Examine the `vssadmin.crescendo.config.json` file to
see how I defined the cmdlets and the parameter sets. The `vssadmin.exe resize shadowstorage`
command has a `/MaxSize=` parameter that can take 3 different types of values. Look at the
definition of the `Resize-VssShadowStorage` cmdlet to see how I handled that.

## Links to resources

- The blog posts
  - [Announcing Crescendo Preview 1][blog1]
  - [Announcing Crescendo Preview 2][blog2]
  - [Announcing Crescendo Preview 3][blog3]
- My [VssAdmin][vssadmin] module
- The [Crescendo repository][repo] on GitHub
- The [Microsoft.PowerShell.Crescendo][gallery] module on the PowerShell Gallery

<!-- link references -->
[blog1]: https://devblogs.microsoft.com/powershell/announcing-powershell-crescendo-preview-1/
[blog2]: https://devblogs.microsoft.com/powershell/announcing-powershell-crescendo-preview-2/
[blog3]: https://devblogs.microsoft.com/powershell/announcing-powershell-crescendo-preview-3/
[jim]: https://devblogs.microsoft.com/powershell/author/jimtrumicrosoft-com/
[jason]: https://devblogs.microsoft.com/powershell/author/jahelmic/
[repo]: https://github.com/PowerShell/Crescendo
[vssadmin]: https://github.com/sdwheeler/modules/vssadmin
[gallery]: https://www.powershellgallery.com/packages/Microsoft.PowerShell.Crescendo
