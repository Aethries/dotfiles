#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d -t dotfiles-agency-test-XXXXXX)"
MOCK_BIN="$TEST_ROOT/bin"
MOCK_LOG="$TEST_ROOT/commands.log"
trap 'rm -rf -- "$TEST_ROOT"' EXIT
mkdir -p "$MOCK_BIN"

cat > "$MOCK_BIN/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "${AGENCY_TEST_LOG:?}"
EOF
chmod +x "$MOCK_BIN/codex"

test -f "$REPO_ROOT/.agency/agency.toml"
test -f "$REPO_ROOT/AGENTS.md"
test -f "$REPO_ROOT/resources/ai/agency.models.env"
if rg -n 'sk-[A-Za-z0-9]' "$REPO_ROOT/.agency" "$REPO_ROOT/resources/ai" "$REPO_ROOT/scripts/agency-codex-agent.sh" "$REPO_ROOT/AGENTS.md"; then
    exit 1
fi

export PATH="$MOCK_BIN:$PATH"
export AGENCY_ROOT="$REPO_ROOT"
export AGENCY_TASK="Inspect the current repository and produce a plan."
export NINEROUTER_API_KEY="fixture-key-not-written-to-repo"
export AGENCY_TEST_LOG="$MOCK_LOG"

bash "$REPO_ROOT/scripts/agency-codex-agent.sh" think-terra-high
grep -q -- '--model cx/gpt-5.6-terra' "$MOCK_LOG"
grep -q -- '--sandbox read-only' "$MOCK_LOG"
grep -q -- 'model_provider="nine_router"' "$MOCK_LOG"
grep -q -- 'model_providers.nine_router.base_url="http://127.0.0.1:20128/v1"' "$MOCK_LOG"
grep -q -- 'model_reasoning_effort="high"' "$MOCK_LOG"
if grep -q -- 'fixture-key-not-written-to-repo' "$MOCK_LOG"; then
    exit 1
fi

bash "$REPO_ROOT/scripts/agency-codex-agent.sh" implement-luna-xhigh
grep -q -- '--model cx/gpt-5.6-luna' "$MOCK_LOG"
grep -q -- '--sandbox workspace-write' "$MOCK_LOG"
grep -q -- 'model_reasoning_effort="xhigh"' "$MOCK_LOG"

echo "[✓] Agency config and secret-safe Codex role adapters validated"
