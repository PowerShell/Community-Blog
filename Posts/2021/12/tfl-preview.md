---
post_title: How to Preview PowerShell Scripts In PowerShell
username: tfl@psp.co.uk
Categories: PowerShell
tags: PowerShell, Explorer, Explorer Preview
Summary: How to Preview PowerShell .PS1, .PSD1, .PSD1 files inside Windows Explorer.
---

**Q:** When I use Windows Explorer and select a PowerShell script file - I do not see the script in the preview window. Can I fix that?

**A:** You can make a few simple registry updates and do just what you want!

At some time in the deep and distant past, Windows Explorer gained the preview pane feature.
The idea is simple: you select a file in Explorer and Windows shows you a preview of the file in a separate pane.
I love this feature, although when clicking on a Word document, it could take a few moments before I could view.
And if you are viewing a file, it was "open" and you could not delete it in a separate window!
A great feature albeit with some minor side effects - so it makes sense that this is turned off by default.
But you can easily turn it back on!

## Microsoft PowerToys to the rescue??

You can use [Microsoft's Power Toys for Windows](https://docs.microsoft.com/windows/powertoys) to enable Explorer to preview more file types.
I love these tools - and have them installed on my computers.
Sadly, PowerToys currently does not enable previewing of PowerShell files.

## Enabling Preview in Windows Explorer

As I mentioned above, file preview within Windows Explorer is disabled by default.
To turn this on, use Explorer's View menu and select preview.
I leave the details of how to set this up as an exercise for the user.
As a small aside, this setting gets reset each time you upgrade Windows - as a Windows Insider, I have to reset this with each new build I take. :-(

## Enabling Preview of .PS1/.PSD1/.PSM1 files

Once you enable preview mode in Explorer as shown above, when you select a `.PS1` file - you see something like this:

![Viewing a .PS1 file in Preview](./media/tfl-preview/before.png)

There is currently no mechanism in Explorer to change the list of file types to be displayed.
Fortunately, there is a straightforward mechanism that involves setting a registry key value.
To enable Explorer to display the relevant files, you can use the following script fragment:

```powershell
# Set path variables for PowerShell file types
$Path1 = 'Registry::HKEY_CLASSES_ROOT\\.ps1'
$Path2 = 'Registry::HKEY_CLASSES_ROOT\\.psm1'
$Path3 = 'Registry::HKEY_CLASSES_ROOT\\.psd1'

# Enable preview of those file types
New-ItemProperty -Path $Path1 -Name PerceivedType -PropertyType String  -Value 'text'
New-ItemProperty -Path $Path2 -Name PerceivedType -PropertyType String  -Value 'text'
New-ItemProperty -Path $Path3 -Name PerceivedType -PropertyType String  -Value 'text'
```

## Result!

Once you run this script, Explorer displays the script file, Explorer now looks like this:

![Viewing a .PS1 file in Preview after updating the registry](./media/tfl-preview/after.png)

That's it - a small change to the registry and I can now preview PowerShell files.
Very handy!
