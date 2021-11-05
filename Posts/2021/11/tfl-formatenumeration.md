---
post_title: How to Use $FormatEnumerationLimit
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, Format, FormatEnumerationLimit variable
Summary: Using The $FormatEnumerationLimit variable in PowerShell
---

**Q:** When I format an object where a property contains more than 4 objects, I never see the extra property values. How can I fix that?

**A:** Use the `$FormatEnumerationLimit` variable.

This query is one I hear in many PowerShell support forums, and I have encountered this issue a lot over the years.
What happens is that you issue a command to return objects, for example `Get-Process`.
The `Get-*` cmdlets return objects which can contain properties that are arrays of values, not just a single value.
When you pipe those objects to `Format-Table`, by default, PowerShell only shows you the first four.

Let me illustrate what this looks like (by default):

```powershell-console
PS> Get-Process -Name pwsh | Format-Table -Property ProcessName, Modules  

ProcessName Modules  
----------- -------  
pwsh        {System.Diagnostics.ProcessModule (pwsh.exe), 
             System.Diagnostics.ProcessModule (ntdll.dll),
             System.Diagnostics.ProcessModule (KERNEL32.DLL), 
             System.Diagnostics.ProcessModule (KERNELBASE.dll)…}
```

This output shows PowerShell getting the process object for `Pwsh.exe` and then passing it to `Format-Table`, which outputs the process name and the modules used by that process.
However, as you can see, PowerShell shows only four modules shown followed by "…" (also known as an ellipsis).
The ellipsis tells you that there are more values in this property, except PowerShell does not show them.

If you know the `Format-Table` command, you might be tempted to use the `-Wrap` or the `-AutoSize` parameters, but these would not help.
It turns out there is no parameter for `Format-Table` or `Format-List` to control this.
The trick is to use the `$FormatEnumerationLimit` variable and assign it a higher value.

The `$FormatEnumerationLimit` automatic variable tells PowerShell and the formatting cmdlets how many occurrences to include in the formatted output.
By default, PowerShell sets this variable to four at startup.
And that is why you see just four processes in output (by default).

With PowerShell, you can adjust this limit in a script or a profile file.
When you change the value, PowerShell outputs more occurrences, up to the limit you set in `$FormatEnumerationLimit`.
Like this:

```powershell-console
PS > $FormatEnumerationLimit = 8
PS > Get-Process -Name PWSH | Format-Table -Property ProcessName, Modules

ProcessName Modules
----------- -------
pwsh        {System.Diagnostics.ProcessModule (pwsh.exe), 
             System.Diagnostics.ProcessModule (ntdll.dll),
             System.Diagnostics.ProcessModule (KERNEL32.DLL),
             System.Diagnostics.ProcessModule (KERNELBASE.dll),
             System.Diagnostics.ProcessModule (apphelp.dll),
             System.Diagnostics.ProcessModule (USER32.dll),
             System.Diagnostics.ProcessModule (win32u.dll),
             System.Diagnostics.ProcessModule (GDI32.dll)…}   
```

In the above output, you can see output for eight modules.
In writing this, there are actually 239 actual modules for the PowerShell process.
If you need to see all the modules, you could set `$FormatEnumerationLimit` to a larger number (e.g. 999) in the shell.
Alternatively, if you set `$FormatEnumerationLimit` to -1, PowerShell displays all occurrences, which may be more than you want in most cases!
I set the limit to 99 in my profile file and that is usually more than sufficient.

## Scoping of $FormatEnumerationLimit

One interesting thing I found is that `$FormatEnumerationLimit` is scoped differently to my expectations.
If you use a format command within a function or script (a child of the global scope), the command only uses the value from the global scope.

The following code contains a function to illustrate the issue:

```powershell
function Test-FormatLimitLocal
{
  # Change format enum limit
  "In Function, limit is: [$FormatEnumerationLimit]"
  $FormatEnumerationLimit = 1
  "After changing: [$FormatEnumerationLimit]"
  Get-Process | Select-Object -Property Name, Threads -First 4
}
```

You might think that this code would display the first thread in each of the first four processes. 
You might, but you would be wrong, as you can see here:

```powershell-console
PS> # Here show the value and call the functin
PS> "Before calling: [$FormatEnumerationLimit]"
Before calling: [4]
PS> Test-FormatLimitLocal
In Function, limit is: [4]
After changing: [1]

Name                    Threads
----                    -------
AggregatorHost          {5240}
ApplicationFrameHost    {16968, 2848}
AppVShNotify            {9164}
Atom.SDK.WindowsService {4064, 4908, 4912, 19144…}
```

As you can see from this output, the final process shows FOUR threads not ONE.
This is because PowerShell seems to only use the globally scoped value, not the locally scoped copy.
To get around this curious scoping, you can re-write the function like this:

```powershell

function Test-FormatLimitGlobal
{
  # Change format enum limit Globally
  $Old = $Global:FormatEnumerationLimit
  $Global:FormatEnumerationLimit = 1
  "After changing: [$Global:FormatEnumerationLimit]"
  Get-Process | Select-Object -Property Name, Threads -First 4
  # Change it back
  $Global:FormatEnumerationLimit = $Old
}
```

When you call the updated function, it now operates more as you might wish, like this:

```powershell-console
PS> # View the value
PS> "Before calling: [$FormatEnumerationLimit]"
Before calling: [4]#
PS> # Now call the updated function
PS> Test-FormatLimitGlobal
After changing: [1]

Name                    Threads
----                    -------
AggregatorHost          {5240}
ApplicationFrameHost    {16968…}
AppVShNotify            {9164}
Atom.SDK.WindowsService {4064…}
```

So, with some careful updating of the global variable, you can get the desired result.
In general, I teach my students to avoid manipulating global variables from within a script or a function (unless you know what you are doing).
If you need to make changes to any global variable to make a function or script do what you want, ensure you know how to revert the variable to its original value.

I am unclear whether this is a bug or a feature! To that end, I submitted a [feature request](https://github.com/PowerShell/PowerShell/issues/16360) in the PowerShell source repository. Feel free to add your opinion in the comments or upvote it if you want to see it added.

## Summary

The `$FormatEnumerationLimit` variable is a neat feature of PowerShell that allows you to see more occurrences when using `Format-Table`.
But remember: if you are using this variable in a function or a script, you should be aware of the scoping issue.

You can read more about `$FormatEnumerationLimit`, and other preference variables in [about_Preference_Variables](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_preference_variables#formatenumerationlimit).
