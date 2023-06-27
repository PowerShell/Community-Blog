---
post_title: 'Measuring average download time'
username: francisconabas
categories: PowerShell
post_slug: measuring-download-time
tags: PowerShell, Automation, Performance, Measure-Command
summary: This post shows how to measure average download time with PowerShell
---

One of the most overlooked roles of a systems administrator is to be able to troubleshoot
network issues. How many times had you been in a situation where your servers are problematic,
and someone asked you to check the network connectivity?
One of the steps is checking downloading time, and speed, and although there are countless
tools available, today we will learn how to do it natively, with PowerShell.

## Methods

We will focus on three methods, ranging from the easiest to the most complex, and discuss
their pros and cons. These methods are the `Start-BitsTransfer` Cmdlet, using .NET with the
`System.Net` namespace, and using the Windows native API.

### Start-BitsTransfer

BITS, or Background Intelligent Transfer Service is a Windows service that manages content transfer
using HTTP or SMB. It was designed to manage the many aspects of content transfer, including cost,
speed, priority, etc.
For us, it also serves as an easy way of downloading files. Here is how you download a file from a
web server using BITS:

```powershell
$startBitsTransferSplat = @{
    Source = 'https://www.contoso.com/Files/BitsDefinition.txt'
    Destination = 'C:\BitsDefinition.txt'
}
Start-BitsTransfer @startBitsTransferSplat
```

Another great advantage of BITS is that it shows progress, which can be useful while
downloading big files. In our case however, we want to know how long does it take to
download a file. For this we will use a handy object of type `System.Diagnostics.Stopwatch`.

```powershell
$stopwatch = [System.Diagnostics.Stopwatch]::new()

$stopwatch.Start()
$startBitsTransferSplat = @{
    Source = 'https://www.contoso.com/Files/BitsDefinition.txt'
    Destination = 'C:\BitsDefinition.txt'
}
Start-BitsTransfer @startBitsTransferSplat
$stopwatch.Stop()

Write-Output $stopwatch.Elapsed
```

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 816
Ticks             : 8165482
TotalDays         : 9.45078935185185E-06
TotalHours        : 0.000226818944444444
TotalMinutes      : 0.0136091366666667
TotalSeconds      : 0.8165482
TotalMilliseconds : 816.5482
```

Awesome, we now have a baseline to build our script upon. First thing we will change is the file.
Since we are more interested on the speed we can use temporary files to download. That also
gives us the opportunity of cleaning up at the end. For this we will use a static method from
`System.IO.Path` called `GetTempFileName`. Other thing we must think is on running the test a number
of times, and calculating the average, this way we have more reliable results.

```powershell
# Changing the progress preference to hide the progress bar.
$ProgressPreference = 'SilentlyContinue'
$payloadUrl = 'https://www.contoso.com/Files/BitsDefinition.txt'
$stopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
$elapsedTime = [timespan]::Zero
$iterationNumber = 3

# Here we are using a foreach loop with a range,
# but this can also be accomplished with a for loop.
foreach ($iteration in 1..$iterationNumber) {
    $tempFilePath = [System.IO.Path]::GetTempFileName()

    $stopwatch.Restart()
    Start-BitsTransfer -Source $payloadUrl -Destination $tempFilePath
    $stopwatch.Stop()

    Remove-Item -Path $tempFilePath
    $elapsedTime = $elapsedTime.Add($stopwatch.Elapsed)
}

# Timespan.Divide is not available on .NET Framework.
if ($PSVersionTable.PSVersion -ge [version]'6.0') {
    $average = $elapsedTime.Divide($IterationNumber)
} else { $
    average = [timespan]::new($elapsedTime.Ticks / $IterationNumber)
}

return $average
```

Great, now we can run the test as many times as we want and get consistent results. This looping
system will also serve as a skeleton for the other methods we will try.

### System.Net.HttpWebRequest

Using `Start-BitsTransfer` is great because it's easy to set up, however is not the most efficient
way. BITS transfers have some overhead involved to start, maintain and cleanup jobs, manage
throttling, etc. If we want to keep our results as true as possible we need to go down in the
abstraction level.
This method uses the following workflow:

- Creates a **request** to the destination URI.
- Gets the **response**, and **response stream**.
- Creates the temporary file by opening a **file stream**.
- Downloads the binary data, and writes in the file stream.
- Closes the request, and file streams.

Here is what this implementation looks like:

```powershell
$uri = [uri]'https://www.contoso.com/Files/BitsDefinition.txt'

$stopwatch = [System.Diagnostics.Stopwatch]::new()

$request = [System.Net.HttpWebRequest]::Create($uri)

# If necessary you can set the download timeout in milliseconds.
$request.Timeout = 15000

$stopwatch.Restart()

# Receiving the first request, opening a file memory stream, and creating a buffer.
$responseStream = $request.GetResponse().GetResponseStream()
$tempFilePath = [System.IO.Path]::GetTempFileName()

$targetStream = [System.IO.FileStream]::new($tempFilePath, 'Create')

# You can experiment with the size of the byte array to try to get the best performance.
$buffer = [System.Byte[]]::new(10Kb)

# Reading data and writing to the file stream, until there is no more data to read.
do {
    $count = $responseStream.Read($buffer, 0, $buffer.Length)
    $targetStream.Write($buffer, 0, $count)

} while ($count -gt 0)

# Stopping the stopwatch, and storing the elapsed time.
$stopwatch.Stop()

# Disposing of unmanaged resources, and deleting the temp file.
$targetStream.Dispose()
$responseStream.Dispose()

Remove-Item -Path $tempFilePath

return $stopwatch.Elapsed
```

There are definitely more steps, and more points of failure, so how does it perform against
the BITS method? Here are the results of both methods, using the same file and 10 iterations.

**BITS**:

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 657
Ticks             : 6575274
TotalDays         : 7.61027083333333E-06
TotalHours        : 0.0001826465
TotalMinutes      : 0.01095879
TotalSeconds      : 0.6575274
TotalMilliseconds : 657.5274
```

**HttpWebRequest**:

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 315
Ticks             : 3151956
TotalDays         : 3.64809722222222E-06
TotalHours        : 8.75543333333333E-05
TotalMinutes      : 0.00525326
TotalSeconds      : 0.3151956
TotalMilliseconds : 315.1956
```

Looking good, a little less than half. Now we know we are closer to the real time spent downloading
the file. But the question is, if .NET it's also an abstraction layer, how low can we go?
The operating system, of course.

### Native

Although there are multiple abstraction layers on the OS itself,
there is a user-mode API defined in `Winhttp.dll` who's exported functions can be used in PowerShell
through Platform Invoke. This means, we need to use **C#** to create these function signatures in
managed .NET. Here is what that code looks like:

```csharp
namespace Utilities
{
    using System;
    using System.IO;
    using System.Runtime.InteropServices;

    public class WinHttp
    {
        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr WinHttpOpen(
            string pszAgentW,
            uint dwAccessType,
            string pszProxyW,
            string pszProxyBypassW,
            uint dwFlags
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr WinHttpConnect(
            IntPtr hSession,
            string pswzServerName,
            uint nServerPort,
            uint dwReserved
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern IntPtr WinHttpOpenRequest(
            IntPtr hConnect,
            string pwszVerb,
            string pwszObjectName,
            string pwszVersion,
            string pwszReferrer,
            string ppwszAcceptTypes,
            uint dwFlags
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool WinHttpSendRequest(
            IntPtr hRequest,
            string lpszHeaders,
            uint dwHeadersLength,
            IntPtr lpOptional,
            uint dwOptionalLength,
            uint dwTotalLength,
            UIntPtr dwContext
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool WinHttpReceiveResponse(
            IntPtr hRequest,
            IntPtr lpReserved
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool WinHttpQueryDataAvailable(
            IntPtr hRequest,
            out uint lpdwNumberOfBytesAvailable
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool WinHttpReadData(
            IntPtr hRequest,
            IntPtr lpBuffer,
            uint dwNumberOfBytesToRead,
            out uint lpdwNumberOfBytesRead
        );

        [DllImport("Winhttp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern bool WinHttpCloseHandle(IntPtr hInternet);
    }
}
```

Then we can use `Add-Type` to compile, and import this type in PowerShell.

```powershell
Add-Type -TypeDefinition (Get-Content -Path 'C:\WinHttpHelper.cs' -Raw)
```

After that, the method is similar to the .NET one, with a few more steps.
It makes sense being alike, because at some point .NET will call a Windows API. Note that
`Winhttp.dll` is not the only API that can be used to download files. This is what the PowerShell
code looks like:

```powershell
$stopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'

# Here we open a WinHttp session, connect to the destination host,
#and open a request to the file.
$hSession = [Utilities.WinHttp]::WinHttpOpen('NativeDownload', 0, '', '', 0)
$hConnect = [Utilities.WinHttp]::WinHttpConnect($hSession, $Uri.Host, 80, 0)
$hRequest = [Utilities.WinHttp]::WinHttpOpenRequest(
    $hConnect, 'GET', $Uri.AbsolutePath, '', '', '', 0
)

$stopwatch.Start()
# Sending the first request.
$boolResult = [Utilities.WinHttp]::WinHttpSendRequest(
    $hRequest, '', 0, [IntPtr]::Zero, 0, 0, [UIntPtr]::Zero
)
if (!$boolResult) {
    Write-Error 'Failed sending request.'
}
if (![Utilities.WinHttp]::WinHttpReceiveResponse($hRequest, [IntPtr]::Zero)) {
    Write-Error 'Failed receiving response.'
}

# Creating the temp file memory stream.
$tempFilePath = [System.IO.Path]::GetTempFileName()
$fileStream = [System.IO.FileStream]::new($tempFilePath, 'Create')

# Reading data until there is no more data available.
do {
    # Querying if there is data available.
    $dwSize = 0
    if (![Utilities.WinHttp]::WinHttpQueryDataAvailable($hRequest, [ref]$dwSize)) {
        Write-Error 'Failed querying for available data.'
    }

    # Allocating memory, and creating the byte array who will hold the managed data.
    $chunk = New-Object -TypeName "System.Byte[]" -ArgumentList $dwSize
    $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($dwSize)

    # Reading the data.
    try {
        $boolResult = [Utilities.WinHttp]::WinHttpReadData(
            $hRequest, $buffer, $dwSize, [ref]$dwSize
        )
        if (!$boolResult) {
            Write-Error 'Failed to read data.'
        }
    
        # Copying the data from the unmanaged pointer to the managed byte array,
        # then ing the data into the file stream.
        [System.Runtime.InteropServices.Marshal]::Copy($buffer, $chunk, 0, $chunk.Length)
        $fileStream.Write($chunk, 0, $chunk.Length)
    }
    finally {
        # Freeing the unmanaged memory.
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
    }

} while ($dwSize -gt 0)
$stopwatch.Stop()

# Closing the unmanaged handles.
[void][Utilities.WinHttp]::WinHttpCloseHandle($hRequest)
[void][Utilities.WinHttp]::WinHttpCloseHandle($hConnect)
[void][Utilities.WinHttp]::WinHttpCloseHandle($hSession)

# Disposing of the file stream will close the file handle, which will allow us
# to manage the file later.
$fileStream.Dispose()
$fileStream.Dispose()

Remove-Item -Path $tempFilePath

return $stopwatch.Elapsed
```

Now with all this extra work you might be asking, how does it perform?

**HttpWebRequest**:

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 281
Ticks             : 2819990
TotalDays         : 3.26387731481481E-06
TotalHours        : 7.83330555555556E-05
TotalMinutes      : 0.00469998333333333
TotalSeconds      : 0.281999
TotalMilliseconds : 281.999
```

**Native**:

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 249
Ticks             : 2497170
TotalDays         : 2.89024305555556E-06
TotalHours        : 6.93658333333333E-05
TotalMinutes      : 0.00416195
TotalSeconds      : 0.249717
TotalMilliseconds : 249.717
```

Wait, that's almost the same thing, why is that? We are calling the OS API directly!
Well, we are, but we are managing everything from PowerShell, while .NET is using compiled
code, from a library. So what if we add all the request work in our C# code, and use it as a method?
Here's what said method looks like:

```csharp
public static string NativeDownload(Uri uri)
{
    IntPtr hInternet = WinHttpOpen("NativeFileDownloader", 0, "", "", 0);
    if (hInternet == IntPtr.Zero)
        throw new SystemException(Marshal.GetLastWin32Error().ToString());

    IntPtr hConnect = WinHttpConnect(hInternet, uri.Host, 443, 0);
    if (hConnect == IntPtr.Zero)
        throw new SystemException(Marshal.GetLastWin32Error().ToString());

    IntPtr hReq = WinHttpOpenRequest(hConnect, "GET", uri.AbsolutePath, "", "", "", 0);
    if (hReq == IntPtr.Zero)
        throw new SystemException(Marshal.GetLastWin32Error().ToString());

    if (!WinHttpSendRequest(hReq, "", 0, IntPtr.Zero, 0, 0, UIntPtr.Zero))
        throw new SystemException(Marshal.GetLastWin32Error().ToString());

    if (!WinHttpReceiveResponse(hReq, IntPtr.Zero))
        throw new SystemException(Marshal.GetLastWin32Error().ToString());

    string tempFilePath = Path.GetTempFileName();
    FileStream fileStream = new FileStream(tempFilePath, FileMode.Create);
    uint dwBytes;
    do
    {
        if (!WinHttpQueryDataAvailable(hReq, out dwBytes))
            throw new SystemException(Marshal.GetLastWin32Error().ToString());

        byte[] chunk = new byte[dwBytes];
        IntPtr buffer = Marshal.AllocHGlobal((int)dwBytes);
        try
        {
            if (!WinHttpReadData(hRequest, buffer, dwBytes, out _))
                throw new SystemException(Marshal.GetLastWin32Error().ToString());

            Marshal.Copy(buffer, chunk, 0, chunk.Length);
            fileStream.Write(chunk, 0, chunk.Length);
        }
        finally
        {
            Marshal.FreeHGlobal(buffer);
        }
    } while (dwBytes > 0);

    WinHttpCloseHandle(hReq);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hInternet);

    fileStream.Dispose();

    return tempFilePath;
}
```

The results:

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 191
Ticks             : 1917438
TotalDays         : 2.21925694444444E-06
TotalHours        : 5.32621666666667E-05
TotalMinutes      : 0.00319573
TotalSeconds      : 0.1917438
TotalMilliseconds : 191.7438
```

And there we go, a slighter faster download, is the small improvement worth all the extra work?
I say yes, that gives us the opportunity to expand our Operating System knowledge.

## Bonus

Before we wrap up, we have calculated the average time, but what about the speed? How can my script
be as cool as those internet speed measuring websites? Well, We have the time, all we need is the
file size, and we can calculate the speed:

```powershell
$uri = [uri]'https://www.contoso.com/Files/BitsDefinition.txt'

# Getting the total file size in bytes.
$totalSizeBytes = [System.Net.HttpWebRequest]::Create($uri).GetResponse().ContentLength

# Elapsed time here is the result of the previous methods.
if ($Host.Version -ge [version]'6.0') { $average = $elapsedTime.Divide($IterationNumber) }
else { $average = [timespan]::new($elapsedTime.Ticks / $IterationNumber) }

# Calculating the speed in Bytes/second
$bytesPerSecond = $totalSizeBytes / $average.TotalSeconds

# Creating an output string based on the B/s result.
switch ($bytesPerSecond) {
    { $_ -gt 99 } { $speed = "$([Math]::Round($bytesPerSecond / 1KB, 2)) Kb/s" }
    { $_ -gt 101376 } { $speed = "$([Math]::Round($bytesPerSecond / 1MB, 2)) Mb/s" }
    { $_ -gt 103809024 } { $speed = "$([Math]::Round($bytesPerSecond / 1GB, 2)) Gb/s" }
    { $_ -gt 106300440576 } { $speed = "$([Math]::Round($bytesPerSecond / 1TB, 2)) Tb/s" }
    Default { $speed = "$([Math]::Round($bytesPerSecond, 2)) B/s" }
}

return [PSCustomObject]@{
    Speed = $speed
    TimeSpan = $average
}
```

```powershell-console
Speed    TimeSpan
-----    --------
3.6 Mb/s 00:00:00.2070106
```

## Conclusion

If you got to this point I hope you had as much fun as I did. You can find all the code we wrote
in my [GitHub page][01].

Until the next one, happy scripting!

- [Test our WindowsUtils module!][02]
- [See what I'm up to][03]

<!-- link references -->
[01]: https://github.com/FranciscoNabas/PowerShellPublic/blob/main/Get-DownloadAverageTimeAndSpeed.ps1
[02]: https://github.com/FranciscoNabas/WindowsUtils
[03]: https://github.com/FranciscoNabas
