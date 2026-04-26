#!/usr/bin/env bash

# Выполняем бенчмарк установки npm-зависимостей с кешем и без кеша.

set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <proxy: true|false> <use_cache: true|false>"
	exit 1
fi

PROXY="$1"
USE_CACHE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.utils.sh"
load_project_env

# Определяем директорию npm-теста для выбранного режима native/proxy.
ROOT="$(get_root_path "$PROXY")"
confirm_directory_exists "$ROOT"

NPM_DIR="$ROOT/npm-install"

# Удаляем node_modules перед каждым прогоном для одинаковых стартовых условий.
if [ "${MSYSTEM:-}" != "" ]; then
	# В Git Bash удаляем через WSL, чтобы не ловить ошибки I/O на proxy-пути. На результаты тестов это не влияет.
	if [ "$PROXY" = "true" ]; then
		WSL_NPM_DIR="$TESTS_FS_WSL/npm-install"
	else
		WSL_NPM_DIR="$(windows_path_to_wsl_path "$TESTS_FS_WINDOWS")/npm-install"
	fi

	wsl -d "$WSL_DISTRO" bash -lc "rm -rf '$WSL_NPM_DIR/node_modules'"
else
	rm -rf "$NPM_DIR/node_modules"
fi

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

write_test_result "${FILES:-0}" "$REAL_TIME" "$USER_CPU" "$SYS_CPU"
