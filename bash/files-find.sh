#!/usr/bin/env bash

# Считаем количество файлов рекурсивно.

set -euo pipefail
export LC_NUMERIC=C

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

COUNT_FILE="$(mktemp)"
TIMEFORMAT="%3R %3U %3S"

# Считываем real/user/sys из встроенной команды `time` в Bash.
TIME_RESULT="$({ time find "$ROOT" -type f > "$COUNT_FILE"; } 2>&1)"
read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

FILES="$(wc -l < "$COUNT_FILE" | tr -d ' ')"
rm -f "$COUNT_FILE"

echo "files: $FILES"
echo "time: $REAL_TIME sec"
echo "cpu_user: $USER_CPU sec"
echo "cpu_sys: $SYS_CPU sec"
