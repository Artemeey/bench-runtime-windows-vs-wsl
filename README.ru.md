# bench-runtime-windows-vs-wsl

Набор бенчмарков для сравнения производительности Windows и WSL в реальных сценариях разработки.

## Тесты

- `files-find` — рекурсивный обход файлов
- `files-create-delete` — создание и удаление 10 000 маленьких файлов
- `npm-install` — установка npm-зависимостей с кешем и без кеша

## Режимы

- `native` — работа с файловой системой текущего окружения
- `proxy` — работа через границу Windows ↔ WSL

## Подготовка окружения

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

## Запуск

PowerShell:

```powershell
.\run.ps1
```

Bash / Git Bash:

```bash
chmod +x *.sh
./run.sh
```

## Как читать результаты

Сравнивайте результаты внутри одного и того же окружения:

- PowerShell `native` vs PowerShell `proxy`
- WSL Bash `native` vs WSL Bash `proxy`
- Git Bash `native` vs Git Bash `proxy`

Прямое сравнение между PowerShell, Git Bash и WSL Bash показывает не только скорость файловой системы, но и разницу runtime, shell и системных API.

## Требования

- Windows
- WSL
- PowerShell
- Bash / Git Bash
- Node.js и npm
