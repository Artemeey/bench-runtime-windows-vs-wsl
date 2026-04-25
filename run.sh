#!/usr/bin/env bash

# Runs all benchmarks and writes CSV results

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"
CSV="$RESULTS_DIR/results.csv"

echo "runtime,test,mode,cache,files,time,cpu_user,cpu_sys" > "$CSV"

parse_result() {
	local output="$1"

	local files time cpu user sys

	files="$(echo "$output" | grep '^files:' | sed 's/files: //')"
	time="$(echo "$output" | grep '^time:' | sed 's/time: //' | sed 's/ sec//')"
	cpu="$(echo "$output" | grep '^cpu:' | sed 's/cpu: //')"

	user="$(echo "$cpu" | cut -d' ' -f1)"
	sys="$(echo "$cpu" | awk -F'\+ ' '{print $2}' | sed 's/ sys sec//')"

	echo "$files,$time,$user,$sys"
}

run_test() {
	local name="$1"
	local mode="$2"
	local cache="$3"
	shift 3

	local output
	output="$("$@")"

	local parsed
	parsed="$(parse_result "$output")"

	echo "bash,$name,$mode,$cache,$parsed" >> "$CSV"
}

"$SCRIPT_DIR/setup-fs.sh"

run_test "files-find" "native" "none" "$SCRIPT_DIR/files-find.sh" false
run_test "files-find" "proxy" "none" "$SCRIPT_DIR/files-find.sh" true

run_test "files-create-delete" "native" "none" "$SCRIPT_DIR/files-create-delete.sh" false
run_test "files-create-delete" "proxy" "none" "$SCRIPT_DIR/files-create-delete.sh" true

run_test "npm-install" "native" "true" "$SCRIPT_DIR/npm-install.sh" false true
run_test "npm-install" "native" "false" "$SCRIPT_DIR/npm-install.sh" false false
run_test "npm-install" "proxy" "true" "$SCRIPT_DIR/npm-install.sh" true true
run_test "npm-install" "proxy" "false" "$SCRIPT_DIR/npm-install.sh" true false
