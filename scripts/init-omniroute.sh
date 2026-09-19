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
OMNIROUTE_PORT="20129"
OMNIROUTE_PINNED_VERSION="3.8.50"

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
        warn "init-omniroute must own user files as '$SUDO_USER'; dropping root privileges."
        exec sudo -u "$SUDO_USER" -H "$SCRIPT_DIR/init-omniroute.sh" "$@"
    fi
    error "Do not run init-omniroute as root. It will request sudo only for system changes."
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
ensure_user_owned "$HOME/.omniroute"

echo -e "${BOLD}=========================================${NC}"
echo -e "${BOLD}     OmniRoute Initializer for NixOS     ${NC}"
echo -e "${BOLD}=========================================${NC}"

# ------------------------------------------------------------------------------
# 1. Ensure fnm & Node.js environment
# ------------------------------------------------------------------------------
info "Checking Node.js & npm environment..."
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)"
fi

if ! command -v npm >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
    if command -v fnm >/dev/null 2>&1; then
        info "Node.js/npm not active; installing and setting up LTS via fnm..."
        fnm install --lts
        fnm default lts-latest 2>/dev/null || true
        eval "$(fnm env --shell bash)"
    fi
fi

if ! command -v npm >/dev/null 2>&1; then
    error "npm not found! Please ensure Node.js / fnm is installed."
fi

# NixOS compatibility: Ensure npm global prefix points to user home ($HOME/.local)
NPM_PREFIX="$(npm config get prefix 2>/dev/null || echo '')"
if [ "$NPM_PREFIX" != "$HOME/.local" ]; then
    npm config set prefix "$HOME/.local"
    NPM_PREFIX="$HOME/.local"
fi
export PATH="$HOME/.local/bin:$PATH"

success "Node.js ($(node -v 2>/dev/null || echo 'unknown')) & npm ($(npm -v 2>/dev/null || echo 'unknown')) are available."

# ------------------------------------------------------------------------------
# 2. Check & create required directories for OmniRoute
# ------------------------------------------------------------------------------
info "Checking required directories for OmniRoute..."

USER_DIRS=(
    "$HOME/.omniroute"
    "$HOME/.omniroute/logs"
    "$HOME/.local/bin"
    "$REPO_ROOT/resources/omniroute"
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
# 3. Configure OmniRoute Environment (.env) & Dedicated Port 20129
# ------------------------------------------------------------------------------
info "Configuring OmniRoute environment and port settings..."

ENV_FILE="$HOME/.omniroute/.env"
DB_FILE="$HOME/.omniroute/storage.sqlite"

if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

# Ensure STORAGE_ENCRYPTION_KEY exists and protect existing database
if ! grep -q '^STORAGE_ENCRYPTION_KEY=' "$ENV_FILE" 2>/dev/null; then
    if [ -s "$DB_FILE" ]; then
        if [ "$FORCE" = false ]; then
            error "Existing database found at $DB_FILE, but STORAGE_ENCRYPTION_KEY is missing in $ENV_FILE. Generating a random key will render existing encrypted credentials unreadable. Either restore your key via 'vault restore' or run 'init-omniroute --force' (which will back up the orphan database to $DB_FILE.orphan.<timestamp> first)."
        else
            ORPHAN_BACKUP="$DB_FILE.orphan.$(date +%Y%m%d%H%M%S)"
            warn "Force flag provided: backing up orphan database to $ORPHAN_BACKUP..."
            mv "$DB_FILE" "$ORPHAN_BACKUP"
        fi
    fi
    NEW_KEY="$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
    echo "STORAGE_ENCRYPTION_KEY=$NEW_KEY" >> "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    success "Generated new STORAGE_ENCRYPTION_KEY in $ENV_FILE"
else
    success "Existing STORAGE_ENCRYPTION_KEY found in $ENV_FILE"
fi

set_or_replace_env() {
    local key="$1"
    local val="$2"
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    else
        echo "${key}=${val}" >> "$ENV_FILE"
    fi
}

set_or_replace_env "PORT" "$OMNIROUTE_PORT"
set_or_replace_env "DASHBOARD_PORT" "$OMNIROUTE_PORT"
set_or_replace_env "HOST" "127.0.0.1"
set_or_replace_env "OMNIROUTE_SERVER_HOST" "127.0.0.1"
set_or_replace_env "API_HOST" "127.0.0.1"
set_or_replace_env "LIVE_WS_HOST" "127.0.0.1"
success "Dedicated loopback host (127.0.0.1) and port ($OMNIROUTE_PORT) configured in $ENV_FILE"

# ------------------------------------------------------------------------------
# 4. Install & Pin OmniRoute via npm
# ------------------------------------------------------------------------------
info "Ensuring omniroute@$OMNIROUTE_PINNED_VERSION is installed via npm..."
ROUTER_BIN="$NPM_PREFIX/bin/omniroute"
CURRENT_OMNI_VER="$("$ROUTER_BIN" --version 2>/dev/null || echo '')"
if [ "$CURRENT_OMNI_VER" != "$OMNIROUTE_PINNED_VERSION" ]; then
    npm i -g "omniroute@$OMNIROUTE_PINNED_VERSION"
    [ -x "$ROUTER_BIN" ] || error "npm completed, but $ROUTER_BIN was not created."
    success "Installed omniroute@$OMNIROUTE_PINNED_VERSION successfully."
else
    success "omniroute is already at pinned version: $OMNIROUTE_PINNED_VERSION"
fi

# ------------------------------------------------------------------------------
# 5. Configure & Enable Systemd Autostart Service
# ------------------------------------------------------------------------------
info "Configuring omniroute systemd user service..."

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

SERVICE_SRC="$REPO_ROOT/resources/systemd/user/omniroute.service"
SERVICE_DEST="$SYSTEMD_USER_DIR/omniroute.service"

[ -f "$SERVICE_SRC" ] || error "Missing service template: $SERVICE_SRC"

if [ "$(readlink -f "$SERVICE_DEST" 2>/dev/null || true)" != "$(readlink -f "$SERVICE_SRC")" ]; then
    if [ -e "$SERVICE_DEST" ] && [ ! -L "$SERVICE_DEST" ]; then
        mv "$SERVICE_DEST" "$SERVICE_DEST.pre-init-omniroute.$(date +%Y%m%d%H%M%S)"
    fi
    ln -sfn "$SERVICE_SRC" "$SERVICE_DEST"
fi
success "omniroute.service is linked to the repository template."

# Reload and enable systemd user service
systemctl --user daemon-reload
systemctl --user enable omniroute.service
success "omniroute.service is enabled to start automatically on system boot!"

# Enable user lingering so service persists across sessions
if command -v loginctl >/dev/null 2>&1; then
    CURRENT_LINGER=$(loginctl show-user "$USER" -p Linger 2>/dev/null | cut -d= -f2 || echo "no")
    if [ "$CURRENT_LINGER" != "yes" ]; then
        info "Enabling user lingering for $USER (so omniroute starts on boot without login)..."
        sudo loginctl enable-linger "$USER" 2>/dev/null || true
    fi
fi

# Stop any rogue omniroute process not managed by systemd
systemctl --user stop omniroute.service 2>/dev/null || true
mapfile -t RUNNING_PIDS < <(pgrep -u "$UID" -f '[o]mniroute serve' 2>/dev/null || true)
if [ "${#RUNNING_PIDS[@]}" -gt 0 ]; then
    info "Stopping running manual omniroute process (PID: ${RUNNING_PIDS[*]})..."
    kill "${RUNNING_PIDS[@]}" 2>/dev/null || true
    sleep 1
fi

# Start or restart the systemd service
info "Starting / restarting omniroute systemd service..."
systemctl --user restart omniroute.service
sleep 3

# ------------------------------------------------------------------------------
# 6. Verification & Health Check
# ------------------------------------------------------------------------------
if systemctl --user is-active --quiet omniroute.service; then
    echo
    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    echo -e "${GREEN}${BOLD}✓ OmniRoute is ACTIVE and configured successfully!   ${NC}"
    echo -e "${GREEN}${BOLD}=====================================================${NC}"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$OMNIROUTE_PORT/v1/models" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "000" ]; then
        echo -e "  - Endpoint Status:   ${GREEN}${BOLD}✓ LISTENING${NC} (HTTP $HTTP_CODE on port $OMNIROUTE_PORT)"
    else
        echo -e "  - Endpoint Status:   ${YELLOW}! Initializing...${NC}"
    fi

    echo -e "  - Port:              ${BOLD}$OMNIROUTE_PORT${NC} (9router remains on 20128)"
    echo -e "  - Dashboard:         ${BOLD}http://localhost:$OMNIROUTE_PORT/dashboard${NC}"
    echo -e "  - OpenAI Endpoint:   ${BOLD}http://localhost:$OMNIROUTE_PORT/v1${NC}"
    echo -e "  - View live status:  ${BOLD}systemctl --user status omniroute${NC}"
    echo -e "  - Follow live logs:  ${BOLD}journalctl --user -u omniroute -f${NC}"
    echo -e "  - Restart service:   ${BOLD}systemctl --user restart omniroute${NC}"
    echo -e "  - Stop service:      ${BOLD}systemctl --user stop omniroute${NC}"
    echo -e "  - Sync config:       ${BOLD}sync-omniroute export | import${NC}"
    echo
else
    warn "Service started but status check returned inactive. Check logs with: journalctl --user -u omniroute -xe"
fi
