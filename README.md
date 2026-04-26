# bench-runtime-windows-vs-wsl

Benchmark suite for comparing Windows and WSL performance in real development scenarios.

## Tests

- `files-find` — recursive file traversal
- `files-create-delete` — create and delete 10,000 small files
- `npm-install` — install npm dependencies with and without cache

## Test correctness

- Bash and PowerShell test suites use the most equivalent operations for their own runtimes and system APIs.
- Git Bash can run on both Windows and WSL. For clean comparison, run it twice:
  - Git Bash (Windows)
  - Git Bash (WSL)

## Modes

- `native` — filesystem of the current environment
- `proxy` — access across the Windows ↔ WSL boundary

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

### Within the same environment

| Comparison                                                | What it shows                                                                       |
|-----------------------------------------------------------|-------------------------------------------------------------------------------------|
| PowerShell `native` vs PowerShell `proxy`                 | PowerShell performance when accessing WSL files across the Windows ↔ WSL boundary   |
| WSL Bash `native` vs WSL Bash `proxy`                     | WSL Bash performance when accessing Windows files across the Windows ↔ WSL boundary |
| Git Bash (Windows) `native` vs Git Bash (Windows) `proxy` | Git Bash (Windows) performance when accessing WSL files                             |
| Git Bash (WSL) `native` vs Git Bash (WSL) `proxy`         | Git Bash (WSL) performance when accessing Windows files                             |

### Across environments

| Comparison                                             | What it shows                                                                                         |
|--------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| Git Bash (Windows) `native` vs Git Bash (WSL) `native` | Difference in native filesystem performance between Windows and WSL using the same runtime (Git Bash) |

Cross-environment comparison reflects differences in runtime, shell, and system APIs.

## Requirements

- Windows
- WSL
- PowerShell
- Bash / Git Bash
- Node.js and npm
