$binaryPath = Join-Path -Path $PSScriptRoot -ChildPath 'snowUtils.dll'

if (Test-Path $binaryPath) {
    Import-Module -Name $binaryPath -PassThru | Out-Null
    Write-Host "Binary Module loaded! All of the funny C# cmdlets should run now!"
} else {
    Write-Error "Binary module not found at path: $binaryPath"
    exit 1
}

# old-style PowerShell stuff.
# TODO: Update everything to a Binary Module

function Test-Command {
    Param ($command)
    $prefstore = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    $res = $false

    try {
        if (Get-Command $command) { $res = $true }
    }
    catch {
        $res = $false
    }
    finally {
        $ErrorActionPreference = $prefstore
    }

    return $res
}

function Clear-SystemData {
    if (Test-Path $HOME/.gradle) {
        Write-Host "Removing the gradle cache..."
        Remove-Item -Recurse -Force $HOME/.gradle
    }

    if (Test-Path $HOME/.m2/repository) {
        Write-Host "Removing the maven cache..."
        Remove-Item -Recurse -Force $HOME/.m2/repository
    }

    if (Test-Command pip) {
        Write-Host "Removing all system-wide installed pip packages..."
        pip freeze | ForEach-Object { pip uninstall $_ -y }
    }

    if (Test-Command dotnet) {
        Write-Host "Clearing the NuGet caches..."
        dotnet nuget locals --clear all
    }

    if (Test-Command scoop) {
        Write-Host "Cleaning up scoop..."
        scoop cache rm *
        scoop cleanup *
    }

    if (Test-Command podman) {
        podman machine start

        podman container prune -f
        podman image prune -f

        podman machine stop
    }

    if (Test-Command choco) {
        if (Test-Command sudo) {
            if (!(Test-Path "C:\tools\BCURRAN3\choco-cleaner.ps1")) {
                sudo choco install choco-cleaner
            }
            sudo "C:\tools\BCURRAN3\choco-cleaner.ps1"
        }
        else {
            Write-Host -ForegroundColor Red "Please install a 'sudo' binary to clean up chcoco packages."
        }
    }

    Clear-RecycleBin -DriveLetter C -Force

    Write-Host "We are done here!" -ForegroundColor Green
}

function Unblock-Recurse {
    [CmdletBinding()]
    param ()

    $previous = Get-ExecutionPolicy -Scope Process
    Set-ExecutionPolicy Bypass -Scope Process
    Get-ChildItem -Path (Get-Location).Path -Recurse | Unblock-File

    Set-ExecutionPolicy $previous
}

function Copy-SSHKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RemoteHost,

        [Parameter(Mandatory)]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Password,

        [string]$KeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub",

        [string]$Port = "22"
    )

    Write-Host "Starting Copy-SSHKey function..." -ForegroundColor Cyan

    # Check if the public key file exists
    Write-Host "Checking if public key exists at $KeyPath..." -ForegroundColor Cyan
    if (!(Test-Path -Path $KeyPath)) {
        Write-Error "Public key not found at $KeyPath. Generate an SSH key pair first."
        return
    }

    Write-Host "Public key found. Reading the key..." -ForegroundColor Cyan
    # Read the public key
    $PublicKey = Get-Content -Path $KeyPath -Raw

    Write-Host "Public key read successfully." -ForegroundColor Green

    # Use SSH to append the public key to the authorized_keys file on the remote host
    #     $ScriptBlock = @"
    #         mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$PublicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
    # "@

    try {
        Write-Host "Copying SSH key to $RemoteHost..." -ForegroundColor Green

        # Execute the script block on the remote host
        Write-Host "Creating secure credential object..." -ForegroundColor Cyan
        $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

        Write-Host "Executing script block on remote host $RemoteHost using port $Port..." -ForegroundColor Cyan
        Invoke-Command -HostName $RemoteHost -Credential $Credential -Port $Port -ScriptBlock {
            param ($PublicKey)
            
            # This runs on the Remote Host
            
            Write-Host "Creating .ssh directory and setting permissions..." -ForegroundColor Yellow
            mkdir -p ~/.ssh
            chmod 700 ~/.ssh

            Write-Host "Checking if public key already exists in authorized_keys..." -ForegroundColor Yellow
            if (!(Select-String -Path ~/.ssh/authorized_keys -Pattern [regex]::Escape($PublicKey))) {
                Write-Host "Public key not found. Appending to authorized_keys..." -ForegroundColor Yellow
                Add-Content -Path ~/.ssh/authorized_keys -Value $PublicKey
            }
            else {
                Write-Host "Public key already exists in authorized_keys." -ForegroundColor Green
            }

            chmod 600 ~/.ssh/authorized_keys
            Write-Host "Permissions updated for authorized_keys." -ForegroundColor Green
            # exited the remote host
        } -ArgumentList $PublicKey

        Write-Host "SSH key successfully copied to $RemoteHost." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy SSH key: $_"
    }

    Write-Host "Copy-SSHKey function execution completed." -ForegroundColor Cyan
}

function Build-Module {
    [CmdletBinding()]
    param (
        [string] $ModuleName,

        $TargetPlatform = "win-x64",

        $TargetPath = ".\build",
        
        [bool] $LoadDirectly = $true
    )

    Remove-Module $ModuleName -ErrorAction SilentlyContinue

    dotnet restore -r $TargetPlatform
    dotnet publish -r $TargetPlatform -o $TargetPath "./$ModuleName"

    if ($LoadDirectly) {
        if (!(Test-Path "./$TargetPath/$ModuleName.psd1")) {
            Write-Error "The module $ModuleName does NOT have a module manifest file ($ModuleName.psd1) located at './$TargetPath/$ModuleName.psd1'. Please create one according to Microsoft's Documentation and set the build action to 'Copy Always' in the Project file."
            exit 1
        }

        Import-Module ".\$TargetPath\$ModuleName.psd1"
        Write-Host -ForegroundColor Yellow "Module $ModuleName loaded!"

        Get-Module $ModuleName
    }
}

Export-ModuleMember -Function Build-Module
Export-ModuleMember -Function Test-Command
Export-ModuleMember -Function Clear-SystemData
Export-ModuleMember -Function Unblock-Recurse
Export-ModuleMember -Function Copy-SSHKey