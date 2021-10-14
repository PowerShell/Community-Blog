---
Categories: PowerShell
post_title: A closer look at the Crescendo configuration
Summary: In this post I take a closer look at a cmdlet definition in the Crescendo configuration file.
featured_image: https://devblogs.microsoft.com/powershell-community/wp-content/uploads/sites/69/2021/09/Crescendo.png
tags: Crescendo, cmdlet, json, configuration
username: sewhee@microsoft.com
---
In my [previous post][3], I looked at the details of a Crescendo output handler from my
[VssAdmin][7] module. In this post, I explain the details of a cmdlet definition in the Crescendo
JSON configuration file.

## The purpose of the configuration

The structure for the interface of a cmdlet is a reasonably predictable thing.

- The cmdlet uses a standard _Verb-Noun_ format
- The cmdlets take input using sets of parameters
- Cmdlets that make changes to the system support `-Confirm` and `-WhatIf` parameters

The pattern of the script code to support these fits a template.

The more difficult part of the cmdlet is in the code that does the work. Crescendo separates the
functional code (the output handler) from the cmdlet interface code. The Crescendo configuration
file defines the interfaces of cmdlets that you want Crescendo to create.

The Crescendo configuration file is a JSON file containing an array of cmdlet definitions. JSON
provides an expressive, structured syntax for defining the properties of objects. But so does,
PowerShell. So why use JSON and not a PowerShell data (PSD1) file? The answer is simple: schema!
Unlike PowerShell's PSD1 files, JSON supports a schema. Having a schema ensures that the syntax of
your definition is correct. And with tools like Visual Studio Code (VS Code), the schema provides
IntelliSense, making it easier to author.

## Defining a cmdlet interface

The structure of a cmdlet definition can be divided into three property categories in the JSON
file:

- Required properties
  - **Verb**
  - **Noun**
  - **OriginalName**
  - **OriginalCommandElements[]**
  - **OutputHandlers[]**
- As-required properties
  - **DefaultParameterSetName**
  - **Parameters[]**
- Nice-to-have properties
  - "Help" properties like **Description**, **Usage**, and **Examples[]**

You might notice that defining **Parameters** is optional. This is not uncommon. In my VssAdmin
module, the cmdlets `Get-VssProvider`, `Get-VssVolume`, and `Get-VssWriter` do not have parameters.
These simple cmdlets don't require any input to return the requested information.

Let's take a closer look at a simple cmdlet definition.

- The **Verb** and **Noun** properties form the name of the cmdlet.
- The **OriginalName** property contains the path to the native command that the cmdlet runs to get
  the output.
- The **OriginalCommandElements** is an array of strings that are passed to the native command as
  parameters. A typical CLI like `vssadmin` has its own set of commands that perform different
  actions. Those commands may have additional parameters. In this example, the
  `vssadmin list providers` command has no additional parameters.
- The **OutputHandlers** property is an array containing one or more handler definitions. The
  handlers receive the output of the native command and return an object containing the data parsed
  from the output.
  - The **HandlerType** can be `Inline`, `Function`, or `Script`. In this example I use `Function`.
  - The **Handler** is the name of the Script or Function to be called, or the actual PowerShell
    code to run if the type is `Inline`.

```json
{
    "$schema": "https://aka.ms/Crescendo/Schema.json",
    "Commands": [
        {
            "Verb": "Get",
            "Noun": "VssProvider",
            "OriginalName": "$env:Windir/system32/vssadmin.exe",
            "OriginalCommandElements": [
                "list",
                "providers"
            ],
            "Description": "List registered volume shadow copy providers",
            "Usage": {
                "Synopsis": "List registered volume shadow copy providers"
            },
            "Examples": [
                {
                    "Command": "Get-VssProvider",
                    "Description": "Get a list of VSS Providers",
                    "OriginalCommand": "vssadmin list providers"
                }
            ],
            "OutputHandlers": [
                {
                    "ParameterSetName": "Default",
                    "HandlerType": "Function",
                    "Handler": "ParseProvider"
                }
            ]
        }
    ]
}
```

The remaining properties -- **Description**, **Usage**, and **Examples** -- are optional.
Crescendo uses these values to create the comment-based help for the cmdlet when it creates the
module.

## Defining parameters and parameter sets

Some of the `vssadmin` commands have optional parameters that can be used in various combinations.
For example:

- `vssadmin List Shadows [/For=ForVolumeSpec] [/Shadow=ShadowId|/Set=ShadowSetId]` - 3 optional
  parameters in 2 parameter sets
- `vssadmin List ShadowStorage [/For=ForVolumeSpec|/On=OnVolumeSpec]` - 2 parameter sets with 1
  optional parameter each

Let's take a look at the help for `vssadmin Resize ShadowStorage`.

```
vssadmin 1.1 - Volume Shadow Copy Service administrative command-line tool
(C) Copyright 2001-2013 Microsoft Corp.

Resize ShadowStorage /For=ForVolumeSpec /On=OnVolumeSpec /MaxSize=MaxSizeSpec
    - Resizes the maximum size for a shadow copy storage association between
    ForVolumeSpec and OnVolumeSpec.  Resizing the storage association may cause shadow
    copies to disappear.  As certain shadow copies are deleted, the shadow copy storage
    space will then shrink.  If MaxSizeSpec is set to the value UNBOUNDED, the shadow copy
    storage space will be unlimited.  MaxSizeSpec can be specified in bytes or as a
    percentage of the ForVolumeSpec storage volume.  For byte level specification,
    MaxSizeSpec must be 320MB or greater and accepts the following suffixes: KB, MB, GB, TB,
    PB and EB.  Also, B, K, M, G, T, P, and E are acceptable suffixes.  To specify MaxSizeSpec
    as percentage, use the % character as the suffix to the numeric value.  If a suffix is not
    supplied, MaxSizeSpec is in bytes.

    Example Usage:  vssadmin Resize ShadowStorage /For=C: /On=D: /MaxSize=900MB
                    vssadmin Resize ShadowStorage /For=C: /On=D: /MaxSize=UNBOUNDED
                    vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=20%
```

The `vssadmin Resize ShadowStorage` command has three required parameters, but the third parameter
`/MaxSize` can take three different types of input. In PowerShell, we prefer fixed types for
parameter values. We can solve this by creating three different parameters, each used in a
different parameter set.

The following JSON defines the `Resize-VssShadowStorage` cmdlet. The definition starts with the
required properties and some help information. This definition also has **SupportsShouldProcess**
set to `true`. With this property, Crescendo adds the `[SupportsShouldProcess()]` attribute to the
cmdlet, which automatically adds the `-WhatIf` and `-Confirm` parameters.

The interesting part starts in the parameter definitions.

```json
  {
      "Verb": "Resize",
      "Noun": "VssShadowStorage",
      "OriginalName": "c:/windows/system32/vssadmin.exe",
      "OriginalCommandElements": [
          "Resize",
          "ShadowStorage"
      ],
      "Description": "Resizes the maximum size for a shadow copy storage association between ForVolumeSpec and OnVolumeSpec. Resizing the storage association may cause shadow copies to disappear. As certain shadow copies are deleted, the shadow copy storage space will then shrink.",
      "Usage": {
          "Synopsis": "Resize the maximum size of a shadow copy storage association."
      },
      "Examples": [
          {
              "Command": "Resize-VssShadowStorage -For C: -On C: -MaxSize 900MB",
              "Description": "Set the new storage size to 900MB",
              "OriginalCommand": "vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=900MB"
          },
          {
              "Command": "Resize-VssShadowStorage -For C: -On C: -MaxPercent '20%'",
              "Description": "Set the new storage size to 20% of the OnVolume size",
              "OriginalCommand": "vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=20%"
          },
          {
              "Command": "Resize-VssShadowStorage -For C: -On C: -Unbounded",
              "Description": "Set the new storage size to unlimited",
              "OriginalCommand": "vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=UNBOUNDED"
          }
      ],
      "SupportsShouldProcess": true,
      "DefaultParameterSetName": "ByMaxSize",
      "Parameters": [
          {
              "OriginalName": "/For=",
              "Name": "For",
              "ParameterType": "string",
              "ParameterSetName": [ "ByMaxSize", "ByMaxPercent", "ByMaxUnbound" ],
              "NoGap": true,
              "Description": "Provide a volume name like 'C:'"
          },
          {
              "OriginalName": "/On=",
              "Name": "On",
              "ParameterType": "string",
              "ParameterSetName": [ "ByMaxSize", "ByMaxPercent", "ByMaxUnbound" ],
              "Mandatory": true,
              "NoGap": true,
              "Description": "Provide a volume name like 'C:'"
          },
          {
              "OriginalName": "/MaxSize=",
              "Name": "MaxSize",
              "ParameterType": "Int64",
              "ParameterSetName": [ "ByMaxSize" ],
              "AdditionalParameterAttributes": [
                  "[ValidateScript({$_ -ge 320MB})]"
              ],
              "Mandatory": true,
              "NoGap": true,
              "Description": "New maximum size in bytes. Must be 320MB or more."
          },
          {
              "OriginalName": "/MaxSize=",
              "Name": "MaxPercent",
              "ParameterType": "string",
              "ParameterSetName": [ "ByMaxPercent" ],
              "AdditionalParameterAttributes": [
                  "[ValidatePattern('[0-9]+%')]"
              ],
              "Mandatory": true,
              "NoGap": true,
              "Description": "A percentage string like '20%'."
          },
          {
              "OriginalName": "/MaxSize=UNBOUNDED",
              "Name": "Unbounded",
              "ParameterType": "switch",
              "ParameterSetName": [ "ByMaxUnbound" ],
              "Mandatory": true,
              "Description": "Sets the maximum size to UNBOUNDED."
          }
      ],
      "OutputHandlers": [
          {
              "ParameterSetName": "ByMaxSize",
              "HandlerType": "Function",
              "Handler": "ParseResizeShadowStorage"
          },
          {
              "ParameterSetName": "ByMaxPercent",
              "HandlerType": "Function",
              "Handler": "ParseResizeShadowStorage"
          },
          {
              "ParameterSetName": "ByMaxUnbound",
              "HandlerType": "Function",
              "Handler": "ParseResizeShadowStorage"
          }
      ]
  }
```

The parameters have the following properties:

- **OriginalName** contains the original parameter used by the native command. Crescendo combines
  the value passed into the cmdlet with the original parameter string. The resulting native
  parameter is added to the original native command that gets executed by the cmdlet.
- **Name** is the name of the parameter for the PowerShell cmdlet you are defining.
- **ParameterType** is the type of the parameter for the cmdlet.
- **ParameterSetName** is an array of one or more parameter set names that the parameter belongs to.
- **AdditionalParameterAttributes** is an array of strings that contain any additional attribute you
  want added to the parameter. You can use this to add parameter validation attributes.
- **NoGap** tell Crescendo not so use a space between the **OriginalName** parameter and the value
  passed into the cmdlet.
- **Description** is the description of the parameter displayed by `Get-Help`.

For this cmdlet, the first two parameters `-For` and `-On` are in all three parameter sets. The
remaining three parameters are unique to each parameter set.

- The `-MaxSize` parameter accepts a 64-bit integer. That value is added to the `/MaxSize=` string
  to form the native parameter. The parameter validation ensures that the value passed in is greater
  than 320MB.
- The `-MaxPercent` parameter accepts a string containing a percentage value. That string is added
  to the `/MaxSize=` string to form the native parameter. The parameter validation ensures that the
  string represents a valid percentage.
- The `-Unbounded` switch parameter is used select a native parameter of `/MaxSize=UNBOUNDED`.

## Defining the output handlers

Since there are three parameters sets, I need to define an output handler for each set. You could
have a separate function for each set. In my case that was not necessary. The
`vssadmin Resize ShadowStorage` command does not have any output unless there is an error. Also,
since the command makes changes, I thought I should call `Get-VssShadowStorage` to show the new
settings.

```powershell
function ParseResizeShadowStorage {
    param(
        [Parameter(Mandatory)]
        $cmdResults
    )
    $textBlocks = ($cmdResults | Out-String) -split "`r`n`r`n"

    if ($textBlocks[1] -like 'Error*') {
        Write-Error $textBlocks[1]
    } elseif ($textBlocks[1] -like 'Success*') {
        Get-VssShadowStorage
    } else {
        $textBlocks[1]
    }
}
```

## The final step

Once the configuration file was complete, I used the `Export-CrescendoModule` cmdlet to create my
**VssAdmin** module.

```powershell
Export-CrescendoModule -ConfigurationFile vssadmin.crescendo.config.json -ModuleName VssAdmin.psm1
```

Crescendo created two new files:

- The module code file - `VssAdmin.psm1`
- The module manifest file - `VssAdmin.psd1`

These are the only two files that need to be installed. The `VssAdmin.psm1` file contains all the
cmdlets that Crescendo generated from the configuration and the Output Handler functions I wrote to
parse the output into objects.

## Conclusion

Crescendo separates the structural interface code required to create a cmdlet from the functional
code that extracts the data. The configuration file defines the cmdlet interfaces. The
`Export-CrescendoModule` cmdlet creates a new module containing the cmdlets defined in the
configuration (complete with the help text provided) and the output handler functions required by
the cmdlets. It also creates a proper module manifest, complete with exports for the new cmdlets.

## Resources

Posts in this series

- [My Crescendo journey][1]
  - [My VssAdmin module][7]
- [Converting string output to objects][2]
- [A closer look at a Crescendo Output Handler][3]
- A closer look at a Crescendo configuration file - this post

References

<!-- link reference -->
[1]: https://devblogs.microsoft.com/powershell-community/my-crescendo-journey/
[2]: https://devblogs.microsoft.com/powershell-community/converting-string-output-to-objects/
[3]: https://devblogs.microsoft.com/powershell-community/a-closer-look-at-the-parsing-code-of-a-crescendo-output-handler/
[7]: https://github.com/sdwheeler/tools-by-sean/tree/master/modules/vssadmin
