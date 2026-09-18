#!/usr/bin/env bash

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICE="$REPO_ROOT/resources/systemd/user/omniroute.service"
BIFROST="$REPO_ROOT/resources/systemd/user/bifrost.service"

grep -q '^ExecStart=/run/current-system/sw/bin/omniroute serve --no-open --no-tray$' "$SERVICE"
grep -q 'OMNIROUTE_SERVER_HOST=127.0.0.1' "$SERVICE"
grep -q 'PORT=20128' "$SERVICE"
grep -q '^Restart=on-failure$' "$SERVICE"
grep -qi '9router' "$SERVICE" "$BIFROST" && exit 1 || true
grep -q 'bifrost-container start' "$BIFROST"
grep -q 'bifrost-container stop' "$BIFROST"

printf 'AI service tests passed.\n'
