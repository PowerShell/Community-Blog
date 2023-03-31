---
post_title: Encode in C# and Decode in PowerShell
username: sorastog
categories: PowerShell
tags: PowerShell,Encode,Decode,C#,Automation
summary: This posts explains how to Encode in C# and Decode in PowerShell
---

Hi Readers,

I had a requirement to read some data in C# windows application, store it in database  and then use it later in a PowerShell script.

It was also required that some data like ‘Keys’ should not be saved directly in database i.e. should not be visible directly to other database users.

One approach is to use complex encryption decryption logic when high data security is a requirement. Read more about Encryption and Decryption of Data [here](https://learn.microsoft.com/en-us/previous-versions/dotnet/netframework-4.0/e970bs09(v=vs.100)).

Another approach is to use Base64 encoding and decoding approach where very high data security is not a requirement. More about Base64 encoding [here](http://msdn.microsoft.com/en-us/library/dhx0d524(v=vs.110).aspx) and decoding [here](http://msdn.microsoft.com/en-us/library/system.convert.frombase64string(v=vs.110).aspx).

I opted out for Base64 encoding approach as data was not getting shared with external sources where data security is very important and my applications and database were in the same network.

## Steps to follow

1. Encode in C# :-

```C#
   public string EncodeKey(string txtKey)
   {
       byte[] passBytes = System.Text.Encoding.Unicode.GetBytes(txtKey);
       string encodedKey = Convert.ToBase64String(passBytes);
       return encodedKey;
   }
```

1. Next step is to save the encoded key in database. There are many posts available on internet that can help on how data can be inserted in SQL database.

1. Decode in PowerShell

```powershell
    Function ReadData
    {
      $ConnectionString = "Data Source='';Initial Catalog='';Integrated Security=SSPI;"
      $con = New-Object "System.Data.SqlClient.SQLConnection"
      $con.ConnectionString = $ConnectionString
      $con.Open()
     
      $sqlcmd = New-Object "System.Data.SqlClient.SqlCommand"
      $sqlcmd.connection = $con
    
      $sqlcmd.CommandText = “Select Key from MyDemoTable where KeyIndex = 'FirstKey'”
      $ds = New-Object System.Data.DataSet
      $da = New-Object System.Data.SqlClient.SqlDataAdapter($sqlcmd)
      $return = $da.fill($ds)
      
      $encodedKeyFromDb = $ds.Tables[0].Rows[0][0]
      $originalKey = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($encodedKeyFromDb))
    
      ## Use the Key for Further Code ##
   }
```

Please note that Base64String encoding is very simple to reverse and do not involves any private or public key concept. In situations where data security is a requirement, Encryption Decryption approach should be followed.

See you in my next blog post 🙂. Happy Scripting!!!