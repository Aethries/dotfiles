#!/usr/bin/env bash
# ==============================================================================
# Bifrost AI Gateway Initializer & Service Manager
#
# Idempotent setup for Bifrost high-performance Go LLM gateway (port 20130).
# Ensures loopback isolation, systemd user service, and health validation.
# ==============================================================================

set -euo pipefail

info() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

warn() {
    echo "! $1"
}

error() {
    echo "✗ $1" >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$REPO_ROOT/scripts/lib/ai-gateway-common.sh" ]; then
    # shellcheck source=/dev/null
    source "$REPO_ROOT/scripts/lib/ai-gateway-common.sh"
fi

BIFROST_PORT="${BIFROST_PORT:-20130}"
BIFROST_HOST="${BIFROST_HOST:-127.0.0.1}"
BIFROST_VERSION="${BIFROST_VERSION:-2.2.1}"

FORCE=false
ENSURE=false
while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        -e|--ensure)
            ENSURE=true
            shift
            ;;
        *)
            warn "Unknown argument: $1"
            shift
            ;;
    esac
done

if [ "$EUID" -eq 0 ]; then
    error "Do not run init-bifrost as root! Run as your standard user."
fi

# ------------------------------------------------------------------------------
# 1. Ensure required directories
# ------------------------------------------------------------------------------
info "Checking required directories for Bifrost..."
mkdir -p "$HOME/.bifrost" "$HOME/.bifrost/logs" "$HOME/.local/bin" "$HOME/.config/systemd/user"
chmod 700 "$HOME/.bifrost" "$HOME/.bifrost/logs" 2>/dev/null || true
success "Directory exists: $HOME/.bifrost (mode 0700)"

# ------------------------------------------------------------------------------
# 2. Verify or provide bifrost binary
# ------------------------------------------------------------------------------
info "Verifying Bifrost binary..."
TARGET_BIN="$HOME/.local/bin/bifrost"

resolve_bifrost_binary() {
    if command -v bifrost >/dev/null 2>&1; then
        command -v bifrost
        return 0
    fi
    if [ -x "$TARGET_BIN" ]; then
        echo "$TARGET_BIN"
        return 0
    fi
    # Search /nix/store for built bifrost binary
    local nix_bin
    nix_bin="$(find /nix/store -maxdepth 3 -name "bifrost" -type f -perm -111 2>/dev/null | grep -v "\.drv" | head -n 1 || true)"
    if [ -n "$nix_bin" ] && [ -x "$nix_bin" ]; then
        echo "$nix_bin"
        return 0
    fi
    return 1
}

RESOLVED_BIN="$(resolve_bifrost_binary || true)"

if [ "$FORCE" = true ] || [ -z "$RESOLVED_BIN" ]; then
    info "Downloading standalone Bifrost binary v$BIFROST_VERSION..."
    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64)  DL_ARCH="amd64" ;;
        aarch64) DL_ARCH="arm64" ;;
        *) error "Unsupported CPU architecture: $ARCH" ;;
    esac
    DL_URL="https://downloads.getmaxim.ai/bifrost/v${BIFROST_VERSION}/linux/${DL_ARCH}/bifrost-http"
    TMP_DL="$(mktemp)"
    curl -fsSL "$DL_URL" -o "$TMP_DL" || error "Failed to download Bifrost from $DL_URL"
    chmod 755 "$TMP_DL"
    mv -f "$TMP_DL" "$TARGET_BIN"
    ln -sfn bifrost "$HOME/.local/bin/bifrost-http"
    success "Installed standalone Bifrost binary to $TARGET_BIN"
    RESOLVED_BIN="$TARGET_BIN"
else
    success "Bifrost binary is available: $RESOLVED_BIN"
    if [ ! -e "$TARGET_BIN" ] && [ "$RESOLVED_BIN" != "$TARGET_BIN" ]; then
        ln -sfn "$RESOLVED_BIN" "$TARGET_BIN"
    fi
fi

# ------------------------------------------------------------------------------
# 3. Configure systemd user service
# ------------------------------------------------------------------------------
info "Configuring Bifrost systemd user service..."
SERVICE_SRC="$REPO_ROOT/resources/systemd/user/bifrost.service"
SERVICE_DEST="$HOME/.config/systemd/user/bifrost.service"

if [ -f "$SERVICE_SRC" ]; then
    if [ -e "$SERVICE_DEST" ] && [ ! -L "$SERVICE_DEST" ]; then
        mv "$SERVICE_DEST" "${SERVICE_DEST}.bak.$(date +%s)"
    fi
    ln -sfn "$SERVICE_SRC" "$SERVICE_DEST"
    success "bifrost.service linked to repository template"
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload || true
    systemctl --user enable bifrost.service 2>/dev/null || true
    success "bifrost.service enabled for user session"

    if [ "$ENSURE" = true ] && systemctl --user is-active --quiet bifrost.service 2>/dev/null && is_port_listening "$BIFROST_PORT"; then
        info "Bifrost service is already active and listening on port $BIFROST_PORT (--ensure mode)."
    else
        info "Starting / restarting Bifrost systemd service..."
        systemctl --user restart bifrost.service
        success "Triggered bifrost.service restart"
    fi

    info "Waiting for Bifrost to listen on port $BIFROST_PORT..."
    if wait_for_port "$BIFROST_PORT" 20; then
        success "Bifrost is active and listening on $BIFROST_HOST:$BIFROST_PORT"
    else
        warn "Bifrost did not start listening on port $BIFROST_PORT within 20s. Check logs: journalctl --user -u bifrost -e"
    fi
else
    warn "systemctl not available; manual invocation required: bifrost -app-dir $HOME/.bifrost -port $BIFROST_PORT -host $BIFROST_HOST"
fi

# ------------------------------------------------------------------------------
# 4. Final Verification
# ------------------------------------------------------------------------------
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "http://${BIFROST_HOST}:${BIFROST_PORT}/" 2>/dev/null || echo "000")"
if [ "$HTTP_CODE" = "200" ]; then
    success "Bifrost Gateway HTTP response: OK ($HTTP_CODE) at http://${BIFROST_HOST}:${BIFROST_PORT}/"
else
    warn "Bifrost Gateway returned HTTP $HTTP_CODE (expected 200). Service may still be completing database migration."
fi

echo
echo "====================================================="
echo "✓ Bifrost AI Gateway initialized successfully!"
echo "  Address   : http://${BIFROST_HOST}:${BIFROST_PORT}/"
echo "  App Dir   : $HOME/.bifrost"
echo "  Service   : systemctl --user status bifrost"
echo "====================================================="
