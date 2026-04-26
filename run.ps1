# Запускаем все бенчмарки проекта и сохраняем результаты в CSV.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()
$emojiRuntime = [char]::ConvertFromUtf32(0x1F7EA) # 🟪 Маркер блока runtime.
$emojiTest = [char]::ConvertFromUtf32(0x1F9EA) # 🧪 Маркер запуска теста.
$emojiModeNative = [char]::ConvertFromUtf32(0x1F7E2) # 🟢 Маркер режима native.
$emojiModeProxy = [char]::ConvertFromUtf32(0x1F7E3) # 🟣 Маркер режима proxy.

$projectRoot = $PSScriptRoot
$powershellTestsDir = Join-Path $projectRoot "powershell"
$resultsDir = Join-Path $projectRoot "results"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

$csv = Join-Path $resultsDir "results.csv"
$resultsTxt = Join-Path $resultsDir "results.txt"
if (-not (Test-Path -LiteralPath $csv)) {
	"runtime,test,cross_fs,cache,files,time,cpu_user,cpu_sys" | Out-File $csv -Encoding utf8
}

# Приводим вывод отдельного теста к формату CSV-полей.
function Parse-Result {
	param ($output)

	$files = ($output | Where-Object { $_ -like "files:*" }) -replace "files: ", ""
	$time = ($output | Where-Object { $_ -like "time:*" }) -replace "time: ", "" -replace " sec", ""
	$user = (($output | Where-Object { $_ -like "cpu_user:*" }) -replace "cpu_user: ", "" -replace " sec", "")
	$sys = (($output | Where-Object { $_ -like "cpu_sys:*" }) -replace "cpu_sys: ", "" -replace " sec", "")

	return @{ files=$files; time=$time; cpu_user=$user; cpu_sys=$sys }
}

# Выполняем один тест и пишем строку результата с метаданными сценария.
function Run-Test {
	param ($name, $crossFs, $cache, $script, $argsText)

	# Печатаем короткий заголовок сценария, чтобы тесты не сливались в логе.
	Write-Output ""
	Write-Output "$emojiTest $name | cross_fs=$crossFs | cache=$cache | args=$argsText"

	$output = & $script
	$output | Write-Output
	$res = Parse-Result $output

	"powershell,$name,$crossFs,$cache,$($res.files),$($res.time),$($res.cpu_user),$($res.cpu_sys)" | Add-Content $csv
}

. "$powershellTestsDir\.utils.ps1"
Import-ProjectEnv -ProjectRoot $projectRoot

$nodeVersion = ((node -v 2>$null) -join '').Trim()
$npmVersion = ((npm -v 2>$null) -join '').Trim()
$wslVersionRaw = ((wsl --version 2>$null | Select-Object -First 1) -join '').Trim()
$wslVersionClean = ($wslVersionRaw -replace "`0", "")
$wslVersion = [regex]::Match($wslVersionClean, '\d+(\.\d+)+').Value
$osVersion = ((Get-CimInstance Win32_OperatingSystem 2>$null | Select-Object -First 1 | ForEach-Object { "$($_.Caption) $($_.Version)" }) -join '').Trim()

# Сохраняем версии инструментов и параметры запуска в текстовый отчёт.
if (Test-Path -LiteralPath $resultsTxt) {
	Add-Content -Path $resultsTxt -Value ""
}

$reportLines = @(
	"$emojiRuntime runtime: powershell"
	"runtime: powershell"
	"os_windows: $osVersion"
	"powershell: $($PSVersionTable.PSVersion)"
	"node: $nodeVersion"
	"npm: $npmVersion"
	"wsl: $wslVersion"
	"TESTS_FS_WINDOWS: $($env:TESTS_FS_WINDOWS)"
	"TESTS_FS_WSL: $($env:TESTS_FS_WSL)"
	"WSL_DISTRO: $($env:WSL_DISTRO)"
)

$reportLines | Write-Output
$reportLines | Add-Content -Path $resultsTxt -Encoding utf8

Write-Output ""
& "$powershellTestsDir\setup-fs.ps1"

Write-Output ""

# Сначала запускаем все native-сценарии (cross_fs=false).
Write-Output "$emojiModeNative Запускаем режим native (cross_fs=false)"
Run-Test "files-find" "false" "none" { & "$powershellTestsDir\files-find.ps1" $false } "proxy=false"
Run-Test "files-create-delete" "false" "none" { & "$powershellTestsDir\files-create-delete.ps1" $false } "proxy=false"
Run-Test "npm-install" "false" "true" { & "$powershellTestsDir\npm-install.ps1" $false $true } "proxy=false,use_cache=true"
Run-Test "npm-install" "false" "false" { & "$powershellTestsDir\npm-install.ps1" $false $false } "proxy=false,use_cache=false"

# Затем запускаем все proxy-сценарии (cross_fs=true).
Write-Output "$emojiModeProxy Запускаем режим proxy (cross_fs=true)"
Run-Test "files-find" "true" "none" { & "$powershellTestsDir\files-find.ps1" $true } "proxy=true"
Run-Test "files-create-delete" "true" "none" { & "$powershellTestsDir\files-create-delete.ps1" $true } "proxy=true"
Run-Test "npm-install" "true" "true" { & "$powershellTestsDir\npm-install.ps1" $true $true } "proxy=true,use_cache=true"
Run-Test "npm-install" "true" "false" { & "$powershellTestsDir\npm-install.ps1" $true $false } "proxy=true,use_cache=false"
