#!/usr/bin/env bash

# Запускаем `run.sh` заданное количество раз для накопления статистики.
set -euo pipefail

RUN_COUNT="${1:-}"

if ! [[ "$RUN_COUNT" =~ ^[1-9][0-9]*$ ]]; then
	echo "Usage: ./runMulti <count>, example: ./runMulti 10" >&2
	exit 1
fi

for ((i = 1; i <= RUN_COUNT; i++)); do
	echo
	echo "🔁 Iteration $i/$RUN_COUNT"
	./run.sh
done

