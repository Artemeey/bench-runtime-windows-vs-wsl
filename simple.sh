#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-.}"
EXT="${2:-*}"
LIST="/tmp/fs-test-files.$$"
RESULTS="/tmp/fs-test-results.$$"

trap 'rm -f "$LIST" "$RESULTS"' EXIT

now_ms() {
	date +%s%3N
}

format_ms() {
	awk -v ms="$1" 'BEGIN { printf "%.3f", ms / 1000 }'
}

measure() {
	local name="$1"
	local start
	local end
	local elapsed

	shift

	start="$(now_ms)"
	"$@"
	end="$(now_ms)"

	elapsed="$((end - start))"

	printf '%s\t%s\n' "$name" "$(format_ms "$elapsed")" >> "$RESULTS"
}

printf 'Filesystem test\n'
printf 'DIR: %s\n' "$DIR"
printf 'EXT: .%s\n\n' "$EXT"

measure "find files" \
	bash -c '
		find "$1" \
			-path "$1/vendor" -prune -o \
			-path "$1/node_modules" -prune -o \
			-path "$1/.git" -prune -o \
			-type f \
			-name "*.$2" \
			-print0 > "$3"
	' _ "$DIR" "$EXT" "$LIST"

FILES_COUNT="$(tr -cd '\0' < "$LIST" | wc -c | tr -d ' ')"

measure "count files" \
	bash -c '
		tr -cd "\0" < "$1" | wc -c >/dev/null
	' _ "$LIST"

measure "read sizes" \
	bash -c '
		xargs -0 stat -c "%s" < "$1" >/dev/null
	' _ "$LIST"

measure "md5" \
	bash -c '
		xargs -0 md5sum < "$1" >/dev/null
	' _ "$LIST"

printf '%-16s %10s\n' "TEST" "SECONDS"
printf '%-16s %10s\n' "----------------" "----------"

while IFS=$'\t' read -r name seconds; do
	printf '%-16s %10s\n' "$name" "$seconds"
done < "$RESULTS"

TOTAL="$(
	awk -F '\t' '{ sum += $2 } END { printf "%.3f", sum }' "$RESULTS"
)"

printf '\n%-16s %10s\n' "files" "$FILES_COUNT"
printf '%-16s %10s\n' "total" "$TOTAL"
