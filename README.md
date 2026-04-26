# bench-runtime-windows-vs-wsl

Benchmark suite for comparing Windows and WSL performance in real development scenarios.

## Tests

- `files-find` — recursive file traversal
- `files-create-delete` — create and delete 10,000 small files
- `npm-install` — install npm dependencies from `package-lock.json` with and without cache

## Test correctness

- Bash and PowerShell test suites use the most equivalent operations for their own runtimes and system APIs.
- Windows uses MSYS2 Bash, while WSL uses native WSL Bash.

## Modes

- `native` — filesystem of the current environment
- `proxy` — access across the Windows ↔ WSL boundary

## Environment setup

- Default values are stored in `.env`.
- All scripts load `.env` automatically.

## Run tests

Test results are written to `results/results.csv` and `results.txt`.  
Results are not cleared automatically.

PowerShell:

```powershell
.\run.ps1
```

Bash:

```bash
./run.sh
```

### Run a single test

Bash:

```bash
bash/npm-install.sh false true
```

PowerShell:

```powershell
.\powershell\npm-install.ps1 $false $true
```

## Reading results

### Within the same environment

| Run source | Comparison                                                    | What it shows                                                                       |
|------------|---------------------------------------------------------------|-------------------------------------------------------------------------------------|
| Windows    | PowerShell `native` vs PowerShell `proxy`                     | PowerShell performance when accessing WSL files across the Windows ↔ WSL boundary   |
| Windows    | MSYS2 Bash (Windows) `native` vs MSYS2 Bash (Windows) `proxy` | MSYS2 Bash (Windows) performance when accessing WSL files                           |
| WSL2       | WSL Bash `native` vs WSL Bash `proxy`                         | WSL Bash performance when accessing Windows files across the Windows ↔ WSL boundary |

### Across environments

| Run source     | Comparison                                         | What it shows                                                    |
|----------------|----------------------------------------------------|------------------------------------------------------------------|
| Windows / WSL2 | MSYS2 Bash (Windows) `native` vs WSL Bash `native` | Combined filesystem + runtime difference between Windows and WSL |

Cross-environment comparisons include both filesystem and runtime differences.

## Requirements

- Windows
- WSL2
- PowerShell
- MSYS2 Bash — https://www.msys2.org/
- Node.js and npm
