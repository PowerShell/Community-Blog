---
post_title: Convert Specific Table of Excel Sheet to JSON
username: sorastog
categories: PowerShell
tags: PowerShell, Excel, Json, Automation
summary: This posts explains how to Convert Specific Table of Excel Sheet to JSON
---

There is an excellent [script on GitHub][01] that helps to convert a full Excel sheet to JSON. The
script expects the table to be at the start of the sheet; that is, to have the first header in the
`A1` cell.

I had a little different requirement. I had to convert a specific table among various tables
available within a sheet in an Excel file as shown in image below.

![Screenshot of an Excel sheet showing a table in the middle of a sheet instead of at the start][02]

Our requirement is to read `Class 6` students' data. In the above screenshot, there are multiple
sheets within the Excel workbook. There are multiple tables like `Class 1`, `Class 2`, and so
on inside the **Science** sheet.

As our requirement is to read `Class 6` students data from **Science** sheet, lets look closely at
how the data is available in the Excel sheet.

- The name of the class is at row 44.
- The column headers are on row 45.
- The data starts from row 46.

[alert type="note" heading="Note"]
The tables can be at any location (any column and any row) within the sheet. The only fixed
identifier is **ClassName** which is `Class 6` in this example.
[/alert]

## Steps to follow

Follow these steps to see how you can read `Class 6` data from **Science** sheet:

1. Handle input parameters.

   The script accepts 3 parameters:

   - `$InputFileFullPath` - This is path of the input Excel file.
   - `$SubjectName` - This is name of the sheet inside the Excel file.
   - `$ClassName` - This is name of the table within the Excel sheet.

   ```powershell
   $InputFileFullPath = 'C:\Data\ABCDSchool.xlsx'
   $SubjectName       = 'Science'
   $ClassName         = 'Class 6'
   ```

1. Open the Excel file and read the **Science** sheet.

   ```powershell
   $excelApplication = New-Object -ComObject Excel.Application
   $excelApplication.DisplayAlerts = $false
   $Workbook = $excelApplication.Workbooks.Open($InputFileFullPath)

   $sheet = $Workbook.Sheets | Where-Object { $_.Name -eq $SubjectName }

   if (-not $sheet) {
       throw "Could not find subject '$SubjectName' in the workbook"
   }
   ```

1. Grab the `Class 6` table within the **Science** sheet to work with.

   ```powershell
   # Find the cell where Class name is mentioned
   $found           = $sheet.Cells.Find($ClassName)
   $beginAddress    = $Found.Address(0, 0, 1, 1).Split('!')[1]
   $beginRowAddress = $beginAddress.Substring(1, 2)
   # Header row starts 1 row after the class name
   $startHeaderRowNumber = [int]$beginRowAddress + 1
   # Student data row starts 1 row after header row
   $startDataRowNumber = $startHeaderRowNumber + 1
   $beginColumnAddress = $beginAddress.Substring(0, 1)
   # ASCII number of column
   $startColumnHeaderNumber = [BYTE][CHAR]$beginColumnAddress - 65 + 1
   ```

1. Extract the header column names (**Logical Seat Location**, **Actual Seat Location**,
   **LAN Port #**, **Monitor Cable Port**, **Student Name**, **Student#**, and **Room Type**)

   ```powershell
   $Headers          = @{}
   $numberOfColumns  = 0
   $foundHeaderValue = $true

   while ($foundHeaderValue -eq $true) {
       $headerCellValue = $sheet.Cells.Item(
           $startHeaderRowNumber,
           ($numberOfColumns + $startColumnHeaderNumber)
       ).Text

       if ($headerCellValue.Trim().Length -eq 0) {
           $foundHeaderValue = $false
       } else {
           $numberOfColumns++
           if ($Headers.ContainsValue($headerCellValue)) {
               # Do not add any duplicate column again.
           } else {
               $Headers.$numberOfColumns = $headerCellValue
           }
       }
   }
   ```

1. Extract the data (`Class 6` student information rows).

   ```powershell
   $results   = @{}
   $rowNumber = $startDataRowNumber
   $finish    = $false

   while ($finish -eq $false) {
       if ($rowNumber -gt 1) {
           $result = @{}

           foreach ($columnNumber in $Headers.GetEnumerator()) {
               $columnName = $columnNumber.Value
               # Student data row, student data column number
               $cellValue = $sheet.Cells.Item(
                   $rowNumber,
                   ($columnNumber.Name + ($startColumnHeaderNumber -1 ))
               ).Value2

               if ($cellValue -eq $null) {
                   $finish = $true
                   break;
               }

               $result.Add($columnName.Trim(), $cellValue.Trim())
           }

           if ($finish -eq $false) {
               # Adding Excel sheet row number for validation
               $result.Add("RowNumber",$rowNumber)
               $results += $result
               $rowNumber++
           }
       }
   }
   ```

1. Create the JSON file and close the Excel file.

   ```powershell
   $inputFileName = Split-Path $InputFileFullPath -leaf
   $inputFileName = $inputFileName.Split('.')[0]
   # Output file name will be "ABCDSchool-Science-Class 6.json"
   $jsonOutputFileName     = "$inputFileName-$SubjectName-$ClassName.json"
   $jsonOutputFileFullPath = [System.IO.Path]::GetFullPath($jsonOutputFileName)

   Write-Host "Converting sheet '$SubjectName' to '$jsonOutputFileFullPath'"

   $null = $results |
       ConvertTo-Json |
       Out-File -Encoding ASCII -FilePath $jsonOutputFileFullPath
   $null = $excelApplication.Workbooks.Close()
   $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
       $excelApplication
   )
   ```

## Putting it all together

The full code goes like this:

```powershell
param (
    # Excel name
    [Parameter(Mandatory=$true)]
    [string]$InputFileFullPath,
    # Sheet name
    [Parameter(Mandatory=$true)]
    [string]$SubjectName,
    # Identifier for the table
    [Parameter(Mandatory=$true)]
    [string]$ClassName
)

#region Open Excel file
$excelApplication = New-Object -ComObject Excel.Application
$excelApplication.DisplayAlerts = $false
$Workbook = $excelApplication.Workbooks.Open($InputFileFullPath)

# Find sheet
$sheet = $Workbook.Sheets | Where-Object { $_.Name -eq $SubjectName }

if (-not $sheet) {
    throw "Could not find subject '$SubjectName' in the workbook"
}
#endregion Open Excel file

#region Grab the table within sheet to work with
# Find the cell where Class name is mentioned
$found           = $sheet.Cells.Find($ClassName)
$beginAddress    = $Found.Address(0, 0, 1, 1).Split('!')[1]
$beginRowAddress = $beginAddress.Substring(1, 2)
# Header row starts 1 row after the class name
$startHeaderRowNumber = [int]$beginRowAddress + 2
# Student data row starts 1 row after header row
$startDataRowNumber = $startHeaderRowNumber + 1
$beginColumnAddress = $beginAddress.Substring(0,1)
# ASCII number of column
$startColumnHeaderNumber = [BYTE][CHAR]$beginColumnAddress - 65 + 1
#endregion Grab the table within sheet to work with

#region Extract Header Columns Name
$Headers          = @{}
$numberOfColumns  = 0
$foundHeaderValue = $true

while ($foundHeaderValue -eq $true) {
    $headerCellValue = $sheet.Cells.Item(
        $startHeaderRowNumber,
        ($numberOfColumns + $startColumnHeaderNumber)
    ).Text

    if ($headerCellValue.Trim().Length -eq 0) {
        $foundHeaderValue = $false
    } else {
        $numberOfColumns++
        if ($Headers.ContainsValue($headerCellValue)) {
            # Do not add any duplicate column again.
        } else {
            $Headers.$numberOfColumns = $headerCellValue
        }
    }
}
#endregion Extract Header Columns Name

#region Extract Student Information Rows
$results   = @()
$rowNumber = $startDataRowNumber
$finish    = $false

while ($finish -eq $false) {
    if ($rowNumber -gt 1) {
        $result = @{}

        foreach ($columnNumber in $Headers.GetEnumerator()) {
            $columnName = $columnNumber.Value
            # Student data row, student data column number
            $cellValue = $sheet.Cells.Item(
                $rowNumber,
                ($columnNumber.Name + ($startColumnHeaderNumber - 1))
            ).Value2

            if ($cellValue -eq $null) {
                $finish = $true
                break
            }

            $result.Add($columnName.Trim(),$cellValue.Trim())
        }

        if ($finish -eq $false) {
            # Adding Excel sheet row number for validation
            $result.Add("RowNumber",$rowNumber)
            $results += $result
            $rowNumber++
        }
    }
}
#endregion Extract Student Information Rows

#region Create JSON file and close Excel file
$inputFileName = Split-Path $InputFileFullPath -leaf
$inputFileName = $inputFileName.Split('.')[0]
# Output file name will be "ABCDSchool-Science-Class 6.json"
$jsonOutputFileName     = "$inputFileName-$SubjectName-$ClassName.json"
$jsonOutputFileFullPath = [System.IO.Path]::GetFullPath($jsonOutputFileName)

Write-Host "Converting sheet '$SubjectName' to '$jsonOutputFileFullPath'"

$null = $results |
    ConvertTo-Json |
    Out-File -Encoding ASCII -FilePath $jsonOutputFileFullPath
$null = $excelApplication.Workbooks.Close()
$null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
    $excelApplication
)
#endregion Create JSON file and close Excel file
```

The output JSON file will look like below:

```json
[
    {
        "Room Type":  "Standard",
        "RowNumber":  46,
        "Student Name":  "Alex",
        "Student#":  "RL45",
        "LAN Port #":  "LAN Port 7-8",
        "Logical Seat Location":  "SL 11",
        "Actual Seat Location":  "Seat43",
        "Monitor Cable Port":  "C-D"
    },
    {
        "Room Type":  "Standard",
        "RowNumber":  47,
        "Student Name":  "Alex",
        "Student#":  "RL45",
        "LAN Port #":  "LAN Port 5-6",
        "Logical Seat Location":  "SL 11",
        "Actual Seat Location":  "Seat43",
        "Monitor Cable Port":  "A-B"
    },
    {
        "Room Type":  "Standard",
        "RowNumber":  48,
        "Student Name":  "John",
        "Student#":  "RL47",
        "LAN Port #":  "LAN Port 3-4",
        "Logical Seat Location":  "SL 11",
        "Actual Seat Location":  "Seat43",
        "Monitor Cable Port":  "C-D"
    },
    {
        "Room Type":  "Standard",
        "RowNumber":  49,
        "Student Name":  "John",
        "Student#":  "RL47",
        "LAN Port #":  "LAN Port 1-2",
        "Logical Seat Location":  "SL 11",
        "Actual Seat Location":  "Seat43",
        "Monitor Cable Port":  "A-B"
    },
    {
        "Room Type":  "Standard",
        "RowNumber":  50,
        "Student Name":  "Victor",
        "Student#":  "RL35",
        "LAN Port #":  "LAN Port 7-8",
        "Logical Seat Location":  "SL 10",
        "Actual Seat Location":  "Seat33",
        "Monitor Cable Port":  "C-D"
    },
    {
        "Room Type":  "Standard",
        "RowNumber":  51,
        "Student Name":  "Victor",
        "Student#":  "RL35",
        "LAN Port #":  "LAN Port 5-6",
        "Logical Seat Location":  "SL 10",
        "Actual Seat Location":  "Seat33",
        "Monitor Cable Port":  "A-B"
    },
    {
        "Room Type":  "Standard",
        "RowNumber":  52,
        "Student Name":  "Honey",
        "Student#":  "RL42",
        "LAN Port #":  "LAN Port 3-4",
        "Logical Seat Location":  "SL 10",
        "Actual Seat Location":  "Seat33",
        "Monitor Cable Port":  "C-D"
    }
]
```

Feel free to drop your feedback and inputs on this page. Till then, Happy Scripting!!!

<!-- Link Reference Definitions -->
[01]: https://github.com/chrisbrownie/Convert-ExcelSheetToJson/blob/master/Convert-ExcelSheetToJson.ps1
[02]: ./media/Convert-Specific-Sheet-Of-Excel-Into-Json-Using-PowerShell/Image-MultipleTablesInOneSheet.png
