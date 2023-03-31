---
post_title: Keeping PowerShell VisualBasic MessageBox in Focus
username: sorastog
categories: PowerShell
tags: PowerShell,VisualBasic,Automation
summary: This posts explains how to keep PowerShell VisualBasic MessageBox in Focus
---

Hi Readers,

I faced an issue where I was using Visual Basic MessageBox for showing messages to users, but the popups were getting hidden behind the tool window. I had to explicitly select the popup, bring it to front and take action on it.

I also tried using ‘System.Windows.Forms.MessageBox’ but it again resulted in a popup window that was hidden behind the tool.

## Solution

To keep MessageBox in Focus and on top of all windows, you can use one of the enumerator values ‘ShowModal’ for MessageBox Style. Follow below code samples to achieve the same.

1. For Error

```powershell
   [Microsoft.VisualBasic.Interaction]::MsgBox("Some error occurred.", 
"OKOnly,SystemModal,Critical", "Error")
```

1. For Warning

```powershell
   [Microsoft.VisualBasic.Interaction]::MsgBox("Please correct fields.", 
"OKOnly,SystemModal,Exclamation", "Warning")
```

1. Success Message

```powershell
   [Microsoft.VisualBasic.Interaction]::MsgBox("Processing Completed.", 
"OKOnly,SystemModal,Information", "Success")
```

## Output

A full working code would look like below:-

```powershell
    [void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") 
    [Microsoft.VisualBasic.Interaction]::MsgBox("Some error occurred.", "OKOnly,SystemModal,Critical", "Error")
    [Microsoft.VisualBasic.Interaction]::MsgBox("Please correct fields.", "OKOnly,SystemModal,Exclamation", "Warning")
    [Microsoft.VisualBasic.Interaction]::MsgBox("Processing Completed.", "OKOnly,SystemModal,Information", "Success")
```

There are various other combinations that are part of Message Box Style Enumerator
ApplicationModal, DefaultButton1, OkOnly, OkCancel, AbortRetryIgnore, YesNoCancel, YesNo, RetryCancel, Critical, Question, Exclamation, Information, DefaultButton2, DefaultButton3, SystemModal, MsgBoxHelp, MsgBoxSetForeground, MsgBoxRight, MsgBoxRtlReading

Use the one which suits your need.

See you in my next blog post 🙂. Happy Scripting!!!