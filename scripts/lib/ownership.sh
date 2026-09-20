#!/usr/bin/env bash

repair_managed_ownership() {
    [ -n "${SUDO_USER:-}" ] || return 0

    # Only repair paths this repository creates; never recurse through all of ~/.config.
    local managed_path
    local managed_paths=(
        "$USER_HOME/.config/niri"
        "$USER_HOME/.config/noctalia"
        "$USER_HOME/.config/kitty"
        "$USER_HOME/.config/antigravity"
        "$USER_HOME/.config/nvim"
        "$USER_HOME/.config/zellij"
        "$USER_HOME/.config/yazi"
        "$USER_HOME/.config/fcitx5"
        "$USER_HOME/.config/warpd"
        "$USER_HOME/.config/starship.toml"
        "$USER_HOME/.zshrc"
        "$USER_HOME/.local/bin"
        "$USER_HOME/.local/lib/node_modules"
    )

    for managed_path in "${managed_paths[@]}"; do
        [ -e "$managed_path" ] || continue
        chown -R "$SUDO_USER:" "$managed_path" 2>/dev/null || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.
    done
}
