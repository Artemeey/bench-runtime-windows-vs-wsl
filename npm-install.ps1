param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy,

	[Parameter(Mandatory = $true)]
	[bool]$UseCache
)

$root = & "$PSScriptRoot\fs-path.ps1" $Proxy
$npmDir = Join-Path $root "npm-install"

Remove-Item -LiteralPath (Join-Path $npmDir "node_modules") -Recurse -Force -ErrorAction SilentlyContinue

if (-not $UseCache) {
	npm cache clean --force | Out-Null
}

$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

$timer = [System.Diagnostics.Stopwatch]::StartNew()

npm install --prefix $npmDir | Out-Null

$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds
$culture = [System.Globalization.CultureInfo]::InvariantCulture

$count = 0
$nodeModules = Join-Path $npmDir "node_modules"
if ([System.IO.Directory]::Exists($nodeModules)) {
	foreach ($file in [System.IO.Directory]::EnumerateFiles($nodeModules, "*", [System.IO.SearchOption]::AllDirectories)) {
		$count++
	}
}

Write-Output ("files: {0}" -f $count)
Write-Output ("time: {0} sec" -f $timer.Elapsed.TotalSeconds.ToString("F3", $culture))
Write-Output ("cpu: {0} user + {1} sys sec" -f $userCpu.ToString("F3", $culture), $sysCpu.ToString("F3", $culture))
