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
     post_title: 'Post Title'
     user_login: The author's WordPress username, not GitHub ID
     author1: <alternative to user_login>
     author2: <optional> The author's WordPress username, not GitHub ID
     author3: <optional> The author's WordPress username, not GitHub ID
     post_slug: <post identifier - see description below>
     categories: existingcategory1, existingcategory2
     tags: tag1, tag2
     summary: summary of the post
     ---

     Add your blog post here
     ```

     - The `post_title`, `summary`, and `user_login` are required fields.
     - `post_slug` is an identifier for your post and it becomes the end portion of the URL for the
       post.
       - If the slug exists in WordPress, the post matching the slug is updated.
       - If the slug does not exist in WordPress, a new post is created.
       - If you don't provide a slug, WordPress creates a slug when it creates the draft.
       - Use lowercase letters, numbers, and hyphens. Use hyphens to separate words rather than other
         punctuation.
       - For more information about slugs, see
         [What is a WordPress slug?](https://www.wpkube.com/wordpress-slug/)
     - `categories` - one or more category strings separated by commas
       - The category values must already exist in your blog
     - `tags` - one or more strings separated by commas
       - New values are added as available tags for your blog in WordPress
     - `summary` - This is the short description of the post that shows in listing of posts on the
       main page of your blog
     - `user_login` or `author1` - can be used to add a single author
     - `author2` or `author3` - should be used when adding up to two additional authors

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

1. Read and follow the rules in the [Reviewer's Guide][2]. Edit your post based on these rules
   before submitting the PR. This saves the reviewers a lot of time and your post can be approved
   more quickly.

## Publishing draft to blog

After submitting your Pull Request, the blog admins will review the post. They may suggest editorial
changes to improve grammar and readability. They may also require specific changes before we can
publish. Once the pull request is merged, the post is automatically copied to WordPress as a draft.
From there, the Blog admins will verify that the post renders correctly, make any formatting changes
required, and publish the post.

<!-- link references -->
[1]: ./Markdown-cheatsheet.md
[2]: ./Reviewers-Guide.md
