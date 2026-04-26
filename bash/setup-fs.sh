#!/usr/bin/env bash

# Создаём тестовые директории для всех сценариев бенчмарка: native и proxy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/fs-path.sh"

for proxy in false true; do
	# Разворачиваем структуру теста в нативной и прокси файловых системах.
	root="$(get_test_root "$proxy")"
	npm_dir="$root/npm-install"

	# Кладём одинаковый package.json в обе директории, чтобы условия npm-теста совпадали.
	mkdir -p "$npm_dir"
	cp "$PROJECT_ROOT/package.json" "$npm_dir/package.json"
	cp "$PROJECT_ROOT/package-lock.json" "$npm_dir/package-lock.json"

	echo "prepared: $root"
done
