---
post_title: Reading Configuration Manager Status Messages With PowerShell
username: francisconabas
categories: PowerShell
tags: SCCM, MECM, Status Message, Config Manager
summary: This post's intent is to show how to read Configuration Manager status messages using WMI and Win32 API function FormatMessage.
---

**Q:** I can read Configuration Manager status messages using the _Monitoring_ tab. Can I do it
using PowerShell?

**A:** Yes you can! We can accomplish this using SQL/WQL queries, plus the Win32 function
FormatMessage.

## Better understanding Status Messages

Before we get our hands dirty we need to understand how the Configuration Manager assembles these
messages and why we can't just query it from some table, view or WMI class.

To avoid storage or performance issues and to provide better standardization, the Config Manager
stores only message's key information (and the ones who change from message to message), and uses a
Win32 function called FormatMessage together with a DLL to assembly and display the full message.

At first, it seems intimidating, specially with the whole Win32 function thing, but it's actually
pretty simple. Let's take a look on one of these messages, so we can visualize what we want to
accomplish.

```
Distribution Manager failed to connect to the distribution point ["Display=\\\\CMGRDP1.contoso.com\\"]MSWNET:["SMS_SITE=PS1"]\\\\CMGRDP1.contoso.com\\. Check your network and firewall settings.
```

This message states a failed content distribution to a Distribution Point. If we remove the part of
the message containing the DP information,
`["Display=\\\\CMGRDP1.contoso.com\\"]MSWNET:["SMS_SITE=PS1"]\\\\CMGRDP1.contoso.com\\`, we end up with a
standard message that can be used every time this problem occurs.

## Querying useful information

Now that we have an overview of the Status Message structure, let's gather the information available
on the Config Manager database. For the purpose of this post, we will use failed distribution
messages, like the one we saw above.

- The WMI classes that store Status Message information interesting for us are **SMS_StatusMessage**
  and **SMS_StatMsgModuleNames**.
- For content distribution status we will use the **SMS_DistributionDPStatus** class.
- The SQL views for these classes are **v_StatusMessage**, **v_StatMsgModuleNames** and
  **vSMS_distributionDPStatus** respectively.
- For performance sake and the SQL language accepting more complex queries we are going to use it
  for our exercise. This SQL query should return all packages from our Distribution Point which the
  status is not _Success_ or _InProgress_

```sql
SELECT  *
FROM    vSMS_DistributionDPStatus
WHERE   [Name] = 'CMGRDP1.contoso.com'
        AND MessageState NOT IN (1,2)
```

On the result, we are interested on some key columns: **MessageID**, **LastStatusID**,
**MessageSeverity** and the **InsString(n)**.

- The **MessageID** and **MessageSeverity** we will use with the **FormatMessage** function.
- The **LastStatusID** we will use to join with the other views, who name this column **RecordID**.
- And perhaps the more interesting ones, the **InsString(n)** columns.

These columns, **InsString1**, **InsString2**, **InsString3**, ..., **InsString10** contain the
custom part of the message. Let's look at one row of the above query shall we?


| ID<sup>1</sup> | MessageID |    LastStatusID    | MessageSeverity |                             InsString1<sup>2</sup>                              | InsString2 |
| :------------- | :-------- | :----------------- | :-------------- | :------------------------------------------------------------------------------ | :--------- |
| 47365          | 2391      | 216172782348300122 | -1073741824     | ["Display=\\\\CMGRDP1.contoso.com\\"]MSWNET:["SMS_SITE=PS1"]\\\\CMGRDP1.contoso.com\\ |            |

- <sup>1</sup> The **ID** column is to help us to identify this specific message later.
- <sup>2</sup> The other **InsString** columns are null

Won't you look at that! The info on **InsString1** is exactly the custom part of our message! Let's
join the other views, and we will have all the information needed to proceed. We are also including
information from **v_Package**, or **SMS_Package** on WMI, to make the end result more meaningful.

```sql
SELECT
        pkg.Name
        ,pkg.PackageID
        ,dps.LastUpdateDate
        ,stm.ModuleName
        ,smn.MsgDLLName
        ,dps.MessageID
        ,CASE
            WHEN dps.MessageSeverity = '1073741824' THEN '1073741824' --Informational
            WHEN dps.MessageSeverity = '-2147483648' THEN '2147483648' --Warning
            WHEN dps.MessageSeverity = '-1073741824' THEN '3221225472' --Error
        END AS 'SeverityCode'
        ,dps.InsString1
        ,dps.InsString2
        ,dps.InsString3
        ,dps.InsString4
        ,dps.InsString5
        ,dps.InsString6
        ,dps.InsString7
        ,dps.InsString8
        ,dps.InsString9
        ,dps.InsString10
FROM    vSMS_distributionDPStatus AS dps
LEFT JOIN    v_StatusMessage AS stm ON stm.RecordID = dps.LastStatusID
LEFT JOIN    v_StatMsgModuleNames AS smn ON smn.ModuleName = stm.ModuleName
LEFT JOIN    v_Package AS pkg ON pkg.PackageID = dps.PackageID
WHERE   dps.MessageState NOT IN (1,2)
        AND dps.ID = '47365'
```

We are using the **ID** from the previous query to stick to our result. Removing this condition
should bring all package distribution failure for that site.

The *Case* statement is necessary because the Message Severity is actually hexadecimal, thus:

```powershell-console
PS C:\\> '{0:X}' -f -1073741824
C0000000
PS C:\\> '{0:X}' -f 3221225472
C0000000
PS C:\\>
PS C:\\> '{0:X}' -f -2147483648
80000000
PS C:\\> '{0:X}' -f 2147483648
80000000
PS C:\\>
```

Let's see what the result of this query looks like.

- Name           : Visual Studio 2019 Professional
- PackageID      : PS100095
- LastUpdateDate : 6/16/2022 3:49:26 AM
- ModuleName     : SMS Server
- MsgDLLName     : srvmsgs.dll
- MessageID      : 2391
- SeverityCode   : 3221225472
- InsString1     : ["Display=\\\\CMGRDP1.contoso.com\\"]MSWNET:["SMS_SITE=PS1"]\\\\CMGRDP1.contoso.com\\
- InsString2     :
- InsString3     :
- InsString4     :
- InsString5     :
- InsString6     :
- InsString7     :
- InsString8     :
- InsString9     :
- InsString10    :

As you can see, we have additional information here, especially **ModuleName** and **MsgDLLName**.
This DLL is the one we are going to use to format the message.

## Formatting the message. Finally!

To format our message to a readable format we will use the Configuration Manager SDK documentation,
which instruct us to use the Win32 API function *FormatMessage* together with the information we
just got. From the documentation:

```cpp
// Get the module handle for the component's message DLL. This assumes the
// message DLL is loaded. If the DLL is not loaded, then load the DLL by using
// the Win32 API LoadLibrary.
hmodMessageDLL = GetModuleHandle(MsgDLLName);

// The flags tell FormatMessage to allocate the memory needed for the message,
// to get the message text from a message DLL, and that the insertion strings are
// stored in an array, instead of a variable length argument list. The last
// parameter, apInsertStrings, is the array of insertion strings returned by the
// query.
dwMsgLen = FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                         FORMAT_MESSAGE_FROM_HMODULE |
                         FORMAT_MESSAGE_ARGUMENT_ARRAY,
                         hmodMessageDLL,
                         Severity | MessageID,
                         0,
                         lpBuffer,
                         nSize,
                         apInsertStrings);

// Free the memory after you use the message text.
LocalFree(lpBuffer);
```

Wait a second... this is... C++? How am I supposed to call this function with PowerShell?

We will borrow a platform from .NET called **PlatformInvoke** or ***Pinvoke*** for short. Combining
this through the namespace **System.Runtime.InteropServices** and importing as a type in PowerShell
using `Add-Type` will do the trick.

> Disclaimer: Using Pinvoke to invoke unmanaged code is another beast in on itself and is beyond the
> scope of this post, however is lot's of fun! I'll leave a couple of links at the end to get you
> started.

The first thing to do is to translate this C++ to C# so we can import into PowerShell.

```csharp
namespace Win32Api
{
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class kernel32
    {

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern IntPtr GetModuleHandle(
            string lpModuleName
        );

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern int FormatMessage(
            uint dwFlags,
            IntPtr lpSource,
            uint dwMessageId,
            uint dwLanguageId,
            StringBuilder msgOut,
            uint nSize,
            string[] Arguments
        );

                [DllImport("kernel32", SetLastError=true, CharSet = CharSet.Unicode)]
        public static extern IntPtr LoadLibrary(
            string lpFileName
        );

    }

}
```

Using `Add-Type` to import this namespace:

```powershell
Add-Type -TypeDefinition @"
namespace Win32Api
{
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class kernel32
    {

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern IntPtr GetModuleHandle(
            string lpModuleName
        );

        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern int FormatMessage(
            uint dwFlags,
            IntPtr lpSource,
            uint dwMessageId,
            uint dwLanguageId,
            StringBuilder msgOut,
            uint nSize,
            string[] Arguments
        );

                [DllImport("kernel32", SetLastError=true, CharSet = CharSet.Unicode)]
        public static extern IntPtr LoadLibrary(
            string lpFileName
        );

    }

}
"@
```

The SDK documentation lists 4 steps:

1. Load the DLL with LoadLibrary.
2. Get a handle to this library with GetModuleHandle.
3. Call the FormatMessage function.
4. Free the memory after using the text with LocalFree

Since we're calling this from PowerShell and the text will be loaded into a **StringBuilder**
object, the last step isn't necessary. The session will take care of the cleaning once we finish.

So let's give it a go!

```powershell
## Initializing the message and last error variables. Useful when processing lots of messages.
$lastError = $null
$message = $null

## All modules location on the CM installation folder.
$smsMsgsPath = "$env:SystemDrive\\Program Files\\Microsoft Configuration Manager\\bin\\X64\\system32\\smsmsgs"
$moduleHandle = [Win32Api.kernel32]::GetModuleHandle("$smsMsgsPath\\srvmsgs.dll") ## The DLL From our query.

## If the handle is zero, the module is not loaded. Checking to avoid loading the same DLL twice.
if ($moduleHandle -eq 0) {
        [void][Win32Api.kernel32]::LoadLibrary("$smsMsgsPath\\srvmsgs.dll")
        $moduleHandle = [Win32Api.kernel32]::GetModuleHandle("$smsMsgsPath\\srvmsgs.dll")
}

$bufferSize = [int]16384 ## Buffer size for our output message.
## The StringBuilder object who will hold our message.
$bufferOutput = New-Object 'System.Text.StringBuilder' -ArgumentList $bufferSize

$result = [Win32Api.kernel32]::FormatMessage(
        0x00000800 -bor 0x00000200 ## FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_IGNORE_INSERTS
        ,$moduleHandle
        ,3221225472 -bor 2391 ## SeverityCode | MessageID
        ,0 ## languageID. 0 = Default.
        ,$bufferOutput
        ,$bufferSize
        ,$null ## Used to inject the InsStrings into the function. We'll process it later to avoid issues.
)

## If the function returns zero, means a failure. Setting our $lastError variable to troubleshoot further.
if ($result -eq 0) { $lastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error() }
```

At this point, if we did everything right the message should be stored on our **StringBuilder**
object.

```powershell-console
PS C:\\> $result = [Win32Api.kernel32]::FormatMessage(
>>         0x00000800 -bor 0x00000200 ## FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_IGNORE_INSERTS
>>         ,$moduleHandle
>>         ,3221225472 -bor 2391 ## SeverityCode | MessageID
>>         ,0 ## languageID. 0 = Default.
>>         ,$bufferOutput
>>         ,$bufferSize
>>         ,$null ## Used to inject the InsStrings into the function. We'll process it later to avoid issues.
>> )
PS C:\\> $result
113
PS C:\\> $bufferOutput.ToString()
%11Distribution Manager failed to connect to the distribution point %1. Check your network and firewall settings.
PS C:\\>
```

Eureka! We did it!

And I bet you already know what that _%1_ means. ;).

It's the location of our **InsString1**.

So doing a little cleaning...

_Assuming the result from our SQL query is stored on the variable `$fail`_:

```powershell-console
PS C:\\> $message = $bufferOutput.ToString().Replace("%11","").Replace("%12","").Replace("%3%4%5%6%7%8%9%10","").Replace("%1",$fail.InsString1).Replace("%2",$fail.InsString2).Replace("%3",$fail.InsString3).Replace("%4",$fail.InsString4).Replace("%5",$fail.InsString5).Replace("%6",$fail.InsString6).Replace("%7",$fail.InsString7).Replace("%8",$fail.InsString8).Replace("%9",$fail.InsString9).Replace("%10",$fail.InsString10)
PS C:\\>
PS C:\\> $message
Distribution Manager failed to connect to the distribution point ["Display=\\\\CMGRDP1.contoso.com\\"]MSWNET:["SMS_SITE=PS1"]\\\\CMGRDP1.contoso.com\\. Check your network and firewall settings.
PS C:\\>
```

Now with the results of the query plus a beautifully formatted message you can store this into a
database or create your own reports and automations. Your imagination is the limit!

## Conclusion

Congratulations! You not only automated Configuration Manager Status Messages, but also called a
Win32 Native API function!

I hope you had as much fun trying this as me writing it.

Thank you very much, and I see you on the next trip!

## Useful links

- [Configuration Manager API Reference](https://docs.microsoft.com/mem/configmgr/develop/reference/configuration-manager-reference)
- [About Component Status Messages](https://docs.microsoft.com/mem/configmgr/develop/core/servers/manage/about-configuration-manager-component-status-messages)
- [FormatMessage Function winbase.h](https://docs.microsoft.com/windows/win32/api/winbase/nf-winbase-formatmessage)
- [LoadLibrary Function libloaderapi.h](https://docs.microsoft.com/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibrarya)
- [GetModuleHandle Function libloaderapi.h](https://docs.microsoft.com/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulehandlea)
- [Platform Invoke (P/Invoke)](https://docs.microsoft.com/dotnet/standard/native-interop/pinvoke)
- [FormatMessage on pinvoke.net (With examples!)](https://www.pinvoke.net/default.aspx/kernel32.formatmessage)
