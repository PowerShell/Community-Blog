# Community-Blog

> NOTE
>
> This is a work in progress. We will provide more information in an announcement coming soon.

Submissions for posts to the
[PowerShell Community blog](https://devblogs.microsoft.com/powershell-community).

Participation in this blog is governed by the
[Microsoft Community Code of Conduct](https://answers.microsoft.com/page/codeofconduct).

See the [Wiki pages](https://github.com/PowerShell/Community-Blog/wiki) for detailed instructions.

## How to write a new blog post

- Create a new `.md` file in **Posts** directory, follow existing posts for naming convention
- Write the blog post!
  - Use [GitHub flavored markdown](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
  - The blog post **MUST** have this header:

    ```yaml
    ---
    post_title: <Title of the blog post>
    username: <Author username as seen in wordpress, not github ID>
    categories: PowerShell
    tags: PowerShell
    featured_image: <Image url>
    summary: <Summary of the post>
    ---
    ```

  - `categories` and `tags` are comma-separated lists. `categories` need to be pre-existing. You can
    add more `categories` and `tags` in the blog dashboard.
  - `featured_image` is optional. It will replace the blue PS icon next to the blog post with your
    selected image.

  - PowerShell code snippet:

    ~~~markdown
    ```powershell
    Get-Help # this would be highlighted with PowerShell syntax
    ```
    ~~~

  - Console output snippet:

    ~~~markdown
    ```powershell-console
    C:>_ # this would be highlighted with royal blue background and white foreground.
    ```
    ~~~

## Publishing draft to blog

Go through the normal review process by submitting a Pull Request. Once the PR is merged, a draft
post is automatically created on the blog. WP admins will review the draft in Word Press to ensure
the conversion from markdown to HTML worked correctly before publishing the post.
