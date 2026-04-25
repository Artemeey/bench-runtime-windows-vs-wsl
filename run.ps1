# Runs all benchmarks for PowerShell.

$ErrorActionPreference = "Stop"

# Prepare benchmark folders before running tests.
& "$PSScriptRoot\setup-fs.ps1"

Write-Output ""
Write-Output "files-find native"
& "$PSScriptRoot\files-find.ps1" $false

Write-Output ""
Write-Output "files-find proxy"
& "$PSScriptRoot\files-find.ps1" $true

Write-Output ""
Write-Output "files-create-delete native"
& "$PSScriptRoot\files-create-delete.ps1" $false

Write-Output ""
Write-Output "files-create-delete proxy"
& "$PSScriptRoot\files-create-delete.ps1" $true

Write-Output ""
Write-Output "npm-install native cache"
& "$PSScriptRoot\npm-install.ps1" $false $true

Write-Output ""
Write-Output "npm-install native no-cache"
& "$PSScriptRoot\npm-install.ps1" $false $false

Write-Output ""
Write-Output "npm-install proxy cache"
& "$PSScriptRoot\npm-install.ps1" $true $true

Write-Output ""
Write-Output "npm-install proxy no-cache"
& "$PSScriptRoot\npm-install.ps1" $true $false
