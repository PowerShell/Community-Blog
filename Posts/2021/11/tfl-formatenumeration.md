---
post_title: How to Use $FormatEnumerationLimit
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, Format, FormatEnumerationLimit variagble
Summary: Using The $FormatEnumerationLimit variable in PowerShell
---

**Q:** When I format an object where a property contains more than 4 objects I never see the extra property values. How can I fix that?

**A:** Use the $FormatEnumerationLimit variable.

I have seen this a lot - you issue a command to return objects. These objects have properties that are actually arrays of objects not a single property. Here is a good example of what you might see, by default.

```powershell-console
PS> Get-Process -Name PWSH | Format-Table -Property processname, modules  

ProcessName Modules  
----------- -------  
pwsh        {System.Diagnostics.ProcessModule (pwsh.exe), System.Diagnostics.ProcessModule (ntdll.dll),
            System.Diagnostics.ProcessModule (KERNEL32.DLL), System.Diagnostics.ProcessModule
            (KERNELBASE.dll)…}
```

PowerShell gets the process object for `Pwsh.exe` and outputs the process name and the modules used by that process. 
As you can see, there are only four modules shown followed by "…". 
That tells you that there are more occurrences in this property but PowerShell does not show them. 

If you know the `Format-Table` command, you might be tempted to use the `-Wrap` or the `-AutoSize` parameters, but these would not help either.
The trick is to use the `$FormatEnumerationLimit` variable.

This variable tells PowerShell how many occurences to format.
By default, PowerShell and Windows PowerShell set this variable to 4 at startup.
But there is nothing to stop you adjusting this limit in a script, or in a profile file.
When you change the value, PowerShell is capable of outputing more, up to the limit you set in `$FormatEnumerationLimit`.

Like this:

```powershell-console
PS > Get-Process -Name PWSH | Format-Table -Property ProcessName, Modules

ProcessName Modules
----------- -------
pwsh        {System.Diagnostics.ProcessModule (pwsh.exe), System.Diagnostics.ProcessModule (ntdll.dll),
            System.Diagnostics.ProcessModule (KERNEL32.DLL),System.Diagnostics.ProcessModule (KERNELBASE.dll),
            System.Diagnostics.ProcessModule (apphelp.dll),System.Diagnostics.ProcessModule (USER32.dll),
            System.Diagnostics.ProcessModule (win32u.dll),System.Diagnostics.ProcessModule (GDI32.dll),
            System.Diagnostics.ProcessModule (gdi32full.dll),System.Diagnostics.ProcessModule (msvcp_win.dll),
            System.Diagnostics.ProcessModule (ucrtbase.dll),System.Diagnostics.ProcessModule (SHELL32.dll),
            System.Diagnostics.ProcessModule (ADVAPI32.dll),System.Diagnostics.ProcessModule (msvcrt.dll),
            System.Diagnostics.ProcessModule (sechost.dll),System.Diagnostics.ProcessModule (RPCRT4.dll),
            System.Diagnostics.ProcessModule (IMM32.DLL),System.Diagnostics.ProcessModule (hostfxr.dll),
            System.Diagnostics.ProcessModule (hostpolicy.dll),System.Diagnostics.ProcessModule (coreclr.dll),
            System.Diagnostics.ProcessModule (ole32.dll),System.Diagnostics.ProcessModule (combase.dll),
            System.Diagnostics.ProcessModule (OLEAUT32.dll),System.Diagnostics.ProcessModule (bcryptPrimitives.dll),
            System.Diagnostics.ProcessModule (System.Private.CoreLib.dll),System.Diagnostics.ProcessModule (clrjit.dll),
            System.Diagnostics.ProcessModule (kernel.appcore.dll),System.Diagnostics.ProcessModule (pwsh.dll),
            System.Diagnostics.ProcessModule (System.Runtime.dll),System.Diagnostics.ProcessModule (Microsoft.PowerShell.ConsoleHost.dll),
            System.Diagnostics.ProcessModule (System.Management.Automation.dll),
            System.Diagnostics.ProcessModule (System.Threading.Thread.dll),  
            System.Diagnostics.ProcessModule (BCrypt.dll),System.Diagnostics.ProcessModule (icu.dll),
            System.Diagnostics.ProcessModule (System.Runtime.InteropServices.dll),System.Diagnostics.ProcessModule (System.Threading.dll),
            System.Diagnostics.ProcessModule (System.Diagnostics.Process.dll),
            System.Diagnostics.ProcessModule (System.Text.RegularExpressions.dll),
            System.Diagnostics.ProcessModule (System.Collections.dll),       
            System.Diagnostics.ProcessModule (System.Collections.Concurrent.dll),
            System.Diagnostics.ProcessModule (System.Xml.ReaderWriter.dll),  
            System.Diagnostics.ProcessModule (System.Private.Xml.dll)…}   
```

In the above output, you can more modules but not all of them.
In my case, there are 239 actual modules. 
Depending on your needs, you could set ``$FormatEnumerationLimit`` to a larger number (eg 999).
Personally, I set the limit to 99 in my profile file and that is usually more than sufficient.
 