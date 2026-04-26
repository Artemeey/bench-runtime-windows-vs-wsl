# Считаем количество файлов рекурсивно.

param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

# Определяем корень теста для выбранного режима native/proxy.
$root = & "$PSScriptRoot\fs-path.ps1" $Proxy

if (-not [System.IO.Directory]::Exists($root)) {
	Write-Error "Path not found: $root"
	exit 1
}

# Фиксируем стартовые значения CPU текущего процесса PowerShell.
$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

# Запускаем измерение wall-clock времени.
$timer = [System.Diagnostics.Stopwatch]::StartNew()

$count = 0
foreach ($file in [System.IO.Directory]::EnumerateFiles($root, "*", [System.IO.SearchOption]::AllDirectories)) {
	$count++
}

# Останавливаем таймер и обновляем процесс для финальных метрик CPU.
$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds
$culture = [System.Globalization.CultureInfo]::InvariantCulture

# Печатаем результат в формате для run.ps1.
Write-Output ("files: {0}" -f $count)
Write-Output ("time: {0} sec" -f $timer.Elapsed.TotalSeconds.ToString($culture))
Write-Output ("cpu_user: {0} sec" -f $userCpu.ToString($culture))
Write-Output ("cpu_sys: {0} sec" -f $sysCpu.ToString($culture))
