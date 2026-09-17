#!/usr/bin/env bash
# ==============================================================================
# Isolated Zellij Sandbox Integration Test Runner
# Verifies Zellij server/client behavior in a strictly isolated sandbox.
# Absolutely zero effect on host system or active user sessions.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

# 1. Path safety assertions
TEST_ID="test-$$"
SANDBOX_BASE="$REPO_ROOT/.sandbox/z"
mkdir -p "$SANDBOX_BASE"
REAL_SANDBOX="$(realpath "$SANDBOX_BASE")"
REAL_REPO="$(realpath "$REPO_ROOT")"

if [[ "$REAL_SANDBOX" != "$REAL_REPO/.sandbox"* ]]; then
    log_fail "Security assertion failed: Sandbox path ($REAL_SANDBOX) outside repository sandbox!"
fi

TEST_DIR="$SANDBOX_BASE/$TEST_ID"
mkdir -p "$TEST_DIR/h" "$TEST_DIR/c" "$TEST_DIR/ca" "$TEST_DIR/st" "$TEST_DIR/d" "$TEST_DIR/r" "$TEST_DIR/s"

# Strict safety verification before proceeding
CLEANUP_TARGET="$(realpath "$TEST_DIR")"
if [[ "$CLEANUP_TARGET" != "$REAL_REPO/.sandbox"* ]]; then
    log_fail "Security assertion failed: Target directory ($CLEANUP_TARGET) outside repository sandbox!"
fi

cleanup() {
    if [[ -d "${CLEANUP_TARGET:-}" ]] && [[ "$CLEANUP_TARGET" == "$REAL_REPO/.sandbox"* ]]; then
        # Kill only recorded test session
        if [ -n "${TEST_SESSION:-}" ]; then
            zellij kill-session "$TEST_SESSION" 2>/dev/null || true
            zellij delete-session "$TEST_SESSION" --force 2>/dev/null || true
        fi
        rm -rf "$CLEANUP_TARGET"
    fi
}
trap cleanup EXIT

# 2. Export strict isolated environment
export HOME="$TEST_DIR/h"
export XDG_CONFIG_HOME="$TEST_DIR/c"
export XDG_CACHE_HOME="$TEST_DIR/ca"
export XDG_STATE_HOME="$TEST_DIR/st"
export XDG_DATA_HOME="$TEST_DIR/d"
export XDG_RUNTIME_DIR="$TEST_DIR/r"
export ZELLIJ_SOCKET_DIR="$TEST_DIR/s"
export ZELLIJ_CONFIG_DIR="$REPO_ROOT/resources/zellij"
export ZELLIJ_CONFIG_FILE="$REPO_ROOT/resources/zellij/config.kdl"

# Link config to isolated XDG_CONFIG_HOME
mkdir -p "$XDG_CONFIG_HOME"
ln -sfn "$REPO_ROOT/resources/zellij" "$XDG_CONFIG_HOME/zellij"

# Assert socket dir is empty
if [ -n "$(ls -A "$ZELLIJ_SOCKET_DIR" 2>/dev/null)" ]; then
    log_fail "Isolated socket directory is not empty before test start!"
fi

# 3. Test Session Lifecycle with Unique Prefix
TEST_SESSION="dotfiles-test-$$-main"

log_info "1. Testing clean background session creation in isolated socket..."
zellij attach --create-background "$TEST_SESSION"
sleep 1

ACTIVE_SESSIONS="$(zellij list-sessions --short --no-formatting 2>/dev/null || true)"
echo "$ACTIVE_SESSIONS" | grep -Fxq "$TEST_SESSION" || log_fail "Session $TEST_SESSION was not created in isolated socket"
log_ok "Isolated session created successfully"

log_info "2. Testing query isolation (no host session leakage)..."
if echo "$ACTIVE_SESSIONS" | grep -Fvq "$TEST_SESSION"; then
    log_fail "Found unmanaged or host sessions in isolated test socket!"
fi
log_ok "Socket isolation verified"

log_info "3. Testing layout dump from isolated configuration..."
ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij" zellij setup --dump-layout default >/dev/null
ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij" zellij setup --dump-layout compact >/dev/null
ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij" zellij setup --dump-layout dotfiles >/dev/null
ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij" zellij setup --dump-layout work >/dev/null
log_ok "All layout configurations evaluated without error"

log_info "4. Testing isolated session termination..."
zellij kill-session "$TEST_SESSION"
sleep 1
REMAINING="$(zellij list-sessions --short --no-formatting 2>&1 || true)"
if echo "$REMAINING" | grep -Fxq "$TEST_SESSION"; then
    log_fail "Session $TEST_SESSION was not terminated"
fi
TEST_SESSION=""
log_ok "Isolated session terminated cleanly"

echo
log_ok "ALL ISOLATED ZELLIJ INTEGRATION TESTS PASSED."
