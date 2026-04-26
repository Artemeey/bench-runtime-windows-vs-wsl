# Создаём и удаляем 10 000 файлов.

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

# Готовим уникальную директорию, чтобы тесты не конфликтовали между запусками.
$fileCount = 10000
$testDir = Join-Path $root ("files-create-delete-" + [System.Guid]::NewGuid().ToString())

New-Item -ItemType Directory -Force -Path $testDir | Out-Null

# Фиксируем стартовые значения CPU текущего процесса PowerShell.
$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

# Запускаем измерение wall-clock времени.
$timer = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $fileCount; $i++) {
	[System.IO.File]::WriteAllText((Join-Path $testDir "file-$i.txt"), "test")
}

[System.IO.Directory]::Delete($testDir, $true)

# Останавливаем таймер и обновляем процесс для финальных метрик CPU.
$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds
$culture = [System.Globalization.CultureInfo]::InvariantCulture

# Печатаем результат в формате для run.ps1.
Write-Output ("files: {0}" -f $fileCount)
Write-Output ("time: {0} sec" -f $timer.Elapsed.TotalSeconds.ToString($culture))
Write-Output ("cpu_user: {0} sec" -f $userCpu.ToString($culture))
Write-Output ("cpu_sys: {0} sec" -f $sysCpu.ToString($culture))
