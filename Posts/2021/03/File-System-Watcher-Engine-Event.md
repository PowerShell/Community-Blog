# A Reusable File System Event Watcher for PowerShell

Have you ever needed a FilesystemWatcher and found it a bit cumbersome to interact with the [.Net frameworks FileSystemWatcher class](https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher) within a powershell script?

The PowerShell module [FSWatcherEngineEvent](https://www.powershellgallery.com/packages/FSWatcherEngineEvent) might help you out.
The module provides commands for creating and managing file system watchers and will publish its notifications as PowerShell engine events instead of directly registered object events.

After installing and importing of the module a new filesystem watcher can easily be created with the 'New-FileSystemWatcher' command.
As an example it will watch for changes in directory 'C:\temp\files'. The command allows to specify the same parameters (with the same names) as if you are using a FileSystemWatcher directly. This includes the notification filters, file name filter and option to include subdirectories. Please refer to the Microsofts reference documentation of the FileSystemWatcher class for the details.

```powershell
PS> New-FileSystemWatcher -SourceIdentifier "myevent" -Path c:\temp\files
```

The filesystem watcher will now send notifications to PowerShells engine event queue using the source identifier "myevent". The event can be consumed by registering an event handler for the same source identifier. The following example just writes the whole event converted to JSON to the console:

```powershell
PS> Register-EngineEvent -SourceIdentifier "myevent" -Action { $event | ConvertTo-Json | Write-Host }

Id     Name            PSJobTypeName   State         HasMoreData     Location             Command
--     ----            -------------   -----         -----------     --------             -------
1      myevent                         NotStarted    False                                $event|ConvertTo-Json|Wr…
```

To produce a new event some characters will be written to a file in the watched directory:

```powershell
PS> "XYZ" >> C:\temp\files\xyz

{
  "ComputerName": null,
  "RunspaceId": "b92c271b-c147-4bd6-97e4-ffc2308a1fcc",
  "EventIdentifier": 4,
  "Sender": {
    "NotifyFilter": 19,
    "Filters": [],
    "EnableRaisingEvents": true,
    "Filter": "*",
    "IncludeSubdirectories": false,
    "InternalBufferSize": 8192,
    "Path": "D:\\tmp\\files\\",
    "Site": null,
    "SynchronizingObject": null,
    "Container": null
  },
  "SourceEventArgs": null,
  "SourceArgs": null,
  "SourceIdentifier": "myevent",
  "TimeGenerated": "2021-03-13T21:39:50.4483088+01:00",
  "MessageData": {
    "ChangeType": 4,
    "FullPath": "C:\\temp\\files\\xyz",
    "Name": "xyz"
  }
}
```

Also event raised before a handler is registered will remain in the queue until they are consumed manually using 'Get.-Event'/'Remove-Event'. This has nothing to do with this module and is just the way PowerShell works.

To suspend the notification temporarily and to resume it later the following two commands can be used:

```powershell
PS> Suspend-FileSystemWatcher -SourceIdentifier "myevent"

PS> Resume-FileSystemWatcher -SourceIdentifier "myevent"
```

To keep track of all the filesystem watchers created in the current Powershell process the command 'Get-FileSystemWatcher' can be used:

```powershell
PS>  Get-FileSystemWatcher

SourceIdentifier      : myevent
Path                  : C:\temp\files\
NotifyFilter          : FileName, DirectoryName, LastWrite
EnableRaisingEvents   : True
IncludeSubdirectories : False
Filter                : *
```

It will write a state object to the pipe containing the configuration of all filesystem watchers. Finally if you want to ger rid of all filesystemwatchers the command 'Remove-FileSystemWatcher' will dispose a filesystem watcher specified by the source identifier of by piping in a collection of watchers:

```powershell
# to dispose one watcher
PS> Remove-FileSystemWatcher -SourceIdentifier "myevent"

# to dispose all 
PS> Get-FileSystemWatcher | Remove-FileSystemWatcher
```

Piping the filesystem watchers also works with the other commands.
If you like the module and want to see more you may inspect or fork its code at [github](https://github.com/wgross/fswatcher-engine-event).
