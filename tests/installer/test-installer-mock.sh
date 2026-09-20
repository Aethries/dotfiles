#!/usr/bin/env bash
# Verify installer orchestration passes install_user explicitly without touching /mnt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NIXOS_INSTALLER_SOURCE_ONLY=1 bash -s -- "$REPO_ROOT/scripts/nixos-installer.sh" <<'EOF'
set -euo pipefail

source "$1"

PREFLIGHT_RAN=0
require_root() { :; }
preflight() { PREFLIGHT_RAN=1; }
banner() { :; }
check_connection() { :; }
setup_disk() { :; }
setup_config() {
    [ "$#" -eq 1 ]
    printf -v "$1" '%s' 'fixture-user'
}
run_install() {
    [ "$#" -eq 1 ]
    [ "$1" = 'fixture-user' ]
}

main
[ "$PREFLIGHT_RAN" -eq 1 ]
EOF

echo "[✓] installer passes install_user explicitly from setup_config to run_install"
