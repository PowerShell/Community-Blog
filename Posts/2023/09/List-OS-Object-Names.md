---
post_title: 'Listing Windows object names'
username: FranciscoNabas
categories: PowerShell
post_slug: listing-windows-object-names
tags: PowerShell, Automation, Windows, Handles, Object Model
summary: This post shows how to list the object names who have open handles with a process.
---

As our knowledge of the Windows operating system grows, we often need to understand how processes
request, utilize, and dispose of operating system resources. This is nothing new, tools like
the Task Manager or Process Explorer show a comprehensive view of these relations.
However, we don't need a complicated application to explore this lower level of abstraction. All
we need is our trusty PowerShell console, and a bit of imagination.

## Method

To achieve this, and to keep it fun, we are going to use a set of documented and partially
documented Windows APIs. Although it's possible to achieve this using 100% PowerShell, to improve
simplicity we are going to use a bit of C# for the function signatures and value types, like
structs.
This post draws inspiration from the blog post [How can I close a handle in another process?][01]
by Pavel Yosifovich. This is one of the posts I keep in my browser's bookmarks.

## Signatures

As explained previously, we are going to define function signatures, and structs using C#. Due to
similarities between C# and PowerShell, this should be relatively familiar.

First we start with the enumerations. These are for making function calls more understandable.

```csharp
namespace Utilities
{
    using System;
    using System.Runtime.InteropServices;

    // This one lists the possible process information we can get
    // with 'NtQueryInformationProcess'.
    public enum PROCESSINFOCLASS
    {
        ProcessBasicInformation = 0,
        ProcessDebugPort = 7,
        ProcessWow64Information = 26,
        ProcessImageFileName = 27,
        ProcessBreakOnTermination = 29,
        ProcessHandleInformation = 51
    }

    // This one is similar to the previous enumeration, but lists
    // possible information we can get from objects.
    public enum OBJECT_INFORMATION_CLASS
    {
        ObjectNameInformation = 1,
        ObjectTypeInformation = 2
    }

    /* Code continues bellow */
}
```

Now we define the structs. There are the structures that will hold the information
we want to query.

```csharp
namespace Utilities
{
    using System;
    using System.Runtime.InteropServices;

    /* Above code */

    // Often when using functions from 'ntdll.dll' we see this
    // structure. It exists to hold a string that can be
    // easily manipulated by the lower levels of the operating
    // system.
    [StructLayout(LayoutKind.Sequential)]
    public struct UNICODE_STRING
    {
        public ushort Length;
        public ushort MaximumLength;
        
        [MarshalAs(UnmanagedType.LPWStr)]
        public string Buffer;
    }

    // This structure is part of 'OBJECT_TYPE_INFORMATION'.
    // We wont use it, but we need to specify it so the final
    // struct alignment is in line with the original.
    [StructLayout(LayoutKind.Sequential)]
    public struct GENERIC_MAPPING {
        public uint GenericRead;
        public uint GenericWrite;
        public uint GenericExecute;
        public uint GenericAll;
    }

    // This structure holds information about objects.
    // It's what's returned when we use the option
    // 'ObjectTypeInformation' when querying 'NtQueryObject'.
    [StructLayout(LayoutKind.Sequential)]
    public struct OBJECT_TYPE_INFORMATION
    {
        public UNICODE_STRING TypeName;
        public uint TotalNumberOfObjects;
        public uint TotalNumberOfHandles;
        public uint TotalPagedPoolUsage;
        public uint TotalNonPagedPoolUsage;
        public uint TotalNamePoolUsage;
        public uint TotalHandleTableUsage;
        public uint HighWaterNumberOfObjects;
        public uint HighWaterNumberOfHandles;
        public uint HighWaterPagedPoolUsage;
        public uint HighWaterNonPagedPoolUsage;
        public uint HighWaterNamePoolUsage;
        public uint HighWaterHandleTableUsage;
        public uint InvalidAttributes;
        public GENERIC_MAPPING GenericMapping;
        public uint ValidAccessMask;
        public bool SecurityRequired;
        public bool MaintainHandleCount;
        public byte TypeIndex;
        public char ReservedByte;
        public uint PoolType;
        public uint DefaultPagedPoolCharge;
        public uint DefaultNonPagedPoolCharge;
    }

    // This structure holds information about a process open
    // handles. An array of these structures is what we are
    // going to work with.
    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_HANDLE_TABLE_ENTRY_INFO
    {
        public IntPtr HandleValue;
        public ulong HandleCount;
        public ulong PointerCount;
        public uint GrantedAccess;
        public uint ObjectTypeIndex;
        public uint HandleAttributes;
        public uint Reserved;
    }

    // This structure is what is returned when we use the option
    // 'ProcessHandleInformation' when querying 'NtQueryInformationProcess'
    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_HANDLE_SNAPSHOT_INFORMATION
    {
        public ulong NumberOfHandles;
        public ulong Reserved;
        public IntPtr Handles;
    }

    /* Code continues bellow */

}
```

Lastly we define the functions.

```csharp
namespace Utilities
{
    using System;
    using System.Runtime.InteropServices;

    /* Above code */

    // We need a class to hold members like methods (functions).
    public class ProcessAndThread
    {
        // This function returns information about processes.
        // The 'DllImport' attribute tells the runtime in which module
        // this function is defined, if we want to set the last error,
        // and optionally the encoding.
        [DllImport("ntdll.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern int NtQueryInformationProcess(
            IntPtr ProcessHandle,
            PROCESSINFOCLASS ProcessInformationClass,
            IntPtr ProcessInformation,
            uint ProcessInformationLength,
            out uint ReturnLength
        );

        // This is similar to the previous one, but returns information about
        // objects being used by processes.
        [DllImport("ntdll.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern int NtQueryObject(
            IntPtr Handle,
            OBJECT_INFORMATION_CLASS ObjectInformationClass,
            IntPtr ObjectInformation,
            uint ObjectInformationLength,
            out uint ReturnLength
        );

        // This function opens a handle to a process. We need to use it instead
        // of the .NET APIs because the handles it uses are only references to
        // native handles, and not the handles themselves.
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(
             uint processAccess,
             bool bInheritHandle,
             uint processId
        );

        // This function duplicates a handle opened by a process.
        // We need to duplicate the handle to be able to query it.
        [DllImport("kernel32.dll", SetLastError=true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DuplicateHandle(
            IntPtr hSourceProcessHandle,
            IntPtr hSourceHandle,
            IntPtr hTargetProcessHandle,
            out IntPtr lpTargetHandle,
            uint dwDesiredAccess,
            [MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            uint dwOptions
        );

        // This function returns a handle to the current process.
        // We need it so the OS can associate the duplicated handle
        // with it.
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr GetCurrentProcess();

        // This function closes a handle opened by certain functions.
        // Is important to close all handles where necessary to avoid
        // memory leaks.
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);
    }
}
```

## The script

### Adding the signature type

The first thing we need to do is add that signature as a type in our PowerShell script. There are
two ways we can do it, by copying that C# text into a here-string, or saving it in a file.
The second one keeps the code cleaner, so for this post, let's assume I saved that file as
`C:\HandleObjectNames.cs`.

```powershell
try {
    Add-Type -TypeDefinition (Get-Content -Path 'C:\HandleObjectNames.cs' -Raw)
}
catch { }
```

The `try-catch` block here catches any exceptions in case we run this script more than once, since
the type was added already. But if you made changes to the C# code, you need to close the PowerShell
session and open it again. In Visual Code you can accomplish this by opening the command palette
with <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> and then selecting **Developer: Reload Window**.

### Listing and opening running processes

Now we need to list all running processes, and open them using the `OpenProcess` method. The handle
returned by this method will be used to list the process's handle list.

```powershell
# These variables represent OS constants. We add them here to improve readability.
$PROCESS_QUERY_INFORMATION = 0x0400
$PROCESS_DUP_HANDLE = 0x0040
$STATUS_INFO_LENGTH_MISMATCH = 0xc0000004
$DUPLICATE_SAME_ACCESS = 2

# Listing all processes, and creating a list to hold the object names.
$process_list = Get-Process
[System.Collections.Generic.List[string]]$object_names = @()

# Iterating through each process.

foreach ($process in $process_list) {

    # 'vmmemCmZygote' is a special protected process used by the Container
    # Manager. Due its nature we can't query information about it, so if you
    # use containers or the Windows Sandbox, include this line to skip it.
    if ($process.Name -eq 'vmmemCmZygote') { continue }

    # The desired access. We want the ability to query process information,
    # and duplicate its handles.
    $proc_access = $PROCESS_QUERY_INFORMATION -bor $PROCESS_DUP_HANDLE

    $h_process = [Utilities.ProcessAndThread]::OpenProcess(
        $proc_access,
        $false,
        $process.Id
    )
    
    # If opening the process fails, we continue to the next one.
    if ($h_process -eq [IntPtr]::Zero) { continue }

    <# ~ Code continues ~ #>
}
```

### Querying process information

The next stage is to list all open handles for the current process in the loop. Since the number
of handles varies, this is a two-part operation. First we call the function to know how much
memory we need to allocate, then we loop trying to get the information until we succeed.

```powershell
foreach ($process in $process_list) {

    <# ~ Previous code ~ #>

    # Querying for the first time to get the buffer size.
    $bytes_needed = 0
    [void][Utilities.ProcessAndThread]::NtQueryInformationProcess(
        $h_process,                    # The handle to the process.
        'ProcessHandleInformation',    # What kind of information we want.
        [IntPtr]::Zero,                # The buffer.
        0,                             # The buffer size.
        [ref]$bytes_needed             # The size needed.
    )

    $succeeded = $true
    do {
        # Allocating memory.
        $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($bytes_needed)

        # Calling the function again.
        $result = [Utilities.ProcessAndThread]::NtQueryInformationProcess(
            $h_process,
            'ProcessHandleInformation',
            $buffer,
            $bytes_needed,
            [ref]$bytes_needed
        )

        # Something went wrong, exiting the loop.
        if ($result -ne 0 -and $result -ne $STATUS_INFO_LENGTH_MISMATCH) {
            $succeeded = $false
            break
        }

        # The call succeeded.
        if ($result -eq 0) {
            break
        }

        # At this point our buffer is too small, so we free it, and increase the size needed
        # To make sure on the next iteration we make it. 
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
        $bytes_needed += 128

    } while ($result -eq $STATUS_INFO_LENGTH_MISMATCH)

    # Something went wrong, so we move to the next process.
    if (!$succeeded) { continue }

    <# ~ Code continues ~ #>
}
```

### Querying the object name

The last stage is to go through each handle, and query its object name. At the end
we should have a unique list of all the object names currently in use.

```powershell
foreach ($process in $process_list) {

    <# ~ Previous code ~ #>

    # Marshaling the buffer to our desired structure.
    [Type]$proc_snapshot_type = [Utilities.PROCESS_HANDLE_SNAPSHOT_INFORMATION]
    $proc_snapshot = [System.Runtime.InteropServices.Marshal]::PtrToStructure($buffer, [type]$proc_snapshot_type)
    
    # This offset represents the current handle object.
    $offset = $proc_snapshot.Handles
    $current_process_handle = [Utilities.ProcessAndThread]::GetCurrentProcess()
    for ($i = 0; $i -lt $proc_snapshot.NumberOfHandles; $i++) {
        
        # Duplicating the handle.
        $h_target = [IntPtr]::Zero

        if (![Utilities.ProcessAndThread]::DuplicateHandle(
                $h_process,               # The owner process handle.
                $offset,                  # The handle object to duplicate.
                $current_process_handle,  # Our current process handle.
                [ref]$h_target,           # The target handle
                0,                        # Desired access (default).
                $false,                   # If the new handle is inheritable.
                $DUPLICATE_SAME_ACCESS    # Duplication flags.
            )) {

            # We failed to duplicate, so we continue to the next handle.
            continue
        }
        
        # Allocating memory. Since this structure is not documented, but is of a fixed size,
        # we allocate enough memory to accomodate a bigger structure.
        $obj_type_buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(1024)
        
        # Querying the object name.
        $result = [Utilities.ProcessAndThread]::NtQueryObject(
            $h_target,                    # The handle to the object.
            'ObjectTypeInformation',      # Information type.
            $obj_type_buffer,             # The buffer.
            1024,                         # The buffer size.
            [ref]$bytes_needed            # The size needed.
        )
        
        # Either if the function fails or succeeds, we need to close our handle.
        [void][Utilities.ProcessAndThread]::CloseHandle($h_target)

        # Something went wrong, continuing to the next handle.
        if ($result -ne -0) { continue }

        # Marshaling the buffer, and adding the object name to our list.
        $obj_type_info = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
            $obj_type_buffer, [type][Utilities.OBJECT_TYPE_INFORMATION])

        if (!$object_names.Contains($obj_type_info.TypeName.Buffer)) {
            [void]$object_names.Add($obj_type_info.TypeName.Buffer)
        }

        # Increasing the offset to the next handle.
        $offset = [IntPtr]::Add($offset, [IntPtr]::Size)
    }
}

# Returning the result.
return $object_names
```

And this is how we leverage the operating system's APIs to query object names.
This goes to show how powerful PowerShell really is. I hope you had fun, and until the next one!

Francisco Nabas.

[OpenProcess function][02]  
[DuplicateHandle function][03]  
[NtQueryInformationProcess function][04]  
[NtQueryObject function][05]

Check out my PowerShell modules!  
Manage Windows like a pro with [WindowsUtils][06]  
Check with module/assembly failed to load with [LibSnitcher][07]

<!-- Links -->

[01]: https://scorpiosoftware.net/2020/03/15/how-can-i-close-a-handle-in-another-process/
[02]: https://learn.microsoft.com/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess
[03]: https://learn.microsoft.com/windows/win32/api/handleapi/nf-handleapi-duplicatehandle
[04]: https://learn.microsoft.com/windows/win32/api/winternl/nf-winternl-ntqueryinformationprocess
[05]: https://learn.microsoft.com/windows/win32/api/winternl/nf-winternl-ntqueryobject
[06]: https://github.com/FranciscoNabas/WindowsUtils
[07]: https://github.com/FranciscoNabas/LibSnitcher
