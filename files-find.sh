#!/usr/bin/env bash

# Count files recursively and measure time/CPU

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

COUNT_FILE="$(mktemp)"
TIMEFORMAT="%3R %3U %3S"

# Capture real/user/sys from bash built-in time
TIME_RESULT="$({ time find "$ROOT" -type f > "$COUNT_FILE"; } 2>&1)"
read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

FILES="$(wc -l < "$COUNT_FILE" | tr -d ' ')"
rm -f "$COUNT_FILE"

echo "files: $FILES"
echo "time: $REAL_TIME sec"
echo "cpu: $USER_CPU user + $SYS_CPU sys sec"
