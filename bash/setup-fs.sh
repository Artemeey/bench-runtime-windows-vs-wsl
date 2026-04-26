#!/usr/bin/env bash

# Создаём тестовые директории для всех сценариев бенчмарка: native и proxy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_JSON="$PROJECT_ROOT/package.json"

source "$SCRIPT_DIR/fs-path.sh"

# Проверяем, что в корне бенчмарка есть package.json для npm-теста.
if [ ! -f "$PACKAGE_JSON" ]; then
	echo "package.json not found: $PACKAGE_JSON" >&2
	exit 1
fi

for proxy in false true; do
	# Разворачиваем структуру теста в нативной и прокси файловых системах.
	root="$(get_test_root "$proxy")"
	npm_dir="$root/npm-install"

	# Кладём одинаковый package.json в обе директории, чтобы условия npm-теста совпадали.
	mkdir -p "$npm_dir"
	cp "$PACKAGE_JSON" "$npm_dir/package.json"

	echo "prepared: $root"
done
