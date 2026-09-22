#!/usr/bin/env bash

safe_link() {
    local src="$1"
    local dest="$2"
    [ -e "$src" ] || error "Required source does not exist: $src"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup
        backup="${dest}.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
        mv -- "$dest" "$backup"
        warn "Moved existing $dest to $backup"
    fi
    ln -sfn "$src" "$dest"
}

setup_wallpapers() {
    info "Checking wallpapers..."

    local wallpaper_src="$REPO_ROOT/resources/static/wallpapers"
    local wallpaper_dest="$USER_HOME/Pictures/Wallpapers"

    if [ -e "$wallpaper_dest" ]; then
        info "Pictures/Wallpapers already exists at $wallpaper_dest, skipping copy."
    elif [ -d "$wallpaper_src" ]; then
        info "Copying wallpapers to $wallpaper_dest..."
        mkdir -p "$USER_HOME/Pictures" "$USER_HOME/Videos" "$USER_HOME/Downloads" "$USER_HOME/Documents"
        cp -r "$wallpaper_src" "$wallpaper_dest"
        if [ -n "${SUDO_USER:-}" ]; then
            # REQUIRED: the repository-created wallpaper subtree must be usable by the target user.
            chown -R "$SUDO_USER:" "$wallpaper_dest"
        fi
        success "Wallpapers copied successfully to $wallpaper_dest"
    else
        echo "! Wallpaper source directory not found at $wallpaper_src"
    fi
}

link_configs() {
    info "Linking configuration files to $USER_HOME/.config..."

    mkdir -p "$USER_HOME/.config" "$USER_HOME/.config/noctalia" "$USER_HOME/.config/fcitx5" "$USER_HOME/.config/gh"

    if [ -f "$REPO_ROOT/resources/gh/config.yml" ]; then
        safe_link "$REPO_ROOT/resources/gh/config.yml" "$USER_HOME/.config/gh/config.yml"
    fi
    safe_link "$REPO_ROOT/resources/niri" "$USER_HOME/.config/niri"
    safe_link "$REPO_ROOT/resources/noctalia/config.toml" "$USER_HOME/.config/noctalia/config.toml"
    safe_link "$REPO_ROOT/resources/kitty" "$USER_HOME/.config/kitty"
    safe_link "$REPO_ROOT/resources/antigravity" "$USER_HOME/.config/antigravity"
    if [ -f "$REPO_ROOT/resources/codex/config.toml" ]; then
        mkdir -p "$USER_HOME/.codex"
        safe_link "$REPO_ROOT/resources/codex/config.toml" "$USER_HOME/.codex/config.toml"
    fi

    if [ -f "$REPO_ROOT/resources/starship/starship.toml" ]; then
        safe_link "$REPO_ROOT/resources/starship/starship.toml" "$USER_HOME/.config/starship.toml"
    fi
    if [ -d "$REPO_ROOT/resources/zsh" ]; then
        safe_link "$REPO_ROOT/resources/zsh/.zshrc" "$USER_HOME/.zshrc"
        safe_link "$REPO_ROOT/resources/zsh/.zimrc" "$USER_HOME/.zimrc"
    fi
    if [ -d "$REPO_ROOT/resources/zellij" ]; then
        safe_link "$REPO_ROOT/resources/zellij" "$USER_HOME/.config/zellij"
    fi
    if [ -d "$REPO_ROOT/resources/nvim" ]; then
        safe_link "$REPO_ROOT/resources/nvim" "$USER_HOME/.config/nvim"
    fi

    if [ -d "$REPO_ROOT/resources/fcitx5" ]; then
        safe_link "$REPO_ROOT/resources/fcitx5/config" "$USER_HOME/.config/fcitx5/config"
        safe_link "$REPO_ROOT/resources/fcitx5/profile" "$USER_HOME/.config/fcitx5/profile"
        mkdir -p "$USER_HOME/.config/fcitx5/conf"
        if [ -d "$REPO_ROOT/resources/fcitx5/conf" ]; then
            safe_link "$REPO_ROOT/resources/fcitx5/conf/bamboo.conf" "$USER_HOME/.config/fcitx5/conf/bamboo.conf"
            safe_link "$REPO_ROOT/resources/fcitx5/conf/classicui.conf" "$USER_HOME/.config/fcitx5/conf/classicui.conf"
            safe_link "$REPO_ROOT/resources/fcitx5/conf/keyboard.conf" "$USER_HOME/.config/fcitx5/conf/keyboard.conf"
        fi
    fi

    if [ -d "$REPO_ROOT/resources/git" ]; then
        [ -f "$REPO_ROOT/resources/git/.gitconfig" ] && safe_link "$REPO_ROOT/resources/git/.gitconfig" "$USER_HOME/.gitconfig"
        [ -f "$REPO_ROOT/resources/git/.gitconfig-1bitlab" ] && safe_link "$REPO_ROOT/resources/git/.gitconfig-1bitlab" "$USER_HOME/.gitconfig-1bitlab"
        if [ -f "$REPO_ROOT/resources/git/ignore" ]; then
            mkdir -p "$USER_HOME/.config/git"
            safe_link "$REPO_ROOT/resources/git/ignore" "$USER_HOME/.config/git/ignore"
        fi
    fi

    if [ -f "$REPO_ROOT/resources/ssh/config" ]; then
        mkdir -p "$USER_HOME/.ssh"
        chmod 700 "$USER_HOME/.ssh"
        safe_link "$REPO_ROOT/resources/ssh/config" "$USER_HOME/.ssh/config"
    fi

    if [ -d "$REPO_ROOT/resources/fastfetch" ]; then
        mkdir -p "$USER_HOME/.config/fastfetch"
        if [ ! -f "$USER_HOME/.config/fastfetch/config.jsonc" ] || [ -L "$USER_HOME/.config/fastfetch/config.jsonc" ]; then
            rm -f "$USER_HOME/.config/fastfetch/config.jsonc"
            cp "$REPO_ROOT/resources/fastfetch/config.jsonc" "$USER_HOME/.config/fastfetch/config.jsonc"
            success "Copied fastfetch configuration template"
        fi
    fi

    if [ -d "$REPO_ROOT/resources/yazi" ]; then
        mkdir -p "$USER_HOME/.config/yazi"
        safe_link "$REPO_ROOT/resources/yazi/keymap.toml" "$USER_HOME/.config/yazi/keymap.toml"
        safe_link "$REPO_ROOT/resources/yazi/yazi.toml" "$USER_HOME/.config/yazi/yazi.toml"
    fi
    if [ -d "$REPO_ROOT/resources/warpd" ]; then
        mkdir -p "$USER_HOME/.config/warpd"
        safe_link "$REPO_ROOT/resources/warpd/config" "$USER_HOME/.config/warpd/config"
    fi

    mkdir -p "$USER_HOME/.local/share/applications"
    [ -f "$REPO_ROOT/resources/static/jira.desktop" ] && safe_link "$REPO_ROOT/resources/static/jira.desktop" "$USER_HOME/.local/share/applications/jira.desktop"
    if [ -f "$REPO_ROOT/resources/static/jira.svg" ]; then
        mkdir -p "$USER_HOME/.local/share/icons/hicolor/scalable/apps"
        safe_link "$REPO_ROOT/resources/static/jira.svg" "$USER_HOME/.local/share/icons/hicolor/scalable/apps/jira.svg"
    fi

    if [ -d "$REPO_ROOT/resources/systemd/user" ]; then
        mkdir -p "$USER_HOME/.config/systemd/user"
        for srv in "$REPO_ROOT/resources/systemd/user/"*.service; do
            [ -f "$srv" ] && safe_link "$srv" "$USER_HOME/.config/systemd/user/$(basename "$srv")"
        done
    fi

    mkdir -p "$USER_HOME/.local/bin"
    safe_link "$REPO_ROOT/scripts/pj.sh" "$USER_HOME/.local/bin/pj"
    safe_link "$REPO_ROOT/scripts/flakify.sh" "$USER_HOME/.local/bin/flakify"
    safe_link "$REPO_ROOT/scripts/vault.sh" "$USER_HOME/.local/bin/vault"
    safe_link "$REPO_ROOT/scripts/secrets.sh" "$USER_HOME/.local/bin/secrets"
    safe_link "$REPO_ROOT/scripts/jira-app.sh" "$USER_HOME/.local/bin/jira-app"
    safe_link "$REPO_ROOT/scripts/build.sh" "$USER_HOME/.local/bin/rebuild"
    safe_link "$REPO_ROOT/scripts/sync-noctalia.sh" "$USER_HOME/.local/bin/sync-theme"
    safe_link "$REPO_ROOT/scripts/screenshot.sh" "$USER_HOME/.local/bin/screenshot"
    safe_link "$REPO_ROOT/scripts/doctor.sh" "$USER_HOME/.local/bin/doctor"
    safe_link "$REPO_ROOT/scripts/check.sh" "$USER_HOME/.local/bin/dotfiles-check"
    safe_link "$REPO_ROOT/scripts/tunnel.sh" "$USER_HOME/.local/bin/tunnel"
    safe_link "$REPO_ROOT/scripts/cleanup.sh" "$USER_HOME/.local/bin/cleanup"
    safe_link "$REPO_ROOT/scripts/init-9router.sh" "$USER_HOME/.local/bin/init-9router"
    safe_link "$REPO_ROOT/scripts/init-9router.sh" "$USER_HOME/.local/bin/9router-init"
    safe_link "$REPO_ROOT/scripts/init-agency.sh" "$USER_HOME/.local/bin/init-agency"
    safe_link "$REPO_ROOT/scripts/init-agency.sh" "$USER_HOME/.local/bin/agency-init"
    safe_link "$REPO_ROOT/scripts/ninerouter-token.sh" "$USER_HOME/.local/bin/ninerouter-token"
    safe_link "$REPO_ROOT/scripts/init-omniroute.sh" "$USER_HOME/.local/bin/init-omniroute"
    safe_link "$REPO_ROOT/scripts/sync-omniroute.sh" "$USER_HOME/.local/bin/sync-omniroute"
    safe_link "$REPO_ROOT/scripts/reconcile-ai-gateways.sh" "$USER_HOME/.local/bin/reconcile-ai-gateways"
    safe_link "$REPO_ROOT/scripts/ai-skills.sh" "$USER_HOME/.local/bin/ai-skills"
    safe_link "$REPO_ROOT/scripts/ai-skills.sh" "$USER_HOME/.local/bin/add-skills"
    safe_link "$REPO_ROOT/scripts/kanata-recovery.sh" "$USER_HOME/.local/bin/kanata-recovery"

    if command -v npm >/dev/null 2>&1; then
        if [ -n "${SUDO_USER:-}" ]; then
            sudo -u "$SUDO_USER" npm config set prefix "$USER_HOME/.local" 2>/dev/null || \
                warn "Optional npm user-prefix configuration was not applied."
        else
            npm config set prefix "$USER_HOME/.local" 2>/dev/null || \
                warn "Optional npm user-prefix configuration was not applied."
        fi
    fi

    repair_managed_ownership \
        "$USER_HOME/.config/gh/config.yml" \
        "$USER_HOME/.config/niri" \
        "$USER_HOME/.config/noctalia/config.toml" \
        "$USER_HOME/.config/kitty" \
        "$USER_HOME/.config/antigravity" \
        "$USER_HOME/.codex/config.toml" \
        "$USER_HOME/.config/starship.toml" \
        "$USER_HOME/.zshrc" \
        "$USER_HOME/.zimrc" \
        "$USER_HOME/.config/zellij" \
        "$USER_HOME/.config/nvim" \
        "$USER_HOME/.config/fcitx5/config" \
        "$USER_HOME/.config/fcitx5/profile" \
        "$USER_HOME/.config/fcitx5/conf/bamboo.conf" \
        "$USER_HOME/.config/fcitx5/conf/classicui.conf" \
        "$USER_HOME/.gitconfig" \
        "$USER_HOME/.gitconfig-1bitlab" \
        "$USER_HOME/.config/git/ignore" \
        "$USER_HOME/.ssh/config" \
        "$USER_HOME/.config/fastfetch/config.jsonc" \
        "$USER_HOME/.config/yazi/keymap.toml" \
        "$USER_HOME/.config/yazi/yazi.toml" \
        "$USER_HOME/.config/warpd/config" \
        "$USER_HOME/.local/share/applications/jira.desktop" \
        "$USER_HOME/.local/share/icons/hicolor/scalable/apps/jira.svg" \
        "$USER_HOME/.local/bin/pj" \
        "$USER_HOME/.local/bin/flakify" \
        "$USER_HOME/.local/bin/vault" \
        "$USER_HOME/.local/bin/secrets" \
        "$USER_HOME/.local/bin/jira-app" \
        "$USER_HOME/.local/bin/rebuild" \
        "$USER_HOME/.local/bin/sync-theme" \
        "$USER_HOME/.local/bin/screenshot" \
        "$USER_HOME/.local/bin/doctor" \
        "$USER_HOME/.local/bin/dotfiles-check" \
        "$USER_HOME/.local/bin/tunnel" \
        "$USER_HOME/.local/bin/cleanup" \
        "$USER_HOME/.local/bin/init-9router" \
        "$USER_HOME/.local/bin/9router-init" \
        "$USER_HOME/.local/bin/init-agency" \
        "$USER_HOME/.local/bin/agency-init" \
        "$USER_HOME/.local/bin/ninerouter-token" \
        "$USER_HOME/.local/bin/init-omniroute" \
        "$USER_HOME/.local/bin/sync-omniroute" \
        "$USER_HOME/.local/bin/reconcile-ai-gateways" \
        "$USER_HOME/.local/bin/ai-skills" \
        "$USER_HOME/.local/bin/add-skills" \
        "$USER_HOME/.local/bin/kanata-recovery"
    success "Configuration files linked successfully!"
}
