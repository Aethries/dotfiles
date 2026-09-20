#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${DOTFILES_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
LIB_DIR="$SCRIPT_DIR/lib"

# Keep the top-level script as orchestration; helpers are sourceable in isolation.
# shellcheck disable=SC1091
source "$LIB_DIR/common.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/machine.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/ownership.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/links.sh"

preflight() {
    "$REPO_ROOT/scripts/preflight.sh" bootstrap
}

rebuild_system() {
    info "Building NixOS..."
    sudo env "DOTFILES_MACHINE_CONFIG=$MACHINE_CONFIG" nixos-rebuild switch \
        --flake "$REPO_ROOT#check" \
        --impure
    success "NixOS configuration applied successfully!"
}

sync_editor_configs() {
    info "Synchronizing editor configuration and extensions..."
    "$REPO_ROOT/scripts/sync-editors.sh"
}

reconcile_gateways() {
    info "Reconciling AI Gateways (9Router & OmniRoute)..."
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" -H "$REPO_ROOT/scripts/reconcile-ai-gateways.sh" \
            || error "AI Gateway reconciliation failed during bootstrap."
    else
        "$REPO_ROOT/scripts/reconcile-ai-gateways.sh" \
            || error "AI Gateway reconciliation failed during bootstrap."
    fi
}

report_completion() {
    echo
    echo "============================================================"
    echo " Bootstrap completed"
    echo "============================================================"
    echo
    echo "Repository:"
    echo "  $REPO_ROOT"
    echo
    echo "Machine:"
    echo "  $MACHINE_DIR"
    echo
    echo "Hardware:"
    echo "  $HARDWARE_CONFIG"
    echo
    echo "Configuration:"
    echo "  $MACHINE_CONFIG"
    echo
    echo "You can now use:"
    echo
    echo "  ./scripts/build.sh"
    echo
}

main() {
    cd "$REPO_ROOT"
    preflight
    detect_machine
    prepare_machine_dir
    generate_machine_state
    ensure_gitignore
    show_generated_state
    setup_wallpapers
    link_configs
    rebuild_system
    sync_editor_configs
    reconcile_gateways
    report_completion
}

if [ "${DOTFILES_BOOTSTRAP_SOURCE_ONLY:-0}" -ne 1 ]; then
    main "$@"
fi
