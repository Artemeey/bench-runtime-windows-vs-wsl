#!/usr/bin/env bash

# npm install benchmark (with/without cache)

set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <true|false> <true|false>"
	exit 1
fi

PROXY="$1"
USE_CACHE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_JSON="$SCRIPT_DIR/package.json"

source "$SCRIPT_DIR/fs-path.sh"

ROOT="$(get_test_root "$PROXY")"
NPM_DIR="$ROOT/npm-install"

if [ ! -f "$PACKAGE_JSON" ]; then
	echo "package.json not found: $PACKAGE_JSON" >&2
	exit 1
fi

# Recreate working dir
rm -rf "$NPM_DIR"
mkdir -p "$NPM_DIR"
cp "$PACKAGE_JSON" "$NPM_DIR/package.json"

# Control npm cache
if [ "$USE_CACHE" = "false" ]; then
	npm cache clean --force > /dev/null 2>&1
fi

TIMEFORMAT="%3R %3U %3S"

if [ "$USE_CACHE" = "true" ]; then
	TIME_RESULT="$({ time npm install --prefer-offline --prefix "$NPM_DIR" > /dev/null; } 2>&1)"
else
	TIME_RESULT="$({ time npm install --prefer-online --prefix "$NPM_DIR" > /dev/null; } 2>&1)"
fi

read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

FILES="$(find "$NPM_DIR/node_modules" -type f 2>/dev/null | wc -l | tr -d ' ')"

echo "files: ${FILES:-0}"
echo "time: $REAL_TIME sec"
echo "cpu: $USER_CPU user + $SYS_CPU sys sec"
