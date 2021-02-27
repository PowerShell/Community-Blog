---
post_title: 'Leveraging XML with New Employee PowerShell Scripts'
username: s-r-turner
categories: PowerShell
tags: XML, ActiveDirectory
featured_image:
summary: using XML referencing to bolster up your new employee scripts with information.
---

I'm going to show how you can leverage XML files for referencing information, to help bolster up your Active Directory user accounts. 
This will ensure things such as Outlook contact cards are correct but also allows you to use this information at a later date, e.g. creating dynamic distribution lists based on office locations, or setting NTFS permissions on fire evacuation plans for specific floors in buildings.
Using XML allows for non-PowerShell savvy users to jump into the files and amend or add address information. Meaning less plain text strings in scripts.

## Scenario

You have multiple subsidiary companies that each have their own individual sets of offices and addresses. 
You need to ensure that each new user you create has the correct address and contact information based on where they are working.
Whilst in this post I am talking about User Accounts, there is no reason why you can't apply the same logic for Computer Accounts or Resources. 
No one likes asking around for the location of a meeting room you were supposed to be in 10 minutes ago!

## Getting Started - Creating the XML

To create the xml, we're going to use the [XmlWriter](https://docs.microsoft.com/dotnet/api/system.xml.xmlwriter) class, put this into a variable to build upon and add some formatting options (this makes it easier to see groups of information). Like so:

```powershell
$XMLPath = "C:\Users\sam\AD-References.xml"
$XMLWriter = New-Object System.XML.XMlTextWriter($XMLPath,$null)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$XmlWriter.IndentChar = "`t"
```

If you run that, nothing crazy happens. We have a new xml source file, with nothing inside; we have set ourselves up to flesh it out.

```powershell
# write the header
$xmlWriter.WriteStartDocument()
# set XSL statements
$xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
$XMLWriter.WriteStartElement('Companies')
```

Okay awesome, now we're getting somewhere. We have started our "Companies" element. Let's create a company and add some office information beneath that. Then we'll finalise the XML document.

```powershell
# Start Company 1
$XMLWriter.WriteStartElement('Company-1')

# Create Birmingham Office
$xmlWriter.WriteStartElement('Birmingham')
$XmlWriter.WriteElementString('Street', 'Unit 77, 132 Dummy Lane')
$XmlWriter.WriteElementString('City', 'Birmingham')
$XMLWriter.WriteElementString('State', 'Staffordshire')
$XMLWriter.WriteElementString('Postcode', 'B1 1BB')
$XMLWriter.WriteElementString('Country', 'GB')
$XMLWriter.WriteEndElement()

#End Company 1
$XMLWriter.WriteEndElement()

# Finish up document
$XMLWriter.WriteEndElement()
$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()
```

So, let's see the finished XML after we run this code.

```xml
<?xml version="1.0"?>
<?xml-stylesheet type='text/xsl' href='style.xsl'?>
<Companies>
	<Company-1>
		<Birmingham>
			<Street>Unit 77, 132 Dummy Lane</Street>
			<City>Birmingham</City>
			<State>Staffordshire</State>
			<Postcode>B1 1BB</Postcode>
			<Country>GB</Country>
		</Birmingham>
	</Company-1>
</Companies>
```

## PowerShell - Working With XML

So, now we have some useable data to work with PowerShell on. You can add more elements for Offices/Companies you are creating users for. It becomes clear how you reference this next. 

Tip: Save your XML-Creation script in the same location as the script referencing it; this makes for easier path variables, but also allows you to quickly create it, should the xml go missing.

```powershell

    # Load up the XML for reference later, if it's been deleted recreate it using the creation script.

    $XMLPath = "$PSScriptRoot\AD-References.xml"
    
    if (Test-Path $XMLPath) {
        
        $XML = New-Object -TypeName XML
        $XML = [XML] (Get-Content $XMLPath)
    }
    else {
        Start-Process "$PSScriptRoot\Write-XML.ps1" -Wait
        $XML = New-Object -TypeName XML
        $XML = [XML] (Get-Content $XMLPath)
    }
    
```

Here, we are testing the path for the XML and, if it doesn't exist, running the creation script again. Then, we're loading it into a variable for reference.

We can gather information for the new users by making use of `Read-Host` and some added validation. Like so:

```powershell
[ValidatePattern("\w+")]$FirstName = Read-Host -Prompt "Please input users first name"
[ValidatePattern("\w+")]$LastName = Read-Host -Prompt "Please input users last name"
[ValidatePattern("\w+")]$Company = Read-Host -Prompt "Please input users company"
[ValidatePattern("\w+")]$Office = Read-Host -Prompt "Please input users office"
```

Dead simple. 4 questions with 4 answers, into 4 variables. Instead of asking lots of questions to find out information like postcode or country, let's use our XML!

```powershell
# Declare some more variables
$FirstInitial = "$FirstName.substring(0,1)"
$Path = 'OU=Users,OU=Contoso,DC=Contoso,DC=com'

# Build hashtable of new user parameters
  $NewUserParams =@{
        GivenName = $FirstName
        Name = "$FirstName $LastName"
        Surname = $LastName
        SamAccountName = "$FirstInitial + $LastName"
        DisplayName = "$FirstName $LastName"
        UserPrincipalName = "$userName" + "@" + "contoso.com"
        AccountPassword = $password
        Office = $Office
        StreetAddress = ($XML.Companies.$Company.$office.Street).Trim()
        PostalCode = ($XML.Companies.$Company.$Office.Postcode).Trim()
        City = ($XML.Companies.$Company.$Office.City).Trim()
        State = ($XML.Companies.$Company.$Office.State).Trim()
        Country = ($XML.Companies.$Company.$Office.Country).Trim()
        Path = $Path
        ChangePasswordAtLogon = $false
        Enabled = $true
    }
# Create the user
New-ADUser @NewUserParams
```

Simple as that, browsing through the xml elements using dot-notation, and trimming off any unwanted whitespace. This is cropped below for convenience:

```powershell
StreetAddress = ($XML.Companies.$Company.$Office.Street).Trim()
PostalCode = ($XML.Companies.$Company.$Office.Postcode).Trim()
City = ($XML.Companies.$Company.$Office.City).Trim()
State = ($xml.Companies.$Company.$Office.State).Trim()
Country = ($xml.Companies.$Company.$Office.Country).Trim()
```

# Helpful Notes

* Be careful when creating your XML elements! No whitespace allowed! You will get XML Writer errors if there are spaces in your XML Elements. I use "-" to seperate mine.

```powershell
$XMLWriter.WriteStartElement('Company-1')
```

* The variables you input using `Read-Host` need to match the Element names in the XML. You could make use of Validation Scripts to validate your inputs. Here is a helpful read on [everything to do with validation inputs](https://adamtheautomator.com/powershell-validatescript).

## Final Comments and Credits

You can really flesh this out more and get a load of information into XML for referencing, e.g. company project information, sets of AD groups users could be added to, managed bookmark URLS (to then be copied into registry items). 

The list goes on and on: they are just strings at the end of the day! 

I was inspired by the following people to both do this work and write this blog post.

* [Thomas Lee](https://twitter.com/doctordns) - thanks for getting this blog started in the first place!
* [Adam Bertram](https://twitter.com/adbertram) and his fantastic book [PowerShell for SysAdmins: Workflow Automation Made Easy](https://nostarch.com/powershellsysadmins)
* [Tobias Weltner](https://twitter.com/TobiasPSP) and his article on [Mastering everday XML Tasks in PowerShell](https://www.powershellmagazine.com/2013/08/19/mastering-everyday-xml-tasks-in-powershell)
