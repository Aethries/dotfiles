#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$(mktemp -d -t dotfiles-gh-test-XXXXXX)"
trap 'rm -rf "$CONFIG_DIR"' EXIT

cp "$REPO_ROOT/resources/gh/config.yml" "$CONFIG_DIR/config.yml"
ALIASES="$(GH_CONFIG_DIR="$CONFIG_DIR" gh alias list)"

expected_aliases=(
    "il: issue list --state open"
    "ila: issue list --state all"
    "iv: issue view --comments"
    "ic: issue create"
    "icl: issue close"
    "ire: issue reopen"
    "prl: pr list"
    "prv: pr view --comments"
    "prd: pr diff"
    "prc: pr create"
    "co: pr checkout"
    "prm: pr merge --squash --delete-branch"
    "ml: '!gh api repos/:owner/:repo/milestones --jq \".[] | {number, title, open_issues, closed_issues, state}\"'"
    "mli: issue list --state all --milestone"
    "d: '!gh-dash'"
    "browse-here: browse"
)

for expected in "${expected_aliases[@]}"; do
    grep -Fqx "$expected" <<<"$ALIASES"
done

echo "[✓] GitHub CLI aliases are loadable, complete, and mapped to expected commands"
