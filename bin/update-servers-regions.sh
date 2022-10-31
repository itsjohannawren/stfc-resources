#!/usr/bin/env bash

SOURCE="https://cdn-nv3-live.startrek.digitgaming.com/gateway/v2/game_info/prime"
TARGET="servers/regions"

# ==============================================================================

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

curl -s -H "Accept: application/json" "${SOURCE}" | \
jq --tab '
	.product.instances |
	. as $servers |
	{
		"by_region": (
			reduce (
				[
					.[].name |
					ascii_downcase |
					sub("-[0-9]+$"; "")
				] |
				unique
			)[] as $region (
				{};
				. += {
					($region): (
						[
							$servers[] |
							select(
								$region == (
									.name |
									ascii_downcase |
									sub("-[0-9]+$"; "")
								)
							)
						] |
						reduce .[] as $server (
							[];
							. += [
								($server.id | tostring)
							]
						)
					)
				}
			)
		),
		"by_server": (reduce .[] as $server (
			{};
			. += {
				($server.id | tostring): ($server.name | ascii_downcase | sub("-[0-9]+$"; ""))
			}
		))
	}
' \
> "$(dirname "${__DIR__}")/${TARGET}.json"

# ==============================================================================

yq -p json -o yaml "$(dirname "${__DIR__}")/${TARGET}.json" > "$(dirname "${__DIR__}")/${TARGET}.yaml"
