# Считаем количество файлов рекурсивно.

param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

. "$PSScriptRoot\.utils.ps1"

Import-ProjectEnv -ProjectRoot (Split-Path -Parent $PSScriptRoot)

$root = Get-RootPath -Proxy $Proxy
Confirm-DirectoryExists -Path $root

$statsStart = Get-StatsSnapshot

$count = 0
foreach ($file in [System.IO.Directory]::EnumerateFiles($root, "*", [System.IO.SearchOption]::AllDirectories)) {
	$count++
}

# Снимаем текущие метрики после завершения теста.
$statsCurrent = Get-StatsSnapshot

Write-TestResult -Files $count -StatsStart $statsStart -StatsCurrent $statsCurrent
