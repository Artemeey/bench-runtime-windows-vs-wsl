#!/usr/bin/env bash

# Prepare benchmark folders for native and proxy modes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_JSON="$SCRIPT_DIR/package.json"

source "$SCRIPT_DIR/fs-path.sh"

if [ ! -f "$PACKAGE_JSON" ]; then
	echo "package.json not found: $PACKAGE_JSON" >&2
	exit 1
fi

for proxy in false true; do
	root="$(get_test_root "$proxy")"
	npm_dir="$root/npm-install"

	mkdir -p "$npm_dir"
	cp "$PACKAGE_JSON" "$npm_dir/package.json"

	echo "prepared: $root"
done
