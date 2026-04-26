#!/usr/bin/env bash

# Считаем количество файлов рекурсивно.

set -euo pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <proxy: true|false>"
	exit 1
fi

PROXY="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.utils.sh"
load_project_env

ROOT="$(get_root_path "$PROXY")"
confirm_directory_exists "$ROOT"

COUNT_FILE="$(mktemp)"
TIMEFORMAT="%3R %3U %3S"

# Считываем real/user/sys из встроенной команды `time` в Bash.
TIME_RESULT="$({ time find "$ROOT" -type f > "$COUNT_FILE"; } 2>&1)"
read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

FILES="$(wc -l < "$COUNT_FILE" | tr -d ' ')"
rm -f "$COUNT_FILE"

write_test_result "$FILES" "$REAL_TIME" "$USER_CPU" "$SYS_CPU"
