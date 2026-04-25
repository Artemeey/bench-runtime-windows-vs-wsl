param (
	# true = proxy (WSL), false = native Windows
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

$win = $env:TESTS_FS_WINDOWS
$wsl = $env:TESTS_FS_WSL
$distro = $env:WSL_DISTRO

if (-not $win -or -not $wsl -or -not $distro) {
	Write-Error "ENV not set"
	exit 1
}

if ($Proxy) {
	"\\wsl.localhost\$distro$($wsl -replace '/', '\\')"
} else {
	$win
}
