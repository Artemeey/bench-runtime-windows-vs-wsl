param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy,

	[Parameter(Mandatory = $true)]
	[bool]$UseCache
)

$root = & "$PSScriptRoot\fs-path.ps1" $Proxy
$npmDir = Join-Path $root "npm-install"

if (-not (Test-Path -LiteralPath (Join-Path $npmDir "package-lock.json"))) {
	Write-Error "package-lock.json not found. Run setup-fs first."
	exit 1
}

Remove-Item -LiteralPath (Join-Path $npmDir "node_modules") -Recurse -Force -ErrorAction SilentlyContinue

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
