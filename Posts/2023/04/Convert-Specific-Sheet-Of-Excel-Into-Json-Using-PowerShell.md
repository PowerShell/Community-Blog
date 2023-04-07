---
post_title: Convert Specific Table of Excel Sheet to JSON
username: sorastog
categories: PowerShell
tags: PowerShell, Excel, Json, Automation
summary: This posts explains how to Convert Specific Table of Excel Sheet to JSON
---

# Summary

There is an excellent [Github script][01] available which helps in converting a full Excel sheet to
JSON. The table is from the start of the page i.e. from `A1` cell (as shown in image below).

![Image-Showing-One-Excel-Sheet][02]

I had a little different requirement. I had to convert a specific table among various tables
available within a sheet in an Excel file as shown in image below.

![Image-Showing-Multiple-Tables-In-One-Excel-Sheet][03]

Our requirement is to read **Class 6** students data. In above screenshot, there are multiple sheets
within the Excel workbook. There are multiple tables like **Class 1**, **Class 2**, and so on
inside the **Science** sheet.

As our requirement is to read **Class 6** students data from **Science** sheet, lets look closely at how
the data is available in Excel sheet.

- Name of the class is at row 44.
- Column Header is at row 45.
- Data starts from row 46.

Note - The tables can be at any location (any column and any row) within the sheet. The only fixed
identifier is TableName which is **Class 6** in this example.

## Steps to follow

Follow below steps to see how you can read **Class 6** data from **Science** sheet:-

1. Input Parameters

   The script accepts 3 parameters

   - `$InputFileFullPath`: This is path of input Excel file.
   - `$SubjectName`: This is name of the sheet inside Excel file.
   - `$ClassName`: This is name of the table within Excel sheet.

   ```powershell
   $InputFileFullPath = 'C:\Data\ABCDSchool.xlsx'
   $SubjectName       = 'Science'
   $ClassName         = 'Class 6'
   ```

1. Open Excel file and read the **Science** sheet

   ```powershell
   $excelApplication = New-Object -ComObject Excel.Application
   $excelApplication.DisplayAlerts = $false
   $Workbook = $excelApplication.Workbooks.Open($InputFileFullPath)

   $sheet = $Workbook.Sheets | Where-Object { $_.Name -eq $SubjectName }

   if (-not $sheet) {
       throw "Could not find subject '$SubjectName' in the workbook"
   }
   ```

1. Grab **Class 6** table within **Science** sheet to work with

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

1. Extract Header Columns Name (**Logical Seat Location**, **Actual Seat Location**, **LAN Port #**,
   **Monitor Cable Port**, **Student Name**, **Student#**, **Room Type**)

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

1. Extract Data Rows (**Class 6** Student Information Rows)

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

1. Create JSON file and close Excel file

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

## Output

Full code goes like this

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

The output JSON file will look like below

![Output-Json][04]

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
[02]: ./media/Convert-Specific-Sheet-Of-Excel-Into-Json-Using-PowerShell/Image1-OneExcelSheet.png
[03]: ./media/Convert-Specific-Sheet-Of-Excel-Into-Json-Using-PowerShell/Image2-MultipleTablesInOneSheet.png
[04]: ./media/Convert-Specific-Sheet-Of-Excel-Into-Json-Using-PowerShell/Image3-OutputJson.png
