#!/usr/bin/env bash

# npm ci benchmark (reproducible)

set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <true|false> <true|false>"
	exit 1
fi

PROXY="$1"
USE_CACHE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/fs-path.sh"

ROOT="$(get_test_root "$PROXY")"
NPM_DIR="$ROOT/npm-install"

if [ ! -f "$NPM_DIR/package-lock.json" ]; then
	echo "package-lock.json not found. Run setup-fs first." >&2
	exit 1
fi

rm -rf "$NPM_DIR/node_modules"

if [ "$USE_CACHE" = "false" ]; then
	npm cache clean --force > /dev/null 2>&1
fi

TIMEFORMAT="%3R %3U %3S"
TIME_RESULT="$({ time npm ci --prefix "$NPM_DIR" > /dev/null 2>/dev/null; } 2>&1)"

read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

FILES="$(find "$NPM_DIR/node_modules" -type f 2>/dev/null | wc -l | tr -d ' ')"

echo "files: ${FILES:-0}"
echo "time: $REAL_TIME sec"
echo "cpu: $USER_CPU user + $SYS_CPU sys sec"
