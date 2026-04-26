#!/usr/bin/env bash

# Создаём тестовые директории для всех сценариев бенчмарка: native и proxy.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/.utils.sh"
load_project_env

for proxy in false true; do
	# Разворачиваем структуру теста в нативной и прокси файловых системах.
	root="$(get_root_path "$proxy")"
	confirm_directory_exists "$root"
	npm_dir="$root/npm-install"
	mode_name="native"
	if [ "$proxy" = "true" ]; then
		mode_name="proxy"
	fi

	# Кладём одинаковые package.json и package-lock.json в обе директории, чтобы условия npm-теста совпадали.
	if [ "${MSYSTEM:-}" != "" ] && [ "$proxy" = "true" ]; then
		# Делаем так, чтобы не было ошибок `mkdir -p` при обходе readonly родительских папок
		wsl -d "$WSL_DISTRO" bash -lc "mkdir -p '$TESTS_FS_WSL/npm-install'"
	else
		mkdir -p "$npm_dir"
	fi

	cp "$PROJECT_ROOT/package.json" "$npm_dir/package.json"
	cp "$PROJECT_ROOT/package-lock.json" "$npm_dir/package-lock.json"

	echo "init dir ($mode_name): $root"
done
