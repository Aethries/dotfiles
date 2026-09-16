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

echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}       9router Initializer for NixOS     ${NC}"
echo -e "${BOLD}=========================================${NC}"

# ------------------------------------------------------------------------------
# 1. Ensure fnm & Node.js environment
# ------------------------------------------------------------------------------
info "Checking Node.js & npm environment..."
FNM_NODE_BIN=""
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)"
    FNM_NODE_BIN="$(dirname "$(command -v node 2>/dev/null || true)")"
fi

if ! command -v npm >/dev/null 2>&1; then
    error "npm not found! Please ensure Node.js / fnm is installed."
fi

# NixOS compatibility: Ensure npm global prefix points to user home ($HOME/.local) rather than read-only /nix/store
NPM_PREFIX="$(npm config get prefix 2>/dev/null || echo '')"
if [[ -z "$NPM_PREFIX" || "$NPM_PREFIX" == /nix/store/* ]]; then
    npm config set prefix "$HOME/.local"
fi

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
    cp -f "$HOME/.9router/mitm/rootCA.key" "$CERTS_DIR/9router-rootCA.key" 2>/dev/null || true
    chmod 600 "$CERTS_DIR/9router-rootCA.key" 2>/dev/null || true
fi

# Install Root CA into system CA directory so 9router validation passes
# 9router checks for the file: /usr/local/share/ca-certificates/9router-root-ca.crt
CA_CERT_DIR="/usr/local/share/ca-certificates"
CA_CERT_FILE="$CA_CERT_DIR/9router-root-ca.crt"
info "Ensuring 9router Root CA is registered in $CA_CERT_DIR..."
sudo mkdir -p "$CA_CERT_DIR"
sudo cp -f "$HOME/.9router/mitm/rootCA.crt" "$CA_CERT_FILE"
sudo chmod 644 "$CA_CERT_FILE"
success "Root CA installed at $CA_CERT_FILE (satisfies 9router trust check)."

# Optional: Register into NSS databases (Chrome / Chromium) if certutil is available
if command -v certutil >/dev/null 2>&1; then
    NSS_DIRS=("$HOME/.pki/nssdb" "$HOME/snap/chromium/current/.pki/nssdb")
    for db in "${NSS_DIRS[@]}"; do
        if [ -d "$db" ]; then
            certutil -d sql:"$db" -A -t "C,," -n "9Router MITM Root CA" -i "$HOME/.9router/mitm/rootCA.crt" 2>/dev/null || \
            certutil -d "$db" -A -t "C,," -n "9Router MITM Root CA" -i "$HOME/.9router/mitm/rootCA.crt" 2>/dev/null || true
        fi
    done
    success "Root CA registered in NSS database."
fi

# ------------------------------------------------------------------------------
# 4. System compatibility: /etc/hosts & lsof
# ------------------------------------------------------------------------------
info "Configuring NixOS system compatibility..."

# /etc/hosts must be a mutable file, not a read-only nix store symlink
if [ -L /etc/hosts ]; then
    warn "/etc/hosts is currently a symlink into the read-only Nix store."
    echo "Converting /etc/hosts into a mutable file for 9router DNS routing (may prompt for sudo)..."
    sudo rm -f /etc/hosts
    sudo cp /etc/static/hosts /etc/hosts
    sudo chmod 644 /etc/hosts
    success "Converted /etc/hosts to mutable file."
else
    success "/etc/hosts is mutable."
fi

# Ensure required 9router MITM DNS endpoints exist in /etc/hosts
REQUIRED_HOSTS=(
    "127.0.0.1 daily-cloudcode-pa.googleapis.com"
    "127.0.0.1 cloudcode-pa.googleapis.com"
)

info "Checking 9router MITM DNS entries in /etc/hosts..."
for entry in "${REQUIRED_HOSTS[@]}"; do
    domain=$(echo "$entry" | awk '{print $2}')
    if awk -v target="$domain" '$1 !~ /^#/ { for (i=2; i<=NF; i++) if ($i == target) { found=1; exit 0 } } END { if (!found) exit 1 }' /etc/hosts 2>/dev/null; then
        success "DNS entry already present in /etc/hosts: $domain"
    else
        echo "Adding '$entry' to /etc/hosts (may prompt for sudo)..."
        if [ -s /etc/hosts ] && [ -n "$(tail -c 1 /etc/hosts 2>/dev/null)" ]; then
            echo "" | sudo tee -a /etc/hosts >/dev/null
        fi
        echo "$entry" | sudo tee -a /etc/hosts >/dev/null
        success "Added DNS entry to /etc/hosts: $entry"
    fi
done

# 9router searches for lsof in /usr/bin/lsof or via PATH
if ! command -v lsof >/dev/null 2>&1; then
    warn "lsof is missing! Installing lsof via nix profile..."
    nix profile add nixpkgs#lsof || true
fi

if command -v lsof >/dev/null 2>&1; then
    LSOF_BIN="$(command -v lsof)"
    success "lsof found at: $LSOF_BIN"
    if [ ! -e /usr/bin/lsof ]; then
        echo "Creating /usr/bin/lsof symlink for 9router (may prompt for sudo)..."
        sudo mkdir -p /usr/bin 2>/dev/null || true
        sudo ln -sfn "$LSOF_BIN" /usr/bin/lsof
        success "Linked $LSOF_BIN -> /usr/bin/lsof"
    else
        success "/usr/bin/lsof exists."
    fi
else
    warn "Could not find lsof. Please ensure pkgs.lsof is installed."
fi

# ------------------------------------------------------------------------------
# 5. Install & update 9router + apply bug fixes
# ------------------------------------------------------------------------------
info "Updating 9router to latest version via npm..."
npm i -g 9router@latest
success "9router is updated: $(9router -v 2>/dev/null || echo 'installed')"

# Upstream Bugfix: 9router v0.5.75 throws 'tool and action required' when clicking
# 'Trust Cert' because 'tool' parameter is only sent for DNS toggles, not cert trust.
ROUTER_ROUTE="$HOME/.local/lib/node_modules/9router/app/.next-cli-build/server/app/api/cli-tools/antigravity-mitm/route.js"
if [ -f "$ROUTER_ROUTE" ]; then
    if grep -q 'if(!b||!c)' "$ROUTER_ROUTE"; then
        sed -i 's/if(!b||!c)/if((!b\&\&c!=="trust-cert")||!c)/g' "$ROUTER_ROUTE"
        success "Patched 9router MITM API validation ('tool and action required' bug fixed)."
    else
        success "9router MITM API route is clean."
    fi
fi

# ------------------------------------------------------------------------------
# 6. Configure & Enable Systemd Autostart Service
# ------------------------------------------------------------------------------
info "Configuring 9router systemd user service..."

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

SERVICE_SRC="$REPO_ROOT/resources/systemd/user/9router.service"
SERVICE_DEST="$SYSTEMD_USER_DIR/9router.service"

if [ -f "$SERVICE_SRC" ]; then
    cp -f "$SERVICE_SRC" "$SERVICE_DEST"
else
    cat << 'EOF' > "$SERVICE_DEST"
[Unit]
Description=9router Local AI Gateway & Proxy Service
After=default.target

[Service]
Type=simple
Environment="PATH=%h/.local/bin:%h/.local/share/fnm/aliases/default/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/wrappers/bin:/run/current-system/sw/bin"
Environment="NODE_EXTRA_CA_CERTS=%h/.9router/mitm/rootCA.crt"
Environment="NODE_PATH=%h/.local/lib/node_modules"
ExecStartPre=/bin/sh -c 'test -x "${HOME}/.local/bin/9router" || (echo "9router binary not found. Run init-9router first." >&2; exit 1)'
ExecStart=%h/.local/bin/9router --skip-update
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
fi

# CRITICAL NIXOS FIX:
# Ensure /run/wrappers/bin precedes /run/current-system/sw/bin so sudo uses the setuid wrapper!
sed -i 's|/run/current-system/sw/bin:/run/wrappers/bin|/run/wrappers/bin:/run/current-system/sw/bin|g' "$SERVICE_DEST"

# Patch service PATH with actual fnm node dir if detected
if [ -n "$FNM_NODE_BIN" ] && [ "$FNM_NODE_BIN" != "." ]; then
    sed -i "s|%h/.local/share/fnm/aliases/default/bin|${FNM_NODE_BIN}|g" "$SERVICE_DEST"
    success "Patched 9router.service PATH with fnm node dir: $FNM_NODE_BIN"
fi

# Reload and enable systemd user service
systemctl --user daemon-reload
systemctl --user enable 9router.service
success "9router.service is enabled to start automatically on system boot!"

# Enable user lingering so service persists across sessions
if command -v loginctl >/dev/null 2>&1; then
    CURRENT_LINGER=$(loginctl show-user "$USER" -p Linger 2>/dev/null | cut -d= -f2 || echo "no")
    if [ "$CURRENT_LINGER" != "yes" ]; then
        info "Enabling user lingering for $USER (so 9router starts on boot without login)..."
        sudo loginctl enable-linger "$USER" 2>/dev/null || true
    fi
fi

# Stop any orphan manual process before restarting service
RUNNING_PIDS=$(pgrep -f "9router/cli.js" 2>/dev/null || true)
if [ -n "$RUNNING_PIDS" ]; then
    info "Stopping running manual 9router process (PID: $RUNNING_PIDS)..."
    kill "$RUNNING_PIDS" 2>/dev/null || sudo kill "$RUNNING_PIDS" 2>/dev/null || true
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
        CERT_TRUSTED=$(echo "$STATUS_JSON" | grep -o '"certTrusted":true' || true)
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
