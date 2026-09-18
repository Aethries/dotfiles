#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_REQUEST="${CODEGRAPH_WORKSPACE:-$PWD}"
WORKSPACE="$(realpath "$WORKSPACE_REQUEST")"

case "$WORKSPACE" in
    "$HOME"|/|"$HOME/Downloads"|"$HOME/Downloads/"*|"$HOME/Documents"|"$HOME/Documents/"*|/Downloads|/Downloads/*|/Documents|/Documents/*)
        echo "CodeGraph MCP requires an explicit Git workspace, not HOME/root/Downloads/Documents." >&2
        exit 1
        ;;
esac

WORKSPACE="$(git -C "$WORKSPACE" rev-parse --show-toplevel)"
args=(--mcp --workspace "$WORKSPACE" --profile core)
while IFS= read -r exclusion; do
    [ -n "$exclusion" ] || continue
    args+=(--exclude "$exclusion")
done < "$REPO_ROOT/resources/ai/codegraph/excludes.txt"

# Không fallback về HOME: MCP chỉ được phép index Git workspace đã xác định.
exec codegraph-server "${args[@]}"
