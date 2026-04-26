# Запускаем переданную команду с переменными из `.env`.

[CmdletBinding()]
param (
	[Parameter(Position = 0)]
	[string]$Command,

	[Parameter(Position = 1, ValueFromRemainingArguments = $true)]
	[string[]]$CommandArgs
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$envPath = Join-Path $projectRoot ".env"

if (-not (Test-Path -LiteralPath $envPath)) {
	Write-Error ".env not found: $envPath"
	exit 1
}

# Загружаем переменные из `.env` в текущее окружение процесса.
Get-Content -Encoding UTF8 -LiteralPath $envPath |
	Where-Object { $_ -match '^\s*[^#].+=' } |
	ForEach-Object {
		$name, $value = $_ -split "=", 2
		Set-Item -Path "Env:$name" -Value $value
	}

if ([string]::IsNullOrWhiteSpace($Command)) {
	return
}

& $Command @CommandArgs
