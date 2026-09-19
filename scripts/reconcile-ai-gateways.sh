#!/usr/bin/env bash

# ==============================================================================
# Reconcile AI Gateways (9Router & OmniRoute)
#
# Authoritative convergence point for both bootstrap.sh and build.sh.
# Idempotently ensures binaries, systemd user services, loopback bindings,
# and runtime health are properly synchronized without configuration drift.
# ==============================================================================

set -euo pipefail

# ANSI color codes
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------------------------
# 1. Load gateway configuration constants
# ------------------------------------------------------------------------------
GATEWAY_ENV="$REPO_ROOT/resources/ai/gateway.env"
if [ -f "$GATEWAY_ENV" ]; then
    # shellcheck disable=SC1090
    source "$GATEWAY_ENV"
fi

OMNIROUTE_PORT="${OMNIROUTE_PORT:-20129}"
OMNIROUTE_HOST="${OMNIROUTE_HOST:-127.0.0.1}"
ROUTER_9_PORT="${ROUTER_9_PORT:-20128}"
OMNIROUTE_PINNED_VERSION="${OMNIROUTE_PINNED_VERSION:-3.8.50}"

FORCE=false
while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            warn "Unknown argument: $1"
            shift
            ;;
    esac
done

if [ "$EUID" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        warn "reconcile-ai-gateways manages user services; dropping root privileges to '$SUDO_USER'."
        exec sudo -u "$SUDO_USER" -H "$SCRIPT_DIR/reconcile-ai-gateways.sh" "$@"
    fi
    error "Do not run reconcile-ai-gateways as root. Run it from the user account."
fi

TARGET_USER="$(id -un)"
TARGET_GROUP="$(id -gn)"
USER_HOME="${HOME:-$(getent passwd "$TARGET_USER" | cut -d: -f6)}"

ensure_user_owned() {
    local path="$1"
    [ -e "$path" ] || return 0
    if [ ! -w "$path" ] || find "$path" -xdev ! -user "$TARGET_USER" -print -quit 2>/dev/null | grep -q .; then
        warn "$path contains root-owned files; repairing ownership..."
        sudo chown -R "$TARGET_USER:$TARGET_GROUP" "$path"
    fi
}

# Giới hạn phạm vi chown chính xác vào các thư mục liên quan, không chown đệ quy ~/.local
ensure_user_owned "$USER_HOME/.local/bin"
ensure_user_owned "$USER_HOME/.omniroute"
ensure_user_owned "$USER_HOME/.9router"

info "Reconciling AI Gateways (9Router on :$ROUTER_9_PORT, OmniRoute on :$OMNIROUTE_PORT)..."

# ------------------------------------------------------------------------------
# 2. Ensure initializers exist and are executable
# ------------------------------------------------------------------------------
INIT_9ROUTER="$REPO_ROOT/scripts/init-9router.sh"
INIT_OMNIROUTE="$REPO_ROOT/scripts/init-omniroute.sh"

[ -f "$INIT_9ROUTER" ] || error "Missing 9router initializer: $INIT_9ROUTER"
[ -f "$INIT_OMNIROUTE" ] || error "Missing OmniRoute initializer: $INIT_OMNIROUTE"
chmod +x "$INIT_9ROUTER" "$INIT_OMNIROUTE" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 3. Reconcile 9Router
# ------------------------------------------------------------------------------
SYSTEMD_USER_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR" "$USER_HOME/.local/bin"

SERVICE_9R_SRC="$REPO_ROOT/resources/systemd/user/9router.service"
SERVICE_9R_DEST="$SYSTEMD_USER_DIR/9router.service"

[ -f "$SERVICE_9R_SRC" ] || error "Missing service template: $SERVICE_9R_SRC"
ln -sfn "$SERVICE_9R_SRC" "$SERVICE_9R_DEST"

ROUTER_9_BIN="$USER_HOME/.local/bin/9router"
if [ "$FORCE" = true ] || [ ! -x "$ROUTER_9_BIN" ]; then
    info "Initializing 9Router via $INIT_9ROUTER..."
    "$INIT_9ROUTER" || error "Failed to initialize 9Router."
else
    success "9Router binary found at $ROUTER_9_BIN."
fi

# ------------------------------------------------------------------------------
# 4. Reconcile OmniRoute
# ------------------------------------------------------------------------------
SERVICE_OMNI_SRC="$REPO_ROOT/resources/systemd/user/omniroute.service"
SERVICE_OMNI_DEST="$SYSTEMD_USER_DIR/omniroute.service"

[ -f "$SERVICE_OMNI_SRC" ] || error "Missing service template: $SERVICE_OMNI_SRC"
ln -sfn "$SERVICE_OMNI_SRC" "$SERVICE_OMNI_DEST"

OMNI_BIN="$USER_HOME/.local/bin/omniroute"
CURRENT_OMNI_VER="$("$OMNI_BIN" --version 2>/dev/null || echo '')"
OMNI_ENV="$USER_HOME/.omniroute/.env"

needs_omni_init=false
if [ "$FORCE" = true ] || [ ! -x "$OMNI_BIN" ] || [ "$CURRENT_OMNI_VER" != "$OMNIROUTE_PINNED_VERSION" ]; then
    needs_omni_init=true
elif [ ! -f "$OMNI_ENV" ] || ! grep -q '^STORAGE_ENCRYPTION_KEY=' "$OMNI_ENV" 2>/dev/null; then
    needs_omni_init=true
fi

if [ "$needs_omni_init" = true ]; then
    info "Initializing / updating OmniRoute via $INIT_OMNIROUTE..."
    "$INIT_OMNIROUTE" || error "Failed to initialize OmniRoute."
else
    success "OmniRoute $OMNIROUTE_PINNED_VERSION is already configured."
fi

# ------------------------------------------------------------------------------
# 5. Reload systemd user manager, enable, and converge services
# ------------------------------------------------------------------------------
if command -v systemctl >/dev/null 2>&1; then
    info "Reloading systemd user daemon and synchronizing services..."
    systemctl --user daemon-reload

    # Enable services
    systemctl --user enable 9router.service 2>/dev/null || true
    systemctl --user enable omniroute.service 2>/dev/null || true

    # Start or restart 9Router
    if systemctl --user is-active --quiet 9router.service 2>/dev/null; then
        systemctl --user restart 9router.service 2>/dev/null || true
    else
        systemctl --user start 9router.service 2>/dev/null || true
    fi

    # Start or restart OmniRoute
    if systemctl --user is-active --quiet omniroute.service 2>/dev/null; then
        systemctl --user restart omniroute.service 2>/dev/null || true
    else
        systemctl --user start omniroute.service 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 6. Service & Port Verification
# ------------------------------------------------------------------------------
info "Verifying AI gateway runtime health and port isolation..."

# Allow services a brief moment to bind sockets
sleep 1

# Verify systemd service state
if command -v systemctl >/dev/null 2>&1; then
    if ! systemctl --user is-active --quiet 9router.service 2>/dev/null; then
        error "9Router service failed to start or remain active. Check: journalctl --user -u 9router -n 20"
    fi
    success "9Router systemd user service is active."

    if ! systemctl --user is-active --quiet omniroute.service 2>/dev/null; then
        error "OmniRoute service failed to start or remain active. Check: journalctl --user -u omniroute -n 20"
    fi
    success "OmniRoute systemd user service is active."
fi

# Verify port listeners
verify_port() {
    local port="$1"

    if command -v ss >/dev/null 2>&1; then
        if ss -tlHn "sport = :$port" 2>/dev/null | grep -q ":$port"; then
            return 0
        fi
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -nP -i ":$port" 2>/dev/null | grep -q 'LISTEN'; then
            return 0
        fi
    fi
    return 1
}

if ! verify_port "$ROUTER_9_PORT"; then
    error "9Router is not listening on expected port $ROUTER_9_PORT."
fi
success "9Router is listening on port $ROUTER_9_PORT."

if ! verify_port "$OMNIROUTE_PORT"; then
    error "OmniRoute is not listening on expected port $OMNIROUTE_PORT."
fi
success "OmniRoute is listening on port $OMNIROUTE_PORT."

# Verify loopback isolation for OmniRoute (strictly prohibited from binding to 0.0.0.0)
# Cột 4 trong ss -tlHn chứa địa chỉ bind cục bộ (Local Address:Port)
if command -v ss >/dev/null 2>&1; then
    LOCAL_BIND="$(ss -tlHn "sport = :$OMNIROUTE_PORT" 2>/dev/null | awk '{print $4}' | head -n 1)"
    if echo "$LOCAL_BIND" | grep -qE '^(0\.0\.0\.0|\*):'; then
        error "CRITICAL SECURITY RISK: OmniRoute is bound to public address $LOCAL_BIND! It MUST bind to loopback 127.0.0.1 only."
    fi
    success "OmniRoute loopback binding verified ($LOCAL_BIND)."
fi

# Verify HTTP reachability
OMNI_HTTP="$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$OMNIROUTE_PORT/v1/models" 2>/dev/null || echo "000")"
if [ "$OMNI_HTTP" != "000" ]; then
    success "OmniRoute HTTP endpoint reachable at http://127.0.0.1:$OMNIROUTE_PORT (HTTP $OMNI_HTTP)."
else
    warn "OmniRoute HTTP endpoint did not respond immediately, but TCP port is open."
fi

echo
success "AI Gateways reconciled successfully! Both 9Router (:20128) and OmniRoute (:20129) are active and healthy."
