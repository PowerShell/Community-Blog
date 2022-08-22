# Setting up Git/GitHub for working locally

To contribute to the blog, you can make and edit Markdown files locally by cloning the corresponding
**PowerShell/Community-Blog** repository. Microsoft requires you to fork the repository into your
own GitHub account so that you have read/write permissions there to store your proposed changes.
Then you use pull requests to merge changes into the read-only central shared repository.

![GitHub Triangle][1]

## Fork the repository

Create a fork of the **PowerShell/Community-Blog** repository into your own GitHub account using
the GitHub website.

A personal fork is required since the main repositories provide read-only access. To make changes,
you must submit a [pull request][2] from your fork into the main repository. To facilitate this
process, you first need your own copy of the repository. A GitHub _fork_ serves that purpose.

1. Go to [https://github.com/PowerShell/Community-Blog][3]
   and click the **Fork** button on the upper right.

   ![GitHub profile example][4]

2. If you are prompted, select your GitHub account tile as the destination where the fork should be
   created. This prompt creates a copy of the repository within your GitHub account, known as a
   fork.

## Choose a local folder

Make a local folder to hold a copy of the repository locally. Some repositories can be large; up to
5 GB for Community-Blog for example. Choose a location with available disk space.

1. Choose a foldername should be easy for you to remember and type. For example, consider a root
   folder `C:\Git\` or make a folder in your user profile directory `~/Documents/Git/`

   > [!IMPORTANT]
   > Avoid choosing a local folder path that's nested inside of another git repository folder
   > location. While it's acceptable to store the git cloned folders adjacent to each other, nesting
   > git folders inside one another causes errors for the file tracking.

1. From the PowerShell command line, change directory (`cd`) into the folder that you created for
   hosting the repository locally. Note that Git Bash uses the Linux convention of forward-slashes
   instead of back-slashes for folder paths.

   For example, `cd ~/Documents/Git/`

## Create a local clone

Prepare to run the **clone** command to pull a copy of a repository (your fork) down to your device
on the current directory.

### Authenticate using Git Credential Manager

If you installed the latest version of Git for Windows and accepted the default installation, Git
Credential Manager is enabled by default. Git Credential Manager makes authentication much easier
because you don't need to recall your personal access token when re-establishing authenticated
connections and remotes with GitHub.

1. Run the **clone** command, by providing the repository name. Cloning downloads (clone) the forked
   repository on your local computer.

    > [!Tip]
    > You can get your fork's GitHub URL for the clone command from the **Clone or download** button
    > in the GitHub UI:
    >
    > ![Clone or download][5]

    Be sure to specify the path to *your fork* during the cloning process, not the main repository
    from which you created the fork. Otherwise, you cannot contribute changes. Your fork is
    referenced through your personal GitHub user account, such as
    `github.com/<github-username>/<repo>`.

    ```powershell
    git clone https://github.com/<github-username>/<repo>.git
    ```

    Your clone command should look similar to this example:

    ```powershell
    git clone https://github.com/MyGitAccount/Community-Blog.git
    ```

1. When you're prompted, enter your GitHub credentials.

    ![GitHub Login][6]

1. When you're prompted, enter your two-factor authentication code.

    ![GitHub two-factor authentication][7]

    > [!NOTE]
    > Your credentials are saved and used to authenticate future GitHub requests. You only need to
    > do this authentication once per computer.

1. The clone command downloads a copy of the files from your fork of the repository into a new
   folder on the local disk. The new folder is created within the current folder. It may take a few
   minutes, depending on the repository size. You can explore the folder to see the structure once
   it is finished.

## Configure remote upstream

After cloning the repository, set up a read-only remote connection to the main repository named
**upstream**. You use the upstream URL to keep your local repository in sync with the latest changes
made by others. The **git remote** command is used to set the configuration value. You use the
**fetch** command to refresh the branch info from the upstream repository.

1. Use the following commands.

   ```powershell
   cd Community-Blog
   git remote add upstream https://github.com/PowerShell/Community-Blog.git
   git fetch upstream
   ```

1. View the configured values and confirm the URLs are correct. Ensure the **origin** URLs point to
   your personal fork. Ensure the **upstream** URLs point to the main repository, such as
   MicrosoftDocs or Azure.

   ```powershell
   git remote -v
   ```

   Example remote output is shown. A fictitious git account named MyGitAccount is configured with a
   personal access token to access the repo Community-Blog:

   ```output
   origin  https://github.com/MyGitAccount/Community-Blog.git (fetch)
   origin  https://github.com/MyGitAccount/Community-Blog.git(push)
   upstream        https://github.com/PowerShell/Community-Blog.git (fetch)
   upstream        https://github.com/PowerShell/Community-Blog.git (push)
   ```

1. If you made a mistake, you can remove the remote value. To remove the upstream value, run the
   command `git remote remove upstream`.

<!-- link references -->
[1]: ./media/Setup-GitHub-for-Local-Workflow/git-and-github-initial-setup.png
[2]: https://docs.microsoft.com/contribute/git-github-fundamentals
[3]: https://github.com/PowerShell/Community-Blog
[4]: ./media/Setup-GitHub-for-Local-Workflow/fork.png
[5]: ./media/Setup-GitHub-for-Local-Workflow/clone-or-download.png
[6]: ./media/Setup-GitHub-for-Local-Workflow/github-login.png
[7]: ./media/Setup-GitHub-for-Local-Workflow/github-2fa.png
