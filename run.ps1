# Runs all benchmarks and writes CSV results

$ErrorActionPreference = "Stop"

$resultsDir = Join-Path $PSScriptRoot "results"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

$csv = Join-Path $resultsDir "results.csv"
"runtime,test,mode,cache,files,time,cpu_user,cpu_sys" | Out-File $csv -Encoding utf8

function Parse-Result {
	param ($output)

	$files = ($output | Where-Object { $_ -like "files:*" }) -replace "files: ", ""
	$time = ($output | Where-Object { $_ -like "time:*" }) -replace "time: ", "" -replace " sec", ""
	$cpuLine = ($output | Where-Object { $_ -like "cpu:*" }) -replace "cpu: ", ""

	$parts = $cpuLine -split " user \+ "
	$user = $parts[0]
	$sys = ($parts[1] -replace " sys sec", "")

	return @{ files=$files; time=$time; cpu_user=$user; cpu_sys=$sys }
}

function Run-Test {
	param ($name, $mode, $cache, $script)

	$output = & $script
	$res = Parse-Result $output

	"powershell,$name,$mode,$cache,$($res.files),$($res.time),$($res.cpu_user),$($res.cpu_sys)" | Add-Content $csv
}

& "$PSScriptRoot\setup-fs.ps1"

Run-Test "files-find" "native" "none" { & "$PSScriptRoot\files-find.ps1" $false }
Run-Test "files-find" "proxy" "none" { & "$PSScriptRoot\files-find.ps1" $true }

Run-Test "files-create-delete" "native" "none" { & "$PSScriptRoot\files-create-delete.ps1" $false }
Run-Test "files-create-delete" "proxy" "none" { & "$PSScriptRoot\files-create-delete.ps1" $true }

Run-Test "npm-install" "native" "true" { & "$PSScriptRoot\npm-install.ps1" $false $true }
Run-Test "npm-install" "native" "false" { & "$PSScriptRoot\npm-install.ps1" $false $false }
Run-Test "npm-install" "proxy" "true" { & "$PSScriptRoot\npm-install.ps1" $true $true }
Run-Test "npm-install" "proxy" "false" { & "$PSScriptRoot\npm-install.ps1" $true $false }
