---
post_title: Mastering the (steppable) pipeline
username: boderonald
categories: PowerShell
tags: PowerShell, Pipeline, Steppable
summary: The PowerShell pipeline explained from the beginning to the end.
---

# Mastering the (steppable) pipeline

Before stepping into the *steppable* pipeline, it is essential that you have a good understanding of how *and when* exactly items are processed by a [cmdlet](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-overview) in the pipeline. The PowerShell pipeline might just look like syntactical sugar but it is a lot more than that. In fact, it really *acts* like a pipeline where each item flows through and is handled by each cmdlet one-at-a-time.
In comparison to the pipes in CMD, PowerShell streams *objects* through the pipeline rather than plain text.

## One-at-a-time `process`

The following explanation describes the **one-at-a-time processing** section of the [About pipelines](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_pipelines#one-at-a-time-processing) document.
A good analogy of the pipeline is a physical assembly line where each consecutive station on the line could be compared with a PowerShell cmdlet. At a specific station and time, some something is done to one item while the next item is prepared at the prior station. For example, at station 2 a component is soldered to the assembly while the next item is being unpacked at station 1. Items iterate through the pipeline like:

**Iteration: `n`**

```
 item 3  --> item 2  --> item 1
Station 1 | Station 2 | Station 3
```

**Iteration: `n + 1`**

```
 item 4  --> item 3  --> item 2
Station 1 | Station 2 | Station 3
```

Cmdlets act like stations in the assembly line, taken a simple example:

```PowerShell
Get-Content .\Input.txt | Foreach-Object { $_ } | Set-Content .\Output.txt
```

In this example the `Foreach-Object { $_ }` cmdlet does nothing more than:

* picking up each item from the pipeline that has been output by the prior cmdlet `Get-Content .\Input.txt`
* placing it back on the pipeline as an input for the next cmdlet `Set-Content .\Output.txt`.

To visualize the order of the items that go through the `Foreach-Object { $_ }` cmdlet you might use the `Trace-Command` cmdlet but that might overwhelm you with data. Instead, using two simple `ForEach-Object` (alias `%`) test commands show you exactly where your measure points are and what goes in and come out the specific cmdlet in between.

- `%{Write-Host 'In:' $_; $_ }`
- `%{Write-Host 'out:' $_; $_ }`

Notice that `...; $_ }` in the end of the command will place the current item back on the pipeline.
In the following example, the cmdlet at the start of the pipeline  (`Get-Content .\Input.txt`) has been replaced with 4 hardcoded input items (`1,2,3,4`)  and the cmdlet at the end of the pipeline  (`Set-Content .\Output.txt`) with `Out-Null` which simply purges the actual output of the pipeline so that only the two test cmdlets produce an output.

```PowerShell
1,2,3,4 | %{Write-Host 'In:' $_; $_ } | Foreach-Object { $_ } | %{Write-Host 'Out:' $_; $_ } | Out-Null
```

This shows the following output:

```Console
In: 1
Out: 1
In: 2
Out: 2
In: 3
Out: 3
In: 4
Out: 4
```

This proves that each item flows out of the pipeline (`Out: 1`) before the next item (`In: 2`) is injected into it.
As you can imagine, this conserves memory as there are only a few items in the pipeline at any time.

## Chocking the pipeline

The previous section explains how a cmdlet would perform if correctly implemented for the middle of a pipeline but there are a few statements that might "**choke**" the pipeline, meaning that the items are no longer processed **one-at-the-time** but piled up in memory and eventually processed **all-at-once**. This happens for:

* **Assigning the pipeline to a variable**:

  ```PowerShell
  $Content = Get-Content .\Input.txt | Foreach-Object { $_ }
  $Content | Set-Content .\Output.txt
  ```

* **Using parentheses**:

  ```PowerShell
  (Get-Content .\Data.txt | Foreach-Object { $_ }) | Set-Content .\Data.txt
  ```

* **Some cmdlets might choke the pipeline by design:**

  In general, a well defined cmdlet should write single records to the pipeline. See the [Strongly Encouraged Development Guidelines](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines) article.

  Yet this is not always possible. Take, for example, the `Sort-Object` cmdlet, which is supposed to sort an object collection. This might result is a new list where the last item ends up first. To determine what item comes first, you must collect all items before they can be sorted. This is visible from the simple test commands used before:

```PowerShell
1,2,3,4 | %{Write-Host 'In:' $_; $_ } | Sort-Object | %{Write-Host 'Out:' $_; $_ } | Out-Null
```

This shows the following output:

```Console
In: 1
In: 2
In: 3
In: 4
Out: 1
Out: 2
Out: 3
Out: 4
```

In general, you should avoid chocking the pipeline, but their are few exceptions where it might be required. For example, where you want to read and write back to the same file as in the previous "using parenthesis" example.

In a smooth pipeline, each item is processed one-at-the-time, meaning that `Get-Content` and `Set-Content` are concurrently processing items in the pipeline. This causes the following error:

> The process cannot access the file '.\Data.txt' because it is being used by another process.  

In this situation, chocking the pipeline and reading the complete file first avoids the error.

### Heavy objects

Objects in the PowerShell pipeline contain more than just the value of the item. They also include properties such as the name and type of the item and of all the properties. Take, for example, the .NET `DataTable` object. The header of a `DataTable` object contains the column (property) names and types where each row in the `DataTable` only contains the value of each column. If you convert a `DataTable` into a list of PowerShell objects, like:
```PowerShell
$Data = $DataTable | Foreach-Object { $_ }
```

PowerShell converts each row into a new object, duplicating the header information for each row. The memory usage considerably increases even if the value is just a few bytes. This extra overhead shouldn't be an issue if you stream the objects through the pipeline because there will only be a few objects in the pipeline at any time.

### Missing properties

A limitation of the PowerShell pipeline is that even each object in the pipeline contains all the member (including properties) information about the current item ( named `$PSItem` or just `$_`). It still might not be enough to define a unified output headers for all the object that might follow.
Consider the following two objects being converted to a Csv list:

```PowerShell
$a = [pscustomobject]@{ name='John'; address='home'}
$b = [pscustomobject]@{ name='Jane'; phone='123'}
$a, $b |Format-Table
```

Results

```Console
name address
---- -------
John home
Jane
```

Notice that there is no `phone` column, meaning that the `phone='123'` property is missing from the results. This is actually due to the one-at-a-time processing: at the moment the `Format-Table` cmdlet receives object `$a` it is supposed to process it immediately by writing it to the console and release it in order to be able to process any following items. The issue is that the `Format-Table` cmdlet is yet unaware of the next object `$b` (which isn't even instantiated and not even exist yet in the pipeline) but the initial output is already written to the console.
In other words, a cmdlet written for one-at-a-time processing bases its output on the first object received from the pipeline. This also implies that if you change the order of the items in the pipeline (e.g. with `$a,  $b  Sort-Object | Format-Table`) properties might reappear and/or disappear.  

### Processing blocks

As you might have noticed, some actions, like outputting a header, are only required only ones. As in the analogy with the assembly line, heating up a soldering gun is only required ones when the pipeline is started, cleaning up the station is only required when the pipeline is completed. Similar time consuming ("expensive") actions could be required for a cmdlet as e.g. open and closing a file. These actions are respectively defined in the `Begin` - and  `End` block of a cmdlet. The actual processing is defined in the `Process` block of cmdlet.
A well defined pipeline PowerShell cmdlet might look like this:

```PowerShell
function MyCmdlet {
    [CmdletBinding()] param(
        [Parameter(ValueFromPipeLine = $True)][String] $InputString
    )
    Begin {
        $Stream = [System.IO.StreamWriter]::new("$($Env:Temp)\My.Log")
    }
    Process {
        $Stream.WriteLine($_)
    }
    End {
        $Stream.Close()
    }
}
```

Using the above cmdlet example with the command like `1..9 | MyCmdlet`, the log file is *only opened once* at the start of the pipeline, than each item in the pipeline is process one-at-a-time and at the end the log file is closed (*once*).
Note that when there are no `Begin`, `Process` and  `End` processing blocks defined in a function, the content of the function is assigned to the `End` block. See also: [about Functions Advanced Methods](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods)

A similar pipeline can be created with the common [`Foreach-Object`](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/foreach-object) cmdlet using the `-Begin`, `-Process` and `-End` parameters to define the corresponding process blocks:

```PowerShell
1..9 | Foreach-Object -Begin {
    $Stream = [System.IO.StreamWriter]::new("$($Env:Temp)\My.Log")
} -Process {
    $Stream.WriteLine($_)
} -End {
    $Stream.Close()
}
```

### Performance

With the above explanation of the pipeline, you might understand now why you shouldn't wrap cmdlet pipeline in other pipeline, like:

```PowerShell
1..9 | ForEach-Object {
    $_ | MyCmdlet
}
```

Wrapping a cmdlet pipeline into another (`ForEach-Object`) pipeline is very expensive because you're also invoking the `begin` and `end` block of `MyCmdlet` which will open and close the concerned log file for each specific item instead of only once (at the beginning and the end of the pipeline). The performance degradation appears with native cmdlets along with `Export-Csv -append` and `Add-Content`. See also [PowerShell scripting performance considerations](https://learn.microsoft.com/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations#avoid-wrapping-cmdlet-pipelines)

## The steppable pipeline

Unfortunately, it is not always possible to create a single syntactical pipeline as you might e.g. need different branches for different parameters, as output paths, along the road. Consider a very large `csv` file which you want to cut in smaller batch files. The obvious approach is:

```PowerShell
$BatchSize = 10000
Import-Csv .\MyLarge.csv | ForEach-Object -Begin { $Index = 0 } -Process {
    $BatchNr = [math]::Floor($Index++/$BatchSize)
    $_ | Export-Csv -append .\Batch$BatchNr.csv
}
```

But as stated this before, this will open and close each output file (`.\Batch$BatchNr.csv` ) 10,000 times where it only needs to be opened and closed once per output file. So, the solution here is to use a steppable pipeline which lets you independently define the processing blocks for the required output stream:

```PowerShell
$BatchSize = 10000
Import-Csv .\MyLarge.csv | ForEach-Object -Begin { $Index = 0 } -Process {
    if ($Index % $BatchSize -eq 0) {
        $BatchNr = [math]::Floor($Index++/$BatchSize)
        $Pipeline = { Export-Csv -notype -Path .\Batch$BatchNr.csv }.GetSteppablePipeline()
        $Pipeline.Begin($True)
    }
    $Pipeline.Process($_)
    if ($Index++ % $BatchSize -eq 0) { $Pipeline.End() }
} -End { $Pipeline.End() }
```

Every 10,000 (`$BatchSize`) entries, the modulus (`%`) is zero and a new pipeline is created for the expression `{ Export-Csv -notype -Path .\Batch$BatchNr.csv }`.

* The `$Pipeline.Begin($True)` invokes the `Begin` block of the steppable pipeline, which opens an new `csv` file named `.\Batch$BatchNr.csv` and writes the headers to the file.
* The `$Pipeline.Process($_)` invokes the `Process` block of the steppable pipeline using the current item (`$_`), which is appended to the `csv` file.
* The `$Pipeline.End()`invokes the `End` block of the steppable pipeline which closes the `csv` file named `.\Batch$BatchNr.csv`. This file holds a total of 10,000 entries.  

(Note that it is important to end the pipeline but there is no harm in invoking the `$Pipeline.End()` multiple times.)

It is a little more code, but if you measure the results you will see that in this situation the later script is more than 50 times faster than the one with the wrapped cmdlet pipeline.

### Multiple output pipelines

With the steppable pipeline technique, you might even have multiple output pipelines open at once. Consider that for the very large `csv` file in the previous example, you do not want batches of 10,000 entries but divide the entries over 26 files based on the first letter of the `LastName` property:

```PowerShell
$Pipeline = @{}
Import-Csv .\MyLarge.csv |
    ForEach-Object -Process {
        $Letter = $_.LastName[0].ToString().ToUpper()
        if (!$Pipeline.Contains($Letter)) {
            $Pipeline[$Letter] = { Export-CSV -notype -Path .\$Letter.csv }.GetSteppablePipeline()
            $Pipeline[$Letter].Begin($True)
        }
        $Pipeline[$Letter].Process($_)
    } -End {
        foreach ($Key in $Pipeline.Keys) { $Pipeline[$Key].End() }
    }
```

**Explanation:**

* `Import-Csv .\MyLarge.csv | ForEach-Object -Process {`
  processes each (One-at-a-time) item of the `csv` file
* `$Letter = $_.LastName[0].ToString().ToUpper()`
  Takes the first character of the `LastName` property and puts that in upper case.
* `if  (!$Pipeline.Contains($Letter))  {`
  If the pipeline for the specific character doesn't yet exist:
  * Open a new steppable pipeline for the specific letter:`{  Export-CSV  -notype -Path .\$Letter.csv }.GetSteppablePipeline()`
  * And invoke the `Begin` block: `.Begin($True)` which creates a new `csv` file with the concerned headers
* `foreach  ($Key in $Pipeline.Keys)  {  $Pipeline[$Key].End()  }`
  Closes all the existing steppable pipelines (aka `csv` files)

### See also

* [About pipelines](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_pipelines)
* [Cmdlet Overview](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-overview)
* [Strongly Encouraged Development Guidelines](h/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)
* [About Functions Advanced Methods](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods)
* [PowerShell scripting performance considerations](https://learn.microsoft.com/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations)
