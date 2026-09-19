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

if [ -f "$REPO_ROOT/resources/ai/gateway.env" ]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/resources/ai/gateway.env"
fi

OMNIROUTE_PORT="${OMNIROUTE_PORT:-20129}"
OMNIROUTE_HOST="${OMNIROUTE_HOST:-127.0.0.1}"
OMNIROUTE_DIR="$HOME/.omniroute"

cmd_backup() {
    info "Triggering Secret Vault backup (authoritative store for ~/.omniroute, scoped)..."
    # Giới hạn scope omniroute để chỉ sao lưu riêng ~/.omniroute vào vault
    "$REPO_ROOT/scripts/vault.sh" backup --scope omniroute "$@"
}

cmd_restore() {
    info "Restoring Secret Vault (restores ~/.omniroute database, keys, and providers, scoped)..."
    # Giới hạn scope omniroute để chỉ phục hồi ~/.omniroute, không ghi đè SSH/Chrome/9router
    "$REPO_ROOT/scripts/vault.sh" restore --scope omniroute "$@"
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

    # Port and host binding state
    local port_bound=false
    if command -v ss >/dev/null 2>&1; then
        if ss -tlHn "sport = :$OMNIROUTE_PORT" 2>/dev/null | grep -E '0\.0\.0\.0|\*:' >/dev/null; then
            echo -e "  - Listening Port:    ${RED}${BOLD}$OMNIROUTE_PORT (INSECURE: Bound to 0.0.0.0)${NC}"
            port_bound=true
        elif ss -tlHn "sport = :$OMNIROUTE_PORT" 2>/dev/null | grep -E '127\.0\.0\.1|\[::1\]' >/dev/null; then
            echo -e "  - Listening Port:    ${GREEN}${BOLD}$OMNIROUTE_PORT (Loopback $OMNIROUTE_HOST, isolated)${NC}"
            port_bound=true
        fi
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -nP -i ":$OMNIROUTE_PORT" 2>/dev/null | grep -q 'LISTEN'; then
            echo -e "  - Listening Port:    ${GREEN}${BOLD}$OMNIROUTE_PORT (Dedicated, isolated)${NC}"
            port_bound=true
        fi
    fi

    if [ "$port_bound" = false ]; then
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
        echo -e "  - Encryption Key:    ${YELLOW}! Missing key in $OMNIROUTE_DIR/.env${NC}"
    fi

    # Directory permissions
    if [ -d "$OMNIROUTE_DIR" ]; then
        local dir_perm
        dir_perm="$(stat -c "%a" "$OMNIROUTE_DIR" 2>/dev/null || echo "unknown")"
        if [ "$dir_perm" = "700" ]; then
            echo -e "  - Permissions:       ${GREEN}${BOLD}Secure ($dir_perm)${NC} on $OMNIROUTE_DIR"
        else
            echo -e "  - Permissions:       ${YELLOW}! Insecure ($dir_perm, expected 700)${NC} on $OMNIROUTE_DIR"
        fi
    fi

    # Vault backup state
    local vault_file="$REPO_ROOT/secrets.vault"
    if [ -f "$vault_file" ]; then
        local v_size v_time
        v_size="$(du -h "$vault_file" | cut -f1)"
        v_time="$(date -r "$vault_file" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")"
        echo -e "  - Encrypted Vault:   ${GREEN}${BOLD}Present ($v_size, $v_time)${NC} at secrets.vault"
    else
        echo -e "  - Encrypted Vault:   ${YELLOW}! No secrets.vault found (run 'sync-omniroute backup')${NC}"
    fi
    echo
}

usage() {
    echo "Usage: $0 {backup|restore|status|export|import}"
    echo
    echo "Commands:"
    echo "  backup, export    Encrypt full OmniRoute state (accounts, tokens, storage.sqlite) into secrets.vault"
    echo "  restore, import   Decrypt and restore OmniRoute state from secrets.vault"
    echo "  status            Show status of OmniRoute service, loopback port, database, and vault"
    echo
    exit 1
}

case "${1:-}" in
    backup|export|save|dump)
        shift
        cmd_backup "$@"
        ;;
    restore|import|load|apply)
        shift
        cmd_restore "$@"
        ;;
    status|info)
        cmd_status
        ;;
    *)
        usage
        ;;
esac
