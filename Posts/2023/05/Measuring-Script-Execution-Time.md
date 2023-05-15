---
post_title: 'Measuring script execution time'
username: francisconabas
categories: PowerShell
tags: PowerShell, Automation, Performance, Measure-Command
summary: This post shows how to measure script execution time in PowerShell
---

Most of the time while developing PowerShell scripts we don't need to worry about performance, or
execution time. After all, scripts were made to run automation in the background. However, as your
scripts become more sophisticated, and you need to work with complex data or big data sizes,
performance becomes something to keep in mind. Measuring a script execution time is the first step
towards script optimization.

## Measure-Command

PowerShell has a built-in cmdlet called `Measure-Command`, which measures the execution time of
other cmdlets, or script blocks. It has two parameters:

- **Expression**: The script block to be measured.
- **InputObject**: Optional input to be passed to the script block. You can use `$_` or `$PSItem` to
  access them.

Besides the two parameters, objects in the pipeline are also passed to the script block.
`Measure-Command` returns an object of type `System.TimeSpan`, giving us more flexibility on how to
work with the result.

```powershell
Measure-Command { foreach ($number in 1..1000) { <# Do work #> } }
```

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 8
Ticks             : 85034
TotalDays         : 9.84189814814815E-08
TotalHours        : 2.36205555555556E-06
TotalMinutes      : 0.000141723333333333
TotalSeconds      : 0.0085034
TotalMilliseconds : 8.5034
```

Using the pipeline or the **InputObject** parameter.

```powershell
1..1000 |
    Measure-Command -Expression { foreach ($number in $_) { <# Do work #> } } |
    Select-Object TotalMilliseconds
```

```powershell-console
TotalMilliseconds
-----------------
            10.60
```

```powershell
Measure-Command -InputObject (1..1000) -Expression { $_ | % { <# Do work #> } } |
    Select-Object TotalMilliseconds
```

```powershell-console
TotalMilliseconds
-----------------
            19.98
```

## Scope and Object Modification

`Measure-Command` runs the script block in the current scope, meaning variables in the current scope
gets modified if referenced in the script block.

```powershell
$studyVariable = 0
Measure-Command { 1..10 | % { $studyVariable += 1 } }
Write-Host "Current variable value: $studyVariable."
```

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 15
Ticks             : 155838
TotalDays         : 1.80368055555556E-07
TotalHours        : 4.32883333333333E-06
TotalMinutes      : 0.00025973
TotalSeconds      : 0.0155838
TotalMilliseconds : 15.5838

Current variable value: 10.
```

To overcome this, you can use the invocation operator `&` and enclose the script block in `{}`, to
execute in a separate context.

```powershell
$studyVariable = 0
Measure-Command { & { 1..10 | % { $studyVariable += 1 } } }
Write-Host "Current variable value: $studyVariable."
```

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 8
Ticks             : 86542
TotalDays         : 1.00164351851852E-07
TotalHours        : 2.40394444444444E-06
TotalMinutes      : 0.000144236666666667
TotalSeconds      : 0.0086542
TotalMilliseconds : 8.6542

Current variable value: 0.
```

It's also worth remember that if your script block modifies system resources, files, databases or
any other static data, the object gets modified.

```powershell
$scriptBlock = {
    if (!(Test-Path -Path C:\SuperCoolFolder)) {
        New-Item -Path C:\ -Name SuperCoolFolder -ItemType Directory
    }
}

Measure-Command -Expression { & $scriptBlock }
Get-ChildItem C:\ -Filter SuperCoolFolder | Select-Object FullName
```

```powershell-console
Days              : 0
Hours             : 0
Minutes           : 0
Seconds           : 0
Milliseconds      : 11
Ticks             : 118978
TotalDays         : 1.37706018518519E-07
TotalHours        : 3.30494444444444E-06
TotalMinutes      : 0.000198296666666667
TotalSeconds      : 0.0118978
TotalMilliseconds : 11.8978

FullName : C:\SuperCoolFolder
```

As a cool exercise, try figuring out why the output from `New-Item` didn't show up.

## Output and Alternatives

`Measure-Command` returns a `System.TimeSpan` object, but not the result from the script. If your
study also includes the result, there are two ways you can go about it.

### Saving the output in a variable

We know that scripts executed with `Measure-Object` runs in the current scope. So we could assign
the result to a variable, and work with it.

```powershell
$range = 1..100
$evenCount = 0
$scriptBlock = {
    foreach ($number in $range) {
        if ($number % 2 -eq 0) {
            $evenCount++
        }
    }
}

Measure-Command -InputObject (1..100) -Expression $scriptBlock |
    Format-List TotalMilliseconds
Write-Host "The count of even numbers in 1..100 is $evenCount."
```

```powershell-console
TotalMilliseconds : 1.3838

The count of even numbers in 1..100 is 50.
```

### Custom Function

If you are serious about the performance variable, and want to keep the script block as clean as
possible, we could elaborate our own function, and shape the output as we want.

The `Measure-Command` Cmdlet uses an object called `System.Diagnostics.Stopwatch`. It works like a
real stopwatch, and we control it using its methods, like `Start()`, `Stop()`, etc. All we need to
do is start it before executing our script block, stop it after execution finishes, and collect the
result from the **Elapsed** property.

```powershell
function Measure-CommandEx {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Expression,

        [Parameter(ValueFromPipeline)]
        [psobject[]]$InputObject
    )

    Begin {
        $stopWatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'

        <#
            We need to define result as a list because the way objects
            are passed to the pipeline. If you pass a collection of objects,
            the pipeline sends them one by one, and the result
            is always overridden by the last item.
        #>
        [System.Collections.Generic.List[PSObject]]$result = @()
    }

    Process {
        if ($InputObject) {

            # Starting the stopwatch.
            $stopWatch.Start()

            # Creating the '$_' variable.
            $dollarUn = New-Object -TypeName psvariable -ArgumentList @('_', $InputObject)

            <#
                Overload is:
                    InvokeWithContext(
                        Dictionary<string, scriptblock> functionsToDefine,
                        List<psvariable> variablesToDefine,
                        object[] args
                    )
            #>
            $result.AddRange($Expression.InvokeWithContext($null, $dollarUn, $null))

            $stopWatch.Stop()
        }
        else {
            $stopWatch.Start()
            $result.AddRange($Expression.InvokeReturnAsIs())
            $stopWatch.Stop()
        }
    }

    End {
        return [PSCustomObject]@{
            ElapsedTimespan = $stopWatch.Elapsed
            Result = $result
        }
    }
}
```

Note that there is overhead when using the **InputObject** parameter, meaning there is a
difference in the overall execution time.

## Conclusion

I hope you, like me, learned something new today, and had fun along the way.

Until a next time, happy scripting!

## Links

- [Measure-Command][01]
- [InvokeWithContext Method][02]
- [InvokeReturnAsIs Method][03]
- [Test our WindowsUtils module!][04]
- [See what I'm up to][05]

<!-- link references -->
[01]: https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/measure-command
[02]: https://learn.microsoft.com/dotnet/api/system.management.automation.scriptblock.invokewithcontext
[03]: https://learn.microsoft.com/dotnet/api/system.management.automation.scriptblock.invokereturnasis
[04]: https://github.com/FranciscoNabas/WindowsUtils
[05]: https://github.com/FranciscoNabas
