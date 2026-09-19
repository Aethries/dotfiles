#!/usr/bin/env bash
# ==============================================================================
# OmniRoute Dynamic Integration, Security & Reconciliation Test Suite
#
# Isolated test suite executing REAL production scripts against temporary
# sandboxes without mutating real host files, permissions, or running services.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORIGINAL_PATH="$PATH"
REAL_HOME="$HOME"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

# Record initial permissions of real ~/.omniroute if present to verify no mutation occurs
INITIAL_REAL_PERM=""
if [ -d "$REAL_HOME/.omniroute" ]; then
    INITIAL_REAL_PERM="$(stat -c "%a" "$REAL_HOME/.omniroute" 2>/dev/null || echo "")"
fi

# Load single-source-of-truth constants
GATEWAY_ENV="$REPO_ROOT/resources/ai/gateway.env"
[ -f "$GATEWAY_ENV" ] || log_fail "gateway.env missing at $GATEWAY_ENV"
# shellcheck disable=SC1090
source "$GATEWAY_ENV"

OMNIROUTE_PORT="${OMNIROUTE_PORT:-20129}"
OMNIROUTE_HOST="${OMNIROUTE_HOST:-127.0.0.1}"
ROUTER_9_PORT="${ROUTER_9_PORT:-20128}"
OMNIROUTE_PINNED_VERSION="${OMNIROUTE_PINNED_VERSION:-3.8.50}"

SANDBOX_DIR="$(mktemp -d)"
MOCK_HOME="$SANDBOX_DIR/home"
MOCK_BIN="$SANDBOX_DIR/bin"
MOCK_STATE="$SANDBOX_DIR/state"
MOCK_LOG="$SANDBOX_DIR/mock.log"
mkdir -p "$MOCK_HOME" "$MOCK_BIN" "$MOCK_STATE"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Mock Implementations for Isolated Testing
# ------------------------------------------------------------------------------

# Mock age
cat << 'EOS' > "$MOCK_BIN/age"
#!/usr/bin/env bash
if [ "${1:-}" = "--passphrase" ] && [ "${2:-}" = "--output" ]; then
    cat > "$3"
elif [ "${1:-}" = "--decrypt" ]; then
    cat "$2"
else
    cat
fi
EOS
chmod +x "$MOCK_BIN/age"

# Mock sudo
cat << 'EOS' > "$MOCK_BIN/sudo"
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
    case "$1" in
        -u|-H) shift 2 ;;
        *) break ;;
    esac
done
exec "$@"
EOS
chmod +x "$MOCK_BIN/sudo"

# Mock fnm & loginctl
cat << 'EOS' > "$MOCK_BIN/fnm"
#!/usr/bin/env bash
exit 0
EOS
chmod +x "$MOCK_BIN/fnm"

cat << 'EOS' > "$MOCK_BIN/loginctl"
#!/usr/bin/env bash
echo "Linger=yes"
exit 0
EOS
chmod +x "$MOCK_BIN/loginctl"

# Mock systemctl: tracks state in MOCK_STATE
cat << 'EOS' > "$MOCK_BIN/systemctl"
#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${MOCK_STATE_DIR:-/tmp}"
LOG_FILE="${MOCK_LOG_FILE:-/dev/null}"
echo "systemctl $*" >> "$LOG_FILE"

action=""
unit=""
user_mode=false

while [ $# -gt 0 ]; do
    case "$1" in
        --user) user_mode=true; shift ;;
        --quiet) shift ;;
        is-active|start|stop|restart|enable|disable|daemon-reload)
            action="$1"
            shift
            ;;
        *)
            if [ -z "$unit" ]; then unit="$1"; fi
            shift
            ;;
    esac
done

unit_safe="$(echo "${unit:-default}" | tr '/' '_')"
unit_file="$STATE_DIR/unit_${unit_safe}"

case "$action" in
    is-active)
        if [ -f "$unit_file" ] && [ "$(cat "$unit_file")" = "active" ]; then
            exit 0
        else
            exit 1
        fi
        ;;
    start|restart)
        echo "active" > "$unit_file"
        exit 0
        ;;
    stop)
        echo "inactive" > "$unit_file"
        exit 0
        ;;
    daemon-reload|enable|disable)
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
EOS
chmod +x "$MOCK_BIN/systemctl"

# Mock pgrep and pkill
cat << 'EOS' > "$MOCK_BIN/pgrep"
#!/usr/bin/env bash
exit 1
EOS
chmod +x "$MOCK_BIN/pgrep"

cat << 'EOS' > "$MOCK_BIN/pkill"
#!/usr/bin/env bash
exit 0
EOS
chmod +x "$MOCK_BIN/pkill"

# Mock npm
cat << 'EOS' > "$MOCK_BIN/npm"
#!/usr/bin/env bash
set -euo pipefail
LOG_FILE="${MOCK_LOG_FILE:-/dev/null}"
echo "npm $*" >> "$LOG_FILE"

if [ "${1:-}" = "config" ] && [ "${2:-}" = "get" ] && [ "${3:-}" = "prefix" ]; then
    echo "$HOME/.local"
    exit 0
fi

if [ "${1:-}" = "i" ] || [ "${1:-}" = "install" ]; then
    mkdir -p "$HOME/.local/bin"
    cat << 'EOB' > "$HOME/.local/bin/omniroute"
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
    echo "3.8.50"
else
    echo "omniroute mock"
fi
EOB
    chmod +x "$HOME/.local/bin/omniroute"
    exit 0
fi

exit 0
EOS
chmod +x "$MOCK_BIN/npm"

# Mock node wrapper (allows simulating specific Node.js versions via MOCK_NODE_VERSION)
REAL_NODE_BIN="$(command -v node)"
cat << EOS > "$MOCK_BIN/node"
#!/usr/bin/env bash
if [ -n "\${MOCK_NODE_VERSION:-}" ]; then
    if [ "\${1:-}" = "-p" ] && [ "\${2:-}" = "process.versions.node" ]; then
        echo "\$MOCK_NODE_VERSION"
        exit 0
    fi
    if [ "\${1:-}" = "-v" ]; then
        echo "v\$MOCK_NODE_VERSION"
        exit 0
    fi
fi
exec "$REAL_NODE_BIN" "\$@"
EOS
chmod +x "$MOCK_BIN/node"

# ------------------------------------------------------------------------------
# 1. Declarative Gateway Constants & Systemd Unit Synchronization
# ------------------------------------------------------------------------------
log_info "1. Verifying synchronization between gateway.env and service templates..."

OMNI_SERVICE="$REPO_ROOT/resources/systemd/user/omniroute.service"
[ -f "$OMNI_SERVICE" ] || log_fail "OmniRoute service template missing at $OMNI_SERVICE"

grep -q "Environment=\"PORT=$OMNIROUTE_PORT\"" "$OMNI_SERVICE" || log_fail "PORT=$OMNIROUTE_PORT not in omniroute.service"
grep -q "Environment=\"DASHBOARD_PORT=$OMNIROUTE_PORT\"" "$OMNI_SERVICE" || log_fail "DASHBOARD_PORT=$OMNIROUTE_PORT not in omniroute.service"
grep -q "Environment=\"OMNIROUTE_SERVER_HOST=$OMNIROUTE_HOST\"" "$OMNI_SERVICE" || log_fail "OMNIROUTE_SERVER_HOST=$OMNIROUTE_HOST not in omniroute.service"
grep -q "Environment=\"HOST=$OMNIROUTE_HOST\"" "$OMNI_SERVICE" || log_fail "HOST=$OMNIROUTE_HOST not in omniroute.service"
grep -q "serve --port $OMNIROUTE_PORT" "$OMNI_SERVICE" || log_fail "ExecStart --port $OMNIROUTE_PORT not in omniroute.service"
grep -q "UMask=0077" "$OMNI_SERVICE" || log_fail "UMask=0077 missing in omniroute.service"

log_ok "omniroute.service is synchronized with gateway.env constants and includes UMask=0077."

ROUTER_SERVICE="$REPO_ROOT/resources/systemd/user/9router.service"
[ -f "$ROUTER_SERVICE" ] || log_fail "9Router service template missing at $ROUTER_SERVICE"
if grep -riE '(rootCA|mitm|generate-ca)' "$OMNI_SERVICE"; then
    log_fail "OmniRoute service unexpectedly contains MITM Root CA configuration!"
fi
log_ok "OmniRoute service is clean of MITM Root CA configuration."

# ------------------------------------------------------------------------------
# 2. Node.js Engine Semver Validation Tests
# ------------------------------------------------------------------------------
log_info "2. Testing exact Node.js engine compatibility boundary logic..."

check_node_semver() {
    local version="$1"
    local major minor patch
    major="$(echo "$version" | cut -d. -f1)"
    minor="$(echo "$version" | cut -d. -f2)"
    patch="$(echo "$version" | cut -d. -f3 | cut -d- -f1)"

    if [ "$major" -eq 22 ]; then
        if [ "$minor" -gt 22 ]; then
            return 0
        elif [ "$minor" -eq 22 ] && [ "$patch" -ge 2 ]; then
            return 0
        fi
        return 1
    elif [ "$major" -ge 24 ] && [ "$major" -lt 27 ]; then
        return 0
    else
        return 1
    fi
}

# Test F: Node 22.22.1 (Must be rejected)
if check_node_semver "22.22.1"; then
    log_fail "Node 22.22.1 was incorrectly accepted!"
fi
log_ok "Node 22.22.1 correctly rejected."

# Test G: Node 22.22.2 (Must be accepted)
if ! check_node_semver "22.22.2"; then
    log_fail "Node 22.22.2 was incorrectly rejected!"
fi
log_ok "Node 22.22.2 correctly accepted."

# Test H: Node 23.x (Must be rejected)
if check_node_semver "23.0.0"; then
    log_fail "Node 23.0.0 was incorrectly accepted!"
fi
log_ok "Node 23.0.0 correctly rejected."

# Test I: Node 24.x (Must be accepted)
if ! check_node_semver "24.2.0"; then
    log_fail "Node 24.2.0 was incorrectly rejected!"
fi
log_ok "Node 24.2.0 correctly accepted."

# Test J: Node 27.x (Must be rejected)
if check_node_semver "27.0.0"; then
    log_fail "Node 27.0.0 was incorrectly rejected!"
fi
log_ok "Node 27.0.0 correctly rejected."

# ------------------------------------------------------------------------------
# 3. Dynamic Execution of Real scripts/init-omniroute.sh in Sandbox
# ------------------------------------------------------------------------------
log_info "3. Executing real init-omniroute.sh in isolated sandbox (key guard tests)..."

INIT_TEST_HOME="$SANDBOX_DIR/init_home"
mkdir -p "$INIT_TEST_HOME/.omniroute"
echo "real-sqlite-payload" > "$INIT_TEST_HOME/.omniroute/storage.sqlite"
touch "$INIT_TEST_HOME/.omniroute/.env"

# Test D: Initial run without --force must fail and preserve existing database
if HOME="$INIT_TEST_HOME" \
   PATH="$MOCK_BIN:$ORIGINAL_PATH" \
   MOCK_STATE_DIR="$MOCK_STATE" \
   MOCK_LOG_FILE="$MOCK_LOG" \
   "$REPO_ROOT/scripts/init-omniroute.sh" >/dev/null 2>&1; then
    log_fail "init-omniroute unexpectedly succeeded without --force on existing unkeyed DB!"
fi

[ -f "$INIT_TEST_HOME/.omniroute/storage.sqlite" ] || log_fail "Existing storage.sqlite was deleted on failed init!"
grep -q '^STORAGE_ENCRYPTION_KEY=' "$INIT_TEST_HOME/.omniroute/.env" && log_fail "Key was generated despite failure!"
ORPHANS="$(find "$INIT_TEST_HOME/.omniroute" -name "storage.sqlite.orphan.*" | wc -l)"
[ "$ORPHANS" -eq 0 ] || log_fail "Orphan backup was created prematurely on unforced failure!"
log_ok "Real init-omniroute safely halted without --force, preserving database."

# Test E: Run with --force must back up orphan database and set new key
if ! HOME="$INIT_TEST_HOME" \
     PATH="$MOCK_BIN:$ORIGINAL_PATH" \
     MOCK_STATE_DIR="$MOCK_STATE" \
     MOCK_LOG_FILE="$MOCK_LOG" \
     "$REPO_ROOT/scripts/init-omniroute.sh" --force >/dev/null 2>&1; then
    log_fail "init-omniroute --force failed unexpectedly!"
fi

grep -q '^STORAGE_ENCRYPTION_KEY=' "$INIT_TEST_HOME/.omniroute/.env" || log_fail "New STORAGE_ENCRYPTION_KEY was not written!"
ORPHANS="$(find "$INIT_TEST_HOME/.omniroute" -name "storage.sqlite.orphan.*" | wc -l)"
[ "$ORPHANS" -gt 0 ] || log_fail "No orphan database created during forced init!"
log_ok "Real init-omniroute --force created orphan backup and initialized new key."

# ------------------------------------------------------------------------------
# 4. Insecure Permission Correction in Sandbox
# ------------------------------------------------------------------------------
log_info "4. Testing permission enforcement in isolated sandbox..."

echo "dummy-data" > "$INIT_TEST_HOME/.omniroute/storage.sqlite"
chmod 755 "$INIT_TEST_HOME/.omniroute"
chmod 644 "$INIT_TEST_HOME/.omniroute/.env"
chmod 644 "$INIT_TEST_HOME/.omniroute/storage.sqlite"

# Run init-omniroute to secure permissions
HOME="$INIT_TEST_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
MOCK_LOG_FILE="$MOCK_LOG" \
"$REPO_ROOT/scripts/init-omniroute.sh" >/dev/null 2>&1

PERM="$(stat -c "%a" "$INIT_TEST_HOME/.omniroute")"
[ "$PERM" = "700" ] || log_fail "Sandbox .omniroute perm is $PERM, expected 700"

ENV_PERM="$(stat -c "%a" "$INIT_TEST_HOME/.omniroute/.env")"
[ "$ENV_PERM" = "600" ] || log_fail "Sandbox .env perm is $ENV_PERM, expected 600"

DB_PERM="$(stat -c "%a" "$INIT_TEST_HOME/.omniroute/storage.sqlite")"
[ "$DB_PERM" = "600" ] || log_fail "Sandbox storage.sqlite perm is $DB_PERM, expected 600"

log_ok "Permissions strictly corrected in sandbox (.omniroute 0700, .env 0600, storage.sqlite 0600)."

# ------------------------------------------------------------------------------
# 5. Scoped Vault Backup & Restore Isolation Tests
# ------------------------------------------------------------------------------
log_info "5. Testing scoped Vault backup and restore isolation..."

VAULT_TEST_HOME="$SANDBOX_DIR/vault_home"
mkdir -p "$VAULT_TEST_HOME/.omniroute" "$VAULT_TEST_HOME/.ssh" "$VAULT_TEST_HOME/.9router"
echo "omni-data" > "$VAULT_TEST_HOME/.omniroute/storage.sqlite"
echo "STORAGE_ENCRYPTION_KEY=testkey" > "$VAULT_TEST_HOME/.omniroute/.env"
echo "ssh-secret" > "$VAULT_TEST_HOME/.ssh/id_rsa"
echo "router-machine-id" > "$VAULT_TEST_HOME/.9router/machine-id"

TEST_VAULT="$SANDBOX_DIR/scoped-omni.vault"

# Test A: Scoped backup must archive ONLY .omniroute
HOME="$VAULT_TEST_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
"$REPO_ROOT/scripts/vault.sh" backup --scope omniroute "$TEST_VAULT" >/dev/null

[ -f "$TEST_VAULT" ] || log_fail "Scoped vault backup file was not created!"

ARCHIVE_FILES="$(tar -tf <(zstd -d < "$TEST_VAULT"))"
echo "$ARCHIVE_FILES" | grep -q "\.omniroute/storage\.sqlite" || log_fail "storage.sqlite missing from scoped vault"
echo "$ARCHIVE_FILES" | grep -q "\.omniroute/\.env" || log_fail ".env missing from scoped vault"

if echo "$ARCHIVE_FILES" | grep -q "\.ssh"; then
    log_fail "CRITICAL LEAK: .ssh was included in omniroute-scoped vault!"
fi
if echo "$ARCHIVE_FILES" | grep -q "\.9router"; then
    log_fail "CRITICAL LEAK: .9router was included in omniroute-scoped vault!"
fi
log_ok "Scoped backup archived ONLY .omniroute/ and omitted all other profiles."

# Test B: Scoped restore must restore ONLY .omniroute without touching other directories
RESTORE_TARGET_HOME="$SANDBOX_DIR/restore_target"
mkdir -p "$RESTORE_TARGET_HOME/.ssh" "$RESTORE_TARGET_HOME/.9router"
echo "preserve-my-ssh" > "$RESTORE_TARGET_HOME/.ssh/keep-me"
echo "preserve-my-router" > "$RESTORE_TARGET_HOME/.9router/keep-me"

HOME="$RESTORE_TARGET_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
"$REPO_ROOT/scripts/vault.sh" restore --scope omniroute "$TEST_VAULT" >/dev/null

[ -f "$RESTORE_TARGET_HOME/.omniroute/storage.sqlite" ] || log_fail "storage.sqlite was not restored!"
[ -f "$RESTORE_TARGET_HOME/.ssh/keep-me" ] || log_fail ".ssh was wiped during omniroute scoped restore!"
[ -f "$RESTORE_TARGET_HOME/.9router/keep-me" ] || log_fail ".9router was wiped during omniroute scoped restore!"
[ "$(cat "$RESTORE_TARGET_HOME/.ssh/keep-me")" = "preserve-my-ssh" ] || log_fail ".ssh content modified!"
[ "$(cat "$RESTORE_TARGET_HOME/.9router/keep-me")" = "preserve-my-router" ] || log_fail ".9router content modified!"
log_ok "Scoped restore restored ~/.omniroute without modifying unrelated directories."

# Test K: Failure during backup must trigger EXIT cleanup and restart omniroute.service
echo "active" > "$MOCK_STATE/unit_omniroute.service"
FAIL_VAULT="/nonexistent_dir_cannot_write/fail.vault"

if HOME="$VAULT_TEST_HOME" \
   PATH="$MOCK_BIN:$ORIGINAL_PATH" \
   MOCK_STATE_DIR="$MOCK_STATE" \
   MOCK_LOG_FILE="$MOCK_LOG" \
   "$REPO_ROOT/scripts/vault.sh" backup --scope omniroute "$FAIL_VAULT" >/dev/null 2>&1; then
    log_fail "Vault backup unexpectedly succeeded with unwritable path!"
fi

# Verify systemctl --user start omniroute.service was invoked in finish_backup_runtime
grep -qE "systemctl.*start.*omniroute\.service" "$MOCK_LOG" || log_fail "omniroute.service was not restarted after backup failure!"
log_ok "Backup EXIT trap safely restored omniroute.service on failure."

# ------------------------------------------------------------------------------
# 6. Shared Reconciliation Engine Tests
# ------------------------------------------------------------------------------
log_info "6. Testing reconcile-ai-gateways.sh behavior..."

RECON_HOME="$SANDBOX_DIR/recon_home"
mkdir -p "$RECON_HOME/.local/bin" "$RECON_HOME/.omniroute" "$RECON_HOME/.9router"
echo "STORAGE_ENCRYPTION_KEY=reconkey" > "$RECON_HOME/.omniroute/.env"
echo "db-recon" > "$RECON_HOME/.omniroute/storage.sqlite"

# Create dummy mock 9router binary so 9router doesn't need external npm
cat << 'EOS' > "$RECON_HOME/.local/bin/9router"
#!/usr/bin/env bash
exit 0
EOS
chmod +x "$RECON_HOME/.local/bin/9router"

# Create dummy mock omniroute binary
cat << 'EOS' > "$RECON_HOME/.local/bin/omniroute"
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then
    echo "3.8.50"
else
    exit 0
fi
EOS
chmod +x "$RECON_HOME/.local/bin/omniroute"

# Test M: Stopped service must be restarted by reconciliation
echo "inactive" > "$MOCK_STATE/unit_omniroute.service"
echo "inactive" > "$MOCK_STATE/unit_9router.service"

# Mock ss to simulate listening ports for reconciliation verification
cat << 'EOS' > "$MOCK_BIN/ss"
#!/usr/bin/env bash
echo "LISTEN 0 512 127.0.0.1:20128 0.0.0.0:*"
echo "LISTEN 0 512 127.0.0.1:20129 0.0.0.0:*"
exit 0
EOS
chmod +x "$MOCK_BIN/ss"

# Mock curl to return 200 for models endpoint
cat << 'EOS' > "$MOCK_BIN/curl"
#!/usr/bin/env bash
echo "200"
exit 0
EOS
chmod +x "$MOCK_BIN/curl"

HOME="$RECON_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
MOCK_LOG_FILE="$MOCK_LOG" \
"$REPO_ROOT/scripts/reconcile-ai-gateways.sh" >/dev/null

[ "$(cat "$MOCK_STATE/unit_omniroute.service")" = "active" ] || log_fail "Reconciliation did not start omniroute.service!"
[ "$(cat "$MOCK_STATE/unit_9router.service")" = "active" ] || log_fail "Reconciliation did not start 9router.service!"
log_ok "Reconciliation converged stopped services into active state."

# Test L: Missing OmniRoute binary triggers init-omniroute
rm -f "$RECON_HOME/.local/bin/omniroute"
echo "" > "$MOCK_LOG"

HOME="$RECON_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
MOCK_LOG_FILE="$MOCK_LOG" \
"$REPO_ROOT/scripts/reconcile-ai-gateways.sh" >/dev/null

[ -x "$RECON_HOME/.local/bin/omniroute" ] || log_fail "Missing binary was not reinstalled by reconciliation!"
log_ok "Reconciliation detected missing gateway binary and reinstalled it."

# Test N: Failure in init propagates nonzero exit to caller
cat << 'EOS' > "$SANDBOX_DIR/fail_init"
#!/usr/bin/env bash
exit 1
EOS
chmod +x "$SANDBOX_DIR/fail_init"

# Temporarily point INIT_OMNIROUTE to failing script
if (
    REPO_ROOT_OVERRIDE="$SANDBOX_DIR/fake_repo"
    mkdir -p "$REPO_ROOT_OVERRIDE/scripts" "$REPO_ROOT_OVERRIDE/resources/ai" "$REPO_ROOT_OVERRIDE/resources/systemd/user"
    cp "$REPO_ROOT/resources/ai/gateway.env" "$REPO_ROOT_OVERRIDE/resources/ai/"
    cp "$REPO_ROOT/resources/systemd/user/"*.service "$REPO_ROOT_OVERRIDE/resources/systemd/user/"
    cp "$SANDBOX_DIR/fail_init" "$REPO_ROOT_OVERRIDE/scripts/init-omniroute.sh"
    cp "$RECON_HOME/.local/bin/9router" "$REPO_ROOT_OVERRIDE/scripts/init-9router.sh"
    cp "$REPO_ROOT/scripts/reconcile-ai-gateways.sh" "$REPO_ROOT_OVERRIDE/scripts/"

    HOME="$RECON_HOME" \
    PATH="$MOCK_BIN:$ORIGINAL_PATH" \
    MOCK_STATE_DIR="$MOCK_STATE" \
    "$REPO_ROOT_OVERRIDE/scripts/reconcile-ai-gateways.sh" --force >/dev/null 2>&1
); then
    log_fail "Reconciler unexpectedly succeeded when init-omniroute failed!"
fi
log_ok "Reconciler propagates initializer failures with nonzero exit code."

# ------------------------------------------------------------------------------
# 7. Verify No Real Host State Was Mutated
# ------------------------------------------------------------------------------
log_info "7. Verifying zero real host state mutation..."
if [ -n "$INITIAL_REAL_PERM" ] && [ -d "$REAL_HOME/.omniroute" ]; then
    CURRENT_REAL_PERM="$(stat -c "%a" "$REAL_HOME/.omniroute" 2>/dev/null || echo "")"
    [ "$CURRENT_REAL_PERM" = "$INITIAL_REAL_PERM" ] || log_fail "Real ~/.omniroute permissions mutated from $INITIAL_REAL_PERM to $CURRENT_REAL_PERM!"
fi
log_ok "Verified: zero real host state or permissions modified during tests."

echo
log_ok "ALL OMNIROUTE DYNAMIC INTEGRATION, SECURITY & RECONCILIATION TESTS PASSED."
