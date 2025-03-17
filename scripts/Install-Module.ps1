<#
.SYNOPSIS
    Installs the snowUtils PowerShell module from GitHub Packages
.DESCRIPTION
    This script registers the GitHub Packages repository and installs the snowUtils module
.PARAMETER GitHubToken
    A GitHub personal access token with the 'read:packages' scope
.PARAMETER Scope
    The scope for the module installation (AllUsers or CurrentUser)
.EXAMPLE
    ./Install-Module.ps1 -GitHubToken "ghp_your_token_here"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
)

# Register GitHub Packages as a repository if it's not already registered
$repoName = "schnow265"
$existingRepo = Get-PSRepository -Name $repoName -ErrorAction SilentlyContinue

if (-not $existingRepo) {
    Write-Host "Registering GitHub Packages repository..." -ForegroundColor Yellow
    $credential = New-Object System.Management.Automation.PSCredential("schnow265", (ConvertTo-SecureString $GitHubToken -AsPlainText -Force))
    
    Register-PSRepository -Name $repoName `
                         -SourceLocation "https://nuget.pkg.github.com/schnow265/index.json" `
                         -PublishLocation "https://nuget.pkg.github.com/schnow265/index.json" `
                         -InstallationPolicy Trusted `
                         -Credential $credential
}

# Install the module
Write-Host "Installing snowUtils module..." -ForegroundColor Yellow
$credential = New-Object System.Management.Automation.PSCredential("schnow265", (ConvertTo-SecureString $GitHubToken -AsPlainText -Force))
Install-Module -Name schnow265.snowUtils -Repository $repoName -Credential $credential -Scope $Scope -Force

Write-Host "snowUtils module has been installed!" -ForegroundColor Green