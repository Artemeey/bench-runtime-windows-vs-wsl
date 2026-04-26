# bench-runtime-windows-vs-wsl

Набор бенчмарков для сравнения производительности Windows и WSL в реальных сценариях разработки.

## Тесты

- `files-find` — рекурсивный обход файлов
- `files-create-delete` — создание и удаление 10 000 маленьких файлов
- `npm-install` — установка npm-зависимостей из `package-lock.json` с кешем и без кеша

## Корректность тестов

- Наборы тестов Bash и PowerShell используют максимально эквивалентные операции для своих runtime и системных API.
- В Windows используется MSYS2 Bash, в WSL используется нативный WSL Bash.

## Режимы

- `native` — работа с файловой системой текущего окружения
- `proxy` — работа через границу Windows ↔ WSL

## Подготовка окружения

- Значения по умолчанию лежат в `.env`.
- Все скрипты сами подхватывают `.env`.

## Запуск

PowerShell:

```powershell
.\run.ps1
```

Bash:

```bash
chmod +x run.sh bash/*.sh
./run.sh
```

### Запуск одного теста

Bash:

```bash
set -a && source .env && set +a
bash/npm-install.sh false true
```

PowerShell:

```powershell
.\powershell\npm-install.ps1 $false $true
```

## Как читать результаты

### Внутри одного окружения

| Сравнение                                                     | Что показывает                                                                       |
|---------------------------------------------------------------|--------------------------------------------------------------------------------------|
| PowerShell `native` vs PowerShell `proxy`                     | Производительность PowerShell при доступе к файлам WSL через границу Windows ↔ WSL   |
| WSL Bash `native` vs WSL Bash `proxy`                         | Производительность WSL Bash при доступе к файлам Windows через границу Windows ↔ WSL |
| MSYS2 Bash (Windows) `native` vs MSYS2 Bash (Windows) `proxy` | Производительность MSYS2 Bash (Windows) при доступе к файлам WSL                     |

### Между окружениями

| Сравнение                                                | Что показывает                                                                 |
|----------------------------------------------------------|--------------------------------------------------------------------------------|
| MSYS2 Bash (Windows) `native` vs WSL Bash `native`       | Суммарную разницу файловой системы и runtime между Windows и WSL              |

Сравнения между разными окружениями включают и разницу файловой системы, и разницу runtime.

## Требования

- Windows
- WSL2
- PowerShell
- MSYS2 Bash — https://www.msys2.org/
- Node.js и npm
