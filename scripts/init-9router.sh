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

echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}       9router Initializer for NixOS     ${NC}"
echo -e "${BOLD}=========================================${NC}"

# ------------------------------------------------------------------------------
# 1. Ensure fnm & Node.js environment
# ------------------------------------------------------------------------------
info "Checking Node.js & npm environment..."
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)"
    # Detect actual fnm node bin dir and patch service Environment PATH so systemd can find node
    FNM_NODE_BIN="$(dirname "$(command -v node 2>/dev/null || true)")"
    if [ -n "$FNM_NODE_BIN" ] && [ "$FNM_NODE_BIN" != "." ]; then
        SERVICE_FILE="$HOME/.config/systemd/user/9router.service"
        if [ -f "$SERVICE_FILE" ]; then
            # Replace the fnm placeholder path with the actual one
            sed -i "s|%h/.local/share/fnm/aliases/default/bin|${FNM_NODE_BIN}|g" "$SERVICE_FILE"
            success "Patched 9router.service PATH with fnm node dir: $FNM_NODE_BIN"
        fi
    fi
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

# User directories
USER_DIRS=(
    "$HOME/.9router"
    "$HOME/.9router/mitm"
    "$HOME/.9router/logs/mitm"
)

for dir in "${USER_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        success "Created user directory: $dir"
    else
        success "Directory exists: $dir"
    fi
done

# Synchronize trusted Root CA from repository so it is consistent across all machines
if [ -f "$CERTS_DIR/9router-rootCA.crt" ] && [ -f "$CERTS_DIR/9router-rootCA.key" ]; then
    info "Synchronizing predefined Root CA from dotfiles repository..."
    cp -f "$CERTS_DIR/9router-rootCA.key" "$HOME/.9router/mitm/rootCA.key"
    cp -f "$CERTS_DIR/9router-rootCA.crt" "$HOME/.9router/mitm/rootCA.crt"
    chmod 600 "$HOME/.9router/mitm/rootCA.key"
    chmod 644 "$HOME/.9router/mitm/rootCA.crt"
    success "Root CA synchronized to ~/.9router/mitm (consistent with NixOS system trust)."
fi

# NixOS compatibility: System CA directory for 9router trust check
CA_CERT_DIR="/usr/local/share/ca-certificates"
if [ ! -d "$CA_CERT_DIR" ]; then
    warn "NixOS missing $CA_CERT_DIR (required by 9router cert trust validation)."
    echo "Creating $CA_CERT_DIR (may prompt for sudo)..."
    sudo mkdir -p "$CA_CERT_DIR"
    success "Created $CA_CERT_DIR"
else
    success "System CA cert directory exists: $CA_CERT_DIR"
fi

# NixOS compatibility: /etc/hosts must be a mutable file, not a read-only nix store symlink.
# ⚠️  WARNING: nixos-rebuild switch will RESTORE the symlink on every rebuild.
# Permanent fix: add entries to networking.extraHosts in your NixOS configuration instead.
# This conversion is a runtime workaround only — it will be undone after each rebuild.
if [ -L /etc/hosts ]; then
    warn "/etc/hosts is currently a symlink into the read-only Nix store."
    warn "NOTE: nixos-rebuild will restore this symlink on every rebuild."
    warn "Permanent fix: use networking.extraHosts in your NixOS config."
    echo "Converting /etc/hosts into a mutable file for 9router DNS routing (may prompt for sudo)..."
    sudo rm -f /etc/hosts
    sudo cp /etc/static/hosts /etc/hosts
    sudo chmod 644 /etc/hosts
    success "Converted /etc/hosts to mutable file (temporary — reverts on next nixos-rebuild)."
else
    success "/etc/hosts is mutable."
fi

# NixOS compatibility: 9router searches for lsof in /usr/bin/lsof or via PATH.
# lsof is now in environment.systemPackages (packages.nix) so it is available via PATH.
# The /usr/bin/lsof symlink is kept for 9router binaries that hardcode /usr/bin/lsof.
if ! command -v lsof >/dev/null 2>&1; then
    warn "lsof is missing! Installing lsof via nix profile..."
    nix profile add nixpkgs#lsof || true
fi

if command -v lsof >/dev/null 2>&1; then
    LSOF_BIN="$(command -v lsof)"
    success "lsof found at: $LSOF_BIN"
    if [ ! -e /usr/bin/lsof ]; then
        echo "Creating /usr/bin/lsof symlink for 9router (may prompt for sudo)..."
        # Note: /usr/bin does not exist on NixOS; this creates the dir if needed
        # Preferred: add pkgs.lsof to environment.systemPackages instead
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
# 3. Check & update 9router to latest
# ------------------------------------------------------------------------------
info "Updating 9router to latest version via npm..."
npm i -g 9router@latest
success "9router is updated to latest: $(9router -v 2>/dev/null || echo 'installed')"

# ------------------------------------------------------------------------------
# 4. Configure & Enable Systemd Autostart Service (Startup with system)
# ------------------------------------------------------------------------------
info "Configuring 9router to always start up automatically with the system..."

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
Environment="PATH=%h/.local/bin:%h/.local/share/fnm/aliases/default/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:/run/wrappers/bin"
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
info "Starting 9router systemd service..."
systemctl --user restart 9router.service
sleep 1

if systemctl --user is-active --quiet 9router.service; then
    echo
    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    echo -e "${GREEN}${BOLD}✓ 9router is ACTIVE and configured for SYSTEM STARTUP${NC}"
    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    echo -e "  - View live status:  ${BOLD}systemctl --user status 9router${NC}"
    echo -e "  - Follow live logs:  ${BOLD}journalctl --user -u 9router -f${NC}"
    echo -e "  - Restart service:   ${BOLD}systemctl --user restart 9router${NC}"
    echo -e "  - Stop service:      ${BOLD}systemctl --user stop 9router${NC}"
    echo
else
    warn "Service started but status check returned inactive. Check logs with: journalctl --user -u 9router -xe"
fi
