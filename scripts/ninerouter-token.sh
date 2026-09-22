#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/agency-common.sh"

key_file="$(agency_secret_file)"
key="$(read_ninerouter_key_file "$key_file")" || exit 1
[ -n "$key" ] || exit 1
printf '%s\n' "$key"
unset key
