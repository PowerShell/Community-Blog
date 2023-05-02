---
post_title: Designing PowerShell For End Users
username: svalding
categories: PowerShell
tags: PowerShell, Design, Toolmaking, User Experience
summary: This posts explains taking user experience into account when designing PowerShell tools
---

PowerShell, being built on .NET and object-oriented in nature, is a _fantastic_ language for developing
tooling that you can deliver to your end users. These may be fellow technologists, or they could also be
non-technical users within your organization. This could also be a tool you wish to share with the community,
either via your own Github or by publishing to the PowerShell Gallery.

## What Are You Doing?

When setting out with the task of developing a tool you should, as a first step, stop and think. Think about
what problem your tool is trying to solve. This could be a number of things

- Creating data
- collating data
- Interacting with a system or systems

The sky is the limit here, but your first thing is to determine what it
is that you are trying to accomplish.

## What Should You Call It?

Your second step should be to consider your tool's name. Whether this is a single function, or a series of functions
that form a new module, you should consider the following:

- Use [approved verbs](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands) for Functions. You can run `Get-Verb` in your console to quickly get a list! _Tip_: Use `Get-Verb | Sort-Object` to make this easier to parse!
- Use a coherent noun. Be as specific as possible. Using a great combination of verb/noun syntax provides clarity
  to what your tool does.

## Designing Parameters

This step _could_ take some time, and a little trial and error. You want your tool to be flexible, but you don't want your parameter
names to be so difficult such that they are hard to use/remember. Succinct is better here. If you need to add some flexibility to your
tool, considering using [ParameterSets](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_parameter_sets). These will give your end users a few different ways to use your tool, if that is or becomes necessary in the future.

### Applying Guardrails

Guardrails, in this context, refers to the application of restrictions upon your parameters. These prevent your end users from passing incorrect input
to the tool you've provided them. Given that PowerShell is built on .NET, there is a _ton_ of flexibility and strength in the guardrails you can employ.

I'll touch on just a few of my favorites, but this is by far not an exhaustive list.

#### 1. ValidateSet

Let's look at an example first:

```powershell
[CmdletBinding()]
Param(
    [Parameter()]
    [ValidateSet('Cat','Dog','Fish','Bird')]
    [String]
    $Animal
)
```

If you notice above, we've defined a non-mandatory parameter that is of type `[String]`. If you notice above, we've defined a non-mandatory parameter that is of type `[String]`. This is a guardrail because any other type causes an error to be thrown.
We have added further restrictions (guardrails) on this parameter by employing a `[ValidateSet()]` attribute, which limits the valid input to _only_ those items that are
a member of the set. Provide `Horse` to the animal parameter and, even though it is a string, it produces an error because it's not a member of the approved set of inputs.

#### 2. ValidateRange

We'll start with another example:

```powershell
[CmdletBinding()]
Param(
    [Parameter()]
    [ValidateRange(2005,2023)]
    [Int]
    $Year
)
```

In this example we have defined a `Year` parameter that is an `[Int]`, meaning only numbers are valid input. We've applied guardrails via `[ValidateRange()]`, which limits the input to between 2005 and 2023. Any number outside of that range produces an error.

#### 3. ValidateScript

The `[ValidateScript()]` attribute is extremely powerful. It allows you to run arbitrary PowerShell code in a script block to check the input of a given parameter.
Let's check out a _very_ simple example:

```powershell
[CmdletBinding()] 
Param( 
    [Parameter()]
    [ValidateScript({ Test-Path $_ })]
    [String]
    $InputFile
)
```

By using `Test-Path $_` in the Scriptblock of our `[ValidateScript()]` attribute we are instructing
PowerShell to confirm that the input we have provided to the parameter actually exists (_Notice the
addition of `{}` here_). This helps by putting guardrails around human error in the form of typos.

## Wrapping It Up

As previously stated, adding guardrails to your tools using these methods (and countless others not mentioned)  _demonstrably_ increases the usability and adoption of your tools.

So take a step back, think about your tool's design _first_, and then start writing the code. I
think you'll find that it is a much more enjoyable experience, from creation to adoption.
