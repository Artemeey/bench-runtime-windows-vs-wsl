#!/usr/bin/env bash

get_test_root() {
	local proxy="$1"

	if [ -z "${TESTS_FS_WINDOWS:-}" ] || [ -z "${TESTS_FS_WSL:-}" ] || [ -z "${WSL_DISTRO:-}" ]; then
		echo "ENV not set" >&2
		exit 1
	fi

	if [ "${MSYSTEM:-}" != "" ]; then
		if [ "$proxy" = "true" ]; then
			echo "//wsl.localhost/${WSL_DISTRO}${TESTS_FS_WSL}"
		else
			echo "$TESTS_FS_WINDOWS"
		fi
	else
		if [ "$proxy" = "true" ]; then
			echo "$TESTS_FS_WINDOWS"
		else
			echo "$TESTS_FS_WSL"
		fi
	fi
}
