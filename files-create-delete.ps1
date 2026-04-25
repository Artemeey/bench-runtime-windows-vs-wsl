param (
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

$root = & "$PSScriptRoot\fs-path.ps1" $Proxy

if (-not [System.IO.Directory]::Exists($root)) {
	Write-Error "Path not found: $root"
	exit 1
}

$fileCount = 10000
$testDir = Join-Path $root ("files-create-delete-" + [System.Guid]::NewGuid().ToString())

New-Item -ItemType Directory -Force -Path $testDir | Out-Null

$process = Get-Process -Id $PID
$userCpuStart = $process.UserProcessorTime
$sysCpuStart = $process.PrivilegedProcessorTime

$timer = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $fileCount; $i++) {
	[System.IO.File]::WriteAllText((Join-Path $testDir "file-$i.txt"), "test")
}

[System.IO.Directory]::Delete($testDir, $true)

$timer.Stop()
$process.Refresh()

$userCpu = ($process.UserProcessorTime - $userCpuStart).TotalSeconds
$sysCpu = ($process.PrivilegedProcessorTime - $sysCpuStart).TotalSeconds
$culture = [System.Globalization.CultureInfo]::InvariantCulture

Write-Output ("files: {0}" -f $fileCount)
Write-Output ("time: {0} sec" -f $timer.Elapsed.TotalSeconds.ToString("F3", $culture))
Write-Output ("cpu: {0} user + {1} sys sec" -f $userCpu.ToString("F3", $culture), $sysCpu.ToString("F3", $culture))
