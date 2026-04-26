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

- `npm-install` — install npm dependencies from `package-lock.json` with and without cache
- `files-find` — recursive file traversal, must run after `npm-install`
- `files-create-delete` — create and delete 1000 small files

## Test correctness

- Bash and PowerShell test suites use the most equivalent operations for their own runtimes and system APIs.
- Windows uses MSYS2 Bash, while WSL uses native WSL Bash.
- Tests are also run in PowerShell to compare PowerShell / Bash performance without WSL impact.
- Tests are run on an idle system.
- Tests run sequentially; parallel run is not allowed.
- Tests can be run multiple times; all results are preserved in CSV.
- The primary metric is execution time. In these tests, it directly reflects filesystem performance.
- Additional CPU metrics are shown only in tests where they are easy to measure.

## Modes

- `native` — filesystem of the current environment
- `proxy` — access across the Windows ↔ WSL boundary

## Settings

- Copy template first: `cp .env.example .env`
- Default settings are stored in `.env.example`.
- All scripts load `.env` automatically.

## Run tests

Test results are written to `${TESTS_FS_WINDOWS}/results/results.csv` and `${TESTS_FS_WINDOWS}/results/results.txt`.

Files are not cleared automatically, so you can run tests multiple times and accumulate statistics for further analysis.

After `run.ps1`/`run.sh` completes, scripts print the results directory path.
Do not open the results file before the full test run is finished, as applications can lock it for writing.

Full test cycle:

- Windows: `powershell .\run.ps1`, runs tests on Windows filesystem, then on WSL
- Windows: `bash ./run.sh`, runs tests on Windows filesystem, then on WSL
- WSL: `./run.sh`, runs tests on WSL filesystem, then on Windows

PowerShell:

```powershell
.\run.ps1
```

Bash:

```bash
sudo chmod +x *.sh bash/*.sh # setup execute permissions once

./run.sh
```

Run tests multiple times:

- PowerShell: `.\runMulti.ps1 -Count 10`
- Bash: `./runMulti.sh 10`

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
