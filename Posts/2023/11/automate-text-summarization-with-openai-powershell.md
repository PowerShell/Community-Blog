---
post_title: 'Automate Text Summarization with OpenAI and PowerShell'
username: thepiyush13
categories: PowerShell, OpenAI, Scripting
post_slug: automate-text-summarization-with-openai-powershell
tags: PowerShell, OpenAI, GPT-3.5, API, Summarization
summary: This easy-to-follow guide shows you how to use PowerShell to summarize text using OpenAI's GPT-3.5 API.
---

Automating tasks is the core of PowerShell scripting. Adding artificial intelligence into the mix
takes automation to a whole new level. Today, we'll simplify the process of connecting to OpenAI's
powerful text summarization API from PowerShell. Let's turn complex AI interaction into a
straightforward script.

To follow this guide, you'll need an OpenAI API key. If you don't already have one, you'll need to
create an [OpenAI account][01] or [sign in][02] to an existing one. Next, navigate to the
[API key page][03] and create a new secret key to use.

## Step-by-Step Function Creation

### Step 1: Define the Function and Parameters

We'll start by setting up our function with parameters such as the API key and text to summarize:

```powershell
function Invoke-OpenAISummarize {
    param(
        [string]$apiKey,
        [string]$textToSummarize,
        [int]$maxTokens = 60,
        [string]$engine = 'davinci'
    )
    # You can add or remove parameters as per your requirements
}
```

### Step 2: Set Up API Connection Details

Next, we'll prepare our connection to OpenAI's API by specifying the URL and headers:

```powershell
    $uri = "https://api.openai.com/v1/engines/$engine/completions"
    $headers = @{
        'Authorization' = "Bearer $apiKey"
        'Content-Type' = 'application/json'
    }
```

### Step 3: Construct the Body of the Request

We need to tell the API what we want it to do: summarize text. We do this in the request body:

```powershell
    $body = @{
        prompt = "Summarize the following text: `"$textToSummarize`""
        max_tokens = $maxTokens
        n = 1
    } | ConvertTo-Json
```

### Step 4: Make the API Request and Return the Summary

The final part of the function sends the request and then gets the summary back from the API:

```powershell
    $parameters = @{
        Method      = 'POST'
        URI         = $uri
        Headers     = $headers
        Body        = $body
        ErrorAction = 'Stop'
    }

    try {
        $response = Invoke-RestMethod @parameters
        return $response.choices[0].text.Trim()
    } catch {
        Write-Error "Failed to invoke OpenAI API: $_"
        return $null
    }
}
```

## Running the Function

Now, to use the function, you just need two pieces of information: your OpenAI API key and the text
to summarize.

```powershell
$summary = Invoke-OpenAISummarize -apiKey 'Your_Key' -textToSummarize 'Your text...'
Write-Output "Summary: $summary"
```

Replace `'Your__Key'` with your actual key and `'Your text...'` with what you want to summarize.

Here's a how I am running this function in my local PowerShell prompt, I copied
the text from Wikipedia:

```powershell
$summary = Invoke-OpenAISummarize -apiKey '*********' -textToSummarize @'
PowerShell is a task automation and configuration management program from
Microsoft, consisting of a command-line shell and the associated scripting
language. Initially a Windows component only, known as Windows PowerShell,
it was made open-source and cross-platform on August 18, 2016, with the
introduction of PowerShell Core.[5] The former is built on the .NET Framework,
the latter on .NET (previously .NET Core).
'@
```

and I get the following result:

```
PowerShell, initially Windows-only, is a Microsoft automation tool that became
cross-platform as open-source PowerShell Core, transitioning from .NET Framework
to .NET.
```

## Conclusion

Combining AI with PowerShell scripting is like giving superpowers to your computer. By breaking
down each step and keeping it simple, you can see how easy it is to automate text summarization
using OpenAI's GPT-3.5 API. Now, try it out and see how you can make this script work for you!

Remember, the beauty of scripts is in their flexibility, so feel free to tweak and expand the
function to fit your needs.

Happy scripting and enjoy the power of AI at your fingertips!

## References

- [OpenAI API reference documentation][04]

[01]: https://platform.openai.com/signup
[02]: https://platform.openai.com/login
[03]: https://platform.openai.com/account/api-keys
[04]: https://platform.openai.com/docs/api-reference
