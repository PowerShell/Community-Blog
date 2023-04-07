# Markdown cheatsheet

## Frontmatter

All posts must have the following YAML blog at the top of the markdown file.

```yaml
---
post_title: 'Post Title'
username: Author username as seen in wordpress, not GitHub ID
categories: existingcategory1, existingcategory2
tags: tag1,tag2
featured_image: check instructions below
summary: summary of the post
---
```

Fill in all sections of the header. The `post_title`, `summary`, and `username` are required
fields.

For featured image, please follow the guidance for images below.

## General formatting

### Headers (ATX Style)

Use `#` in front of a header to identify it as a header and also to auto-generate a section-link for
that header. This

```markdown
# for H1
## for H2
### for H3
#### for H4
##### for H5
###### for H6
```

While Markdown supports other formats for headers, please use only ATX Style headers.

### Emphasis

- Italics - use underscores `_` (use without spaces) - _this is Italics_
- Bold - use double asterisks `**` (use without spaces) - **this is bold**
- Strikethrough - use two tildes (use without spaces) -  ~~Scratch this~~

### Lists

~~~markdown
1. First ordered list item
1. Another item
1. Actual numbers don't matter. Use 1. for every item. This makes it easier to reorder
   - Unordered sub-list.
   - Use hyphens - for unordered list item. Markdown supports other characters but the asterisk is
     too easily confused as emphasis. Using the hyphen avoids this confusion.
1. Ordered sub-list
   1. First subitem

      You can have properly indented paragraphs within list items. Notice the blank line above, and
      the leading spaces. The first character of the paragraph should line up with the first
      character of the list item.
~~~

1. First ordered list item
1. Another item
1. Actual numbers don't matter. Use `1.` for every item. This makes it easier to reorder
   - Unordered sub-list.
   - Use hyphens `-` for unordered list item. Markdown supports other characters but the asterisk is
     too easily confused as emphasis. Using the hyphen avoids this confusion.
1. Ordered sub-list
   1. First subitem

      You can have properly indented paragraphs within list items. Notice the blank line above, and
      the leading spaces. The first character of the paragraph should line up with the first
      character of the list item.

### Code blocks

Code blocks can be added using the triple-backtick ` ``` ` block style. See example below.

~~~markdown
```powershell
Invoke-RestMethod
```
~~~

```powershell
Invoke-RestMethod
```

If you are mixing code with output, use the `powershell-console` language label for the code block.
For example:

~~~markdown
```powershell-console
PS C:\> # Get the current date
PS C:\> Get-Date
08 January 2021 11:24:46

# Store the date in a variable
$Now = Get-Date
$Now
08 January 2021 11:24:47
```
~~~

### Code within text

Code within a paragraph can be added using single-backticks. See example below.

```markdown
This is a sentence with `inline code` in between.
```

This is a sentence with `inline code` in between.

### Images

- Images in public space e.g. public GitHub repo

  If the images are in a public space like docs, or already in the blog media folder, or a public
  GitHub repo, simply add them in the standard markdown format as shown below. Remember to add alt
  text for all your images.

  ![alttext][1]

  If you want images from public site, to be copied over to your blog's media folder, then follow
  the steps mentioned in the images in private repo section.

- Images in the GitHub repo

  To include images in your post you must:

  1. Create a `media/<post-filename>` folder under the current month's folders. `<post-filename>`
     should match the name of your markdown file (without the file extension).
  1. Put all images for the post in that folder.
  1. Link to the image using the standard markdown syntax:

     ```markdown
     ![alt-text](./media/<post-filename>/image-name.ext)
     ```

### Videos

For videos directly uploaded to the WordPress media folder, you can add the video links in GitHub
with this `video` shortcode.

```markdown
[video src="https://devblogs.microsoft.com/powershell/wp-content/uploads/sites/30/2020/05/PSNativePSPathResolution.mp4"]
```

For videos uploaded to the GitHub repo, if you add a link to the video in GitHub repo, we don't yet
have a way to bring it into the media folder in WordPress. So all such videos need to be uploaded to
the WordPress media library then added to the draft in WordPress, or added to the draft in GitHub
via the video shortcode, example shown above.

#### YouTube Videos

You can add YouTube videos. The typical YouTube embed code looks like this :

```html
<iframe width="320" height="240" src="https://www.youtube.com/embed/hLFyycJVo0I" frameborder="0"
allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen>
</iframe>
```

You can use the `iframe` shortcode for simpler syntax. To align the video use `<p>` tag as shown
in this example:

```html
<p align="right">
[iframe src="https://www.youtube.com/embed/hLFyycJVo0I" width="320" height="240"]
</p>
```

### Links

Links can be added using standard markdown link format. See example below.

```markdown
[tidy up the ASP.NET Core shared framework](https://blogs.msdn.microsoft.com/webdev/2018/10/29/a-first-look-at-changes-coming-in-asp-net-core-3-0/),
Json.NET is being removed from the shared framework and now needs to be added as a package.
```

### Tables

Markdown supports tables with alignment (left,center,right). See examples below.

```markdown
|  Syntax   | Description |  Test Text  |
| :-------- | :---------: | ----------: |
| Header    |    Title    | Here's this |
| Paragraph |    Text     |    And more |
```

This is what the basic table will look like:

|  Syntax   | Description |  Test Text  |
| :-------- | :---------: | ----------: |
| Header    |    Title    | Here's this |
| Paragraph |    Text     |    And more |

You can use HTML tags if you need more attributes for a table.

## Blog-specific formatting

### Embedding media files

The blogging platform supports embedded media (videos, audio, podcasts, etc.) in your posts. You can
add embedded media using the WordPress editor after the PR has been merged. Or you can use special
markup in your Markdown source in GitHub. If you want to do this, add a comment to your PR
requesting assistance from a Blog admin to create the proper link.

### Alert boxes

Similar to the Docs platform, our WordPress platform supports Alert boxes used for calling out
important information. You can use the following syntax in your Markdown post to create an alert.

```markdown
[alert type="note" heading="Note"]
Information the user should notice even if skimming.
[/alert]

[alert type="tip" heading="Tip"]
Optional information to help a user be more successful.
[/alert]

[alert type="important" heading="Important"]
Essential information required for user success.
[/alert]

[alert type="caution" heading="Caution"]
Negative potential consequences of an action.
[/alert]

[alert type="warning" heading="Warning"]
Dangerous certain consequences of an action.
[/alert]
```

You can also customize the heading as appropriate. The following image shows what each alert type
looks like (with and without a heading).

![Alerts][2]

<!-- link references -->
[1]: https://devblogsarchiv.wpengine.com/wp-content/uploads/2020/02/allmycomments.jpg
[2]: ./media/Markdown-cheetsheet/alerts.png