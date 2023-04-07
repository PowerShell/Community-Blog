# Reviewer's Guide

This is a summary of rules to apply when writing new or updating existing articles. See other
articles in the Contributor's Guide for detailed explanations and examples of these rules.

## PR Quality

- Submitted from a working branch (not from main)
- PR contains only one post
- The post is in the correct folder with a correctly structured filename
  `Posts/yyyy/mm/simple-title-of-post.md`
  - No spaces in filenames
  - Lowercase preferred
  - Must have `.md` file extension

## User profile

- The submitter has a valid WordPress profile with appropriate personal information
  - Full name
  - Any links included are valid and appropriate
  - The picture is appropriate (avatars are OK - prefer actual photo)
- The submitter has been changed to the **Author** role in WordPress

## Content quality

- Reasonable grammar and spelling
- Correct spelling and usage of brands (eg. "PowerShell" not "Powershell")
- Content is designed to teach or inform not market or sell
- Submitter has proper rights to the content they are submitting

## Metadata

All blog posts must include the YAML frontmatter:

```yaml
---
post_title: <Title of the blog post>
username: <Author username as seen in wordpress, not github ID>
categories: <choose from list of predefined categories>
tags: <choose from list of predefined tags>
featured_image: <Optional Image url>
summary: <Summary of the post - short one-line description>
---
```

## Formatting

- Backtick syntax elements that appear, inline, within a paragraph
  - Cmdlet names `Verb-Noun`
  - Variable `$counter`
  - Syntactic examples `Verb-Noun -Parameter`
  - File paths `C:\Program Files\PowerShell`, `/usr/bin/pwsh`
  - URLs that aren't meant to be clickable in the document
  - Property or parameter values
- Use bold for property names, parameter names, class names, module names, entity names, object or
  type names
  - Bold is used for semantic markup, not emphasis
  - Bold - use asterisks `**`
- Italic - use underscore `_`
  - Only used for emphasis, not for semantic markup
- Line breaks at 100 columns - helps when reviewing diffs
  - Use the [Reflow Markdown][1] extension in VS Code to help
- No hard tabs - use spaces only
- No trailing spaces on lines

### Headers

- DO NOT use the H1 header - WordPress automatically puts the title at the top of the post
- Use [ATX Headers][2] only
- Use sentence case for all headers
- Don't skip levels - no H3 without an H2
- Max depth of H3 or H4
- Blank line before and after

### Code blocks

- Blank line before and after the code block (not inside the code block)
- Use tagged code fences - `powershell`, `powershell-console`, or other appropriate language tags
- Untagged fence - syntax blocks or other shells
- Put output in separate `powershell-console` code block
- Don't use the PowerShell prompt in code blocks unless:
  - You are showing an example meant to be used on the command line.
  - Use `PS>` for the prompt unless the path is important to the example.

### Lists

- Blank line before first item and after last item
- Indented properly
  - Additional lines for an item should line up with first character after the list marker
- Bullet - use hyphen (`-`) not asterisk (`*`) - too easy to confuse with emphasis
- For numbered lists, all numbers are "1."

## Terminology

- PowerShell vs. Windows PowerShell vs. PowerShell Core
- See [Product Terminology][3]

## Linking to other websites

- Do not include locales in URLs linking to Microsoft properties (eg. remove `/en-us` from URL)
- Do not include the `?view=<version>` query parameter when linking to docs.microsoft.com
- All URLs to websites should use HTTPS unless that is not valid for the target site
- Image links should have unique alt text
- No bare URLs - Use standard markdown link syntax `[text of link](https://site.domain/path/to/page#anchor)`
- The link text should be the title of the page or the anchor that you link to

<!-- link references -->
[1]: https://marketplace.visualstudio.com/items?itemName=marvhen.reflow-markdown
[2]: https://github.github.com/gfm/#atx-headings
[3]: https://learn.microsoft.com/powershell/scripting/community/contributing/product-terminology
