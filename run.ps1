# Запускаем все бенчмарки проекта и сохраняем результаты в CSV.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

$projectRoot = $PSScriptRoot
$powershellTestsDir = Join-Path $projectRoot "powershell"

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
	Write-Output "🧪 $name | cross_fs=$crossFs | cache=$cache | args=$argsText"

	$output = & $script
	$output | Write-Output
	$res = Parse-Result $output

	"powershell,$name,$crossFs,$cache,$($res.files),$($res.time),$($res.cpu_user),$($res.cpu_sys)" | Add-Content $resultsCsvPath
}

. "$powershellTestsDir\.utils.ps1"
Import-ProjectEnv -ProjectRoot $projectRoot

# Формируем директорию результатов внутри TESTS_FS_WINDOWS, чтобы все прогоны писались в одно место.
$resultsDir = Join-Path $env:TESTS_FS_WINDOWS "results"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

$resultsCsvPath = Join-Path $resultsDir "results.csv"
$resultsTxtPath = Join-Path $resultsDir "results.txt"
if (-not (Test-Path -LiteralPath $resultsCsvPath)) {
	"runtime,test,cross_fs,cache,files,time,cpu_user,cpu_sys" | Out-File $resultsCsvPath -Encoding utf8
}

$nodeVersion = ((node -v 2>$null) -join '').Trim()
$npmVersion = ((npm -v 2>$null) -join '').Trim()
$wslVersionRaw = ((wsl --version 2>$null | Select-Object -First 1) -join '').Trim()
$wslVersionClean = ($wslVersionRaw -replace "`0", "")
$wslVersion = [regex]::Match($wslVersionClean, '\d+(\.\d+)+').Value
$osVersion = ((Get-CimInstance Win32_OperatingSystem 2>$null | Select-Object -First 1 | ForEach-Object { "$($_.Caption) $($_.Version)" }) -join '').Trim()
$windowsFsType = ((Get-Volume -DriveLetter C -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FileSystem) -join '').Trim()
$wslFsType = ((wsl -d $env:WSL_DISTRO bash -lc "df -T '$($env:TESTS_FS_WSL)' 2>/dev/null | sed -n '2p' | tr -s ' ' | cut -d' ' -f2" 2>$null) -join '').Trim()

# Сохраняем версии инструментов и параметры запуска в текстовый отчёт.
if (Test-Path -LiteralPath $resultsTxtPath) {
	Add-Content -Path $resultsTxtPath -Value ""
}

$reportLines = @(
	"🟦 runtime: powershell"
	"os_windows: $osVersion"
	"powershell: $($PSVersionTable.PSVersion)"
	"wsl: $wslVersion $($env:WSL_DISTRO)"
	"fs_windows: $($env:TESTS_FS_WINDOWS) -> $(if ($windowsFsType) { $windowsFsType } else { 'unknown' })"
	"fs_wsl: $($env:TESTS_FS_WSL) -> $(if ($wslFsType) { $wslFsType } else { 'unknown' })"
	"node: $nodeVersion"
	"npm: $npmVersion"
)

$reportLines | Write-Output
$reportLines | Add-Content -Path $resultsTxtPath -Encoding utf8

Write-Output ""
& "$powershellTestsDir\setup-fs.ps1"

Write-Output ""

# Сначала запускаем все native-сценарии (cross_fs=false).
Write-Output "🟢 Running native mode (cross_fs=false)"
Run-Test "npm-install" "false" "true" { & "$powershellTestsDir\npm-install.ps1" $false $true } "proxy=false,use_cache=true"
Run-Test "npm-install" "false" "false" { & "$powershellTestsDir\npm-install.ps1" $false $false } "proxy=false,use_cache=false"
Run-Test "files-find" "false" "none" { & "$powershellTestsDir\files-find.ps1" $false } "proxy=false"
Run-Test "files-create-delete" "false" "none" { & "$powershellTestsDir\files-create-delete.ps1" $false } "proxy=false"

Write-Output ""

# Затем запускаем все proxy-сценарии (cross_fs=true).
Write-Output "🟣 Running proxy mode (cross_fs=true)"
Run-Test "npm-install" "true" "true" { & "$powershellTestsDir\npm-install.ps1" $true $true } "proxy=true,use_cache=true"
Run-Test "npm-install" "true" "false" { & "$powershellTestsDir\npm-install.ps1" $true $false } "proxy=true,use_cache=false"
Run-Test "files-find" "true" "none" { & "$powershellTestsDir\files-find.ps1" $true } "proxy=true"
Run-Test "files-create-delete" "true" "none" { & "$powershellTestsDir\files-create-delete.ps1" $true } "proxy=true"

# Показываем путь и готовую ссылку, чтобы пользователь сразу открыл папку результатов.
$resultsDirNormalized = (Resolve-Path -LiteralPath $resultsDir).Path
$resultsUri = [System.Uri]::new($resultsDirNormalized)
Write-Output ""
Write-Output "📁 Results directory: $resultsDirNormalized"
Write-Output "🔗 Results link: $($resultsUri.AbsoluteUri)"
