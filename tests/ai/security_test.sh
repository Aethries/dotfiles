#!/usr/bin/env bash

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ai.sh contains the policy regex itself; scan the implementation inputs here.
if rg -n -i '(npm|pnpm|yarn)[^\n]*@(latest|main|master|nightly|next)|curl[^\n]*\|[^\n]*(sh|bash)|wget[^\n]*\|[^\n]*(sh|bash)|sed[[:space:]]+-i[^\n]*node_modules|loginctl[[:space:]]+enable-linger|tee[[:space:]]+.*(/etc|/usr)' \
    "$REPO_ROOT/pkgs" "$REPO_ROOT/resources/ai" "$REPO_ROOT/scripts" -g '!ai.sh' >/tmp/dotfiles-ai-security-findings 2>/dev/null; then
    sed -n '1,120p' /tmp/dotfiles-ai-security-findings >&2
    exit 1
fi

if rg -n -i 'Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' \
    "$REPO_ROOT/resources/ai" "$REPO_ROOT/scripts/ai.sh" >/tmp/dotfiles-ai-secret-findings 2>/dev/null; then
    sed -n '1,120p' /tmp/dotfiles-ai-secret-findings >&2
    exit 1
fi

printf 'AI security policy tests passed.\n'
