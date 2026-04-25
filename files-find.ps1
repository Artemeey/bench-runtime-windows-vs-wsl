param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

$root = & "$PSScriptRoot\fs-path.ps1" $Proxy

if (-not [System.IO.Directory]::Exists($root)) {
	Write-Error "Path not found: $root"
	exit 1
}

$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

$timer = [System.Diagnostics.Stopwatch]::StartNew()

$count = 0
foreach ($file in [System.IO.Directory]::EnumerateFiles($root, "*", [System.IO.SearchOption]::AllDirectories)) {
	$count++
}

$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds
$culture = [System.Globalization.CultureInfo]::InvariantCulture

Write-Output ("files: {0}" -f $count)
Write-Output ("time: {0} sec" -f $timer.Elapsed.TotalSeconds.ToString("F3", $culture))
Write-Output ("cpu: {0} user + {1} sys sec" -f $userCpu.ToString("F3", $culture), $sysCpu.ToString("F3", $culture))
