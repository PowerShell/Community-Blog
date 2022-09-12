---
post_title: PowerShell Registry Monitor
username: FranciscoNabas
categories: PowerShell
tags: PowerShell, Registry, Win32, COM, Windows Management
summary: How to set up a simple registry key monitor with PowerShell
---
  
Recently, while discussing work-related topics, a co-worker asked me if there is a way of monitoring changes on a Windows registry key.  
I knew we can monitor files, with the **System.IO.FileSystemWatcher** .NET class, but never heard of registry monitoring.  
Well, turns out Windows provides an API for it, and with the help of Interop Services, we can call it from PowerShell.  
  
## About tools
  
To accomplish this, we will need to work with **Platform Invoke**, or **PinVoke** for short.  
It consists of a .NET library who will wrap the native APIs to be called by managed .NET code.  
This library comes with Windows, on the Global Assembly Cache, and also with PowerShell Core.  
  
In addition to that, we will work with a couple of Windows API functions, listed below:
-   **RegOpenKeyEx:** Responsible for opening a handle¹ to the key.
-   **RegNotifyChangeKeyValue:** Responsible for monitoring the key, and triggering an event when a change happens.
-   **CreateEvent:** Responsible for creating the event.
-   **WaitForSingleObject:** This will monitor the event, and return a result based on the outcome.
-   **RegCloseKey:** To close the handle to our registry key.
-   **CloseHandle:** To close the handle to the event created.

  
The last two commands are not mandatory, because the Interop Services will wrap the handles in something called **Safe Handle**.  
This handle is released by the Garbage Collector at the end, but is not only a good practice, it creates the habit of monitoring object's lifecycles.  
If we are looking into interoperating with Windows more often, we need to get used on how it manages memory, to avoid unexpected behavior.  
  
If you want a series of posts based on **PinVoke** and interoperability, let me know in the comments!  
  
## About definition
  
If we want to leverage **System.Runtime.InteropServices**, we need to write part of our code in C#.  
Don't get intimidated, C# and PowerShell are very similar, and it won't be hard at all.  
Let's start by defining our functions.  
  
I will demonstrate step by step with **RegOpenKeyEx**, and the others will follow the same procedure.  
From Microsoft's documentation page, the function definition looks like this:  
  
```cpp
LSTATUS RegOpenKeyExW(
  [in]           HKEY    hKey,
  [in, optional] LPCWSTR lpSubKey,
  [in]           DWORD   ulOptions,
  [in]           REGSAM  samDesired,
  [out]          PHKEY   phkResult
);
```
  
Don't worry about the **'W'** at the end. Most of Windows functions have two versions, the **ANSI** version, and **UNICODE** version.  
Functions terminated in **'A'** are **ANSI** compliant, the **'W'** ones comply to **UNICODE**.  
If you call **RegOpenKeyEx**, Windows will route to one of the two.  
  
In order to represent this function with C#, we need to convert the parameter types. This process is often called **Marshalling**.
We can interpret these types as follows:  
-   HKEY: This represents a **handle**. Handles are a type of **Pointer**, so we can represent it as **System.IntPtr**. Since memory addresses are numbers, this type is a special kind of integer.
-   LPCWSTR: A pointer to a constant string with 16-bit Unicode characters. For us, a **System.String**.
-   DWORD: A 32-bit unsigned integer. In other words, a **System.UInt32**.
-   REGSAM: A Registry Security Access Mask. We will talk about it in a bit.
-   PHKEY: A pointer to a variable that will receive the opened key handle. We know that we can represent pointers as **System.IntPtr**.
-   LSTATUS: The function's return type. This maps to a **long**. We will represent it with **System.Int**.

  
The **REGSAM** data type is a list of definitions that will map Registry Key security to unsigned integers, so we can represent it as a **System.Uint32**.  
We will be using the **KEY_NOTIFY** REGSAM, which translates to **0x0010**.  
At the end, our function definition will look something like this:  
  
```csharp
[DllImport("Advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern int RegOpenKeyExW(
    IntPtr hKey,
    string lpSubKey,
    uint ulOptions,
    uint samDesired,
    out IntPtr phkResult
);
```
  
The first line in square brackets is called **DllImport Attribute**. Is what tells PinVoke which DLL contains the definition for **RegOpenKeyExW**.  
**CharSet = CharSet.Unicode** defines Unicode as our encoding, and **SetLastError = true** will set the last error with the corresponding Win32 error, if the function call fails.  
Setting the last error is crucial for debugging and troubleshooting these function calls.  
  
Following the same approach, we write the full code:  
  
```csharp
using System;
using System.Runtime.InteropServices;

namespace Win32
{
    public class Regmon
    {
        [DllImport("Advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int RegOpenKeyExW(
            int hKey,
            string lpSubKey,
            int ulOptions,
            uint samDesired,
            out IntPtr phkResult
        );

        [DllImport("Advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int RegNotifyChangeKeyValue(
            IntPtr hKey,
            bool bWatchSubtree,
            int dwNotifyFilter,
            IntPtr hEvent,
            bool fAsynchronous
        );

        [DllImport("Advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int RegCloseKey(IntPtr hKey);

        [DllImport("Advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int CloseHandle(IntPtr hKey);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr CreateEventW(
            int lpEventAttributes,
            bool bManualReset,
            bool bInitialState,
            string lpName
        );

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int WaitForSingleObject(
            IntPtr hHandle,
            int dwMilliseconds
        );
    }
}
```
  
Originally, the parameter **lpEventAttributes** is from the **LPSECURITY_ATTRIBUTES**, which is a structure.  
Since we are not going to use it, defining as **int** won't cause troubles.  
If we were to use it, we could define **LPSECURITY_ATTRIBUTES**³.  
  
## Writing the PowerShell code
  
Now that all the paper work is done, we can write the PowerShell code that will use these functions.  
To avoid filling your screen with repetitive code, I will represent the previous definition text as **$signature**.  
You just have to create a string that will receive the C# code.  
I use **Here-strings**:  
  
```powershell
$signature = @'
    Your code goes here.
'@
```
  
The final script looks like this:  
  
```powershell
using namespace System.Runtime.InteropServices

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$KeyPath,

    [Parameter()]
    [string]$LogPath = "$PSScriptRoot\RegMon-$(Get-Date -Format 'yyyyMMdd-hhmmss').log",

    [Parameter()]
    [int]$Timeout = 0xFFFFFFFF #INFINITE
)

Add-Type -TypeDefinition $signature

if (!(Test-Path -Path $KeyPath)) { throw "Registry key not found." }

switch -Wildcard ((Get-Item $KeyPath).Name) {
    'HKEY_CLASSES_ROOT*' { $regdefault = 0x80000000 }
    'HKEY_CURRENT_USER*' { $regdefault = 0x80000001 }
    'HKEY_LOCAL_MACHINE*' { $regdefault = 0x80000002 }
    'HKEY_USERS*' { $regdefault = 0x80000003 }
    Default { throw 'Unsuported hive.' }
}

$handle = [IntPtr]::Zero
$result = [Win32.Regmon]::RegOpenKeyExW($regdefault, ($KeyPath -replace '^.*:\\'), 0, 0x0010, [ref]$handle)
$event = [Win32.Regmon]::CreateEventW($null, $true, $false, $null)

<#
This will run indefinitely until it fails or reaches a timeout.
Adjust accordingly.
#>
:Outer while ($true) {
    $result = [Win32.Regmon]::RegNotifyChangeKeyValue(
        $handle,
        $false,
        0x00000001L -bor #REG_NOTIFY_CHANGE_NAME
        0x00000002L -bor #REG_NOTIFY_CHANGE_ATTRIBUTES
        0x00000004L -bor #REG_NOTIFY_CHANGE_LAST_SET
        0x00000008L, #REG_NOTIFY_CHANGE_SECURITY
        $event,
        $true
    )
    $wait = [Win32.Regmon]::WaitForSingleObject($event, $Timeout)
    
    switch ($wait) {
        0xFFFFFFFF { break Outer } #WAIT_FAILED
        
        0x00000102L { #WAIT_TIMEOUT
            $outp = 'Timeout reached.'
            Write-Host $outp -ForegroundColor DarkGreen
            Add-Content -FilePath $LogPath -Value $outp
            break Outer
        }
        
        0 { #WAIT_OBJECT_0 ~> Change detected.
            $outp = "Change triggered on the specified key. Timestamp: $(Get-Date -Format 'hh:mm:ss - dd/MM/yyyy')."
            Write-Host $outp -ForegroundColor DarkGreen
            Add-Content -FilePath $LogPath -Value $outp
        }
    }
}

[Win32.Regmon]::CloseHandle($event)
[Win32.Regmon]::RegCloseKey($handle)
```
  
Note: When calling **RegOpenKeyExW** for the first time, we don't have the handle to the key yet, so we specify which root key we want to use.  
The parameter **lpSubKey** is optional. When not specified, the function will monitor the root key.  
  
## Caveats
  
The **RegNotifyChangeKeyValue** is limited on what information it provides to the caller.  
If the parameter **bWatchSubtree** is false, the function will monitor only the key specified.
If this parameter is true, the function monitors subtrees, but if an event is triggered, it will not inform which key was modified.  
  
Is there a way of getting more information about Registry Events?  
Yes², but this is topic for another post.  
  
## Conclusion
  
I hope this post made calling Windows API Functions with PowerShell, less intimidating.  
Once you get used to Platform Invoke, you will need a bigger toolbox to store your new tools.  
  
Thank you for following along, once again, and I will see you next time!  
  
  
Useful links.

(1) [Handles and Objects](https://docs.microsoft.com/en-us/windows/win32/sysinfo/handles-and-objects)  
(2) [Registry and Event Tracing](https://docs.microsoft.com/en-us/windows/win32/etw/registry)  
(2) [SECURITY_ATTRIBUTES structure](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/aa379560(v=vs.85))  
[Platform Invoke](https://docs.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke)  
[A great resource of examples and how-tos for PinVoke](https://www.pinvoke.net/)
  
Want to test, or give suggestions on our **WindowsUtils** PowerShell module?  
[Windows Utils](https://github.com/FranciscoNabas/WindowsUtils)  
  
[See what I'm up to](https://github.com/FranciscoNabas/)