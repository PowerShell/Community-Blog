---
post_title: Reading a text file bottom up
username: tfl@psp.co.uk
Catagories: PowerShell
tags: Array
Summary: How can I read a file from the bottom up?
---

**Q:** I have a log file in which new data is appended to the end of the file.
That means the most recent entries are at the end of the file.
I’d like to be able to read the file starting with the last line and then ending with the first line, but I can’t figure out how to do that.

**A:**  There are loads of ways you can do this.
A simple way is to use the power of array handling in PowerShell.

## The Get-Content Cmdlet

Before getting into the solution, let's look at the `Get-Content` cmdlet.
The `Get-Content` cmdlet always reads a file from start to finish.
You can always get the very last line of the file like this:

```powershell
Get-Content -Path C:\Foo\BigFile.txt |
  Select-Object -Last 1
```

This is similar to the `tail` command in Linux.
As is so often the case, the command doesn't quite do what you want it to.
That being said, with PowerShell 7, there's _always_ a way.

## Using Arrays

We can start by reading through the file from top to bottom.
Before displaying those lines to the screen we store them in an array, with each line in the file representing one element in the array.

As you probably know, an array is a collection of objects.
An array can hold multiple objects of the same, or different, types.
In this case you want the array to hold the lines in your file.
Each line is a string.
Once you have the lines in the array, you can work backwards to achieve your goal.

## Creating a simple file

To demonstrate, let's start by creating a simple file, and output it to a local text file, like this

```powershell-console
PS C:\Foo> $File = @'
>> violet
>> indigo
>> blue
>> green
>> yellow
>> orange
>> red
>> '@
PS C:\Foo> $File | Out-File -Path C:\Foo\SmallFile.txt
PS C:\Foo> Get-ChildItem -Path C:\Foo\SmallFile.txt

    Directory: C:\Foo

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          22/01/2021    20:13             44 SmallFile.txt
```

Once you have created the file, you can get the contents and display it, like this:

```powershell-console
PS C:\Foo> $Array = Get-Content -Path C:\Foo\SmallFile.txt
PS C:\Foo> $Array
violet
indigo
blue
green
yellow
orange
red
```

Admittedly, all we seem to have done so far is get back to where we started - displaying the file from the start to the finish not the reverse.
So how do we get to where you want to go?

## Arrays vs text files

There’s an important difference between a text file and an array.
With a text file, using `Get-Content`, you read it from only from the start to the finish.
Windows, .NET, and PowerShell do not provide a way to read the file in reverse.
However, once you have the file contained in an array. it’s easy to read the array from the bottom to the top.

Let's start by working out how many lines there are in the array.
And, more as a sanity check, display how many lines there are in the file, like this:

```powershell-console
PS C:\Foo> $Array = Get-Content -Path C:\Foo\SmallFile.txt
PS C:\Foo> $Length = $Array.count
PS C:\Foo> "There are $Length lines in the file"
There are 7 lines in the file
```

So that tells us you have the number of lines in the array that you expected. 

## Getting Array Members

So let's give you a solution. 
In our sample array, `$Array` we have 7 lines.
We can address any individual array member directly using `[<index>]` syntax (after the array name).
So the first item in the array always has an index number of 0 or `$Array[0]`).
In our array, the line **violet** has an index number of 0 so you can get to it using `$Array[0]`.
Likewise, red has an index number of 6, or `$Array[6]`.
But that doesn't help us much - just yet!

A particularly neat feature of array handling in PowerShell is that we can work backwards in an array using negative index values.
An index of [-1] is always the last element of an array, [-2] is the penultimate line, and so on.
So `$Array[-1]` is Red, `$Array[-2]` is Orange, and so on.

So what we do is to look first at `$Array[-1]`, then `$Array[-2]`, and so on, all withing a simple foreach loop, like this:

```powershell-console
PS C:\Foo> $Array = Get-Content -Path C:\Foo\SmallFile.txt
PS C:\Foo> $Length = $Array.count
PS C:\Foo> "There are $Length lines in the file"
There are 7 lines in the file
PS C:\Foo> $Line = 1
PS C:\Foo> 1..$Length | ForEach-Object {$Array[-$Line]; $Line++}
red
orange
yellow
green
blue
indigo
violet
```

This code snippet first sets a variable, `$Line`, to 1.
Then you read the file and display how many lines are in the file.
You then use `ForEach-Object` to run a script block once for each line in the file.
Inside the script block you get the array element starting at the end and output it to the console.
Then you increment the line number and repeat.

This may be a little confusing if you haven't work with arrays, but once you get the hang of it, you see how simple it really is.
Arrays are a fantastic capability within PowerShell.

## For More Information

For more information on arrays in PowerShell, see [About_Arrays](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_arrays).
And for more information on `Get-Content` see the [Get-Content](https://docs.microsoft.com/powershell/module/microsoft.powershell.management/get-content) help page.

## Summary

So as you saw, `Get-Content` does not read backwards through a file.
If you bring the file contents into an array, you can easily read it backwards.

## Tip of the Hat

This article is based on an earlier Scripting Guys blog article at [Can I Read a Text file from the Bottom Up?](https://devblogs.microsoft.com/scripting/can-i-read-a-text-file-from-the-bottom-up/).
I am not sure who wrote the original article.
