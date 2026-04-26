# Запускаем `run.ps1` заданное количество раз для накопления статистики.
param(
	[Parameter(Mandatory = $true)]
	[int]$Count
)

$ErrorActionPreference = "Stop"

if ($Count -lt 1) {
	Write-Error "Usage: .\runMulti.ps1 -Count <number>, example: .\runMulti.ps1 -Count 10"
	exit 1
}

for ($i = 1; $i -le $Count; $i++) {
	Write-Output ""
	Write-Output "🔁 Iteration $i/$Count"
	& "$PSScriptRoot\run.ps1"
}

