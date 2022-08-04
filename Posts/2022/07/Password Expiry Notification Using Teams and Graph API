---
post_title: Password Expiry Notification Using Teams and Graph API
username: farismalaeb
categories: PowerShell
tags: GraphAPI, Teams, PowerShell
summary: This post's intent is to show how to use Graph API through PowerShell to send a Teams message.
---

**Q**: How do I send a password expiration notification to a user using Teams chat?

**A**: Not only can you send the password notification, but you can use PowerShell with the Teams Graph API to send any message to a Teams user.

But first, let's talk about Graph API, so we are all on the same page.

## What is the Graph API?

Microsoft had a different endpoint for each cloud service.
This makes it hard for the admin as it needs knowledge of each endpoint API URI and manages the authentication and authorization separately.
So Microsoft came up with the Graph API as a one-stop shop to manage all the cloud services using a single endpoint, authentication, and a scoped authorization.

[Microsoft Graph](https://docs.microsoft.com/graph/overview) is the gateway to read data from a wide range of Microsoft services, including Azure Active Directory, Teams, OneDrive…etc.
You can get the data using a single module and a single interface.

Microsoft Graph API supports modern authentication protocols such as access token, certificate, and browser authentication.

> You can read more about the Graph API available endpoint from the [Microsoft Graph REST API Endpoint v1.0 Reference](https://docs.microsoft.com/graph/api/overview).

## Downloading Graph API PowerShell Module

You can download Microsoft Graph PowerShell Module by running the following command.

```powershell
Install-Module -Name Microsoft.Graph
```

Microsoft PowerShell Graph Module SDK is cross-platform and supports Windows, macOS, and Linux.

## Connecting To Graph API Using PowerShell

Unlike other modules such as the AzureAD, ExchangeOnline, etc.
where the admin needs only to connect with the right credentials and have full access, the graph has a different approach.  

When connecting to the Graph API, you need to specify the scope of permissions or, let's say, declare the required permissions that are used during the script execution.
The script fails if it tries to perform an action that was not in the scope.

For example, if the script needs to read all user data in the azure directory, it's not enough just to connect to read all the data, even if the user credentials are for the global admin for the tenant.
Instead, you must declare and specify that you will connect and use the `User.Read.All` permission.

To connect to Graph API with the required scope, use the following:

```powershell-console
PS> $Scope=@('User.Read.All','User.ReadWrite.All')
PS> Connect-MgGraph -Scopes $Scope

Welcome To Microsoft Graph!
```

To check which identity is used during the connecting with the Graph API along with the used scope, use the `Get-MgContext` cmdlet.

```powershell-console
PS> Get-MgContext

ClientId              : 2ee82eec-204b-204b-204b-e55eec26bf5a
TenantId              : 14d82eec-4d5a-4d5a-4d5a-26bf5ae55eec
CertificateThumbprint : 
Scopes                : {User.Read.All, User.ReadWrite.All…}
AuthType              : Delegated
AuthProviderType      : InteractiveAuthenticationProvider
CertificateName       : 
Account               : farismalaeb@contoso.com
AppName               : Microsoft Graph PowerShell
ContextScope          : CurrentUser
Certificate           : 
PSHostVersion         : 2022.6.3
ClientTimeout         : 00:05:00
```

To add additional permission to the scope, rerun `Connect-MgGraph`, setting the new scope with the **Scope** parameter and connect again. There is no need to specify the same scope already provided.

So let's assume that an admin connected to the Graph API using the following scope:

```powershell
$Scope=@('User.Read.All')
Connect-MgGraph -Scopes $Scope
```

Later on, the admin wants to add the `User.ReadWrite.All` permission, all the admin needs to do is run the `Connect-MgGraph` and set the new scope

```powershell
$Scope=@('User.ReadWrite.All')
Connect-MgGraph -Scopes $Scope
```

The new scope permission adds to the current one.

A good starting point in finding out the required permission to execute a certain cmdlet is [Find-MgGraphcommand](https://docs.microsoft.com/powershell/microsoftgraph/find-mg-graph-command) and [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer).

## Password Expiry Notification Using Teams and Graph API

### Getting Password Expiration information

To make this tutorial more fun, let's make a scenario.
Consider a company named Contoso.com.
Contoso.com have an on-premise AD syncing with AAD. The Password Expiration policy is set to 3 months.

The administrator is looking for a way to send the users a notification through Microsoft Teams chat one week before the password expires, so, how to start?

To get the password expiration for users, use the following code.
This code reads the **Name**, **EmailAddress**, **UserPrincipalName** and [**msDS-UserPasswordExpiryTimeComputed**](https://docs.microsoft.com/openspecs/windows_protocols/ms-adts/f9e9b7e2-c7ac-4db6-ba38-71d9696981e9).
The **msDS-UserPasswordExpiryTimeComputed** property notes when the user's password expires, check it below.

```powershell
$DaysToSendWarning = (Get-Date).AddDays(7).ToLongDateString()

$QueryParameters = @{
    Filter     = {
        Enabled -eq $true -and
        PasswordNeverExpires -eq $false -and
        PasswordLastSet -gt 0
    }
    Properties = @(
        'Name'
        'EmailAddress'
        'msDS-UserPasswordExpiryTimeComputed'
        'UserPrincipalName'
    )
    SearchBase = $LDAPdistinguishedName
}

$SelectionProperties = @(
    "Name"
    "UserPrincipalName"
    "EmailAddress"
    @{
        Name = 'PasswordExpiry'
        Expression = {
            [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed").ToLongDateString()
        }
    }
)

$Users = Get-ADUser @QueryParameters | Select-Object -Property $SelectionProperties
```

To see the result, call the `$Users` variable.

```powershell-console
Name              UserPrincipalName          EmailAddress            PasswordExpiry
----              -----------------          ------------           --------------
test               test@contoso.com          test1@contoso.com      Monday, August 15, 2022
User1              User1@contoso.com         User1@contoso.com      Tuesday, October 18, 2022
User2              User2@contoso.com         User2@contoso.com      Sunday, August 7, 2022
.
.
.
Output trimmed
```

Later on a `ForEach-Object` loop goes through the users, and if any user **msDS-UserPasswordExpiryTimeComputed** matches the date in the `$DaysToSendWarning`, then the script sends them the chat message.
More to come in the full script.

## Using Microsoft Graph to Create a Teams Chat Session

[Microsoft Graph API documentation](https://docs.microsoft.com/graph/) is the best start with anything related to Graph API.

We need to connect to the Graph API and use the following permission in the scope.

```powershell
$Scope=@('Chat.Create','Chat.ReadWrite','User.Read','User.Read.All') 
Connect-MgGraph -Scopes $Scope
```

First, start a chat session. The chat session contains a list of all the parties involved in the chat session. Also, it will provide a unique ID representing the communication between all the parties involved in the chat.

```powershell-console
$NewChatIDParam = @{
    ChatType = "oneOnOne"
    Members  = @(
        @{
            "@odata.type" = "#microsoft.graph.aadUserConversationMember"
            Roles = @(
                "owner"
            )
            "User@odata.bind" = "https://graph.microsoft.com/v1.0/users('*XXXXXXXXXX*')"
        }
        @{
            "@odata.type" = "#microsoft.graph.aadUserConversationMember"
            Roles = @(
                "owner"
            )
            "User@odata.bind" = "https://graph.microsoft.com/v1.0/users('*XXXXXXXXXX*')"
        }
    )
}

$ChatSessionID = New-MgChat -BodyParameter $NewChatIDParam


PS> $ChatSessionID.id
19:b980153c-9129-9129-9129-fb57a348d4d3_eafa5e65-9129-4e69-4e69-19f3fe6@unq.gbl.spaces

```

Replace each `*XXXXXXXXXX*` with a user ID who is participating in the chat. It doesn't matter if the sender or the recipient is first. it's a two-way communication bridge.
But that the caller user id must be one of the members specified in the request body.

You can get the user id by running `(Get-MgUser -userID user1@contoso.com).id`

Read more about the parameters in the chat session from the [Create chat](https://docs.microsoft.com/graph/api/chat-post?view=graph-rest-beta&tabs=http).

Executing the example above returns a long ID. The chat session ID must be used between these parties specified in the chat body.

Running the example above again and again returns the same chat session id if the chat session already exists.
So no need to go through all the chat sessions to seek a certain chat conversation id.

## Using Microsoft Graph to Send a Teams Chat Message

As for now, we have the chat session id.
We can send a message with a line of code.

```powershell
New-MgChatMessage -ChatId $ChatSessionID.id -Body  @{Content ='<strong>Hello, I am PowerShell</strong>';ContentType='html'}
```

Looking to know more about `New-MgChatMessage` parameters, take a look at [Send chatMessage in channel or a chat](https://docs.microsoft.com/graph/api/chatmessage-post?view=graph-rest-beta&tabs=http) and also [Send HTML Teams Message Using PowerShell Graph](https://www.powershellcenter.com/2022/07/15/new-mgchat/).

## Full Script to send notification

So now we know the basics. Let's build it all together.

There is no need to modify anything except the **$DaysToSendWarning** variable.
Set it to the number of days you want.
Everything else should be fine with no issues.

You might need to consent and accept the new permission after connecting using the `Connect-MgGraph`.

```powershell
Import-Module ActiveDirectory
Import-Module Microsoft.Graph.Teams

$Scope = @(
    'Chat.Create'
    'Chat.ReadWrite'
    'User.Read'
    'User.Read.All'
)
Connect-MgGraph -Scopes $Scope

$DaysToSendWarning = 7

#Find accounts that are enabled and have expiring passwords
$QueryParameters = @{
    Filter     = {
        Enabled -eq $true -and
        PasswordNeverExpires -eq $false -and
        PasswordLastSet -gt 0
    }
    Properties = @(
        'Name'
        'EmailAddress'
        'msDS-UserPasswordExpiryTimeComputed'
        'UserPrincipalName'
    )
    SearchBase = $LDAPdistinguishedName
}

$SelectionProperties = @(
    "Name"
    "UserPrincipalName"
    "EmailAddress"
    @{
        Name = 'PasswordExpiry'
        Expression = {
            [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed").ToLongDateString()
        }
    }
)

$Users = Get-ADUser @QueryParameters | Select-Object -Property $SelectionProperties

foreach ($User in $Users) {
    $RecpID = Get-MgUser -UserId $User.UserPrincipalName -ErrorAction Stop
    if ($User.PasswordExpiry -eq $DaysToSendWarning) {
        $NewChatIDParam = @{
            ChatType = "oneOnOne"
            Members = @(
                @{
                    "@odata.type" = "#microsoft.graph.aadUserConversationMember"
                    Roles = @(
                        "owner"
                    )
                    "User@odata.bind" = "https://graph.microsoft.com/v1.0/users('"+(get-mguser -userid (Get-MgContext).account).id +"')"
                }
                @{
                    "@odata.type" = "#microsoft.graph.aadUserConversationMember"
                    Roles = @(
                        "owner"
                    )
                    "User@odata.bind" = "https://graph.microsoft.com/v1.0/users('"+$RecpID.id +"')"
                }
            )
        }

        $ChatSessionID = New-MgChat -BodyParameter $NewChatIDParam

        Write-Host "Sending Message to $($RecpID.Mail)" -ForegroundColor Green

        try {
            #### Sending The Message
            $Body = @{
                ContentType = 'html'
                Content = @"
                Hello $($RecpID.DisplayName)<br>
                Your password will expire in $($DaysToSendWarning), Please follow <Strong><a href='www.office.com'>the instruction here to update it</a> </Strong> <BR>
                Thanks for your attention
"@
              }

        New-MgChatMessage -ChatId $ChatSessionID.ID -Body $Body -Importance Urgent
        } catch{
            Write-Host $_.Exception.Message
        }
    }
}
```

## Conclusion

This post shows how to send a basic HTML message, but there is still a lot.
Take a look at the Graph API documentation to know how to receive, read and have a wider control of not only Teams but also other Microsoft cloud services.

It's ok to feel a bit lost about all these hashtables, arrays, and new things and the structure. No need to memorize it. just open the Graph API documentation, guiding you straight to the point.

Lets me know if you try it; how did it go :)
