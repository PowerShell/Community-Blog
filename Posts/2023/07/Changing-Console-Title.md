---
post_title: 'Changing your console window title'
username: FranciscoNabas
categories: PowerShell
post_slug: changing-console-title
tags: PowerShell, Automation, console, terminal
summary: This post shows how to change the title of your console terminal window.
---

As our skill as a PowerShell developer grows, and the complexity of our scripts increase, we start
incorporating new elements to improve the user experience. That might include changing fonts, the
background color, or the console window title. This task was already discussed in a blog post from
2004, [Can I Change the Command Window Title When Running a Script?][01]. However, the post uses VB
script, and changes the title if you are willing to open a new console. Today we learn how to do it
with PowerShell, using the same window.

## Methods

We will explore two ways of changing the console window title.

- The `$Host` automatic variable.
- Console virtual terminal sequences.

## The $Host automatic variable

This variable contains an object that represents the current host application for PowerShell. This
object contains a property called `$Host.UI.RawUI` that allows us to change various aspects of the
current PowerShell host, including the window title. Here is how we do it.

```powershell
$Host.UI.RawUI.WindowTitle = 'MyCoolWindowTitle!'
```

And with just a property value change our window title changed.

![RawUI.WindowTitle](./Media/WindowTitle.png)

For as simple and straight forward the previous method is, there is something to keep in mind. The
`$Host` automatic variable is host dependent.

## Virtual terminal sequences

Console virtual terminal sequences are control character sequences that can control various aspects
of the console when written to the output stream. The terminal sequences are intercepted by the
console host when written into the output stream. To see all sequences, and more in-depth examples
go to the [Microsoft documentation page][02]. Virtual terminal sequences are preferred because they
follow a well-defined standard, and are fully documented. The window title is limited to 255
characters.

To change the window title the sequence is `ESC]0;<string><ST>` or `ESC]2;<string><ST>`, where

- `ESC` is character 0x1B.
- `<ST>` is the string terminator, which in this case is the "Bell" character 0x7.

The bell character can also be used with the escape sequence `\a`. Here is how we change a console
window title with virtual terminal sequences.

```powershell
$title = 'Title with terminal sequences!'

Write-Host "$([char]0x1B)]0;$title$([char]0x7)"

# Using the escape sequence.
Write-Host "$([char]0x1B)]0;$title`a"
```

## Conclusion

PowerShell is a versatile tool that often provides multiple ways of achieving the same goal. I hope
you had as much fun reading as I had writing. See you in the next one.

Happy scripting!

Useful links:

- [PowerShell automatic variable][03]
- [xterm terminal emulator][05]
- [Escape sequences][06]

Test our PowerShell module:

- [WindowsUtils][07]

<!-- link references -->
[01]: https://devblogs.microsoft.com/scripting/can-i-change-the-command-window-title-when-running-a-script/
[02]: https://learn.microsoft.com/windows/console/console-virtual-terminal-sequences
[03]: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_automatic_variables#home
[05]: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
[06]: https://learn.microsoft.com/cpp/c-language/escape-sequences
[07]: https://github.com/FranciscoNabas/WindowsUtils
