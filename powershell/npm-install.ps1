# Выполняем бенчмарк установки npm-зависимостей с кешем и без кеша.

param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy,

	[Parameter(Mandatory = $true)]
	[bool]$UseCache
)

# Определяем директорию npm-теста для выбранного режима native/proxy.
$root = & "$PSScriptRoot\fs-path.ps1" $Proxy
$npmDir = Join-Path $root "npm-install"

# Удаляем node_modules перед каждым прогоном для одинаковых стартовых условий.
Remove-Item -LiteralPath (Join-Path $npmDir "node_modules") -Recurse -Force -ErrorAction SilentlyContinue

# Для сценария без кеша запускаем команду очистки npm cache перед установкой.
if (-not $UseCache) {
	npm cache clean --force | Out-Null
}

# Фиксируем стартовые значения CPU текущего процесса PowerShell.
$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

# Запускаем измерение wall-clock времени.
$timer = [System.Diagnostics.Stopwatch]::StartNew()

npm ci --prefix $npmDir | Out-Null

# Останавливаем таймер и обновляем процесс для финальных метрик CPU.
$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds
$culture = [System.Globalization.CultureInfo]::InvariantCulture

# Подсчитываем итоговое количество файлов в node_modules для поля files.
$count = 0
$nodeModules = Join-Path $npmDir "node_modules"
if ([System.IO.Directory]::Exists($nodeModules)) {
	foreach ($file in [System.IO.Directory]::EnumerateFiles($nodeModules, "*", [System.IO.SearchOption]::AllDirectories)) {
		$count++
	}
}

# Печатаем результат в формате для run.ps1.
Write-Output ("files: {0}" -f $count)
Write-Output ("time: {0} sec" -f $timer.Elapsed.TotalSeconds.ToString($culture))
Write-Output ("cpu_user: {0} sec" -f $userCpu.ToString($culture))
Write-Output ("cpu_sys: {0} sec" -f $sysCpu.ToString($culture))
