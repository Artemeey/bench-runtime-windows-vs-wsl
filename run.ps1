# Запускаем все бенчмарки проекта и сохраняем результаты в CSV.

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$powershellTestsDir = Join-Path $projectRoot "powershell"
$resultsDir = Join-Path $projectRoot "results"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

$csv = Join-Path $resultsDir "results.csv"
"runtime,test,mode,cache,files,time,cpu_user,cpu_sys" | Out-File $csv -Encoding utf8

# Приводим вывод отдельного теста к формату CSV-полей.
function Parse-Result {
	param ($output)

	$files = ($output | Where-Object { $_ -like "files:*" }) -replace "files: ", ""
	$time = ($output | Where-Object { $_ -like "time:*" }) -replace "time: ", "" -replace " sec", ""
	$cpuLine = ($output | Where-Object { $_ -like "cpu:*" }) -replace "cpu: ", ""

	$parts = $cpuLine -split " user \+ "
	$user = $parts[0]
	$sys = ($parts[1] -replace " sys sec", "")

	return @{ files=$files; time=$time; cpu_user=$user; cpu_sys=$sys }
}

# Выполняем один тест и пишем строку результата с метаданными сценария.
function Run-Test {
	param ($name, $mode, $cache, $script, $argsText)

	# Выводим параметры сценария перед запуском теста.
	Write-Output "=== test ==="
	Write-Output "runtime: powershell"
	Write-Output "test: $name"
	Write-Output "mode: $mode"
	Write-Output "cache: $cache"
	Write-Output "args: $argsText"
	Write-Output "TESTS_FS_WINDOWS: $($env:TESTS_FS_WINDOWS)"
	Write-Output "TESTS_FS_WSL: $($env:TESTS_FS_WSL)"
	Write-Output "WSL_DISTRO: $($env:WSL_DISTRO)"

	$output = & $script
	$res = Parse-Result $output

	"powershell,$name,$mode,$cache,$($res.files),$($res.time),$($res.cpu_user),$($res.cpu_sys)" | Add-Content $csv
}

# Подготавливаем тестовые директории перед запуском всех бенчмарков.
& "$powershellTestsDir\setup-fs.ps1"

# Запускаем тест рекурсивного обхода файлов.
Run-Test "files-find" "native" "none" { & "$powershellTestsDir\files-find.ps1" $false } "proxy=false"
Run-Test "files-find" "proxy" "none" { & "$powershellTestsDir\files-find.ps1" $true } "proxy=true"

# Запускаем тест массового создания и удаления файлов.
Run-Test "files-create-delete" "native" "none" { & "$powershellTestsDir\files-create-delete.ps1" $false } "proxy=false"
Run-Test "files-create-delete" "proxy" "none" { & "$powershellTestsDir\files-create-delete.ps1" $true } "proxy=true"

# Запускаем тест npm-install с прогретым и пустым кешем.
Run-Test "npm-install" "native" "true" { & "$powershellTestsDir\npm-install.ps1" $false $true } "proxy=false,use_cache=true"
Run-Test "npm-install" "native" "false" { & "$powershellTestsDir\npm-install.ps1" $false $false } "proxy=false,use_cache=false"
Run-Test "npm-install" "proxy" "true" { & "$powershellTestsDir\npm-install.ps1" $true $true } "proxy=true,use_cache=true"
Run-Test "npm-install" "proxy" "false" { & "$powershellTestsDir\npm-install.ps1" $true $false } "proxy=true,use_cache=false"
