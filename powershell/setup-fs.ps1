# Создаём тестовые директории для всех сценариев бенчмарка: native и proxy.

$projectRoot = Split-Path -Parent $PSScriptRoot
$packageJson = Join-Path $projectRoot "package.json"

# Проверяем, что в корне бенчмарка есть package.json для npm-теста.
if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf)) {
	Write-Error "package.json not found: $packageJson"
	exit 1
}

foreach ($proxy in @($false, $true)) {
	# Разворачиваем структуру теста в нативной и прокси файловых системах.
	$root = & "$PSScriptRoot\fs-path.ps1" $proxy
	$npmDir = Join-Path $root "npm-install"

	# Кладём одинаковый package.json в обе директории, чтобы условия npm-теста совпадали.
	New-Item -ItemType Directory -Force -Path $npmDir | Out-Null
	Copy-Item -LiteralPath $packageJson -Destination (Join-Path $npmDir "package.json") -Force

	Write-Output ("prepared: {0}" -f $root)
}
