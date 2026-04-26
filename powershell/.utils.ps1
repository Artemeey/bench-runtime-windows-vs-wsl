# Загружаем переменные окружения из `.env` в текущий процесс.
function Import-ProjectEnv {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ProjectRoot
	)

	$envPath = Join-Path $ProjectRoot ".env"

	Get-Content -Encoding UTF8 -LiteralPath $envPath |
		Where-Object { $_ -match '^\s*[^#].+=' } |
		ForEach-Object {
			$name, $value = $_ -split "=", 2
			Set-Item -Path "Env:$name" -Value $value
		}
}

# Возвращаем корневую директорию для выбранного режима native/proxy.
function Get-RootPath {
	param (
		[Parameter(Mandatory = $true)]
		[bool]$Proxy
	)

	$win = $env:TESTS_FS_WINDOWS
	$wsl = $env:TESTS_FS_WSL
	$distro = $env:WSL_DISTRO

	if (-not $win -or -not $wsl -or -not $distro) {
		Write-Error "ENV not set: TESTS_FS_WINDOWS, TESTS_FS_WSL, WSL_DISTRO"
		exit 1
	}

	if ($Proxy) {
		return "\\wsl.localhost\$distro$($wsl -replace '/', '\')"
	}

	return $win
}

# Возвращаем текущие метрики процесса.
function Get-StatsSnapshot {
	$process = Get-Process -Id $PID

	return @{
		UserCpu = $process.UserProcessorTime.TotalSeconds
		SysCpu = $process.PrivilegedProcessorTime.TotalSeconds
		Timestamp = [System.Diagnostics.Stopwatch]::GetTimestamp()
	}
}

# Печатаем результат теста в формате для run.ps1.
function Write-TestResult {
	param (
		[Parameter(Mandatory = $true)]
		[int]$Files,

		[Parameter(Mandatory = $true)]
		$StatsStart,

		[Parameter(Mandatory = $true)]
		$StatsCurrent
	)

	$culture = [System.Globalization.CultureInfo]::InvariantCulture
	$time = ($StatsCurrent.Timestamp - $StatsStart.Timestamp) / [System.Diagnostics.Stopwatch]::Frequency
	$cpuUser = $StatsCurrent.UserCpu - $StatsStart.UserCpu
	$cpuSys = $StatsCurrent.SysCpu - $StatsStart.SysCpu

	Write-Output ("files: {0}" -f $Files)
	Write-Output ("time: {0} sec" -f $time.ToString($Culture))
	Write-Output ("cpu_user: {0} sec" -f $cpuUser.ToString($Culture))
	Write-Output ("cpu_sys: {0} sec" -f $cpuSys.ToString($Culture))
}

# Проверяем, что директория существует перед запуском теста.
function Confirm-DirectoryExists {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	if (-not [System.IO.Directory]::Exists($Path)) {
		Write-Error "Path not found: $Path"
		exit 1
	}
}
