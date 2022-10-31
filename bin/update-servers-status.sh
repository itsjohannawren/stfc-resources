#!/usr/bin/env bash

SOURCE="https://cdn-nv3-live.startrek.digitgaming.com/gateway/v2/game_info/prime"
TARGET="data/servers/status"

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
jq '
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
				($server.id | tostring): {
					"id": ($server.id),
					"name": ($server.name),
					"region": ($server.name | ascii_downcase | sub("-[0-9]+$"; "")),
					"priority": ($server.priority),
					"up": (if ($server.status | tonumber) == 1 then true else false end),
					"maintenance": (if ($server.maintenance | tonumber) == 0 then false else true end),
					"transfer_in": ($server.player_transfer_state.transfer_in),
					"transfer_out": ($server.player_transfer_state.transfer_out)
				}
			}
		))
	}
' \
> "$(dirname "${__DIR__}")/${TARGET}.json"

# ==============================================================================

yq -p json -o yaml "$(dirname "${__DIR__}")/${TARGET}.json" > "$(dirname "${__DIR__}")/${TARGET}.yaml"
