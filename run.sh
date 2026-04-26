#!/usr/bin/env bash

# Запускаем все бенчмарки проекта и сохраняем результаты в CSV.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BASH_TESTS_DIR="$SCRIPT_DIR/bash"
RESULTS_DIR="$PROJECT_ROOT/results"
source "$BASH_TESTS_DIR/.utils.sh"

mkdir -p "$RESULTS_DIR"
CSV="$RESULTS_DIR/results.csv"
RESULTS_TXT="$RESULTS_DIR/results.txt"

if [ ! -f "$CSV" ]; then
	echo "runtime,test,cross_fs,cache,files,time,cpu_user,cpu_sys" > "$CSV"
fi

# Приводим вывод отдельного теста к формату CSV-полей.
parse_result() {
	local output="$1"

	local files time user sys

	files="$(echo "$output" | grep '^files:' | sed 's/files: //')"
	time="$(echo "$output" | grep '^time:' | sed 's/time: //' | sed 's/ sec//')"
	user="$(echo "$output" | grep '^cpu_user:' | sed 's/cpu_user: //' | sed 's/ sec//')"
	sys="$(echo "$output" | grep '^cpu_sys:' | sed 's/cpu_sys: //' | sed 's/ sec//')"

	echo "$files,$time,$user,$sys"
}

# Выполняем один тест и пишем строку результата с метаданными сценария.
run_test() {
	local name="$1"
	local cross_fs="$2"
	local cache="$3"
	local script="$4"
	local separator="${5:-}"

	if [ "$separator" != "--" ]; then
		echo "Usage: run_test <name> <cross_fs> <cache> <script> -- [args...]" >&2
		exit 1
	fi

	# Печатаем короткий заголовок сценария, чтобы тесты не сливались в логе.
	echo
	echo "🧪 $name | cross_fs=$cross_fs | cache=$cache | args=${*:6}"

	# Вызываем скрипт теста отдельно от служебных параметров run_test:
	# первые 4 аргумента — метаданные строки CSV, 5-й — разделитель `--`,
	# аргументы с 6-го — параметры теста.
	local output
	output="$("$script" "${@:6}")"

	echo "$output"

	local parsed
	parsed="$(parse_result "$output")"

	echo "bash,$name,$cross_fs,$cache,$parsed" >> "$CSV"
}

# Подготавливаем тестовые директории перед запуском всех бенчмарков.
load_project_env

# Сохраняем версии инструментов и параметры запуска в текстовый отчёт.
wsl_version_raw="$(wsl --version 2>/dev/null | tr -d '\000' | sed -E 's/[^[:print:]]//g' | head -n 1 || true)"
wsl_version="$(echo "$wsl_version_raw" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1 || true)"
windows_os="$(uname -sr 2>/dev/null | sed -E 's/^.*(NT-[0-9.]+).*$/Windows \1/' || true)"
unix_os="$(uname -srmo 2>/dev/null || true)"

report_block="$({
	[ -s "$RESULTS_TXT" ] && echo
	echo "🟦 runtime: bash"
	echo "runtime: bash"
	echo "os_unix: $unix_os"
	echo "os_windows: $windows_os"
	echo "bash: ${BASH_VERSION:-unknown}"
	echo "node: $(node -v 2>/dev/null || true)"
	echo "npm: $(npm -v 2>/dev/null || true)"
	echo "wsl: $wsl_version"
	echo "TESTS_FS_WINDOWS: ${TESTS_FS_WINDOWS:-}"
	echo "TESTS_FS_WSL: ${TESTS_FS_WSL:-}"
	echo "WSL_DISTRO: ${WSL_DISTRO:-}"
})"

echo "$report_block" | tee -a "$RESULTS_TXT"

"$BASH_TESTS_DIR/setup-fs.sh"

# Печатаем параметры окружения один раз на весь прогон.
echo "⚙️ runtime=bash | TESTS_FS_WINDOWS=${TESTS_FS_WINDOWS:-} | TESTS_FS_WSL=${TESTS_FS_WSL:-} | WSL_DISTRO=${WSL_DISTRO:-}"

# Сначала запускаем все native-сценарии (cross_fs=false).
run_test "files-find" "false" "none" "$BASH_TESTS_DIR/files-find.sh" -- false
run_test "files-create-delete" "false" "none" "$BASH_TESTS_DIR/files-create-delete.sh" -- false
run_test "npm-install" "false" "true" "$BASH_TESTS_DIR/npm-install.sh" -- false true
run_test "npm-install" "false" "false" "$BASH_TESTS_DIR/npm-install.sh" -- false false

# Затем запускаем все proxy-сценарии (cross_fs=true).
run_test "files-find" "true" "none" "$BASH_TESTS_DIR/files-find.sh" -- true
run_test "files-create-delete" "true" "none" "$BASH_TESTS_DIR/files-create-delete.sh" -- true
run_test "npm-install" "true" "true" "$BASH_TESTS_DIR/npm-install.sh" -- true true
run_test "npm-install" "true" "false" "$BASH_TESTS_DIR/npm-install.sh" -- true false
