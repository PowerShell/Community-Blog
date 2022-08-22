# Creating a new post

1. Always create a _working branch_ in your local repo before starting a new article. Avoid working
   in the `main` branch.
1. Create a new `.md` file in `Posts/YYYY/MM` directory. For example, posts scheduled to be
   published in February of 2021 go in the `Posts/2021/02` folder. Create the monthly folder if it
   doesn't exist yet.
   - Filenames should only use the following characters: A-Z (upper and lower), 0-9, and hyphen (`-`)
   - Don't use spaces or special characters in filenames
   - Separate words in the filename with hyphens
   - The filename must include the `.md` file extension
1. Write the blog post!
   - Use [GitHub flavored markdown][1].
   - The blog post **MUST** have this header:

     ```yaml
     ---
     post_title: <Title of the blog post>
     username: <Author username as seen in wordpress, not github ID>
     categories: PowerShell
     tags: <relevant keyword for your topic>
     featured_image: <optional Image url>
     summary: <Summary of the post>
     ---
     ```

   - `categories` and `tags` are comma-separated lists. `categories` need to be pre-existing. You
     can add more `categories` and `tags` in the blog dashboard.
   - `featured_image` is optional. This image replaces the blue PS icon next to the blog post with your
     selected image.

   - PowerShell code snippet:

     ~~~markdown
     ```powershell
     Get-Alias dir # this will be highlighted with PowerShell syntax
     ```
     ~~~

   - Console output snippet:

     ~~~markdown
     ```powershell-console
     CommandType     Name                                               Version    Source
     -----------     ----                                               -------    ------
     Alias           dir -> Get-ChildItem
     ```
     ~~~

1. Read and following the rules in the [Reviewer's Guide][2]. Edit your post based on these rules
   before submitting the PR. This saves the reviewers a lot of time and your post can be approved
   more quickly.

## Publishing draft to blog

After submitting your Pull Request, the blog admins will review the post. The may suggest editorial
changes to improve grammar and readability. They may also require specific changes before we can
publish. Once the pull request is merged, the post is automatically copied to WordPress as a draft.
From there, the Blog admins will verify that the post renders correctly, make any formatting changes
required, and publish the post.

<!-- link references -->
[1]: ./Markdown-cheatsheet.md
[2]: ./Reviewers-Guide.md
