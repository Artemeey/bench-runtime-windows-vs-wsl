# Создаём тестовые директории для всех сценариев бенчмарка: native и proxy.

$projectRoot = Split-Path -Parent $PSScriptRoot
$packageJson = Join-Path $projectRoot "package.json"
$packageLockJson = Join-Path $projectRoot "package-lock.json"

foreach ($proxy in @($false, $true)) {
	# Разворачиваем структуру теста в нативной и прокси файловых системах.
	$root = & "$PSScriptRoot\fs-path.ps1" $proxy
	$npmDir = Join-Path $root "npm-install"

	# Кладём одинаковый package.json в обе директории, чтобы условия npm-теста совпадали.
	New-Item -ItemType Directory -Force -Path $npmDir | Out-Null
	Copy-Item -LiteralPath $packageJson -Destination (Join-Path $npmDir "package.json") -Force
	Copy-Item -LiteralPath $packageLockJson -Destination (Join-Path $npmDir "package-lock.json") -Force

	Write-Output ("prepared: {0}" -f $root)
}
