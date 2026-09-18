#!/usr/bin/env bash

set -euo pipefail
BASE_URL="http://127.0.0.1:20128"

command -v curl >/dev/null 2>&1 || { echo "curl is required for smoke test" >&2; exit 1; }
systemctl --user is-enabled omniroute.service >/dev/null
systemctl --user is-active omniroute.service >/dev/null
curl --fail --silent --show-error --max-time 5 "$BASE_URL/api/health/ping" >/dev/null
curl --fail --silent --show-error --max-time 5 "$BASE_URL/v1/models" >/dev/null
printf 'AI smoke test passed.\n'
