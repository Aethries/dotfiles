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

    # Export declarative non-secret parts (exclude keys and providers to protect credentials)
    if omniroute sync bundle --include settings,combos,policies,skills,memory "$BUNDLE_FILE" 2>/dev/null; then
        success "Exported non-sensitive declarative bundle to $BUNDLE_FILE ($(du -h "$BUNDLE_FILE" | cut -f1))"
    else
        warn "Declarative bundle export skipped or unavailable. The authoritative sync is managed via vault."
    fi

    echo
    echo -e "${BOLD}NOTE:${NC} The authoritative source of truth for accounts, tokens, and storage.sqlite"
    echo "      is your encrypted vault. Run 'vault backup' to sync all state securely."
}

cmd_import() {
    info "Importing OmniRoute declarative bundle from $BUNDLE_FILE..."
    if [ ! -f "$BUNDLE_FILE" ]; then
        warn "Bundle file not found: $BUNDLE_FILE."
        info "If restoring on a new machine, run 'vault restore' to restore full OmniRoute database and environment."
        return 0
    fi

    if ! command -v omniroute >/dev/null 2>&1; then
        error "omniroute CLI not found in PATH. Run init-omniroute first."
    fi

    export PORT="$OMNIROUTE_PORT"
    export DASHBOARD_PORT="$OMNIROUTE_PORT"

    if omniroute sync import "$BUNDLE_FILE" 2>/dev/null; then
        success "OmniRoute configuration bundle imported successfully!"
        echo "Restarting service to load new settings..."
        systemctl --user restart omniroute.service 2>/dev/null || true
    else
        warn "Could not import bundle. Run 'vault restore' to restore your complete database."
    fi
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
            echo -e "  - Listening Port:    ${GREEN}${BOLD}$OMNIROUTE_PORT (Loopback 127.0.0.1, isolated)${NC}"
            port_bound=true
        fi
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -nP -i ":$OMNIROUTE_PORT" 2>/dev/null | grep -q 'LISTEN'; then
            echo -e "  - Listening Port:    ${GREEN}${BOLD}$OMNIROUTE_PORT (Dedicated, isolated from 20128)${NC}"
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

    # Vault backup state
    local vault_file="$REPO_ROOT/secrets.vault"
    if [ -f "$vault_file" ]; then
        local v_size v_time
        v_size="$(du -h "$vault_file" | cut -f1)"
        v_time="$(date -r "$vault_file" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")"
        echo -e "  - Encrypted Vault:   ${GREEN}${BOLD}Present ($v_size, $v_time)${NC} at secrets.vault"
    else
        echo -e "  - Encrypted Vault:   ${YELLOW}! No secrets.vault found (run 'vault backup')${NC}"
    fi

    # Declarative bundle
    if [ -f "$BUNDLE_FILE" ]; then
        local b_size b_time
        b_size="$(du -h "$BUNDLE_FILE" | cut -f1)"
        b_time="$(date -r "$BUNDLE_FILE" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")"
        echo -e "  - Declarative Bundle:${GREEN}${BOLD} Present ($b_size, $b_time)${NC} (gitignored)"
    else
        echo -e "  - Declarative Bundle:${YELLOW}! Not exported yet${NC}"
    fi
    echo
}

cmd_backup() {
    info "Triggering Secret Vault backup (authoritative store for ~/.omniroute)..."
    "$REPO_ROOT/scripts/vault.sh" backup
}

cmd_restore() {
    info "Restoring Secret Vault (restores ~/.omniroute database and keys)..."
    "$REPO_ROOT/scripts/vault.sh" restore
}

usage() {
    echo "Usage: $0 {export|import|status|backup|restore}"
    echo
    echo "Commands:"
    echo "  export    Export non-sensitive declarative bundle (settings, combos, skills)"
    echo "  import    Import declarative bundle into local OmniRoute instance"
    echo "  status    Show status of OmniRoute service, loopback port, database, and vault"
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
