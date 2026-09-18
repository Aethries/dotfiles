#!/usr/bin/env bash

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AI="$REPO_ROOT/scripts/ai.sh"
TEST_HOME="$(mktemp -d -t dotfiles-ai-migration-XXXXXX)"
TEST_STATE="$(mktemp -d -t dotfiles-ai-migration-state-XXXXXX)"
mkdir -p "$TEST_HOME/.9router/mitm" "$TEST_HOME/.local/bin"
printf 'credential-placeholder\n' > "$TEST_HOME/.9router/mitm/rootCA.key"
ln -s "$REPO_ROOT/scripts/init-9router.sh" "$TEST_HOME/.local/bin/init-9router"
before="$(find "$TEST_HOME" -print | sort)"

HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_STATE" "$AI" migrate-9router --dry-run >/dev/null
after="$(find "$TEST_HOME" -print | sort)"
[ "$before" = "$after" ]
[ -f "$TEST_HOME/.9router/mitm/rootCA.key" ]

printf 'AI migration tests passed.\n'
