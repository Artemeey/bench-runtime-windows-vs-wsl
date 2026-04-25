param (
	# true = proxy FS, false = native FS
	[Parameter(Mandatory = $true)]
	[bool]$Proxy,

	# true = use cache, false = clean cache before install
	[Parameter(Mandatory = $true)]
	[bool]$UseCache
)

$root = & "$PSScriptRoot\fs-path.ps1" $Proxy
$npmDir = Join-Path $root "npm-install"
$packageJson = Join-Path $PSScriptRoot "package.json"

if (-not (Test-Path -LiteralPath $packageJson -PathType Leaf)) {
	Write-Error "package.json not found: $packageJson"
	exit 1
}

# Ensure reproducible install
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "package-lock.json"))) {
	npm install --package-lock-only | Out-Null
}

Remove-Item -LiteralPath $npmDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $npmDir | Out-Null
Copy-Item -LiteralPath $packageJson -Destination (Join-Path $npmDir "package.json") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "package-lock.json") -Destination (Join-Path $npmDir "package-lock.json") -Force

if (-not $UseCache) {
	npm cache clean --force | Out-Null
}

$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

$timer = [System.Diagnostics.Stopwatch]::StartNew()

npm ci --prefix $npmDir | Out-Null

$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds

$count = 0
$nodeModules = Join-Path $npmDir "node_modules"
if ([System.IO.Directory]::Exists($nodeModules)) {
	foreach ($file in [System.IO.Directory]::EnumerateFiles($nodeModules, "*", [System.IO.SearchOption]::AllDirectories)) {
		$count++
	}
}

Write-Output ("files: {0}" -f $count)
Write-Output ("time: {0:N3} sec" -f $timer.Elapsed.TotalSeconds)
Write-Output ("cpu: {0:N3} user + {1:N3} sys sec" -f $userCpu, $sysCpu)
