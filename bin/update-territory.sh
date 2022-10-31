#!/usr/bin/env bash

{
	__DIR__="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P 2>/dev/null)"
	if [ -z "${__DIR__}" ]; then
		echo "Error: Failed to determine directory containing this script" 1>&2
		exit 1
	else
		#shellcheck disable=SC2034
		__FILE__="${__DIR__}/$(basename "${BASH_SOURCE[0]}")"
	fi
}

# ==============================================================================

while read -r SOURCE; do
	if [ -z "${SOURCE}" ]; then
		continue
	fi

	yq -p json -o yaml "${SOURCE}" > "${SOURCE%.json}.yaml"
done <<<"$(find "$(dirname "${__DIR__}")/territory" -type f -name '*.json')"
