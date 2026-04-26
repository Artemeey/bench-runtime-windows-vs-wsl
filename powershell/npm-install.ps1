# Выполняем бенчмарк установки npm-зависимостей с кешем и без кеша.

param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy,

	[Parameter(Mandatory = $true)]
	[bool]$UseCache
)

. "$PSScriptRoot\.utils.ps1"

Import-ProjectEnv -ProjectRoot (Split-Path -Parent $PSScriptRoot)

$root = Get-RootPath -Proxy $Proxy
Confirm-DirectoryExists -Path $root

$statsStart = Get-StatsSnapshot

$npmDir = Join-Path $root "npm-install"

# Удаляем node_modules перед каждым прогоном для одинаковых стартовых условий.
Remove-Item -LiteralPath (Join-Path $npmDir "node_modules") -Recurse -Force -ErrorAction SilentlyContinue

# Для сценария без кеша запускаем команду очистки npm cache перед установкой.
if (-not $UseCache) {
	npm cache clean --force | Out-Null
}

# Запускаем npm ci из директории теста.
Push-Location $npmDir
try {
	npm ci --ignore-scripts | Out-Null
} finally {
	Pop-Location
}

# Снимаем текущие метрики после завершения теста.
$statsCurrent = Get-StatsSnapshot

# Подсчитываем итоговое количество файлов в node_modules для поля files.
$count = 0
$nodeModules = Join-Path $npmDir "node_modules"
if ([System.IO.Directory]::Exists($nodeModules)) {
	foreach ($file in [System.IO.Directory]::EnumerateFiles($nodeModules, "*", [System.IO.SearchOption]::AllDirectories)) {
		$count++
	}
}

# IncludeCpu = false - Не получаем информацию CPU от npm процесса
Write-TestResult -Files $count -StatsStart $statsStart -StatsCurrent $statsCurrent -IncludeCpu $false
