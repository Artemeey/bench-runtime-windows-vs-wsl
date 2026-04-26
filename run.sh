#!/usr/bin/env bash

# Запускаем все бенчмарки проекта и сохраняем результаты в CSV.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BASH_TESTS_DIR="$SCRIPT_DIR/bash"
RESULTS_DIR="$PROJECT_ROOT/results"
mkdir -p "$RESULTS_DIR"
CSV="$RESULTS_DIR/results.csv"

echo "runtime,test,mode,cache,files,time,cpu_user,cpu_sys" > "$CSV"

# Приводим вывод отдельного теста к формату CSV-полей.
parse_result() {
	local output="$1"

	local files time cpu user sys

	files="$(echo "$output" | grep '^files:' | sed 's/files: //')"
	time="$(echo "$output" | grep '^time:' | sed 's/time: //' | sed 's/ sec//')"
	cpu="$(echo "$output" | grep '^cpu:' | sed 's/cpu: //')"

	user="$(echo "$cpu" | cut -d' ' -f1)"
	sys="$(echo "$cpu" | awk -F'\+ ' '{print $2}' | sed 's/ sys sec//')"

	echo "$files,$time,$user,$sys"
}

# Выполняем один тест и пишем строку результата с метаданными сценария.
run_test() {
	local name="$1"
	local mode="$2"
	local cache="$3"
	local script="$4"
	local separator="${5:-}"

	if [ "$separator" != "--" ]; then
		echo "Usage: run_test <name> <mode> <cache> <script> -- [args...]" >&2
		exit 1
	fi

	# Выводим параметры сценария перед запуском теста.
	echo "=== test ==="
	echo "runtime: bash"
	echo "test: $name"
	echo "mode: $mode"
	echo "cache: $cache"
	echo "script: $script"
	echo "args: ${*:6}"
	echo "TESTS_FS_WINDOWS: ${TESTS_FS_WINDOWS:-}"
	echo "TESTS_FS_WSL: ${TESTS_FS_WSL:-}"
	echo "WSL_DISTRO: ${WSL_DISTRO:-}"

	# Вызываем скрипт теста отдельно от служебных параметров run_test:
	# первые 4 аргумента — метаданные строки CSV, 5-й — разделитель `--`,
	# аргументы с 6-го — параметры теста.
	local output
	output="$("$script" "${@:6}")"

	local parsed
	parsed="$(parse_result "$output")"

	echo "bash,$name,$mode,$cache,$parsed" >> "$CSV"
}

# Подготавливаем тестовые директории перед запуском всех бенчмарков.
"$BASH_TESTS_DIR/setup-fs.sh"

# Запускаем тест рекурсивного обхода файлов.
run_test "files-find" "native" "none" "$BASH_TESTS_DIR/files-find.sh" -- false
run_test "files-find" "proxy" "none" "$BASH_TESTS_DIR/files-find.sh" -- true

# Запускаем тест массового создания и удаления файлов.
run_test "files-create-delete" "native" "none" "$BASH_TESTS_DIR/files-create-delete.sh" -- false
run_test "files-create-delete" "proxy" "none" "$BASH_TESTS_DIR/files-create-delete.sh" -- true

# Запускаем тест npm-install с прогретым и пустым кешем.
run_test "npm-install" "native" "true" "$BASH_TESTS_DIR/npm-install.sh" -- false true
run_test "npm-install" "native" "false" "$BASH_TESTS_DIR/npm-install.sh" -- false false
run_test "npm-install" "proxy" "true" "$BASH_TESTS_DIR/npm-install.sh" -- true true
run_test "npm-install" "proxy" "false" "$BASH_TESTS_DIR/npm-install.sh" -- true false
