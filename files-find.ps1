param (
	# true = proxy FS, false = native FS
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

# Resolve path via shared env-based resolver
$root = & "$PSScriptRoot\fs-path.ps1" $Proxy

if (-not [System.IO.Directory]::Exists($root)) {
	Write-Error "Path not found: $root"
	exit 1
}

# Capture CPU baseline
$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

# Wall-clock timer
$timer = [System.Diagnostics.Stopwatch]::StartNew()

# Enumerate files using streaming API
$count = 0
foreach ($file in [System.IO.Directory]::EnumerateFiles($root, "*", [System.IO.SearchOption]::AllDirectories)) {
	$count++
}

$timer.Stop()
$process.Refresh()

# CPU deltas
$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds

# Unified output format
Write-Output ("files: {0}" -f $count)
Write-Output ("time: {0:N3} sec" -f $timer.Elapsed.TotalSeconds)
Write-Output ("cpu: {0:N3} user + {1:N3} sys sec" -f $userCpu, $sysCpu)
