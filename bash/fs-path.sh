#!/usr/bin/env bash

# Определяем корневой путь тестов для режима native/proxy.
# false = нативная файловая система, true = доступ через границу Windows ↔ WSL.

# Конвертируем путь Windows (C:\foo\bar) в формат Git Bash (/c/foo/bar).
windows_path_to_git_bash_path() {
	local path="$1"
	local drive="${path:0:1}"
	local rest="${path:2}"

	drive="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
	rest="${rest//\\//}"

	printf '/%s%s\n' "$drive" "$rest"
}

# Конвертируем путь Windows (C:\foo\bar) в формат WSL (/mnt/c/foo/bar).
# Используем это в proxy-режиме WSL Bash, когда тесты идут по файловой системе Windows.
windows_path_to_wsl_path() {
	local path="$1"
	local drive="${path:0:1}"
	local rest="${path:2}"

	drive="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
	rest="${rest//\\//}"

	printf '/mnt/%s%s\n' "$drive" "$rest"
}

# Определяем корневой путь тестов для заданного режима и текущего runtime.
get_test_root() {
	local proxy="$1"

	# Проверяем обязательные переменные окружения для обоих направлений теста.
	if [ -z "${TESTS_FS_WINDOWS:-}" ] || [ -z "${TESTS_FS_WSL:-}" ] || [ -z "${WSL_DISTRO:-}" ]; then
		echo "ENV not set: TESTS_FS_WINDOWS, TESTS_FS_WSL, WSL_DISTRO" >&2
		exit 1
	fi

	# Ограничиваем режим только true/false, чтобы не получить случайный путь.
	if [ "$proxy" != "true" ] && [ "$proxy" != "false" ]; then
		echo "Invalid mode: $proxy" >&2
		exit 1
	fi

	if [ "${MSYSTEM:-}" != "" ]; then
		# Обрабатываем ветку Git Bash.
		if [ "$proxy" = "true" ]; then
			# Строим путь Git Bash (Windows) -> файловая система WSL через UNC \\wsl.localhost\...
			printf '//wsl.localhost/%s%s\n' "$WSL_DISTRO" "$TESTS_FS_WSL"
		else
			# Строим путь Git Bash (Windows) -> файловая система Windows в формате /c/...
			windows_path_to_git_bash_path "$TESTS_FS_WINDOWS"
		fi
	else
		# Обрабатываем ветку WSL Bash.
		if [ "$proxy" = "true" ]; then
			# Строим путь WSL Bash -> файловая система Windows в формате /mnt/<drive>/...
			windows_path_to_wsl_path "$TESTS_FS_WINDOWS"
		else
			# Берём путь WSL Bash -> файловая система WSL напрямую.
			printf '%s\n' "$TESTS_FS_WSL"
		fi
	fi
}
