param (
	# true = доступ через границу Windows ↔ WSL, false = нативная файловая система.
	[Parameter(Mandatory = $true)]
	[bool]$Proxy
)

# Читаем корневые пути для Windows/WSL и имя дистрибутива из переменных окружения.
$win = $env:TESTS_FS_WINDOWS
$wsl = $env:TESTS_FS_WSL
$distro = $env:WSL_DISTRO

# Проверяем обязательные переменные окружения для обоих направлений теста.
if (-not $win -or -not $wsl -or -not $distro) {
	Write-Error "ENV not set: TESTS_FS_WINDOWS, TESTS_FS_WSL, WSL_DISTRO"
	exit 1
}

if ($Proxy) {
	# Возвращаем UNC-путь к файловой системе WSL для запуска из PowerShell на Windows.
	"\\wsl.localhost\$distro$($wsl -replace '/', '\\')"
} else {
	# Возвращаем прямой путь к файловой системе Windows для нативного режима PowerShell.
	$win
}
