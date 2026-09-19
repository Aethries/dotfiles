#!/usr/bin/env bash

set -euo pipefail

# ANSI color codes
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

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
OMNIROUTE_DIR="$HOME/.omniroute"
RESOURCES_OMNI="$REPO_ROOT/resources/omniroute"
BUNDLE_FILE="$RESOURCES_OMNI/bundle.json"
OMNIROUTE_PORT="20129"

mkdir -p "$RESOURCES_OMNI"

cmd_export() {
    info "Exporting OmniRoute declarative bundle..."
    if ! command -v omniroute >/dev/null 2>&1; then
        error "omniroute CLI not found in PATH. Run init-omniroute first."
    fi

    # Ensure port 20129 is used
    export PORT="$OMNIROUTE_PORT"
    export DASHBOARD_PORT="$OMNIROUTE_PORT"

    if omniroute sync bundle "$BUNDLE_FILE" 2>/dev/null; then
        success "Exported bundle to $BUNDLE_FILE ($(du -h "$BUNDLE_FILE" | cut -f1))"
    else
        warn "Could not export via 'omniroute sync bundle'. Creating database snapshot in vault instead."
    fi

    echo
    echo "Tip: Run 'vault backup' to include all providers, tokens, and storage.sqlite into your encrypted secrets.vault!"
}

cmd_import() {
    info "Importing OmniRoute declarative bundle from $BUNDLE_FILE..."
    if [ ! -f "$BUNDLE_FILE" ]; then
        error "Bundle file not found: $BUNDLE_FILE. Run 'sync-omniroute export' first."
    fi

    if ! command -v omniroute >/dev/null 2>&1; then
        error "omniroute CLI not found in PATH. Run init-omniroute first."
    fi

    export PORT="$OMNIROUTE_PORT"
    export DASHBOARD_PORT="$OMNIROUTE_PORT"

    omniroute sync import "$BUNDLE_FILE"
    success "OmniRoute configuration bundle imported successfully!"
    echo "Restarting service to load new settings..."
    systemctl --user restart omniroute.service 2>/dev/null || true
}

cmd_status() {
    info "Checking OmniRoute synchronization and runtime status..."
    echo

    # Service state
    if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet omniroute.service 2>/dev/null; then
        echo -e "  - Service Status:    ${GREEN}${BOLD}Active (Running)${NC}"
    else
        echo -e "  - Service Status:    ${YELLOW}! Inactive or Stopped${NC}"
    fi

    # Port state
    if lsof -i ":$OMNIROUTE_PORT" >/dev/null 2>&1; then
        echo -e "  - Listening Port:    ${GREEN}${BOLD}$OMNIROUTE_PORT (Dedicated, no conflict with 20128)${NC}"
    else
        echo -e "  - Listening Port:    ${YELLOW}! Not listening on $OMNIROUTE_PORT${NC}"
    fi

    # Database state
    if [ -f "$OMNIROUTE_DIR/storage.sqlite" ]; then
        local db_size
        db_size="$(du -h "$OMNIROUTE_DIR/storage.sqlite" | cut -f1)"
        echo -e "  - Database:          ${GREEN}${BOLD}Present ($db_size)${NC} at $OMNIROUTE_DIR/storage.sqlite"
    else
        echo -e "  - Database:          ${YELLOW}! Missing (run init-omniroute)${NC}"
    fi

    # .env key state
    if [ -f "$OMNIROUTE_DIR/.env" ] && grep -q '^STORAGE_ENCRYPTION_KEY=' "$OMNIROUTE_DIR/.env"; then
        echo -e "  - Encryption Key:    ${GREEN}${BOLD}Configured${NC} in $OMNIROUTE_DIR/.env"
    else
        echo -e "  - Encryption Key:    ${YELLOW}! Missing key${NC}"
    fi

    # Tracked bundle
    if [ -f "$BUNDLE_FILE" ]; then
        local b_size
        b_size="$(du -h "$BUNDLE_FILE" | cut -f1)"
        local b_time
        b_time="$(date -r "$BUNDLE_FILE" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")"
        echo -e "  - Dotfiles Bundle:   ${GREEN}${BOLD}Synced ($b_size, $b_time)${NC}"
    else
        echo -e "  - Dotfiles Bundle:   ${YELLOW}! No exported bundle in $RESOURCES_OMNI${NC}"
    fi
    echo
}

cmd_backup() {
    info "Triggering Secret Vault backup (includes ~/.omniroute)..."
    "$REPO_ROOT/scripts/vault.sh" backup
}

cmd_restore() {
    info "Restoring Secret Vault (restores ~/.omniroute)..."
    "$REPO_ROOT/scripts/vault.sh" restore
}

usage() {
    echo "Usage: $0 {export|import|status|backup|restore}"
    echo
    echo "Commands:"
    echo "  export    Export local OmniRoute configuration bundle to resources/omniroute/bundle.json"
    echo "  import    Import resources/omniroute/bundle.json into local OmniRoute instance"
    echo "  status    Show status of OmniRoute service, port, database, and repository sync"
    echo "  backup    Encrypt full OmniRoute database and environment into secrets.vault"
    echo "  restore   Decrypt and restore OmniRoute database and environment from secrets.vault"
    echo
    exit 1
}

case "${1:-}" in
    export|save|dump)
        cmd_export
        ;;
    import|load|apply)
        cmd_import
        ;;
    status|info)
        cmd_status
        ;;
    backup)
        cmd_backup
        ;;
    restore)
        cmd_restore
        ;;
    *)
        usage
        ;;
esac
