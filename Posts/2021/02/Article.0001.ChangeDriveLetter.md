---
post_title: Changing Drive Letters and Labels via PowerShell
username: tfl@psp.co.uk
Catagories: PowerShell, WMI
Summary: Shows how to change a drive's letter and label using PowerShell and WMI
---

# Changing Drive Letters and Labels via PowerShell

**Q:** I want to change the drive letter and the drive label for a new USB drive. 
Is there a way with PowerShell?

**A:**  Of course. One way is to use WMI and the CIM cmdlets.

The Windows management tools have cmdlets (`Set-Partition` and `Set-Volume`) to change the drive letter and the caption directly. But it is also good to know how to do it via WMI and the CIM cmdlets to change both the drive letter and drive label. And under the covers, when you use `Set-Partition`, you are actually using WMI. Both the Windows Storage and Windows Networking teams make heavy use of WMI and expose cmdlets via **CDXML** modules. The `*-Partition` cmdlets are implemented by the **CDXML** Storage module.

## WMI Classes, Class properties and Class Methods

WMI holds a huge amount of information about a Windows host in the form of WMI classes.
Every IT professional should know about WMI.

WMI holds a hierarchical database of classes and class occurrences. 
These classes describe the hardware and software in your computer.
This database is organized in to namespaces each which contains classes and, optionally, additional namespaces.
You can use the CIM cmdlets to both retrieve and update this information. 

For example, you can discover the drive letter and drive label for a drive from the **Win32_Volume** class.
This class in in the root\CimV2 namespace.

Many WMI classes also contain methods that you can use to act on the WMI object.
You can use the `Format()` method of the **Win32_Volume** class to format a Windows volume.

To obtain the values of the properties of a WMI class, or to invoke a class method, you can use the WMI cmdlets, which shipped with Windows PowerShell V1.
However, these cmdlets no longer ship with PowerShell 7.
Of course, a determined IT Pro could find a way around that - but you don't have to!

With PowerShell 7, you use the CIM cmdlets to access this information.
The CIM cmdlets first shipped with Windows PowerShell V3 and represented a major overhaul in how IT Pros access WMI.
The newer cmdlets do the same job as the WMI cmdlets but have different cmdlets, and different ways of working as you can see in this article.


## Discovering WMI Class Properties

You use the cmdlet `Get-CimClass` to discover the names (and type) of the properties of any given class.
You can discover the properties of the **Win32_Volume** class like this:

```powershell
Get-CimClass -ClassName Win32_Volume |
  Select-Object -ExpandProperty CimClassProperties |
    Sort-Object -Property Name |
      Format-Table Name, CimType, Qualifiers
```

The output from this commands looks like this:

```powershell-console
Name                             CimType Qualifiers
----                             ------- ----------
Access                            UInt16 {read}
Automount                        Boolean {read}
Availability                      UInt16 {MappingStrings, read, ValueMap}
BlockSize                         UInt64 {MappingStrings, read}
BootVolume                       Boolean {read}
Capacity                          UInt64 {read}
Caption                           String {MaxLen, read}
Compressed                       Boolean {read}
ConfigManagerErrorCode            UInt32 {read, Schema, ValueMap}
ConfigManagerUserConfig          Boolean {read, Schema}
CreationClassName                 String {CIM_Key, read}
Description                       String {read}
DeviceID                          String {CIM_Key, read, key, MappingStrings, Override}
DirtyBitSet                      Boolean {read}
DriveLetter                       String {read, write}
DriveType                         UInt32 {MappingStrings, read}
ErrorCleared                     Boolean {read}
ErrorDescription                  String {read}
ErrorMethodology                  String {read}
FileSystem                        String {read}
FreeSpace                         UInt64 {read}
IndexingEnabled                  Boolean {read, write}
InstallDate                     DateTime {MappingStrings, read}
Label                             String {read, write}
LastErrorCode                     UInt32 {read}
MaximumFileNameLength             UInt32 {read}
Name                              String {read}
NumberOfBlocks                    UInt64 {MappingStrings}
PageFilePresent                  Boolean {read}
PNPDeviceID                       String {read, Schema}
PowerManagementCapabilities  UInt16Array {read}
PowerManagementSupported         Boolean {read}
Purpose                           String {read}
QuotasEnabled                    Boolean {read}
QuotasIncomplete                 Boolean {read}
QuotasRebuilding                 Boolean {read}
SerialNumber                      UInt32 {read}
Status                            String {MaxLen, read, ValueMap}
StatusInfo                        UInt16 {MappingStrings, read, ValueMap}
SupportsDiskQuotas               Boolean {read}
SupportsFileBasedCompression     Boolean {read}
SystemCreationClassName           String {CIM_Key, Propagated, read}
SystemName                        String {CIM_Key, Propagated, read}
SystemVolume                     Boolean {read}
```

In this list, you see each property of the **Win32_Volume** WMI class, the data type of the property and qualifiers.
Qualifiers tell you more about the property - in particular whether a given property is read-only or read-write.
The **PageFilePresent** property tells whether a given volume contains a Windows paging file. 
This property can not be changed using the CIM cmdlets.
The DriveLetter and Label properties, on the other hand, are ones you can update. 
Let's look at how you can change those properties.

## Getting WMI properties

Suppose you want to change the volume label of a disk drive.
In my host, the `M:\` drive contains a collection of digitised music and my collection of thousands of Grateful Dead live concerts.
I have been collecting for a long time and have a disk deadicated [SIC] to the task.
But sometimes, when I plug in my USB backup drives to perform a backup, Windows changes the drive letter for me.
To ensure my backup scripts work, I need to change it back so my backup scripts work properly.

To obtain the value of the drive label and drive letter, you can do this:

```powershell
$Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'M:'"
$Drive | Select-Object -Property SystemName, Label, DriveLetter
```

On my Windows 10 host (Cookham24), the output looks like this:

```powershell-console
PS C:\> $Drive | Select-Object -Property SystemName, DriveLetter, Label, DriveLetter

SystemName DriveLetter Label
---------- ----------- -----
COOKHAM24  M:          Master GD
```

## Changing Drive Label

You saw above that both the drive label and the drive letter are writable properties. 
To change the label for this disk volume, you assign a new value to the label property of `$Drive`.
Changing the property value updates the in-memory class instance which is not a permanent change.
In order to persist the change, you need to use the `Set-CimInstance` CMDLET. 
Here is how you can change the drive label, and then confirm the change:

```powershell
$Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'M:'"
$Drive | Set-CimInstance -Property @{Label='Grateful Dead'}
Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'M:'" |
  Select-Object -Property SystemName, Label, DriveLetter
```

The output form this command, which shows the updated system label, looks like this

```powershell-console
SystemName Label         DriveLetter
---------- -----         -----------
COOKHAM24  Grateful Dead M:  
```

## Changing Drive Letter

To change the drive letter for a volume, you use `Set-CimInstance` to change the drive letter, like this:

``` powershell
$Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'M:'"
$Drive | Set-CimInstance -Property @{DriveLetter ='X:'}
```

If you are running PowerShell 7 in a non-elevated session, this operation fails like this:

```powershell-console
PS C:\Foo> $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'M:'"
PS C:\Foo> $Drive | Set-CimInstance -Property @{DriveLetter ='X:'}
Set-CimInstance: Access is denied.
```

This error is expected since you are not running PowerShell as an administrator.
To overcome this error, re-run the command in an elevated session (run as administrator).
Then your output looks like this:

```powershell-console
PS C:\Foo> $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'M:'"
PS C:\Foo> $Drive | Set-CimInstance -Property @{DriveLetter ='X:'}
PS C:\Foo> Get-Volume | Where-Object FileSystemLabel -eq 'Grateful Dead'

DriveLetter FriendlyName  FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining    Size
----------- ------------  -------------- --------- ------------ ----------------- -------------    ----
X           Grateful Dead NTFS           Fixed     Healthy      OK                    591.78 GB 3.64 TB
```

Changing the drive letter can take a while - so be patient.

And as a final point - you can combine the two property updates in a single call to `Set-CimInstance`. 
To revert this drive to the old drive letter (`M:\`) and it's Label (**GD Master**) and confirm the change, you can do it like this:

```powershell
$Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'X:'"
$Drive | Set-CimInstance -Property @{DriveLetter = 'M:'; Label = 'GD Master'}
```

You can view the resulting change to drive letter and label using `Get-Volume`.
The output should look this:

```powershell-console
PS C:\Foo> Get-Volume | Where-Object FileSystemLabel -match 'GD Master'
DriveLetter FriendlyName FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining    Size
----------- ------------ -------------- --------- ------------ ----------------- -------------    ----
M           GD Master    NTFS           Fixed     Healthy      OK                    591.78 GB 3.64 TB
```

> **_NOTE:_**  
One issue you may encounter when you change a drive letter then revert it as shown here.
It appears that Windows holds on to the old drive letter and does not allow you revert it back immediately.
Thus you may get a "Set-CimInstance: not available" error message when trying to revert the drive letter.
To get around this, you have to reboot Windows - it appears just logging off and back on is not adequate.

## Summary

Changing drive letters using PowerShell 7 is simple and straightforward.
As you can see, using the `Set-CimInstance` PowerShell cmdlet to modify writable WMI properties is easy.
I feel it's more intuitive than making multiple property value assignments (once you you master the hash table). 
The cool thing is that multiple properties can be modified at one time instead of making multiple value assignments.

And as ever, this post shows there is often more than one way to achieve any aim.

## Tip of the Hat

This article was inspired by an earlier Scripting Guys Blog post: <https://devblogs.microsoft.com/scripting/change-drive-letters-and-labels-via-a-simple-powershell-command/>.
That article was written by the most excellent Ed Wilson - thanks Ed!
