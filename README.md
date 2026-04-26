# bench-runtime-windows-vs-wsl

Benchmark suite for comparing Windows and WSL performance.

These tests show how strongly file location affects performance when working with WSL. Even in simple scenarios, you can
hit performance degradation by tens or hundreds of times. This directly affects task execution speed, development tool
responsiveness, and SSD load.

It is important to understand that this is not a bug and not a WSL configuration issue. In most cases, the root cause is
an incorrect filesystem workflow model. This is especially common with Docker on Windows: mounting volumes from the
Windows filesystem (`C:\` → `/mnt/c`) causes a sharp performance drop. This behavior is often misinterpreted as IDE
freezes or environment instability, while in reality it is an architectural limitation.

Typical mixed-scenario examples:

- The project is opened in IDE from `C:\`, but commands (`npm`, `composer`, `docker`) run inside WSL
- Docker containers in WSL use a volume mounted from `C:\` (`/mnt/c/`)
- `node_modules` or `vendor` are on Windows FS, while build runs in WSL
- Git repository is on Windows, but operations (`git status`, `checkout`) are executed from WSL
- Database runs in a container (WSL), but data volume is on Windows FS
- Watchers (webpack, vite) monitor files in `C:\`, but run inside WSL

## Tests

- `files-find` — recursive file traversal
- `files-create-delete` — create and delete 10,000 small files
- `npm-install` — install npm dependencies from `package-lock.json` with and without cache

## Test correctness

- Bash and PowerShell test suites use the most equivalent operations for their own runtimes and system APIs.
- Windows uses MSYS2 Bash, while WSL uses native WSL Bash.
- Tests are run on an idle system.
- Tests run sequentially; parallel run is not allowed.
- Tests can be run multiple times; all results are preserved in CSV.

## Modes

- `native` — filesystem of the current environment
- `proxy` — access across the Windows ↔ WSL boundary

## Settings

- Default settings are stored in `.env`.
- All scripts load `.env` automatically.

## Run tests

Test results are written to `results/results.csv` and `results.txt`.

Files are not cleared automatically, so you can run tests multiple times and accumulate statistics for further analysis.

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
