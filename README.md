# bench-runtime-windows-vs-wsl

Benchmark suite for comparing Windows and WSL performance in real development scenarios.

## Tests

- `files-find` — recursive file traversal
- `files-create-delete` — create and delete 10,000 small files
- `npm-install` — install npm dependencies with and without cache

## Modes

- `native` — filesystem of the current environment
- `proxy` — access across the Windows ↔ WSL boundary

## Benchmark equivalence

PowerShell and Bash scripts do not execute the same commands. They use different runtimes and system APIs.

The benchmark compares equivalent operations:

- `files-find`
  - PowerShell: recursive enumeration via .NET APIs
  - Bash: recursive enumeration via `find`
- `files-create-delete`
  - PowerShell: file operations via .NET APIs
  - Bash: file operations via shell utilities
- `npm-install`
  - both variants execute `npm install`
  - cache mode is controlled explicitly

Results must be interpreted as runtime/environment benchmarks, not pure filesystem microbenchmarks.

## Environment setup

PowerShell:

```powershell
$env:TESTS_FS_WINDOWS="C:\Windows\Temp\tests-fs"
$env:TESTS_FS_WSL="/tmp/tests-fs"
$env:WSL_DISTRO="Ubuntu"
```

Bash / Git Bash:

```bash
export TESTS_FS_WINDOWS="C:\Windows\Temp\tests-fs"
export TESTS_FS_WSL="/tmp/tests-fs"
export WSL_DISTRO="Ubuntu"
```

## Run

PowerShell:

```powershell
.\run.ps1
```

Bash / Git Bash:

```bash
chmod +x *.sh
./run.sh
```

## Reading results

Compare results within the same environment:

- PowerShell native vs proxy
- WSL Bash native vs proxy
- Git Bash native vs proxy

Cross-environment comparison reflects differences in runtime, shell and system layers.

## Requirements

- Windows
- WSL
- PowerShell
- Bash / Git Bash
- Node.js and npm
