# Script to update the ModuleVersion in a PowerShell module manifest (.psd1)
param (
    [Parameter(Mandatory)]
    [string]$ManifestPath,

    [Parameter(Mandatory)]
    [string]$NewVersion
)

# Check if the file exists
if (-not (Test-Path -Path $ManifestPath)) {
    throw "Manifest file not found at path: $ManifestPath"
}

# Import the module manifest
try {
    $manifest = Import-PowerShellDataFile -Path $ManifestPath
} catch {
    throw "Failed to import module manifest. Ensure it's a valid .psd1 file."
}

# Check for the ModuleVersion key
if (-not $manifest.ContainsKey('ModuleVersion')) {
    throw "Manifest file does not contain a 'ModuleVersion' key."
}

# Update the ModuleVersion
$oldVersion = $manifest.ModuleVersion
$updatedContent = Get-Content -Path $ManifestPath | ForEach-Object {
    $_ -replace "ModuleVersion\s*=\s*'[^']+'", "ModuleVersion = '$NewVersion'"
}

# Save the updated content back to the manifest file
Set-Content -Path $ManifestPath -Value $updatedContent -Force

Write-Host "Updated ModuleVersion from $oldVersion to $NewVersion in $ManifestPath"
