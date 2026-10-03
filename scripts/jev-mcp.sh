#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${JEV_NODE_BIN:-node}" "$SCRIPT_DIR/jev-mcp.mjs"
