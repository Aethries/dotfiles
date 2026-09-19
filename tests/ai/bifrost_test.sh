#!/usr/bin/env bash
# ==============================================================================
# Bifrost Dynamic Integration, Security & Isolation Test Suite
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORIGINAL_PATH="$PATH"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

# Load single-source-of-truth constants
GATEWAY_ENV="$REPO_ROOT/resources/ai/gateway.env"
[ -f "$GATEWAY_ENV" ] || log_fail "gateway.env missing at $GATEWAY_ENV"
# shellcheck disable=SC1090
source "$GATEWAY_ENV"

BIFROST_PORT="${BIFROST_PORT:-20130}"
BIFROST_HOST="${BIFROST_HOST:-127.0.0.1}"
BIFROST_VERSION="${BIFROST_VERSION:-2.2.1}"

SANDBOX_DIR="$(mktemp -d)"
MOCK_HOME="$SANDBOX_DIR/home"
MOCK_BIN="$SANDBOX_DIR/bin"
MOCK_STATE="$SANDBOX_DIR/state"
mkdir -p "$MOCK_HOME" "$MOCK_BIN" "$MOCK_STATE"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# 1. Service Template Verification
# ------------------------------------------------------------------------------
log_info "1. Verifying Bifrost systemd service template..."
BIFROST_SERVICE="$REPO_ROOT/resources/systemd/user/bifrost.service"
[ -f "$BIFROST_SERVICE" ] || log_fail "bifrost.service missing at $BIFROST_SERVICE"

grep -q "UMask=0077" "$BIFROST_SERVICE" || log_fail "UMask=0077 missing in bifrost.service"
grep -q "bifrost" "$BIFROST_SERVICE" || log_fail "bifrost binary invocation missing in bifrost.service"
grep -q "20130" "$BIFROST_SERVICE" || log_fail "Port 20130 missing in bifrost.service"
grep -q -- "-app-dir" "$BIFROST_SERVICE" || log_fail "-app-dir missing in bifrost.service"
grep -q "\.bifrost" "$BIFROST_SERVICE" || log_fail ".bifrost app-dir missing in bifrost.service"
log_ok "bifrost.service template verified (UMask=0077, port 20130, dedicated app-dir)."

# ------------------------------------------------------------------------------
# 2. Mock Environment Setup
# ------------------------------------------------------------------------------
log_info "2. Setting up isolated test sandbox..."

cat << 'EOS' > "$MOCK_BIN/systemctl"
#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${MOCK_STATE_DIR:-/tmp}"
action=""
unit=""
while [ $# -gt 0 ]; do
    case "$1" in
        --user|--quiet) shift ;;
        is-active|is-enabled|start|stop|restart|enable|disable|daemon-reload)
            action="$1"; shift ;;
        *)
            if [ -z "$unit" ]; then unit="$1"; fi
            shift ;;
    esac
done
unit_safe="$(echo "${unit:-default}" | tr '/' '_')"
unit_file="$STATE_DIR/unit_${unit_safe}"
case "$action" in
    is-active)
        if [ -f "$unit_file" ] && [ "$(cat "$unit_file")" = "active" ]; then exit 0; else exit 1; fi ;;
    is-enabled) exit 0 ;;
    start|restart) echo "active" > "$unit_file"; exit 0 ;;
    stop) echo "inactive" > "$unit_file"; exit 0 ;;
    enable|disable|daemon-reload) exit 0 ;;
    *) exit 0 ;;
esac
EOS
chmod +x "$MOCK_BIN/systemctl"

cat << 'EOS' > "$MOCK_BIN/curl"
#!/usr/bin/env bash
out=""
while [ $# -gt 0 ]; do
    case "$1" in
        -o) out="$2"; shift 2 ;;
        *) shift ;;
    esac
done
if [ -n "$out" ]; then
    echo '#!/usr/bin/env bash' > "$out"
    echo 'exit 0' >> "$out"
    chmod +x "$out"
fi
echo "200"
exit 0
EOS
chmod +x "$MOCK_BIN/curl"

# ------------------------------------------------------------------------------
# 3. Test init-bifrost.sh execution in isolated sandbox
# ------------------------------------------------------------------------------
log_info "3. Testing init-bifrost.sh in isolated sandbox..."
HOME="$MOCK_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
"$REPO_ROOT/scripts/init-bifrost.sh" >/dev/null

[ -d "$MOCK_HOME/.bifrost" ] || log_fail "$MOCK_HOME/.bifrost was not created"
DIR_PERM="$(stat -c "%a" "$MOCK_HOME/.bifrost")"
[ "$DIR_PERM" = "700" ] || log_fail "Directory permissions not 0700: $DIR_PERM"
[ -f "$MOCK_HOME/.config/systemd/user/bifrost.service" ] || log_fail "bifrost.service link was not established"
log_ok "init-bifrost.sh successfully secured ~/.bifrost (mode 0700) and deployed user service."

# ------------------------------------------------------------------------------
# 4. Idempotency test
# ------------------------------------------------------------------------------
log_info "4. Testing init-bifrost.sh idempotency..."
HOME="$MOCK_HOME" \
PATH="$MOCK_BIN:$ORIGINAL_PATH" \
MOCK_STATE_DIR="$MOCK_STATE" \
"$REPO_ROOT/scripts/init-bifrost.sh" --ensure >/dev/null

DIR_PERM_AFTER="$(stat -c "%a" "$MOCK_HOME/.bifrost")"
[ "$DIR_PERM_AFTER" = "700" ] || log_fail "Permissions drifted: $DIR_PERM_AFTER"
log_ok "init-bifrost.sh demonstrated complete idempotency."

echo
log_ok "ALL BIFROST DYNAMIC INTEGRATION & SECURITY TESTS PASSED."
