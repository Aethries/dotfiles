#!/usr/bin/env bash

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d -t dotfiles-codegraph-XXXXXX)"
WORKSPACE="$TEST_ROOT/workspace"
FAKE_BIN="$TEST_ROOT/bin"
mkdir -p "$WORKSPACE" "$FAKE_BIN"
git -C "$WORKSPACE" init -q
cp "$REPO_ROOT/tests/ai/fixtures/codegraph-server" "$FAKE_BIN/codegraph-server"
chmod +x "$FAKE_BIN/codegraph-server"

export CODEGRAPH_TEST_LOG="$TEST_ROOT/args"
export CODEGRAPH_WORKSPACE="$WORKSPACE"
PATH="$FAKE_BIN:$PATH" "$REPO_ROOT/scripts/codegraph-mcp.sh"
grep -q -- '--mcp' "$CODEGRAPH_TEST_LOG"
grep -q -- '--profile core' "$CODEGRAPH_TEST_LOG"
grep -q -- '--exclude .env' "$CODEGRAPH_TEST_LOG"

if CODEGRAPH_WORKSPACE="$HOME" PATH="$FAKE_BIN:$PATH" "$REPO_ROOT/scripts/codegraph-mcp.sh" >/dev/null 2>&1; then
    echo "CodeGraph accepted HOME as a workspace" >&2
    exit 1
fi

printf 'CodeGraph safety tests passed.\n'
