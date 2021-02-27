---
post_title: Lightning Fast and Easy Provisioning of Git with SSH Key Authentication on Windows
username: DarwinJS@sanoys.com
Catagories: PowerShell
tags: Git, DevOps
Summary: Getting your team setup with Git over SSH as quickly as possible!
featured_image: ./media/DarwinJS-Contribution-LightningFastandEasyProvisioningofGitwithSSHKeyAuthenticationonWindows/windows-git-ssh.png
CanonicalURL: https://missionimpossiblecode.io/post/lightning-fast-and-easy-provisioning-of-git-with-ssh-key-authentication-on-windows/
---


Maybe you have a team of Windows developers that are onboarding for your new Git server installation or maybe you've decided to drop http password authentication to your existing Git server (due to it's many problems).  Your next steps may well be into a rough and rocky rabbit hole when you were holding out hope for simplicity (you know the kind you've fallen into before if you've been in tech for more than about 45 minutes).

The guides on the internet for getting Windows setup for SSH authentication for Git are unnecessarily complex.

My inner tool smith really loathes when the very first steps into something new are fraught with rocky rabbit holes - so I took on the challenge of creating an easier way. 

The resultant tool is a 20 line PowerShell script that deploys Git, configures SSH and leaves the public key on your clipboard so you can paste it into GitLab or any other Git collaborative webserver. There is also an optional connectivity test.

<!-- more -->

## Reasons For Moving to SSH

There are multiple reasons you may want to move your Windows developers to SSH authentication for Git:

1. You want to get away from git storing local passwords - whether in the git config or in Windows Credentials (with the windows credential helper) because it is pure pain to walk people through how to find and update this password when they change it on the Git server.
2. You want to avoid both http passwords and the http protocol for git.

## Conventional Wisdom on SSH Configuration

The conventional wisdom solution offers many steps that are roughly:

1. Installing git manually.
2. Installing the well known Windows SSH client Putty
3. Installing Putty's key generator.
4. Converting the non-compatible putty generated key into an ssh compatible one.
5. Precisely placing the SSH key on disk.
6. Precisely and ~~manually~~ permissioning the SSH key and it's parent folder (ssh is purposely fussy about this in order to keep the key secure).

> Most of this can be avoided by simply using the full SSH client that is embedded inside of the Windows git client install.

## The Cleanest Way (With Working Automation Code) 

Besides the above pure pain, here are the additional things solved for in this code:

1. Automatically installs Git - but only if necessary (idempotent)
2. Automatically installs chocolatey to install Git - but only if necessary (idempotent)
3. Automatically generates an SSH key - but only if necessary (idempotent) (which avoids killing a key that might be in use)
4. Uses the Git's built-in SSH client to create SSH keys (avoids the complexity of the above conventional wisdom)
5. Copies the public key to the clip board and pauses for the user to add it to the Git server (in their profile)
6. Optionally does a SSH login test if you provide a value for: $SSHEndPointToGitForTesting

## Solution Details

This code can be run directly from GitLab with this command:

```bash
Invoke-Expression -command "Invoke-WebRequest -uri 'https://gitlab.com/missionimpossiblecode/MissionImpossibleCode/-/raw/master/install-gitwithssh.ps1' -UseBasicParsing -OutFile ./install-gitwithssh.ps1" ; . ./install-gitwithssh.ps1
```

If you want to download dynamically, but also want the test and instructions to work, then set these environment variables before calling the above:

```bash
$env:YourGitServerhttpURL="https://gitlab.com"
$env:GitSSHUserAndEndPointForTesting="git@gitlab.com" #some Git servers might want the windows userid "git", which is specified as $env:username
```

You can also simply copy the code, hardcode the two variables and distribute it in your organization.

## Main Code

```bash

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
