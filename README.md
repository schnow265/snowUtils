# snowUtils

A collection of Functions and Cmdlets which I use regularly.

## Installation

### Option 1: Install from GitHub Packages

1. Create a GitHub Personal Access Token with the `read:packages` permission
2. Run the installation script:

```powershell
# Download and run the installation script
$installScript = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/schnow265/snowUtils/main/scripts/Install-Module.ps1"
Invoke-Expression $installScript.Content
Install-Module.ps1 -GitHubToken "your-github-token-here"
```

### Option 2: Manual Build and Import

This project follows the Compiler-Compiler Problem (use the compiled software to compile itself). It essentially boils down to this:

- The first compile needs to be manual
- From the second one onward you can use an internal function called ``Build-Module`` which will rebuild the project and optionally load the just compiled module.

#### The first build

To build this module for Windows and load it, use these commands:

```powershell
dotnet restore -r win-x64
dotnet publish -r win-x64 -o ./build ./snowUtils

# load the module
Import-Module ./build/snowUtils.psd1

# Verify that the module has been loaded
Get-Module -Name snowUtils
```

#### Using the module to build the module easier

This module, as mentioned previously contains the Function ``Build-Module`` which can be used to rebuild the module and then (possibly) load it.

```powershell
Build-Module snowUtils; Import-Module .\build\snowUtils.psd1
```

## Creating a New Release

To create a new release:

1. Make your changes to the codebase
2. Run the `New-Release.ps1` script with the new version number:

```powershell
./scripts/New-Release.ps1 -Version "1.2.0"
```

3. Push the new tag to GitHub:

```powershell
git push origin v1.2.0
```

This will automatically trigger the GitHub workflow to build, create a release, and publish the module.

## Features

- Git branch management with `Clear-Branches` cmdlet
- System cleanup utilities with `Clear-SystemData`
- Lorem ipsum generation with `New-LoremDump`
- SSH key deployment with `Copy-SSHKey`
- PowerShell module building utilities with `Build-Module`
