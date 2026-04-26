# Создаём тестовые директории для всех сценариев бенчмарка: native и proxy.

. "$PSScriptRoot\.utils.ps1"

Import-ProjectEnv -ProjectRoot (Split-Path -Parent $PSScriptRoot)

$projectRoot = Split-Path -Parent $PSScriptRoot
$packageJson = Join-Path $projectRoot "package.json"
$packageLockJson = Join-Path $projectRoot "package-lock.json"

foreach ($proxy in @($false, $true)) {
	# Разворачиваем структуру теста в нативной и прокси файловых системах.
	$root = Get-RootPath -Proxy $proxy
	Confirm-DirectoryExists -Path $root
	$npmDir = Join-Path $root "npm-install"
	$modeName = if ($proxy) { "proxy" } else { "native" }

	# Кладём одинаковый package.json в обе директории, чтобы условия npm-теста совпадали.
	New-Item -ItemType Directory -Force -Path $npmDir | Out-Null
	Copy-Item -LiteralPath $packageJson -Destination (Join-Path $npmDir "package.json") -Force
	Copy-Item -LiteralPath $packageLockJson -Destination (Join-Path $npmDir "package-lock.json") -Force

	Write-Output ("init dir (${modeName}): {0}" -f $root)
}
