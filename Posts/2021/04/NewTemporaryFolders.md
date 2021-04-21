---
post_title: Borrowing a built-in PowerShell command to create a temporary folder
username: sean.kearney@microsoft.com
Catagories: PowerShell, Function
tags: Function,Fun trick,Existing Cmdlet,New Purpose
Summary: Leveraging a built-in cmdlet in a new and interesting way
---

**Q:** Hey I question for you.  It seems silly and I know I could probably put
something together with Get-Random.  But can you think of another way to create
a temporary folder with a random name in PowerShell?

Ideally, I'd like it to be in a user's own "Temporary Folder" is possible.

**A:**  We sure can!  If Doctor Scripto was sitting here right now, I'd see that
little green haired shout out "Never fear, Scripto is here!"

## New-TemporaryFile Cmdlet

Within PowerShell there is a built in Cmdlet called `New-TemporaryFile`.
Running this cmdlet simply creates a random 0 byte file in the `$ENV:Temp folder`
in whichever platform you are working in.

However, we can _borrow_ the filename created and use it to create a folder
instead.   It’s not really difficult, but maybe just not thought of very often.

When we execute the following cmdlet we get output similar to this as it
generates a new 0 Byte random file in the User's Temp folder stored in
`$ENV:Temp`

```output
PS> New-TemporaryFile

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----         3/31/2021   9:25 PM              0 tmpA927.tmp
```

Ok, that really wasn’t that impressive but what if we were to do this instead?

```powershell
$File = New-TemporaryFile
```

Now we’ve created the file and stored it away in the `$File` object.   With this
we can remove the file of course using the `Remove-Item` cmdlet

```powershell
Remove-Item -path $File -force
```

HA! I’ve already saved some time! The `$File` object is still there with the
information I want to use.

So, I could access the name in the object property and use it to create a
directory instead in the following manner.

```powershell
New-Item -ItemType Directory -Path $File.Name
```

But the problem is that it would be in whatever default folder PowerShell was
looking into at the time.

Hmmmmm…. How to solve that?

But there is a built in variable called `$ENV:Temp` which targets the exact
Temporary folder that the `New-TemporaryFile` cmdlet uses as well!

I can then take that variable and the original name of the Temporary file and
combine them together like this.

```powershell
$ENV:Temp + '\\' + $File.Name
```

_or_

I can even put them together in a single String like this.

```powershell
"$($ENV:Temp)\\$($File.Name)"
```

With this I could just create a new temporary directory under our temp folder
in this manner.

```powershell
New-Item -ItemType Directory -Path "$($ENV:Temp)\\$($File.Name)"
```

Now to identify where the file ended up, I could same thing as last time by
storing it as an object like `$DirectoryName` if I wanted.   Then I could remove
the "Random Directory name" later if I needed to.

```powershell
$Folder=New-Item -ItemType Directory -Path "$($ENV:Temp)\\$($File.Name)"
```

Then when I am done with that folder that was presumably used to hold some
garbage data. I can just use `Remove-Item` again.

But because it's a directory, I need to add `-recurse -force` to ensure all data
and Subfolders are removed.

```powershell
Remove-Item -Path $Folder -Recurse -Force
```

But here is the fun and neat bit. If you needed on a regular basis, we could
make this into a quick function for your code, module or to impress
friends with!

```powershell
Function New-TemporaryFolder {
    # Create Temporary File and store object in $T
    $T = New-TemporaryFile

    # Remove the temporary file .... Muah ha ha ha haaaaa!
    Remove-item $T -Force

    # Make a new folder based upon the old name
    New-Item -Itemtype Directory -Path "$($ENV:Temp)\\$($File.Name)" 
}
```

Now at this point I had thought my journey was complete.  It was until I posted
the solution to the [Facebook group for the PowerShell Community Blog](https://www.facebook.com/groups/pscommunityblog/) to share.

A fellow member of the Community noted the approach, while neat, was not very
efficient.

At that point I dug into the code on Github for the open source version of
PowerShell 7.x to see how it was done there.

In reading the source code for `New-TemporaryItem` I was able to see the .NET
object being used to generate the file.  It turns out there is also a .NET
method that can be used to create just that temporary name which all I wanted
to use in the first place for the directory name.

When I ran this in the PowerShell Console it produced the following output of a
New Temporary Folder

```output
PS> [System.IO.Path]::GetTempFileName()
C:\\Users\\Administrator\\AppData\\Local\\Temp\\2\\tmp3864.tmp
```

This was exactly what I wanted, that random temporary Name to be consumed for
the `New-Item` Cmdlet. With this approach the function became a lot simpler and
far more efficient!

```powershell
Function New-TemporaryFolder {
    # Make a new folder based upon a TempFileName
    New-Item -ItemType Directory -Path([System.IO.Path]::GetTempFileName())
}
```

Why did all of this pop into my head?  I was actually creating some PowerShell
for customer and needed a consistent and random set of folders in a common and
easily erasable location.

I was hoping that we had a `New-TemporaryDirectory` cmdlet, but found it was
just as easy to write one by _borrowing_ an existing cmdlet.

It was fun as well to discover how I could improve on the solution by reading
the [Source codefor New-TemporaryItem](https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.Commands.Utility/commands/utility/NewTemporaryFileCommand.cs)
on Github.

Thanks to a little nudging from the Community. So a big Thank you to Joel
Bennett for the critique! :)

Sean Kearney - Customer Engineer/Microsoft - @PowerShellMan

_"Remember with great PowerShell comes great responsibilty..."_
