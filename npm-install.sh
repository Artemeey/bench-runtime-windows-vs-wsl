#!/usr/bin/env bash

# npm install benchmark (reproducible via npm ci)

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

# Ensure lockfile exists
if [ ! -f "$SCRIPT_DIR/package-lock.json" ]; then
	npm install --package-lock-only > /dev/null
fi

rm -rf "$NPM_DIR"
mkdir -p "$NPM_DIR"
cp "$PACKAGE_JSON" "$NPM_DIR/package.json"
cp "$SCRIPT_DIR/package-lock.json" "$NPM_DIR/package-lock.json"

if [ "$USE_CACHE" = "false" ]; then
	npm cache clean --force > /dev/null 2>&1
fi

TIMEFORMAT="%3R %3U %3S"
TIME_RESULT="$({ time npm ci --prefix "$NPM_DIR" > /dev/null; } 2>&1)"

read -r REAL_TIME USER_CPU SYS_CPU <<< "$TIME_RESULT"

FILES="$(find "$NPM_DIR/node_modules" -type f 2>/dev/null | wc -l | tr -d ' ')"

echo "files: ${FILES:-0}"
echo "time: $REAL_TIME sec"
echo "cpu: $USER_CPU user + $SYS_CPU sys sec"
