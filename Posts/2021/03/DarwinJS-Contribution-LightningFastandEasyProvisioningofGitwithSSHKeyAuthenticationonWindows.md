---
post_title: Lightning Fast and Easy Provisioning of Git with SSH Key Authentication on Windows
username: DarwinJS
Catagories: PowerShell
tags: Git, DevOps
Summary: Getting your team setup with Git over SSH as quickly as possible!
featured_image: ./media/DarwinJS-Contribution-LightningFastandEasyProvisioningofGitwithSSHKeyAuthenticationonWindows/windows-git-ssh.png
CanonicalURL: https://missionimpossiblecode.io/post/lightning-fast-and-easy-provisioning-of-git-with-ssh-key-authentication-on-windows/
---

Maybe you have a team of Windows developers that are onboarding for your new Git server installation or maybe you've decided to drop http password authentication to your existing Git server (due to it's many problems).  Your next steps may well be into a rough and rocky rabbit hole when you were holding out hope for simplicity (you know the kind you've fallen into before if you've been in tech for more than about 45 minutes).

The common Internet guidance for setting up Git with SSH authentication on Windows are unnecessarily complex.

My inner tool smith really loathes when the very first steps into something new are fraught with rocky rabbit holes - so I took on the challenge of creating an easier way. 

The resultant tool is a 20 line PowerShell script that deploys Git, configures SSH and leaves the public key on your clipboard so you can paste it into GitLab or any other Git collaborative webserver. There is also an optional connectivity test.

## Reasons For Moving to SSH

There are multiple reasons you may want to move your Windows developers to SSH authentication for Git:

1. You want to get away from git storing local passwords - whether in the git config or in Windows Credentials (with the windows credential helper) because it is painful to walk people through how to find and update this password when they change it on the Git server.
2. You want to avoid both http passwords and the http protocol for git CLI operations.

## Conventional Wisdom on SSH Configuration

The conventional wisdom solution offers many steps that are roughly:

1. Installing git manually.
2. Installing the well known Windows SSH client Putty.
3. Installing Putty's key generator.
4. Converting the non-compatible putty generated key into an ssh compatible one.
5. Precisely placing the SSH key on disk.
6. Precisely and manually permissioning the SSH key and it's parent folder (ssh is purposely fussy about this in order to keep the key secure).

> Most of this can be avoided by simply using the full SSH client that is embedded inside of the Windows git client install.

## The Cleanest Way (With Working Automation Code)

Mission Impossible Code is an evolving hypothesis I have about how specific architectural design heuristics can yield simpler, more flexible and robust solutions.  If you become curious to know more, you can checkout [Mission Impossible Code Heuristics for Creating Super-Spy Code That Always Gets the Job Done](https://missionimpossiblecode.io/post/mission-impossible-code-heuristics-for-creating-super-spy-code-that-always-gets-the-job-done/).

### Mission Impossible Coding Principal 1: Steal Lessons From Desired State Automation

The code in this article is idempotent or "desired state oriented" - meaning that it always checks if the system is already in the desired state and only takes action if it is not. While coding this way takes a little extra effort, there are multiple rewards:

1. Reduction in runtime if something is already installed or configured correctly.
2. Does not accidentally upgrade software nor destroy existing configurations (e.g. this code will not accidentally overwrite a pre-existing primary ssh key).
3. If the code fails, it can be run again until it works because it picks up where it left off.

### Mission Impossible Coding Principal 2: Reduce Unnecessary Complexity

This code also lowers complexity in other ways:

1. By using the presence of a data value as a switch.  In this case, if SSHEndPointToGitForTesting contains a value, then an SSH connect test is done, otherwise the test is simply assumed to be disabled on purpose.
2. The parameters for triggering a test can be hard coded or passed in environment variables - keeping the code simple, but compatible with the possibility of multiple git server endpoints and with enclosing automation.
3. By selecting a single test that tests for the maximum problematic connectivity conditions. In this case, using an SSH login tests all end-to-end connectivity at all ISO layers between the client and the git server as well as SSL configuration. It also tests the authentication mechanisms of the server and that the SSH key was added to the correct place in the git server. Another great trick for simpler scenarios is using a tcp connect test instead of ping. This could also be updated to do a tcp connect test **only if** the ssh login fails - sort of building in self-diagnosing intelligence.

### Mission Impossible Coding Principal 3: Enable Zero Footprint Execution of the Latest Version (Directly From Repository)

Like many Mission Impossible Code examples, this one is designed and test to be executed directly from a git raw URL to make it easily used from a single repository location.  Here is the command to run it from the source location:

`Invoke-Expression -command "Invoke-WebRequest -uri 'https://gitlab.com/missionimpossiblecode/MissionImpossibleCode/-/raw/master/install-gitwithssh.ps1' -UseBasicParsing -OutFile ./install-gitwithssh.ps1" ; . ./install-gitwithssh.ps1`

### Code Behavior

1. If not present, automatically installs Git.
2. If not present, automatically installs chocolatey to install Git.
3. If not present, automatically generates an SSH key.
4. Key generation always uses the Git's built-in SSH client to create SSH keys (avoids much of the complexity of the above conventional wisdom approach).
5. Copies the public key to the clip board and pauses for the user to add it to the Git server (in their profile).
6. Optionally does a SSH login test (only if you provide a value for: $SSHEndPointToGitForTesting).

## Solution Details

This code can be run directly from GitLab with this command:

```powershell
Invoke-Expression -command "Invoke-WebRequest -uri 'https://gitlab.com/missionimpossiblecode/MissionImpossibleCode/-/raw/master/install-gitwithssh.ps1' -UseBasicParsing -OutFile ./install-gitwithssh.ps1" ; . ./install-gitwithssh.ps1
```

If you want to download dynamically, but also want the test and instructions to work, then set these environment variables before calling the above:

```powershell
$env:YourGitServerhttpURL="https://gitlab.com"
$env:GitSSHUserAndEndPointForTesting="git@gitlab.com" #some Git servers might want the windows userid "git", which is specified as $env:username
```

You can also simply copy the code, hardcode the two variables and distribute it in your organization.

## Main Code

```powershell
# Set environment variables before calling in order to test
If ((Test-Path env:YourGitServerhttpURL) -and (!(Test-Path variable:YourGitServerhttpURL))) {$YourGitServerhttpURL="$env:YourGitServerhttpURL"}
If ((Test-Path env:GitSSHUserAndEndPointForTesting) -and (!(Test-Path variable:GitSSHUserAndEndPointForTesting))) {$GitSSHUserAndEndPointForTesting="$env:GitSSHUserAndEndPointForTesting"}
# $YourGitServerhttpURL="https://gitlab.com" 
# $GitSSHUserAndEndPointForTesting="$env:username@gitlab.com" #Optional to trigger testing Use "git@gitlab.com" for GitLab.

If (!(Test-Path 'C:\Program Files\git\usr\bin\ssh-keygen.exe'))
{
  Write-Host 'Installing latest git client using Chocolatey'
  If (!(Test-Path env:chocolateyinstall)) 
  {
    Write-Host "Chocolatey is not present, installing on demand."
    iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
  } 
  cinst -y git
}
If (!(Test-Path $env:userprofile\.ssh\id_rsa.pub))
{ 
  Write-Host 'No default ssh key present in $env:userprofile\.ssh, generating a new one.'
  Write-Warning 'Press enter for default file name and twice for password to set it to not have a password'
  & 'C:\Program Files\git\usr\bin\ssh-keygen.exe'
}
get-content $env:userprofile\.ssh\id_rsa.pub | clip
write-host "Your public ssh key is now on your clipboard, ready to be pasted into your git server at $YourGitServerhttpURL"

If (Test-Path variable:GitSSHUserAndEndPointForTesting)
{
  Write-Host 'NOTE: Sometimes it takes a while for your Git server to propagate your key so it is available for authentication after first adding it!'
  Write-Host 'After you have setup the key, to test the connection, press any key to continue...';
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  #Use git's open ssh:
  Write-Host "...Testing ssh login as ${GitSSHUserAndEndPointForTesting} using key $env:userprofile\.ssh\id_rsa on port 22"
  $env:term = 'xterm256colors'
  push-location 'c:\program files\git\usr\bin'
  .\ssh.exe "${GitSSHUserAndEndPointForTesting}" -i $env:userprofile\.ssh\id_rsa -p 22
  pop-location
  Write-Host 'After observing the test result above (note it may take time for your new key to propagate at the server), press any key to continue...';
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
```

## Code For This Article

[install-gitwithssh.ps1](https://gitlab.com/missionimpossiblecode/MissionImpossibleCode/-/blob/master/install-gitwithssh.ps1)
