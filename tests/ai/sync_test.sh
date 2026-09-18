#!/usr/bin/env bash

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AI="$REPO_ROOT/scripts/ai.sh"
TEST_HOME="$(mktemp -d -t dotfiles-ai-home-XXXXXX)"
TEST_STATE="$(mktemp -d -t dotfiles-ai-state-XXXXXX)"

export HOME="$TEST_HOME"
export XDG_STATE_HOME="$TEST_STATE"

"$AI" generate >/dev/null
"$AI" sync >/dev/null
"$AI" sync >/dev/null
[ -L "$HOME/.gemini/config/mcp_config.json" ]
[ "$(readlink "$HOME/.gemini/config/mcp_config.json")" = "$REPO_ROOT/resources/ai/generated/gemini/mcp_config.json" ]
jq -e '.mcpServers.godot and .mcpServers.codegraph' "$HOME/.gemini/config/mcp_config.json" >/dev/null

rm -f "$HOME/.gemini/antigravity/mcp_config.json"
ln -s /tmp/wrong-ai-target "$HOME/.gemini/antigravity/mcp_config.json"
if "$AI" sync >/dev/null 2>&1; then
    echo "wrong symlink was accepted" >&2
    exit 1
fi
rm -f "$HOME/.gemini/antigravity/mcp_config.json" "$HOME/.codex/config.toml"
printf 'old codex config\n' > "$HOME/.codex/config.toml"
if "$AI" sync >/dev/null 2>&1; then
    echo "regular Codex config was silently replaced" >&2
    exit 1
fi
"$AI" sync --adopt codex >/dev/null
[ -L "$HOME/.codex/config.toml" ]
find "$HOME/.codex" -maxdepth 1 -name 'config.toml.pre-ai.*' -print -quit | grep -q .

printf 'AI sync tests passed.\n'
