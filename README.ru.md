# bench-runtime-windows-vs-wsl

Набор бенчмарков для сравнения производительности Windows и WSL в реальных сценариях разработки.

## Тесты

- `files-find` — рекурсивный обход файлов
- `files-create-delete` — создание и удаление 10 000 маленьких файлов
- `npm-install` — установка npm-зависимостей с кешем и без кеша

## Корректность тестов

- Наборы тестов Bash и PowerShell используют максимально эквивалентные операции для своих runtime и системных API.
- Git Bash можно запускать и в Windows, и в WSL. Для чистого сравнения нужно два отдельных прогона:
  - Git Bash (Windows)
  - Git Bash (WSL)

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

### Внутри одного окружения

| Сравнение                                                 | Что показывает                                                                       |
|-----------------------------------------------------------|--------------------------------------------------------------------------------------|
| PowerShell `native` vs PowerShell `proxy`                 | Производительность PowerShell при доступе к файлам WSL через границу Windows ↔ WSL   |
| WSL Bash `native` vs WSL Bash `proxy`                     | Производительность WSL Bash при доступе к файлам Windows через границу Windows ↔ WSL |
| Git Bash (Windows) `native` vs Git Bash (Windows) `proxy` | Производительность Git Bash (Windows) при доступе к файлам WSL                       |
| Git Bash (WSL) `native` vs Git Bash (WSL) `proxy`         | Производительность Git Bash (WSL) при доступе к файлам Windows                       |

### Между окружениями

| Сравнение                                              | Что показывает                                                                                 |
|--------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Git Bash (Windows) `native` vs Git Bash (WSL) `native` | Разницу нативной производительности файловых систем Windows и WSL при одном runtime (Git Bash) |

Прямое сравнение между PowerShell, Git Bash и WSL Bash показывает не только скорость файловой системы, но и разницу runtime, shell и системных API.

## Требования

- Windows
- WSL
- PowerShell
- Bash / Git Bash
- Node.js и npm
