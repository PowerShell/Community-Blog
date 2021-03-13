---
post_title: Determine if a folder exists
username: baumanisf
Catagories: PowerShell
tags: File, Test-Path
Summary: How can I determine if a folder exists?
---

**Q:** Is there any way to determine whether or not a specific folder exists on a computer?
**A:**  There are loads of ways you can do this.

## The Test-Path Cmdlet

The easiest way to do this is to use the `Test-Path` cmdlet.
It looks for a given path and returns `True` if it exists, otherwise it returns `False`.
You could evaluate the result of the `Test-Path` like in the code snippet below 

```powershell
$Folder = 'C:\\Windows'
"Test to see if folder [$Folder]  exists"
if (Test-Path -Path $Folder) {
    "Path exists!"
} else {
    "Path doesn't exist."
}
```
This is similar to the `-d $filepath` operator for IF statements in Bash. `True` is returned if `$filepath` exists, otherwise `False` is returned.

## For More Information

And for more information on `Test-Path` see the [Test-Path](https://docs.microsoft.com/powershell/module/microsoft.powershell.management/test-path) help page.

## Summary

So as you saw, `Test-Path` tests the existence of a path and returns a boolean value.
This return value can be evaluated in a IF statement for example.
## Tip of the Hat

This article is based on an earlier Scripting Guys blog article at [How can I determine if a folder exists on a computer?](https://devblogs.microsoft.com/scripting/how-can-i-determine-if-a-folder-exists-on-a-computer/).
I am not sure who wrote the original article.
