# Prepare benchmark folders for native and proxy modes.

$packageJson = Join-Path $PSScriptRoot "package.json"

if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf)) {
	Write-Error "package.json not found: $packageJson"
	exit 1
}

foreach ($proxy in @($false, $true)) {
	$root = & "$PSScriptRoot\fs-path.ps1" $proxy
	$npmDir = Join-Path $root "npm-install"

	New-Item -ItemType Directory -Force -Path $npmDir | Out-Null
	Copy-Item -LiteralPath $packageJson -Destination (Join-Path $npmDir "package.json") -Force

	Write-Output ("prepared: {0}" -f $root)
}
