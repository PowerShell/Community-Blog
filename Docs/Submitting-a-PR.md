1. Create your a new MD file for your post

   - Always create a _working branch_ in your local repo before starting a new article. Avoid
     working in the `main` branch.
   - Create the new post in the folder for the current month (E.g. `Posts/2021/02` for February of
     2021).
   - All images you want to include go in the `media` folder of the current month.
     - If the media folder does not exist, create it.
     - Create a subfolder that matches the name of you post's MD file in the `media` folder.

1. Write your content in markdown.

   - Be sure to include the YAML frontmatter in your file.
   - Follow the guidance in our
     [Reviewer's Guide](https://github.com/PowerShell/Community-Blog/wiki/Reviewers-Guide).
   - You do not need to repeat the title as an H1 header. The first header in your post should be
     H2. This header DOES NOT need to be the first lin of you post after the frontmatter.

1. Push your _working branch_ to your fork in GitHub.
1. Create a PR to merge the _working branch_ of your fork into the `main` branch of the
   **PowerShell/Community-Blog** repository.
1. Fill out the PR template and click submit.

   - Include specific instructions in the template if you want the post to be published at a
     specific date and time.

## After submitting your PR

### Contributor License Agreement

If you are contributing for the first time, you will be asked to complete a short Contribution
License Agreement (CLA). After the CLA step is cleared, your pull request is processed.

### PR Review process

Your PR will be reviewed by the Blog staff. They may have editorial suggestions. Please fix issues
and accept the editorial changes.

Once your PR has been reviewed and approved, it will be merged. Once merged the post is
automatically copied to WordPress where the WP admins will preview the rendering. They may have to
make minor changes to fix issues created by the translation to WordPress. If the Preview is good,
the post will be published.
