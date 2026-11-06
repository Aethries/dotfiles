#!/usr/bin/env bash
# Small status line for the Hyprlock surface.
set -euo pipefail

battery="$(upower -e 2>/dev/null | grep -m1 '/BAT' | xargs -r upower -i 2>/dev/null |
	awk '/percentage:/ { print $2; exit }')"

if [[ -n "$battery" ]]; then
	echo "Battery $battery"
else
	date +"%A, %d %B"
fi
