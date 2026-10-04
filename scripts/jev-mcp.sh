#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Expand systemd %h specifier in NODE_EXTRA_CA_CERTS if present
if [[ "${NODE_EXTRA_CA_CERTS:-}" == *"%h"* ]]; then
	NODE_EXTRA_CA_CERTS="${NODE_EXTRA_CA_CERTS//%h/$HOME}"
	if [[ -f "$NODE_EXTRA_CA_CERTS" ]]; then
		export NODE_EXTRA_CA_CERTS
	else
		unset NODE_EXTRA_CA_CERTS
	fi
fi

exec "${JEV_NODE_BIN:-node}" "$SCRIPT_DIR/jev-mcp.mjs"

