<#
.SYNOPSIS
    Creates a new version release for the snowUtils module
.DESCRIPTION
    Updates version numbers and creates a tagged commit
.PARAMETER Version
    The new version number (format: x.y.z)
.PARAMETER Push
    Whether to automatically push changes and tags to origin
.EXAMPLE
    ./New-Release.ps1 -Version "1.1.0"
.EXAMPLE
    ./New-Release.ps1 -Version "1.1.0" -Push
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [switch]$Push
)

# Update the version in the manifest
$manifestPath = Join-Path $PSScriptRoot "..\snowUtils\snowUtils.psd1"
Write-Host "Updating module manifest version to $Version..." -ForegroundColor Yellow
& "$PSScriptRoot\Update-ManifestVersion.ps1" -ManifestPath $manifestPath -NewVersion $Version

# Update the version in the csproj file
$csprojPath = Join-Path $PSScriptRoot "..\snowUtils\snowUtils.csproj"
[xml]$csproj = Get-Content $csprojPath
$versionElement = $csproj.CreateElement("Version")
$versionElement.InnerText = $Version

$propertyGroup = $csproj.Project.PropertyGroup
if ($propertyGroup.Version) {
    $propertyGroup.Version = $Version
} else {
    $propertyGroup.AppendChild($versionElement)
}

$csproj.Save($csprojPath)
Write-Host "Updated project file version to $Version" -ForegroundColor Green

# Create git commit
Write-Host "Creating git commit for version $Version..." -ForegroundColor Yellow
git add $manifestPath
git add $csprojPath
git commit -m "Release version $Version"

# Create git tag
Write-Host "Creating git tag v$Version..." -ForegroundColor Yellow
git tag -a "v$Version" -m "Release version $Version"

if ($Push) {
    Write-Host "Pushing changes and tags to origin..." -ForegroundColor Yellow
    git push origin
    git push origin "v$Version"
    Write-Host "Changes and tags pushed successfully!" -ForegroundColor Green
    Write-Host "GitHub Actions workflow will automatically create a release and publish the module." -ForegroundColor Cyan
} else {
    Write-Host "Version update complete! Next steps:" -ForegroundColor Green
    Write-Host "1. Push your changes: git push origin" -ForegroundColor Cyan
    Write-Host "2. Push the tag to trigger release creation: git push origin v$Version" -ForegroundColor Cyan
}