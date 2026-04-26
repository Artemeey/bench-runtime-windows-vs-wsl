#!/usr/bin/env bash

# Создаём и удаляем 1000 файлов.

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

FILE_COUNT=1000
TEST_DIR="$ROOT/files-create-delete-$(date +%s%N)"

mkdir "$TEST_DIR"

TIMEFORMAT="%3R %3U %3S"
TIME_RESULT="$({ time {
	for i in $(seq 1 "$FILE_COUNT"); do
		printf 'test' > "$TEST_DIR/file-$i.txt"
	done

	rm -rf "$TEST_DIR"
}; } 2>&1)"

read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

write_test_result "$FILE_COUNT" "$REAL_TIME" "$USER_CPU" "$SYS_CPU"
