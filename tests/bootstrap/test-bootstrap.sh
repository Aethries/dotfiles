#!/usr/bin/env bash
# Sandbox tests for machine-state generation and repository-owned links.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX_DIR="$(mktemp -d -t dotfiles-bootstrap-test-XXXXXX)"
trap 'rm -rf "$SANDBOX_DIR"' EXIT

DOTFILES_BOOTSTRAP_SOURCE_ONLY=1 bash -s -- "$REPO_ROOT" "$SANDBOX_DIR" <<'EOF'
set -euo pipefail

REPO_ROOT="$1"
SANDBOX_DIR="$2"
source "$REPO_ROOT/scripts/bootstrap.sh"

MACHINE_DIR="$SANDBOX_DIR/machine"
USER_HOME="$SANDBOX_DIR/home"
HOSTNAME='fixture-host'
USERNAME='fixture-user'
DOTFILES_STATE_VERSION='26.05'
mkdir -p "$MACHINE_DIR" "$USER_HOME"
export HOME="$USER_HOME"

sudo() {
    [ "$1" = 'nixos-generate-config' ]
    printf '%s\n' '{ fileSystems."/" = { device = "fixture"; }; }'
}

generate_machine_state

test -s "$MACHINE_DIR/hardware-configuration.nix"
test -s "$MACHINE_DIR/configuration.nix"
test -s "$MACHINE_DIR/hardware-extra.nix"
grep -q 'dotfiles.primaryUser = "fixture-user"' "$MACHINE_DIR/configuration.nix"
grep -q 'system.stateVersion = "26.05"' "$MACHINE_DIR/configuration.nix"

first_config="$(sha256sum "$MACHINE_DIR/configuration.nix")"
generate_machine_state
second_config="$(sha256sum "$MACHINE_DIR/configuration.nix")"
test "$first_config" = "$second_config"

link_configs
test -L "$USER_HOME/.config/nvim"
link_configs
test -L "$USER_HOME/.config/nvim"

if (safe_link "$SANDBOX_DIR/missing" "$SANDBOX_DIR/should-not-exist"); then
    echo 'safe_link accepted a missing required source' >&2
    exit 1
fi
EOF

echo "[✓] bootstrap machine generation and isolated link idempotency passed"
