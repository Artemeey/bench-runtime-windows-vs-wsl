#!/usr/bin/env bash

# Запускаем все бенчмарки проекта и сохраняем результаты в CSV.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BASH_TESTS_DIR="$SCRIPT_DIR/bash"
source "$BASH_TESTS_DIR/.utils.sh"

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

	echo "bash,$name,$cross_fs,$cache,$parsed" >> "$RESULTS_CSV_PATH"
}

# Подготавливаем тестовые директории перед запуском всех бенчмарков.
load_project_env

# Формируем директорию результатов внутри TESTS_FS_WINDOWS, чтобы все прогоны писались в одно место.
RESULTS_DIR_WINDOWS="${TESTS_FS_WINDOWS%/}/results"

if [ "${MSYSTEM:-}" != "" ]; then
	RESULTS_DIR_PATH="$(windows_path_to_git_bash_path "$RESULTS_DIR_WINDOWS")"
else
	RESULTS_DIR_PATH="$(windows_path_to_wsl_path "$RESULTS_DIR_WINDOWS")"
fi

mkdir -p "$RESULTS_DIR_PATH"
RESULTS_CSV_PATH="$RESULTS_DIR_PATH/results.csv"
RESULTS_TXT_PATH="$RESULTS_DIR_PATH/results.txt"

if [ ! -f "$RESULTS_CSV_PATH" ]; then
	echo "runtime,test,cross_fs,cache,files,time,cpu_user,cpu_sys" > "$RESULTS_CSV_PATH"
fi

# Сохраняем версии инструментов и параметры запуска в текстовый отчёт.
wsl_version_raw="$(wsl --version 2>/dev/null | tr -d '\000' | sed -E 's/[^[:print:]]//g' | head -n 1 || true)"
wsl_version="$(echo "$wsl_version_raw" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n 1 || true)"
windows_os="$(uname -sr 2>/dev/null | sed -E 's/^.*(NT-[0-9.]+).*$/Windows \1/' || true)"
unix_os="$(uname -srmo 2>/dev/null || true)"

# Определяем тип файловой системы по локальному пути.
get_fs_type_local() {
	local path="$1"
	df -T "$path" 2>/dev/null | awk 'NR==2 {print $2}'
}

# Определяем тип файловой системы по пути внутри WSL.
get_fs_type_wsl() {
	local path="$1"
	wsl -d "$WSL_DISTRO" bash -lc "df -T '$path' 2>/dev/null | sed -n '2p' | tr -s ' ' | cut -d' ' -f2" 2>/dev/null
}

windows_path_for_bash="$(windows_path_to_git_bash_path "$TESTS_FS_WINDOWS")"
windows_path_for_wsl="$(windows_path_to_wsl_path "$TESTS_FS_WINDOWS")"
wsl_path_for_wsl="$TESTS_FS_WSL"

if [ "${MSYSTEM:-}" != "" ]; then
	fs_windows="$(get_fs_type_local "$windows_path_for_bash")"
	fs_wsl="$(get_fs_type_wsl "$wsl_path_for_wsl")"
else
	fs_windows="$(get_fs_type_local "$windows_path_for_wsl")"
	fs_wsl="$(get_fs_type_local "$wsl_path_for_wsl")"
fi

report_block="$({
	[ -s "$RESULTS_TXT_PATH" ] && echo
	echo "🟦 runtime: bash"
	echo "os_unix: $unix_os"
	echo "os_windows: $windows_os"
	echo "wsl: $wsl_version (${WSL_DISTRO:-})"
	echo "fs_windows: ${TESTS_FS_WINDOWS} -> ${fs_windows:-unknown}"
	echo "fs_wsl: ${TESTS_FS_WSL} -> ${fs_wsl:-unknown}"
	echo "bash: ${BASH_VERSION:-unknown}"
	echo "node: $(node -v 2>/dev/null || true)"
	echo "npm: $(npm -v 2>/dev/null || true)"
})"

echo "$report_block" | tee -a "$RESULTS_TXT_PATH"

echo "";
"$BASH_TESTS_DIR/setup-fs.sh"

echo "";

# Сначала запускаем все native-сценарии (cross_fs=false).
echo "🟢 Running native mode (cross_fs=false)"
run_test "npm-install" "false" "true" "$BASH_TESTS_DIR/npm-install.sh" -- false true
run_test "npm-install" "false" "false" "$BASH_TESTS_DIR/npm-install.sh" -- false false
run_test "files-find" "false" "none" "$BASH_TESTS_DIR/files-find.sh" -- false
run_test "files-create-delete" "false" "none" "$BASH_TESTS_DIR/files-create-delete.sh" -- false

echo "";

# Затем запускаем все proxy-сценарии (cross_fs=true).
echo "🟣 Running proxy mode (cross_fs=true)"
run_test "npm-install" "true" "true" "$BASH_TESTS_DIR/npm-install.sh" -- true true
run_test "npm-install" "true" "false" "$BASH_TESTS_DIR/npm-install.sh" -- true false
run_test "files-find" "true" "none" "$BASH_TESTS_DIR/files-find.sh" -- true
run_test "files-create-delete" "true" "none" "$BASH_TESTS_DIR/files-create-delete.sh" -- true

# Подготавливаем команду открытия папки результатов в Проводнике.
if [ "${MSYSTEM:-}" != "" ]; then
	RESULTS_DIR_FOR_EXPLORER="${RESULTS_DIR_WINDOWS//\//\\}"
else
	RESULTS_DIR_FOR_EXPLORER="$(wslpath -w "$RESULTS_DIR_PATH")"
fi

RESULTS_URI_PATH="${RESULTS_DIR_FOR_EXPLORER//\\//}"
RESULTS_LINK="file:///$RESULTS_URI_PATH"

echo
echo "📁 Results directory: $RESULTS_DIR_PATH"
echo "🔗 Results link: $RESULTS_LINK"
