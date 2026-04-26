# Создаём и удаляем 10 000 файлов.

param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

. "$PSScriptRoot\.utils.ps1"

Import-ProjectEnv -ProjectRoot (Split-Path -Parent $PSScriptRoot)

$root = Get-RootPath -Proxy $Proxy
Confirm-DirectoryExists -Path $root

$statsStart = Get-StatsSnapshot

# Готовим уникальную директорию, чтобы тесты не конфликтовали между запусками.
$fileCount = 10000
$testDir = Join-Path $root ("files-create-delete-" + [System.Guid]::NewGuid().ToString())

New-Item -ItemType Directory -Force -Path $testDir | Out-Null

for ($i = 1; $i -le $fileCount; $i++) {
	[System.IO.File]::WriteAllText((Join-Path $testDir "file-$i.txt"), "test")
}

[System.IO.Directory]::Delete($testDir, $true)

# Снимаем текущие метрики после завершения теста.
$statsCurrent = Get-StatsSnapshot

Write-TestResult -Files $fileCount -StatsStart $statsStart -StatsCurrent $statsCurrent
