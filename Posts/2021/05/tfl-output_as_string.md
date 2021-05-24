---
post_title: How to send output to a file
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, output
Summary: Multiple ways of sending output to a file. 
---

**Q:** Is there an easy way to save my script output to a text file rather than displaying it on screen?

**A:** Of course - there are multiple ways to do just that!

## PowerShell and Output

One of PowerShell's great features is the way it automatically formats output.
You type a command - PowerShell gives you the output it thinks you want.
If the default output is not what you need, use the formatting cmdlets like `Format-Table` and `Format-List` to get what you want.
But sometimes, what you want is getting output to a file, not to the console.
You might want to run a command or script that outputs information to a file and sends this file via email or possibly FTP.
Or, you might want to view it in a text editor or print it out later.

Once you have created the code (script, fragment, or a single command) that creates the output you need, you can use several techniques to send that output to a file.

## The alternative methods

There are (at least) four ways to get output to a file.
You can use any or all of:

* `*-Content` cmdlets
* `Out-File` cmdlet
* Redirection operators
* .NET classes

Writing this reminds me of my friends in Portugal who tell me there are 1000 ways to cook bacalao (cod).
Then they whisper: plus the way my mother taught me.
If there are more techniques for file output, I expect to see them in the comments to this article. 😃

## Using the `*-Content` cmdlets

There are four `*-Content` cmdlets:

* `Add-Content` - appends content to a file.
* `Clear-Content` - removes all content of a file.
* `Get-Content` - retrieves the content of a file.
* `Set-Content` - writes new content which replaces the content in a file.

The two cmdlets you use to send command or script output to a file are `Set-Content` and `Add-Content`.
Both cmdlets convert the objects you pass in the pipeline to strings, and then output these strings to the specified file.
A very important point here - if you pass either cmdlet a non-string object, these cmdlets use each object's **ToString()** method to convert the object to a string before outputting it to the file.
For example:

```powershell-console
PS> Get-Process -Name pwsh | Set-Content -Path C:\\Foo\\AAA.txt
PS> Get-Content -Path C:\\Foo\\AAA.txt
System.Diagnostics.Process (pwsh)
System.Diagnostics.Process (pwsh)
System.Diagnostics.Process (pwsh)
System.Diagnostics.Process (pwsh)
System.Diagnostics.Process (pwsh)
```

In many cases, this conversion does not produce what you expect (or want).
In this example, PowerShell found the 5 pwsh.exe processes, converted each to a string using **ToString()**, and outputs those strings to the file.
When you use **ToString** .Net's default implementation prints out the object's type name, like this:

```powershell-console
PS> $Foo = [System.Object]::new()
PS> $Foo.ToString()
System.Object
```

The **System.Diagnostics.Process** class's implementation of the **ToString()** method is only marginally richer.
The **ToString()** method for this class outputs the object's type name and includes the process name as you see above.
But it is far short of the richer output you see when you use `Get-Process` from the console.

The `*-Content` cmdlets are useful when you are building up a report programmatically.
For example, you could create a string, then add to it repeatedly in a script, finally outputting the report string to a file.
You can see the basic approach to building up a report in [this script that creates a Hyper-V VM summary report](https://github.com/doctordns/Wiley20/blob/master/10%20-%20Reporting/10.8%20-%20Creating%20a%20Hyper-V%20Status%20Report.ps1).

You can improve the output from `Set-Content` by using `Out-String`, like this:

```powershell-console
PS> # Get Powershell processes, convert to string, then output to a file
PS> Get-Process -Name pwsh |
      Out-String |
        Set-Content .\\Process.txt
PS> # View the file
PS> Get-Content .\\Process.txt

 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
     70    56.65     109.05      13.19    2876   1 pwsh
     87   100.72     161.84       4.69   31252   1 pwsh
     63    54.40      93.90      22.27   31500   1 pwsh
    145   295.50     355.05     465.28   38132   1 pwsh
     64    52.82      95.29      52.95   38436   1 pwsh
```

Now that is looking a lot more like what I suspect you wanted!
But there is an easier way.

## Using `Out-File`

The `Out-File` cmdlet sends output to a file.
The cmdlet, however, uses PowerShell's formatting system to write to the file rather than using **ToString()**.
Using this cmdlet means Powershell sends the file the same display representation that you see from the console.

Using `Out-File` looks like this:

```powershell-console
PS> # Get Powershell processes and output to a file
PS> Get-Process -Name pwsh | Out-File -Path C:\\Foo\\pwsh.txt
PS> Get-Content -Path C:\\Foo\\pwsh.txt

 NPM(K)    PM(M)      WS(M)     CPU(s)      Id  SI ProcessName
 ------    -----      -----     ------      --  -- -----------
     72    57.62     109.93      13.41    2876   1 pwsh
     92   136.95     202.20       5.44   31252   1 pwsh
     63    54.40      93.90      22.30   31500   1 pwsh
    145   295.49     355.05     465.80   38132   1 pwsh
     64    52.88      95.32      52.98   38436   1 pwsh

```

The `Out-File` cmdlet gives you control over the output that PowerShell composes and sends to the file.
You can use the `-Encoding` parameter to tell PowerShell how to encode the output.
By default, PowerShell 7 uses the [UTF-8](https://en.wikipedia.org/wiki/UTF-8) encoding, but you can choose others should you need to.

If you output very wide tables, you can use the  `-Width` parameter to adjust the output's width.
In PowerShell 7, you can specify a value of up to 1024, enabling very wide tables.
Although the documentation does not specify any maximum upper value, formatting is erratic if you specify a width greater than 1025 characters.

## The Redirection Operators

There are two PowerShell operators you can use to redirect output: `>` and `>>`.
The `>` operator is equivalent to `Out-File` while `>>` is equivalent to `Out-File -Append`.
The redirection operators have other uses like redirecting error or verbose output streams.
You can read more about the [redirection operator(s) in the online help](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_redirection).

## Using .NET Classes

There are several .NET classes you can leverage to produce output to a file.
C# developers have to use these classes since C# does not have PowerShell's formatting engine.
There are three classes, depending on your use case, that you might use:

* [BinaryWriter](https://docs.microsoft.com/dotnet/api/system.io.binarywriter) - Writes primitive types in binary to a stream.
* [StreamWriter](https://docs.microsoft.com/dotnet/api/system.io.streamwriter) - writes characters to a stream in a particular encoding.
* [StringWriter](https://docs.microsoft.com/dotnet/api/system.io.stringwriter) - writes information to a string. With this class, Powershell stores the string information in a [StringBuilder](https://docs.microsoft.com/dotnet/api/system.text.stringbuilder) object.

Of these three, the class you are most likely to use to send output to a file is the **StreamWriter** class.
Like this:

```powershell
# Get the directories in C:\\
$Dirs = Get-ChildItem -Path C:\\ -Directory
# Open a stream writer
$File   = 'C:\\Foo\\Dirs.txt'
$Stream = [System.IO.StreamWriter]::new($File)
# Write the folder names for these folders to the file
foreach($Dir in $Dirs) {
  $Stream.WriteLine($Dir.FullName)
}
# Close the stream
$Stream.Close()
 ```

You can use `Get-Content` to view the generated content, like this:

```powershell-console
PS> Get-Content -Path c:\\Foo\\Dirs.txt
C:\\AUDIT
C:\\Boot
C:\\Foo
C:\\inetpub
C:\\jea
C:\\NVIDIA
C:\\PerfLogs
C:\\Program Files
C:\\Program Files (x86)
C:\\PSDailyBuild
C:\\ReskitApp
C:\\Temp
C:\\Users
C:\\WINDOWS
```

For most PowerShell-using IT Pros, using the classes in the `System.IO` namespace is useful in two situations.
The first case is where you are doing a quick and dirty translation of a complex C# fragment to PowerShell.
The stream writer example above is based on the C# sample in the [SteamWriter's documentation page](https://docs.microsoft.com/dotnet/api/system.io.streamwriter).
In some cases, it might be easier to translate the code to PowerShell than to recode it to use cmdlets.
The second use case is where you are writing very large amounts of data to the file.
There is a limit on how big a .NET string object can be, restricting your report-writing.
If you are writing reports of tens of millions of lines of output (e.g. in an IoT scenario), writing one line at a time may be a way to avoid out of memory issues.
I doubt many IT Pros encounter such issues, but it's always a good idea to know there are alternatives where you need them.

## Summary

You have many options over how you send output to a file.
Each method has different use cases, as I mentioned above.
In most cases, I prefer using `Out-File`.
Using `Set-Content` is useful to set the initial contents of a file, for example, if you create a new script file based on a standard corporate template.
From the console, doing stuff quick/dirty, using the redirection operators can be useful alternatives.
Using the `System.IO` classes is another way to perform output and useful for very large output sets.
So lots of options - and I would not be surprised to find more methods I'd not considered!

## Tip of the Hat

I based this article on one written for the earlier Scripting GUys blog [How Can I Save Output to a Text File?](https://devblogs.microsoft.com/scripting/how-can-i-save-output-to-a-text-file/).
I am not sure who the author was.
