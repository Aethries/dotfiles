#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$(mktemp -d -t dotfiles-gh-test-XXXXXX)"
trap 'rm -rf "$CONFIG_DIR"' EXIT

cp "$REPO_ROOT/resources/gh/config.yml" "$CONFIG_DIR/config.yml"
ALIASES="$(GH_CONFIG_DIR="$CONFIG_DIR" gh alias list)"

for alias in il ila iv ic icl ire prl prv prd prc co prm ml mli d browse-here; do
    grep -Eq "^${alias}:" <<<"$ALIASES"
done

echo "[✓] GitHub CLI aliases are loadable and complete"
