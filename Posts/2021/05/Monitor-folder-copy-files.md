---
post_title: Monitor Folder With File Watcher
username: francisconabas@outlook.com
Catagories: PowerShell
tags: File, File Watch, Copy, Content
Summary: How to monitor a folder and copy files when a change happens.
---

**Q:** I have and application that everytime it opens a session, a file is created on %TEMP%.
When the application closes the session, this file is uploaded and erased from the machine.
However, some times the file is not uploaded or it goes corrupted.
How can i monitor the folder and every time a file is created i copy it to a backup directory?
Files with the same content cannot be copied or replaced.

**A:** Luckly for us there is a .NET class called System.IO.FileSystemWatcher.
With a little bit of imagination and the tools PowerShell provide us we can tackle this isse.

## What is a Class anyways?

Classes are often described as a set of instructions for a given objec.
In this set of instructions you have the object **Properties** and **Methods**.
Class properties describe what the values and objects look like.
Class methods are functions that works with the properies.

Example: Let's say i want a object that can store _FirstName_ and _LastName_.

```powershell
Class PersonalData {
    [string]$FirstName
    [string]$LastName
}
```

Then i can create an object with these properties and assign values for it:

```powershell-console
PS C:\> $Object = New-Object PersonalData
PS C:\> $Object.FirstName = 'Petter'
PS C:\> $Object.LastName = 'Parker'
```

Now let's say i want to get the full name of that object.
I can build a method for it:

```powershell
Class PersonalData {
    [string]$FirstName
    [string]$LastName

    [string]GetName() {
        return "$($this.FirstName) $($this.LastName)"
    }
}
```

And call it:

```powershell-console
PS C:\> $Object = New-Object PersonalData
PS C:\> $Object.FirstName = 'Petter'
PS C:\> $Object.LastName = 'Parker'
PS C:\> $Object.GetName()
Petter Parker
PS C:\>
```

And this is the simplest Class example i could came up with.
The Class addition on PowerShell came to make the tool appealing to developers.
In case you're curious on what are the Properties and Methods of a class, the _Get-Member_ cmdlet got you covered.
If we use it on our class we can see the properties and method we created:

```powershell-console
PS C:\> $Object | Get-Member

   TypeName: PersonalData

Name        MemberType Definition
----        ---------- ----------
Equals      Method     bool Equals(System.Object obj)
GetHashCode Method     int GetHashCode()
GetName     Method     string GetName()
GetType     Method     type GetType()
ToString    Method     string ToString()
FirstName   Property   string FirstName {get;set;}
LastName    Property   string LastName {get;set;}

PS C:\>
```

## Creating the File Watcher

Now that we have a notion of what classes are, let's talk about the one we will use for this project.
_System.IO.FileSystemWatcher_

Let's create an object using this class and see how it's like on the inside with the _Get-Member_ cmdlet:

```powershell-console
PS C:\> $FileWatcher = New-Object System.IO.FileSystemWatcher
PS C:\> $FileWatcher | Get-Member

   TypeName: System.IO.FileSystemWatcher

Name                      MemberType Definition
----                      ---------- ----------
Changed                   Event      System.IO.FileSystemEventHandler Changed(System.Object, System.IO.FileSystemEvent…
Created                   Event      System.IO.FileSystemEventHandler Created(System.Object, System.IO.FileSystemEvent…
Deleted                   Event      System.IO.FileSystemEventHandler Deleted(System.Object, System.IO.FileSystemEvent…
Disposed                  Event      System.EventHandler Disposed(System.Object, System.EventArgs)
Error                     Event      System.IO.ErrorEventHandler Error(System.Object, System.IO.ErrorEventArgs)
Renamed                   Event      System.IO.RenamedEventHandler Renamed(System.Object, System.IO.RenamedEventArgs)
BeginInit                 Method     void BeginInit(), void ISupportInitialize.BeginInit()
Dispose                   Method     void Dispose(), void IDisposable.Dispose()
EndInit                   Method     void EndInit(), void ISupportInitialize.EndInit()
Equals                    Method     bool Equals(System.Object obj)
GetHashCode               Method     int GetHashCode()
GetLifetimeService        Method     System.Object GetLifetimeService()
GetType                   Method     type GetType()
InitializeLifetimeService Method     System.Object InitializeLifetimeService()
ToString                  Method     string ToString()
WaitForChanged            Method     System.IO.WaitForChangedResult WaitForChanged(System.IO.WatcherChangeTypes change…
Container                 Property   System.ComponentModel.IContainer Container {get;}
EnableRaisingEvents       Property   bool EnableRaisingEvents {get;set;}
Filter                    Property   string Filter {get;set;}
Filters                   Property   System.Collections.ObjectModel.Collection[string] Filters {get;}
IncludeSubdirectories     Property   bool IncludeSubdirectories {get;set;}
InternalBufferSize        Property   int InternalBufferSize {get;set;}
NotifyFilter              Property   System.IO.NotifyFilters NotifyFilter {get;set;}
Path                      Property   string Path {get;set;}
Site                      Property   System.ComponentModel.ISite Site {get;set;}
SynchronizingObject       Property   System.ComponentModel.ISynchronizeInvoke SynchronizingObject {get;set;}

PS C:\>
```

Beautiful, now we know which properties we can set, methods we can call and _envents_ (More on that latter).
Based on that, lets create a File Watcher to monitor all **files** from **C:** drive, shaw we?

```powershell
$FileWatcher = New-Object System.IO.FileSystemWatcher
$FileWatcher.Path = 'C:\'
$FileWatcher.Filter = '*.*' #Filtering files only
$FileWatcher.IncludeSubdirectories = $true #Include sub directories on the watch
$FileWatcher.EnableRaisingEvents = $true #Enable this watcher to raise events
```

Alright! Now we are all set to monitor all files from drive C:\
But how do i start? And most importantly, how do i set an action if an event is triggered?
Let's start with the action. We need to define a _ScriptBlock_ that will be executed when a event is triggered:

```powershell
$Action = {
    $Path = $Event.SourceEventArgs.FullPath
    $Type = $Event.SourceEventArgs.ChangeType
    Write-Output "$Type detected on $Path."
}
```

Neat! Now every time an event is trigger i'll output de type and path.
And since we are talking a lot about _events_, let's register one, using the _Register-ObjectEvent_ cmdlet

```powershell
Register-ObjectEvent $FileWatcher 'Created' -Action $Action
```

Now every time a file is created on C: drive we will be notified.
And how do i know which events i can register?
By taking a look on the $FileWatcher object with Get-Member, just like we did in the beggining.
We can register the following events: 'Changed','Created','Deleted','Disposed','Error','Renamed'.

Now that we know how to monitore a path and trigger actions we just need to put a _Copy-Item_ on the action and run everything on a loop:

```powershell
$FileWatcher = New-Object System.IO.FileSystemWatcher
$FileWatcher.Path = 'C:\'
$FileWatcher.Filter = '*.*'
$FileWatcher.IncludeSubdirectories = $true
$FileWatcher.EnableRaisingEvents = $true
$Action = {
    $Path = $Event.SourceEventArgs.FullPath
    $Type = $Event.SourceEventArgs.ChangeType
    Write-Output "$Type detected on $Path."
    Copy-Item -Source $Source -Destination $Destination
}
$WatcherEvents = @('Changed','Created','Deleted','Disposed','Error','Renamed')
foreach ($WEvent in $WatcherEvents) {
        Register-ObjectEvent $FileWatcher "$WEvent" -Action $Action
    }

while ($true) {
    Write-Verbose "File Watcher running..."
    Start-Sleep -Secconds 5
}
```

## Summary

We just scrached the surface of what can be done with this class.
If you want to get your _Actions_ up a notch i would recomend those:

1. Use the -MessageData parameter to get data inside your action.
1. Take a look at the _Global:_ tag on your functions to be able to use it on your actions.

## Tip of the Hat

Wait! you said we would be able to copy content-unique files with this class.
Indeed and we do this using the MD5 hash of each file to decide if it's content-unique.
Please, be my guest at: [PowerShell Galery - FileWatcher](https://www.powershellgallery.com/packages/FileWatcher/1.0)
I have an example there with all of this implemented.
Thank you and see you next time!