#!/usr/bin/env bash

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
CERTS_DIR="$REPO_ROOT/resources/certs"
SECRETS_DIR="$REPO_ROOT/secrets"

if [ "$EUID" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        warn "init-9router must own user files as '$SUDO_USER'; dropping root privileges."
        exec sudo -u "$SUDO_USER" -H "$SCRIPT_DIR/init-9router.sh" "$@"
    fi
    error "Do not run init-9router as root. It will request sudo only for system changes."
fi

TARGET_USER="$(id -un)"
TARGET_GROUP="$(id -gn)"

ensure_user_owned() {
    local path="$1"

    [ -e "$path" ] || return 0
    if [ ! -w "$path" ] || find "$path" -xdev ! -user "$TARGET_USER" -print -quit 2>/dev/null | grep -q .; then
        warn "$path contains root-owned files; repairing ownership (sudo may prompt)..."
        sudo chown -R "$TARGET_USER:$TARGET_GROUP" "$path"
    fi
}

ensure_user_owned "$HOME/.local"
ensure_user_owned "$HOME/.9router"

echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}       9router Initializer for NixOS     ${NC}"
echo -e "${BOLD}=========================================${NC}"

# ------------------------------------------------------------------------------
# 1. Ensure fnm & Node.js environment
# ------------------------------------------------------------------------------
info "Checking Node.js & npm environment..."
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)"
fi

if ! command -v npm >/dev/null 2>&1; then
    error "npm not found! Please ensure Node.js / fnm is installed."
fi

# NixOS compatibility: Ensure npm global prefix points to user home ($HOME/.local) rather than read-only /nix/store
NPM_PREFIX="$(npm config get prefix 2>/dev/null || echo '')"
if [ "$NPM_PREFIX" != "$HOME/.local" ]; then
    npm config set prefix "$HOME/.local"
    NPM_PREFIX="$HOME/.local"
fi
export PATH="$HOME/.local/bin:$PATH"

success "Node.js ($(node -v 2>/dev/null || echo 'unknown')) & npm ($(npm -v 2>/dev/null || echo 'unknown')) are available."

# ------------------------------------------------------------------------------
# 2. Check & create required directories for 9router MITM
# ------------------------------------------------------------------------------
info "Checking required directories for 9router..."

USER_DIRS=(
    "$HOME/.9router"
    "$HOME/.9router/mitm"
    "$HOME/.9router/logs/mitm"
    "$SECRETS_DIR"
)

for dir in "${USER_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        success "Created directory: $dir"
    else
        success "Directory exists: $dir"
    fi
done

# ------------------------------------------------------------------------------
# 3. Synchronize & establish Root CA across machines
# ------------------------------------------------------------------------------
info "Synchronizing 9router Root CA & SSL certificates..."

# Restore Root CA key if missing from ~/.9router/mitm/
if [ ! -f "$HOME/.9router/mitm/rootCA.key" ]; then
    if [ -f "$SECRETS_DIR/9router-rootCA.key" ]; then
        info "Restoring Root CA key from secrets/ (decrypted vault)..."
        cp -f "$SECRETS_DIR/9router-rootCA.key" "$HOME/.9router/mitm/rootCA.key"
        chmod 600 "$HOME/.9router/mitm/rootCA.key"
        success "Restored rootCA.key from $SECRETS_DIR/9router-rootCA.key"
    elif [ -f "$CERTS_DIR/9router-rootCA.key" ]; then
        info "Restoring Root CA key from resources/certs/..."
        cp -f "$CERTS_DIR/9router-rootCA.key" "$HOME/.9router/mitm/rootCA.key"
        chmod 600 "$HOME/.9router/mitm/rootCA.key"
        success "Restored rootCA.key from $CERTS_DIR/9router-rootCA.key"
    fi
fi

# Ensure predefined Root CA cert is in place if available
if [ -f "$CERTS_DIR/9router-rootCA.crt" ] && [ ! -f "$HOME/.9router/mitm/rootCA.crt" ]; then
    cp -f "$CERTS_DIR/9router-rootCA.crt" "$HOME/.9router/mitm/rootCA.crt"
    chmod 644 "$HOME/.9router/mitm/rootCA.crt"
    success "Synchronized predefined 9router-rootCA.crt to ~/.9router/mitm/rootCA.crt"
fi

# If key and cert still do not exist on this machine, generate a local pair
if [ ! -f "$HOME/.9router/mitm/rootCA.key" ] || [ ! -f "$HOME/.9router/mitm/rootCA.crt" ]; then
    warn "No predefined Root CA found. Generating new 9router MITM Root CA..."
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "$HOME/.9router/mitm/rootCA.key" \
        -out "$HOME/.9router/mitm/rootCA.crt" \
        -days 3650 \
        -subj "/CN=9Router MITM Root CA/O=9Router/C=US" 2>/dev/null
    chmod 600 "$HOME/.9router/mitm/rootCA.key"
    chmod 644 "$HOME/.9router/mitm/rootCA.crt"
    success "Generated new Root CA pair in ~/.9router/mitm/"
fi

# Preserve local backup in secrets/ (gitignored) so user can sync with 'secrets encrypt'
if [ -f "$HOME/.9router/mitm/rootCA.key" ] && [ ! -f "$SECRETS_DIR/9router-rootCA.key" ]; then
    cp -f "$HOME/.9router/mitm/rootCA.key" "$SECRETS_DIR/9router-rootCA.key"
    chmod 600 "$SECRETS_DIR/9router-rootCA.key"
    success "Saved Root CA key copy to secrets/ (encrypt via 'secrets encrypt' to sync to other machines)."
fi

# Keep resources/certs/9router-rootCA.key locally if missing (also gitignored)
if [ -f "$HOME/.9router/mitm/rootCA.key" ] && [ ! -f "$CERTS_DIR/9router-rootCA.key" ]; then
    cp -f "$HOME/.9router/mitm/rootCA.key" "$CERTS_DIR/9router-rootCA.key" 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
    chmod 600 "$CERTS_DIR/9router-rootCA.key" 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
fi

# The OS trust store is owned declaratively by NixOS (modules/base.nix).
# Keep the user-local certificate above for 9router and Node.js only.

# Optional: Register into NSS databases (Chrome / Chromium) if certutil is available
if command -v certutil >/dev/null 2>&1; then
    NSS_DIRS=("$HOME/.pki/nssdb" "$HOME/snap/chromium/current/.pki/nssdb")
    for db in "${NSS_DIRS[@]}"; do
        if [ -d "$db" ]; then
            certutil -d sql:"$db" -A -t "C,," -n "9Router MITM Root CA" -i "$HOME/.9router/mitm/rootCA.crt" 2>/dev/null || \
            certutil -d "$db" -A -t "C,," -n "9Router MITM Root CA" -i "$HOME/.9router/mitm/rootCA.crt" 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
        fi
    done
    success "Root CA registered in NSS database."
fi

# ------------------------------------------------------------------------------
# 4. Read-only system compatibility checks
# ------------------------------------------------------------------------------
info "Validating NixOS-managed compatibility state..."

# Ensure required 9router MITM DNS endpoints exist in /etc/hosts
REQUIRED_HOSTS=(
    "127.0.0.1 daily-cloudcode-pa.googleapis.com"
    "127.0.0.1 cloudcode-pa.googleapis.com"
)

info "Checking 9router MITM DNS entries in /etc/hosts..."
[ -r /etc/hosts ] || error "/etc/hosts is not readable; rebuild NixOS before initializing 9router."
for entry in "${REQUIRED_HOSTS[@]}"; do
    domain=$(echo "$entry" | awk '{print $2}')
    if awk -v target="$domain" '$1 !~ /^#/ { for (i=2; i<=NF; i++) if ($i == target) { found=1; exit 0 } } END { if (!found) exit 1 }' /etc/hosts 2>/dev/null; then
        success "DNS entry already present in /etc/hosts: $domain"
    else
        error "Missing NixOS-managed DNS entry in /etc/hosts: $entry"
    fi
done

# 9router searches for lsof via PATH; NixOS provides it declaratively.
if ! command -v lsof >/dev/null 2>&1; then
    error "lsof is missing from PATH; rebuild NixOS with pkgs.lsof before initializing 9router."
else
    success "lsof found at $(command -v lsof)"
fi

# ------------------------------------------------------------------------------
# 5. Install & update 9router + apply bug fixes
# ------------------------------------------------------------------------------
ROUTER_9_PINNED_VERSION="${ROUTER_9_PINNED_VERSION:?ROUTER_9_PINNED_VERSION is required in resources/ai/gateway.env}"
info "Installing pinned 9router version $ROUTER_9_PINNED_VERSION via npm..."
npm i -g "9router@$ROUTER_9_PINNED_VERSION"
ROUTER_BIN="$NPM_PREFIX/bin/9router"
[ -x "$ROUTER_BIN" ] || error "npm completed, but $ROUTER_BIN was not created."
ROUTER_VERSION_OUTPUT="$("$ROUTER_BIN" -v 2>/dev/null || echo '')"
[[ "$ROUTER_VERSION_OUTPUT" == *"$ROUTER_9_PINNED_VERSION"* ]] \
    || error "Installed 9router version does not match $ROUTER_9_PINNED_VERSION: $ROUTER_VERSION_OUTPUT"
success "9router is installed at pinned version $ROUTER_9_PINNED_VERSION"

# Upstream Bugfix: 9router v0.5.75 throws 'tool and action required' when clicking
# 'Trust Cert' because 'tool' parameter is only sent for DNS toggles, not cert trust.
NPM_ROOT="$(npm root -g)"
ROUTER_ROUTE="$NPM_ROOT/9router/app/.next-cli-build/server/app/api/cli-tools/antigravity-mitm/route.js"
[ -f "$ROUTER_ROUTE" ] || error "Pinned 9router package is missing expected MITM route: $ROUTER_ROUTE"
if grep -Fq 'if(!b||!c)' "$ROUTER_ROUTE"; then
    sed -i 's/if(!b||!c)/if((!b\&\&c!=="trust-cert")||!c)/g' "$ROUTER_ROUTE"
    success "Patched pinned 9router MITM API validation."
elif grep -Fq 'if((!b&&c!=="trust-cert")||!c)' "$ROUTER_ROUTE"; then
    success "Pinned 9router MITM API route is already patched."
else
    error "Pinned 9router route format changed; refusing an unverified patch."
fi
grep -Fq 'if((!b&&c!=="trust-cert")||!c)' "$ROUTER_ROUTE" \
    || error "9router MITM patch post-condition failed."

# ------------------------------------------------------------------------------
# 6. Configure & Enable Systemd Autostart Service
# ------------------------------------------------------------------------------
info "Configuring 9router systemd user service..."

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

SERVICE_SRC="$REPO_ROOT/resources/systemd/user/9router.service"
SERVICE_DEST="$SYSTEMD_USER_DIR/9router.service"

[ -f "$SERVICE_SRC" ] || error "Missing service template: $SERVICE_SRC"

# bootstrap.sh deliberately links user units to the repository. Keep that model
# here instead of copying a file through a symlink back onto itself.
if [ "$(readlink -f "$SERVICE_DEST" 2>/dev/null || true)" != "$(readlink -f "$SERVICE_SRC")" ]; then # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
    if [ -e "$SERVICE_DEST" ] && [ ! -L "$SERVICE_DEST" ]; then
        mv "$SERVICE_DEST" "$SERVICE_DEST.pre-init-9router.$(date +%Y%m%d%H%M%S)"
    fi
    ln -sfn "$SERVICE_SRC" "$SERVICE_DEST"
fi
success "9router.service is linked to the repository template."

# Reload and enable systemd user service
systemctl --user daemon-reload
systemctl --user enable 9router.service
success "9router.service is enabled to start automatically on system boot!"

# Enable user lingering so service persists across sessions
if command -v loginctl >/dev/null 2>&1; then
    CURRENT_LINGER=$(loginctl show-user "$USER" -p Linger 2>/dev/null | cut -d= -f2 || echo "no")
    if [ "$CURRENT_LINGER" != "yes" ]; then
        info "Enabling user lingering for $USER (so 9router starts on boot without login)..."
        sudo loginctl enable-linger "$USER" 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
    fi
fi

# Stop the managed service first so Restart=on-failure cannot race the cleanup,
# then terminate only leftover 9router processes owned by this user.
systemctl --user stop 9router.service 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
mapfile -t RUNNING_PIDS < <(pgrep -u "$UID" -f '[9]router/cli.js' 2>/dev/null || true) # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
if [ "${#RUNNING_PIDS[@]}" -gt 0 ]; then
    info "Stopping running manual 9router process (PID: ${RUNNING_PIDS[*]})..."
    kill "${RUNNING_PIDS[@]}" 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
    sleep 1
fi

# Start or restart the systemd service
info "Starting / restarting 9router systemd service..."
systemctl --user restart 9router.service
sleep 2

# ------------------------------------------------------------------------------
# 7. Verification & Health Check
# ------------------------------------------------------------------------------
if systemctl --user is-active --quiet 9router.service; then
    echo
    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    echo -e "${GREEN}${BOLD}✓ 9router is ACTIVE and configured successfully!     ${NC}"
    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    
    # Check MITM status via API
    CLI_TOKEN=$(node -e '
        const fs = require("fs");
        const crypto = require("crypto");
        const path = require("path");
        const homedir = require("os").homedir();
        try {
            const m = fs.readFileSync(path.join(homedir, ".9router", "machine-id"), "utf8").trim();
            const s = fs.readFileSync(path.join(homedir, ".9router", "auth", "cli-secret"), "utf8").trim();
            console.log(crypto.createHash("sha256").update(m + "9r-cli-auth" + s).digest("hex").substring(0, 16));
        } catch { process.exit(1); }
    ' 2>/dev/null || echo "")

    if [ -n "$CLI_TOKEN" ]; then
        STATUS_JSON=$(curl -s -H "x-9r-cli-token: $CLI_TOKEN" http://localhost:20128/api/cli-tools/antigravity-mitm 2>/dev/null || echo "{}")
        CERT_TRUSTED=$(echo "$STATUS_JSON" | grep -o '"certTrusted":true' || true) # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
        if [ -n "$CERT_TRUSTED" ]; then
            echo -e "  - Root CA Status:    ${GREEN}${BOLD}✓ TRUSTED${NC} (Dashboard will show green checkmarks)"
        else
            echo -e "  - Root CA Status:    ${YELLOW}! Requires refresh / check${NC}"
        fi
    fi

    echo -e "  - Dashboard:         ${BOLD}http://localhost:20128/dashboard/mitm${NC}"
    echo -e "  - View live status:  ${BOLD}systemctl --user status 9router${NC}"
    echo -e "  - Follow live logs:  ${BOLD}journalctl --user -u 9router -f${NC}"
    echo -e "  - Restart service:   ${BOLD}systemctl --user restart 9router${NC}"
    echo -e "  - Stop service:      ${BOLD}systemctl --user stop 9router${NC}"
    echo
else
    warn "Service started but status check returned inactive. Check logs with: journalctl --user -u 9router -xe"
fi
