#!/usr/bin/env bash

# Resolve benchmark root path.
# false = native filesystem, true = proxy filesystem.

windows_path_to_git_bash_path() {
	local path="$1"
	local drive="${path:0:1}"
	local rest="${path:2}"

	drive="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
	rest="${rest//\\//}"

	printf '/%s%s\n' "$drive" "$rest"
}

windows_path_to_wsl_path() {
	local path="$1"
	local drive="${path:0:1}"
	local rest="${path:2}"

	drive="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
	rest="${rest//\\//}"

	printf '/mnt/%s%s\n' "$drive" "$rest"
}

get_test_root() {
	local proxy="$1"

	if [ -z "${TESTS_FS_WINDOWS:-}" ] || [ -z "${TESTS_FS_WSL:-}" ] || [ -z "${WSL_DISTRO:-}" ]; then
		echo "ENV not set: TESTS_FS_WINDOWS, TESTS_FS_WSL, WSL_DISTRO" >&2
		exit 1
	fi

	if [ "$proxy" != "true" ] && [ "$proxy" != "false" ]; then
		echo "Invalid mode: $proxy" >&2
		exit 1
	fi

	if [ "${MSYSTEM:-}" != "" ]; then
		if [ "$proxy" = "true" ]; then
			printf '//wsl.localhost/%s%s\n' "$WSL_DISTRO" "$TESTS_FS_WSL"
		else
			windows_path_to_git_bash_path "$TESTS_FS_WINDOWS"
		fi
	else
		if [ "$proxy" = "true" ]; then
			windows_path_to_wsl_path "$TESTS_FS_WINDOWS"
		else
			printf '%s\n' "$TESTS_FS_WSL"
		fi
	fi
}
