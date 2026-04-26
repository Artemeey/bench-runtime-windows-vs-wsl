#!/usr/bin/env bash

# Выполняем бенчмарк установки npm-зависимостей с кешем и без кеша.

set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <true|false> <true|false>"
	exit 1
fi

PROXY="$1"
USE_CACHE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/fs-path.sh"

# Определяем директорию npm-теста для выбранного режима native/proxy.
ROOT="$(get_test_root "$PROXY")"
NPM_DIR="$ROOT/npm-install"

# Удаляем node_modules перед каждым прогоном для одинаковых стартовых условий.
rm -rf "$NPM_DIR/node_modules"

# Для сценария без кеша очищаем npm cache перед установкой.
if [ "$USE_CACHE" = "false" ]; then
	npm cache clean --force > /dev/null 2>&1
fi

# Запускаем измерение wall-clock времени и CPU через встроенный `time`.
TIMEFORMAT="%3R %3U %3S"
TIME_RESULT="$({ time (cd "$NPM_DIR" && npm ci > /dev/null 2>/dev/null); } 2>&1)"

read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

# Подсчитываем итоговое количество файлов в node_modules для поля files.
FILES="$(find "$NPM_DIR/node_modules" -type f 2>/dev/null | wc -l | tr -d ' ')"

# Печатаем результат в формате для run.sh.
echo "files: ${FILES:-0}"
echo "time: $REAL_TIME sec"
echo "cpu: $USER_CPU user + $SYS_CPU sys sec"
