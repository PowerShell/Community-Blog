---
post_title: Getting Yesterday's Date
username: tfl@psp.co.uk
Catagories: PowerShell
tags: .NET, Scripting Guys Update
Summary: Shows how to get a recent date and use that in your scripting.
---


**Q:** How can I get yesterday's date?

**A:** You can use a combination of the `Get-Date` cmdlet and .NET Time/Date methods.

First, let's look at dates in PowerShell and .NET
Then we can look at how to calculate yesterday and use that in your scripts.

## Dates in PowerShell

Let's start by looking at how you can deal with dates and times.
As you probably know, PowerShell contains the `Get-Date` cmdlet.
This cmdlet returns a .NET **System.DateTime** object.

Using the `Get-Date` cmdlet, you can get any date and time, and either display it or store it in a variable. 
To get today's date. you could do this:

```powershell-console
PS C:\> # Get the current date
PS C:\> Get-Date
08 January 2021 11:24:46

# Store the date in a variable
$Now = Get-Date
$Now
08 January 2021 11:24:47
```

As mentioned, the `Get-Date` cmdlet returns an object whose type is **System.DateTime**.
This .NET structure provides a rich set of properties and methods to help you manipulate the date/time object.
See the [System.DateTime documentation](https://docs.microsoft.com/dotnet/api/system.datetime) for more details on this structure.
A date and time object contains both a date and a time.
This means you can create an object with just a date or just a time, or both, which gives you huge flexibility in handling dates and times.

If you run `Get-Date` and specify no parameters, the cmdlet returns the current date and time.
There are several parameters you can specify that allow you to create an object for a particular date, like this:

```powershell-console
PS C:\> # Using the -Date Parameter and a date string
PS C:\> Get-Date -Date '1 August 1942'
01 August 1942 00:00:00

# Using the -Month, Day, Year to be specific and avoid parsing
PS C:\> Get-Date -Month 8 -Day 1 -Year 1942 -Hour 0 -Minute 0 -Second 0
01 August 1942 00:00:00
```

You can see the other features of `Get-Date` to help get the date in the exact format you need, see the [`Get-Date` help information](https://docs.microsoft.com/powershell/module/microsoft.powershell.utility/get-date?view=powershell-7.1).

## Obtaining Yesterday's Date

So as you can see, you can use `Get-Date` to return a specific date/time.
So how do you get yesterday's date - or the date or last month or last year?
The trick here is to use the object returned from `Get-Date`.
The object has a type of `System.DateTime` which contains a number of methods allowing you to add increments of time - a month, a day, etc to the object.

To get yesterday's date (or tomorrow's) you create a date and time object for today using `Get-Date` with no parameters.
Then you use the ``AddDays()`` method to add/subtract some number of days, like this:

```powershell-console
PS C:\> # Get today's Date
PS C:\> $Today     = Get-Date
PS C:\> $Yesterday = $Today.AddDays(-1)
PS C:\> $Yesterday
19 February 2021 12:13:51

PS C:\> # Or more simply
PS C:\> $Yesterday = (Get-Date).AddDays(-1)
PS C:\> $Yesterday
19 February 2021 12:13:52

PS C:> # Get tomorrow's date
PS C:> $Tomorrow  = (Get-Date).AddDays(1)
PS C:> $Tomorrow
21 February 2021 12:13:54
```

It is worth noting that a `System.DateTime` object is immutable.
This means you can not change property values after you create the object.
If you use any of the `Add` methods, .NET returns a new object with updated property values.

## Using Yesterday's Date

There are a variety use cases for getting a date in the past (or the future), including:

* Identifying files that are older/younger than a day/month/etc ago
* Determining which AD Users have not logged on in the last week
* Creating a file name for a file representing last weeks information.

Here are some examples:

```powershell-console
PS C:> # Finding files newer than yesterday
PS C:> $Yesterday = (Get-Date).AddDays(-1)
PS C:> Get-ChildItem | Where-Object LastAccessTime -gt $Yesterday

    Directory: C:\
    
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          20/02/2021    14:20          11041 GratefulDead Show List.txt

PS C:> # Getting users who have logged on in the past day
PS C:> Get-ADUser -Filter * -Property LastLogonDate | Where-Object LastlogonDate -gt $Yesterday

DistinguishedName : CN=Administrator,CN=Users,DC=cookham,DC=net
Enabled           : True
GivenName         : Jerry
LastLogonDate     : 20/02/2021 04:20:42
Name              : Jerry Garcia
ObjectClass       : user
ObjectGUID        : ae31ca0d-3f01-4eb4-8593-b1d79c71f912
SamAccountName    : JerryG
SID               : S-1-5-21-2550804810-443649076-1856842782-500
Surname           : Garcia

# Creating a file with yesterday's date
PS C:\> # Creating a file with today's date
PS C:\> $Yesterday     = (Get-Date).AddDays(-1).ToString() -replace '/','-'
PS C:\> $YesterdayDate = ($Yesterday -split ' ')[0]
PS C:\> $YesterdayFN   = "Results for $YesterdayDate.Txt"
PS C:\> 
PS C:\> New-Item -Path C:\Results -Name  $YesterdayFN -ItemType File

Directory: C:\Results

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          20/02/2021    12:56              0 Results for 19-02-2021.Txt
```

In that last example, you need to do a bit of manipulation of the date/time returned by `Get-Date` in order to get a filename that Windows accepts.
This manipulation is needed because `Get-Date` returns a string that contains the "/" character `New-Item` views as a path character.
You use the `-Replace` operator to replace the "/" character with a "-".
Additionally, after performing the replacement, you end up with an (unneeded) time value.
You can use the `-Split` operator to pull out just the date, which is what you want for the file name.
Once you do get the date, you can create you can create a file name for the file.

Another way to generate the file name based on `Get-Date` would be to use the **ToString()** method and specify the exact output you want, like this:

```powershell
$YesterdayDate = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')         
$YesterdayFN   = "Results for $YesterdayDate.Txt"
```

Another point worth making is that Windows tries to display dates in a culture-aware way.
`Get-Date` does a fairly good job in most cases of converting a date string into the date you wanted.
But if you want a specific result, using **ToString()** and a date format string is possibly better - and fewer lines of code.

Needless to say, you could do all those file name manipulations operations as a one-liner.
I leave that as an exercise for you!

## Summary

.NET provides a rich date and time structure (`System.DateTime`).
This structure contains a number of properties such the day, month, hour, millisecond for a given date/time.
You also get a wide range of methods that enable you to manipulate dates by adding or subtracting hours, days, etc.
You can use `Get-Date` cmdlet to get the current date/time or an object for a specific date/time.
Get-Date returns an object of System.DateTime.
You use the methods of the `System.DateTime` structure to get relative dates, such as yesterday, last month or 2 years 42 days, and 32 milliseconds.

## Tip of the Hat

This article is based on an earlier Scripting Guys blog article at [How can I get yesterday's date?](https://devblogs.microsoft.com/scripting/how-can-i-get-yesterdays-date).
Not sure who wrote it.
