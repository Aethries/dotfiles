#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/agency-common.sh"

CHECK_ONLY=false
DEFER_SECRET=false
SET_API_KEY=false

usage() {
    cat <<'EOF'
Usage: init-agency.sh [--check] [--defer-secret] [--set-api-key]

  --check          Validate existing Agency, tmux, 9Router, and model routes.
  --defer-secret   Install/check Agency without requiring the local API key.
  --set-api-key    Read a new 9Router key without echoing it and store it in
                   ~/.config/9router/agency.env (mode 600).
EOF
}

die() {
    echo "✗ $1" >&2
    exit 1
}

install_agency() {
    if command -v agency >/dev/null 2>&1; then
        return 0
    fi
    command -v npm >/dev/null 2>&1 || die "npm is required to install agency-cli."
    echo "==> Installing agency-cli@$AGENCY_CLI_VERSION"
    npm install --global --prefix "$HOME/.local" --no-audit --no-fund "agency-cli@$AGENCY_CLI_VERSION"
    command -v agency >/dev/null 2>&1 || die "agency-cli installed but 'agency' is not on PATH."
}

set_api_key() {
    local file directory key
    file="$(agency_secret_file)"
    directory="$(dirname "$file")"
    mkdir -p "$directory"
    chmod 700 "$directory"
    printf 'Enter the 9Router API key (input hidden): '
    IFS= read -r -s key
    printf '\n'
    [ -n "$key" ] || die "The API key cannot be empty."
    umask 077
    printf 'NINEROUTER_API_KEY=%s\n' "$key" > "$file"
    chmod 600 "$file"
    unset key
    echo "✓ Stored the key at $file"
}

verify_routes() {
    local base_url header_file models_file model
    base_url="$(agency_router_base_url)"
    header_file="$(mktemp)"
    models_file="$(mktemp)"
    chmod 600 "$header_file"
    printf 'Authorization: Bearer %s\n' "$NINEROUTER_API_KEY" > "$header_file"

    if ! curl --fail --silent --show-error --connect-timeout 3 \
        --header "@$header_file" \
        "$base_url/models" > "$models_file"; then
        rm -f "$header_file" "$models_file"
        die "9Router model catalog is unavailable at $base_url."
    fi

    command -v jq >/dev/null 2>&1 || die "jq is required to validate the 9Router model catalog."
    for model in \
        "$AGENCY_MODEL_THINK_TERRA" \
        "$AGENCY_MODEL_THINK_SOL" \
        "$AGENCY_MODEL_IMPLEMENT_LUNA" \
        "$AGENCY_MODEL_IMPLEMENT_GEMINI_HIGH" \
        "$AGENCY_MODEL_IMPLEMENT_GEMINI_MEDIUM"; do
        jq -e --arg model "$model" '.data | map(.id) | index($model) != null' "$models_file" >/dev/null \
            || die "Configured model is not exposed by 9Router: $model"
    done

    rm -f "$header_file" "$models_file"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --check) CHECK_ONLY=true; shift ;;
        --defer-secret) DEFER_SECRET=true; shift ;;
        --set-api-key) SET_API_KEY=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage; die "Unknown argument: $1" ;;
    esac
done

if [ "$SET_API_KEY" = true ]; then
    set_api_key
fi

if [ "$CHECK_ONLY" = false ]; then
    install_agency
fi

command -v agency >/dev/null 2>&1 || die "Agency is not installed. Run this script without --check."
command -v tmux >/dev/null 2>&1 || die "tmux is missing. Apply the NixOS package change, then run this script again."
command -v codex >/dev/null 2>&1 || die "codex is required by the configured Agency agents."
command -v curl >/dev/null 2>&1 || die "curl is required to validate 9Router."

if [ "$DEFER_SECRET" = true ]; then
    echo "✓ Agency and tmux are installed; secret/model validation deferred."
    exit 0
fi

ensure_ninerouter_key
if command -v systemctl >/dev/null 2>&1 && ! systemctl --user is-active --quiet 9router.service; then
    systemctl --user start 9router.service
fi
verify_routes

echo "✓ Agency is ready with 9Router as the gateway."
echo "  Project config: $REPO_ROOT/.agency/agency.toml"
echo "  Default role: think-terra-high (planning-only)"
