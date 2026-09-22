#!/usr/bin/env bash

# Shared, secret-safe helpers for the Agency adapters.

if [ "${AGENCY_COMMON_LOADED:-0}" -eq 1 ]; then
    return 0
fi
AGENCY_COMMON_LOADED=1

AGENCY_SCRIPT_DIR="${AGENCY_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AGENCY_REPO_ROOT="${AGENCY_REPO_ROOT:-$(cd "$AGENCY_SCRIPT_DIR/.." && pwd)}"
AGENCY_GATEWAY_ENV="$AGENCY_REPO_ROOT/resources/ai/gateway.env"
AGENCY_MODEL_ENV="$AGENCY_REPO_ROOT/resources/ai/agency.models.env"

# shellcheck disable=SC1090
source "$AGENCY_GATEWAY_ENV"
# shellcheck disable=SC1090
source "$AGENCY_MODEL_ENV"

agency_secret_file() {
    printf '%s\n' "${NINEROUTER_SECRET_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/9router/agency.env}"
}

read_ninerouter_key_file() {
    local file="$1"
    local line name value

    [ -f "$file" ] || return 0
    if find "$file" -prune -perm /077 -print -quit 2>/dev/null | grep -q .; then
        printf '%s\n' "Secret file is too permissive: $file" >&2
        return 1
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in
            ''|'#'*) continue ;;
        esac
        name="${line%%=*}"
        value="${line#*=}"
        if [ "$name" != "NINEROUTER_API_KEY" ]; then
            continue
        fi
        if [[ "$value" == \"*\" && "$value" == *\" ]]; then
            value="${value:1:${#value}-2}"
        elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
            value="${value:1:${#value}-2}"
        fi
        printf '%s' "$value"
        return 0
    done < "$file"
}

ensure_ninerouter_key() {
    local file key

    if [ -n "${NINEROUTER_API_KEY:-}" ]; then
        export NINEROUTER_API_KEY
        return 0
    fi

    file="$(agency_secret_file)"
    key="$(read_ninerouter_key_file "$file")" || return 1
    if [ -z "$key" ]; then
        printf '%s\n' "NINEROUTER_API_KEY is missing. Run: ./scripts/init-agency.sh --set-api-key" >&2
        return 1
    fi

    export NINEROUTER_API_KEY="$key"
    unset key
}

require_ninerouter_key() {
    local file key

    if [ -n "${NINEROUTER_API_KEY:-}" ]; then
        return 0
    fi

    file="$(agency_secret_file)"
    key="$(read_ninerouter_key_file "$file")" || return 1
    if [ -z "$key" ]; then
        printf '%s\n' "NINEROUTER_API_KEY is missing. Run: ./scripts/init-agency.sh --set-api-key" >&2
        return 1
    fi
    unset key
}

agency_router_base_url() {
    printf 'http://127.0.0.1:%s/v1\n' "${ROUTER_9_PORT:-20128}"
}
