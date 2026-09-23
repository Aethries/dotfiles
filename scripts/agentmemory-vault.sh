#!/usr/bin/env bash

# Safe one-command lifecycle wrapper for the agentmemory Vault scope.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
VAULT_SCRIPT="$SCRIPT_DIR/vault.sh"
SERVICE_NAME="agentmemory.service"
DEFAULT_DATA_DIR="/var/lib/agentmemory"

error() {
    echo "✗ $1" >&2
    exit 1
}

usage() {
    cat <<'USAGE'
Usage: agentmemory-vault.sh {backup|restore} [vault-file]

The wrapper preserves the service state. If agentmemory.service is active, it
stops the service, performs the encrypted agentmemory Vault operation, and
starts the service again even when the operation fails.

AGENTMEMORY_DATA_DIR defaults to /var/lib/agentmemory.
USAGE
}

if [ "$EUID" -eq 0 ]; then
    error "Run agentmemory-vault as the desktop user, not as root."
fi

action="${1:-}"
case "$action" in
    backup|restore) ;;
    -h|--help|help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
shift

if [ "$#" -gt 1 ]; then
    error "Expected at most one vault file argument."
fi
if [ ! -x "$VAULT_SCRIPT" ]; then
    error "Vault script is missing or not executable: $VAULT_SCRIPT"
fi
if ! command -v systemctl >/dev/null 2>&1; then
    error "systemctl is required to manage $SERVICE_NAME."
fi

vault_args=("$action" --scope agentmemory)
if [ "$#" -eq 1 ]; then
    vault_args+=("$1")
fi

service_was_active=false
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    service_was_active=true
    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is required to stop and restart $SERVICE_NAME."
    fi
    echo "==> Stopping $SERVICE_NAME for a consistent agentmemory snapshot..."
    sudo systemctl stop "$SERVICE_NAME" || error "Could not stop $SERVICE_NAME."
else
    echo "==> $SERVICE_NAME is not active; preserving its inactive state."
fi

restore_service() {
    local status="$1"

    if [ "$service_was_active" = true ]; then
        echo "==> Restarting $SERVICE_NAME..."
        if ! sudo systemctl start "$SERVICE_NAME"; then
            echo "✗ Could not restart $SERVICE_NAME." >&2
            status=1
        elif ! systemctl is-active --quiet "$SERVICE_NAME"; then
            echo "✗ $SERVICE_NAME did not become active." >&2
            status=1
        fi
    fi

    return "$status"
}

cleanup() {
    local status="$?"
    trap - EXIT
    restore_service "$status" || status="$?"
    exit "$status"
}
trap cleanup EXIT

echo "==> Running agentmemory Vault $action..."
AGENTMEMORY_DATA_DIR="${AGENTMEMORY_DATA_DIR:-$DEFAULT_DATA_DIR}" \
    "$VAULT_SCRIPT" "${vault_args[@]}"
