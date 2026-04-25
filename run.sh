#!/usr/bin/env bash

# Runs all benchmarks for Bash / WSL / Git Bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prepare benchmark folders before running tests
"$SCRIPT_DIR/setup-fs.sh"

echo
echo "files-find native"
"$SCRIPT_DIR/files-find.sh" false

echo
echo "files-find proxy"
"$SCRIPT_DIR/files-find.sh" true

echo
echo "files-create-delete native"
"$SCRIPT_DIR/files-create-delete.sh" false

echo
echo "files-create-delete proxy"
"$SCRIPT_DIR/files-create-delete.sh" true

echo
echo "npm-install native cache"
"$SCRIPT_DIR/npm-install.sh" false true

echo
echo "npm-install native no-cache"
"$SCRIPT_DIR/npm-install.sh" false false

echo
echo "npm-install proxy cache"
"$SCRIPT_DIR/npm-install.sh" true true

echo
echo "npm-install proxy no-cache"
"$SCRIPT_DIR/npm-install.sh" true false
