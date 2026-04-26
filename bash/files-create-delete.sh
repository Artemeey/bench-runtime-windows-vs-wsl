#!/usr/bin/env bash

# Создаём и удаляем 10 000 файлов.

set -euo pipefail

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <true|false>"
	exit 1
fi

PROXY="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/fs-path.sh"

ROOT="$(get_test_root "$PROXY")"

if [ ! -d "$ROOT" ]; then
	echo "Path not found: $ROOT" >&2
	exit 1
fi

FILE_COUNT=10000
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

echo "files: $FILE_COUNT"
echo "time: $REAL_TIME sec"
echo "cpu: $USER_CPU user + $SYS_CPU sys sec"
