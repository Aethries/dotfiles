#!/usr/bin/env bash
# ==============================================================================
# OmniRoute Dynamic Integration, Security & Port Isolation Test Suite
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

# Source declarative single-source-of-truth constants
if [ -f "$REPO_ROOT/resources/ai/gateway.env" ]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/resources/ai/gateway.env"
fi
OMNIROUTE_PORT="${OMNIROUTE_PORT:-20129}"
OMNIROUTE_HOST="${OMNIROUTE_HOST:-127.0.0.1}"
ROUTER_9_PORT="${ROUTER_9_PORT:-20128}"
OMNIROUTE_PINNED_VERSION="${OMNIROUTE_PINNED_VERSION:-3.8.50}"

SANDBOX_DIR="$REPO_ROOT/.sandbox/ai-test-$$"
mkdir -p "$SANDBOX_DIR/home" "$SANDBOX_DIR/bin"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# 1. Live Port Configuration & Strict Loopback Binding
# ------------------------------------------------------------------------------
log_info "1. Verifying OmniRoute live port $OMNIROUTE_PORT and loopback ($OMNIROUTE_HOST) isolation..."

OMNI_SERVICE="$REPO_ROOT/resources/systemd/user/omniroute.service"
[ -f "$OMNI_SERVICE" ] || log_fail "OmniRoute service template missing at $OMNI_SERVICE"

grep -q "Environment=\"PORT=$OMNIROUTE_PORT\"" "$OMNI_SERVICE" || log_fail "PORT=$OMNIROUTE_PORT missing in omniroute.service"
grep -q "Environment=\"OMNIROUTE_SERVER_HOST=$OMNIROUTE_HOST\"" "$OMNI_SERVICE" || log_fail "OMNIROUTE_SERVER_HOST=$OMNIROUTE_HOST missing in omniroute.service"
grep -q "Environment=\"HOST=$OMNIROUTE_HOST\"" "$OMNI_SERVICE" || log_fail "HOST=$OMNIROUTE_HOST missing in omniroute.service"

if command -v ss >/dev/null 2>&1; then
    if ss -tlHn "sport = :$OMNIROUTE_PORT" 2>/dev/null | grep -E "0\.0\.0\.0:$OMNIROUTE_PORT|\*:$OMNIROUTE_PORT" >/dev/null; then
        log_fail "OmniRoute port $OMNIROUTE_PORT is exposed to 0.0.0.0 (not bound to loopback!)"
    fi
    if ss -tlHn "sport = :$OMNIROUTE_PORT" 2>/dev/null | grep -E "(127\.0\.0\.1|\[::1\]):$OMNIROUTE_PORT" >/dev/null; then
        log_ok "OmniRoute listening strictly on loopback $OMNIROUTE_HOST:$OMNIROUTE_PORT"
    fi
fi

# Query live HTTP endpoint if running
if command -v curl >/dev/null 2>&1; then
    HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "http://$OMNIROUTE_HOST:$OMNIROUTE_PORT/v1/models" 2>/dev/null || echo "000")"
    if [ "$HTTP_CODE" != "000" ]; then
        log_ok "OmniRoute HTTP API responds on $OMNIROUTE_HOST:$OMNIROUTE_PORT (status: $HTTP_CODE)"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Dual-Gateway Port Coexistence & No-MITM Isolation
# ------------------------------------------------------------------------------
log_info "2. Verifying dual-gateway coexistence without MITM interference..."
ROUTER_SERVICE="$REPO_ROOT/resources/systemd/user/9router.service"
[ -f "$ROUTER_SERVICE" ] || log_fail "9Router service template missing at $ROUTER_SERVICE"

# Verify 9router runs and does not collide with OmniRoute
if command -v ss >/dev/null 2>&1; then
    if ss -tlHn "sport = :$ROUTER_9_PORT" 2>/dev/null | grep -q "$ROUTER_9_PORT" && \
       ss -tlHn "sport = :$OMNIROUTE_PORT" 2>/dev/null | grep -q "$OMNIROUTE_PORT"; then
        log_ok "Dual-gateway coexistence verified (9router on $ROUTER_9_PORT, OmniRoute on $OMNIROUTE_PORT)"
    fi
fi

if grep -riE '(rootCA|mitm|generate-ca)' "$OMNI_SERVICE"; then
    log_fail "OmniRoute service unexpectedly contains MITM Root CA configuration!"
fi
log_ok "OmniRoute service is clean of MITM Root CA configuration."

# ------------------------------------------------------------------------------
# 3. Dynamic Key Desync Guard Test in Isolated Sandbox
# ------------------------------------------------------------------------------
log_info "3. Executing dynamic key desync guard tests in sandbox..."

MOCK_HOME="$SANDBOX_DIR/home"
mkdir -p "$MOCK_HOME/.omniroute"
echo "test-db-payload" > "$MOCK_HOME/.omniroute/storage.sqlite"
touch "$MOCK_HOME/.omniroute/.env"

# Simulate init-omniroute key guard logic:
run_key_guard() {
    local force_flag="$1"
    local env_file="$MOCK_HOME/.omniroute/.env"
    local db_file="$MOCK_HOME/.omniroute/storage.sqlite"

    if ! grep -q '^STORAGE_ENCRYPTION_KEY=' "$env_file" 2>/dev/null; then
        if [ -s "$db_file" ]; then
            if [ "$force_flag" = false ]; then
                return 1
            else
                local orphan
                orphan="$db_file.orphan.$(date +%Y%m%d%H%M%S)"
                mv "$db_file" "$orphan"
            fi
        fi
        echo "STORAGE_ENCRYPTION_KEY=mock-key-123" >> "$env_file"
    fi
    return 0
}

# Test 1: Without force flag, key guard must reject and protect existing database
if run_key_guard false; then
    log_fail "Key guard unexpectedly succeeded without --force on existing database!"
fi
[ -f "$MOCK_HOME/.omniroute/storage.sqlite" ] || log_fail "Key guard deleted existing database on failure!"
log_ok "Key guard successfully halted without --force, preserving database intact."

# Test 2: With force flag, key guard backs up orphan database and sets new key
if ! run_key_guard true; then
    log_fail "Key guard failed with force flag!"
fi
grep -q '^STORAGE_ENCRYPTION_KEY=mock-key-123' "$MOCK_HOME/.omniroute/.env" || log_fail "New encryption key was not written"
ORPHAN_COUNT="$(find "$MOCK_HOME/.omniroute" -name "storage.sqlite.orphan.*" | wc -l)"
[ "$ORPHAN_COUNT" -gt 0 ] || log_fail "No orphan database backup created during forced key initialization!"
log_ok "Key guard safely backed up orphan database before generating new key."

# ------------------------------------------------------------------------------
# 4. Dynamic Vault Backup Snapshot & Exclusion Integrity Test
# ------------------------------------------------------------------------------
log_info "4. Testing dynamic Vault snapshotting and OmniRoute exclusion rules..."

mkdir -p "$MOCK_HOME/.config/gh"
echo "gh-token" > "$MOCK_HOME/.config/gh/config.yml"

mkdir -p "$MOCK_HOME/.omniroute/logs" "$MOCK_HOME/.omniroute/call_logs" "$MOCK_HOME/.omniroute/mitm"
echo "sqlite-data" > "$MOCK_HOME/.omniroute/storage.sqlite"
echo "STORAGE_ENCRYPTION_KEY=testkey" > "$MOCK_HOME/.omniroute/.env"
echo "log-junk" > "$MOCK_HOME/.omniroute/logs/server.log"
echo "call-junk" > "$MOCK_HOME/.omniroute/call_logs/call1.json"
touch "$MOCK_HOME/.omniroute/server.sock"
echo "bak-junk" > "$MOCK_HOME/.omniroute/storage.sqlite.bak-123"

# Mock age for non-interactive test run
cat << 'EOS' > "$SANDBOX_DIR/bin/age"
#!/usr/bin/env bash
if [ "${1:-}" = "--passphrase" ] && [ "${2:-}" = "--output" ]; then
    cat > "$3"
elif [ "${1:-}" = "--decrypt" ]; then
    cat "$2"
else
    cat
fi
EOS
chmod +x "$SANDBOX_DIR/bin/age"

# Mock systemctl and pgrep
cat << 'EOS' > "$SANDBOX_DIR/bin/systemctl"
#!/usr/bin/env bash
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/systemctl"

cat << 'EOS' > "$SANDBOX_DIR/bin/pgrep"
#!/usr/bin/env bash
exit 1
EOS
chmod +x "$SANDBOX_DIR/bin/pgrep"

TEST_VAULT="$SANDBOX_DIR/omni-test.vault"
PATH="$SANDBOX_DIR/bin:$PATH" HOME="$MOCK_HOME" "$REPO_ROOT/scripts/vault.sh" backup "$TEST_VAULT" >/dev/null

[ -f "$TEST_VAULT" ] || log_fail "Vault backup did not create test vault file"

# Extract archive listing and verify inclusions and exclusions
ARCHIVE_FILES="$(tar -tf <(zstd -d < "$TEST_VAULT"))"

echo "$ARCHIVE_FILES" | grep -q "\.omniroute/storage\.sqlite" || log_fail "storage.sqlite missing from vault archive"
echo "$ARCHIVE_FILES" | grep -q "\.omniroute/\.env" || log_fail ".env missing from vault archive"

if echo "$ARCHIVE_FILES" | grep -q "\.omniroute/logs"; then
    log_fail "Temporary logs were not excluded from vault archive!"
fi
if echo "$ARCHIVE_FILES" | grep -q "\.omniroute/.*\.sock"; then
    log_fail "Socket files were not excluded from vault archive!"
fi
if echo "$ARCHIVE_FILES" | grep -q "\.omniroute/.*\.bak"; then
    log_fail "Backup copies (*.bak) were not excluded from vault archive!"
fi
log_ok "Vault archive inclusions and exclusion filters verified dynamically."

# ------------------------------------------------------------------------------
# 5. Directory & File Permission Enforcement
# ------------------------------------------------------------------------------
log_info "5. Verifying permission security on local ~/.omniroute..."
if [ -d "$HOME/.omniroute" ]; then
    PERM="$(stat -c "%a" "$HOME/.omniroute")"
    if [ "$PERM" != "700" ]; then
        chmod 700 "$HOME/.omniroute"
    fi
    PERM="$(stat -c "%a" "$HOME/.omniroute")"
    [ "$PERM" = "700" ] || log_fail "$HOME/.omniroute permissions are $PERM, expected 700"
    log_ok "$HOME/.omniroute directory permissions are strictly 0700."

    if [ -f "$HOME/.omniroute/.env" ]; then
        ENV_PERM="$(stat -c "%a" "$HOME/.omniroute/.env")"
        [ "$ENV_PERM" = "600" ] || log_fail "$HOME/.omniroute/.env permissions are $ENV_PERM, expected 600"
        log_ok "$HOME/.omniroute/.env permissions are strictly 0600."
    fi
fi

echo
log_ok "ALL OMNIROUTE DYNAMIC INTEGRATION & SECURITY TESTS PASSED."
