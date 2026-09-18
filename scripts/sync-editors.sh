#!/usr/bin/env bash

# Synchronize editor configuration and pinned Antigravity extensions from this
# repository. All persistent configuration remains repo-owned through symlinks.

set -euo pipefail

info() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

warn() {
    echo "! $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCK_FILE="$REPO_ROOT/resources/antigravity/extensions.lock.json"
SYNC_EXTENSIONS=true

if [ "${1:-}" = "--no-extensions" ]; then
    SYNC_EXTENSIONS=false
elif [ "$#" -gt 0 ]; then
    echo "Usage: $0 [--no-extensions]" >&2
    exit 2
fi

TARGET_USER="$(id -un)"
TARGET_HOME="$HOME"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

TARGET_CACHE="${XDG_CACHE_HOME:-$TARGET_HOME/.cache}"
TARGET_DATA="${XDG_DATA_HOME:-$TARGET_HOME/.local/share}"

safe_link() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup
        backup="${dest}.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
        mv -- "$dest" "$backup"
        warn "Moved existing $dest to $backup"
    fi
    ln -sfn "$src" "$dest"
}

run_as_target() {
    if [ "$TARGET_USER" != "$(id -un)" ]; then
        sudo -u "$TARGET_USER" env \
            HOME="$TARGET_HOME" \
            XDG_CACHE_HOME="$TARGET_CACHE" \
            XDG_DATA_HOME="$TARGET_DATA" \
            "$@"
    else
        "$@"
    fi
}

info "Synchronizing repo-owned editor configuration"
safe_link "$REPO_ROOT/resources/nvim" "$TARGET_HOME/.config/nvim"
safe_link "$REPO_ROOT/resources/antigravity" "$TARGET_HOME/.config/antigravity"
safe_link \
    "$REPO_ROOT/resources/antigravity/User/settings.jsonc" \
    "$TARGET_HOME/.antigravity-ide/User/settings.json"
safe_link \
    "$REPO_ROOT/resources/antigravity/User/keybindings.generated.jsonc" \
    "$TARGET_HOME/.antigravity-ide/User/keybindings.json"

TEMPLATE_SOURCE="${GODOT_EXPORT_TEMPLATES_SOURCE:-/run/current-system/sw/share/godot/export_templates}"
if [ -d "$TEMPLATE_SOURCE" ]; then
    safe_link "$TEMPLATE_SOURCE" "$TARGET_DATA/godot/export_templates"
else
    warn "Godot export templates are not in the active system profile yet"
fi

if [ "$TARGET_USER" != "$(id -un)" ]; then
    chown -h "$TARGET_USER:" \
        "$TARGET_HOME/.config/nvim" \
        "$TARGET_HOME/.config/antigravity" \
        "$TARGET_HOME/.antigravity-ide/User/settings.json" \
        "$TARGET_HOME/.antigravity-ide/User/keybindings.json"
    chown -R "$TARGET_USER:" "$TARGET_HOME/.antigravity-ide/User" 2>/dev/null || true
fi
success "Neovim, Antigravity, and template links are synchronized"

if [ "$SYNC_EXTENSIONS" = false ]; then
    exit 0
fi

command -v antigravity-ide >/dev/null 2>&1 || {
    warn "Antigravity IDE is not available; extension sync skipped"
    exit 0
}
command -v curl >/dev/null 2>&1 || {
    warn "curl is not available; extension sync skipped"
    exit 0
}
command -v jq >/dev/null 2>&1 || {
    warn "jq is not available; extension sync skipped"
    exit 0
}

info "Synchronizing pinned Antigravity extensions"
EXTENSION_CACHE="$TARGET_CACHE/dotfiles/antigravity-extensions"
mkdir -p "$EXTENSION_CACHE"
if [ "$TARGET_USER" != "$(id -un)" ]; then
    chown -R "$TARGET_USER:" "$EXTENSION_CACHE"
fi

INSTALLED="$(run_as_target antigravity-ide --list-extensions --show-versions 2>/dev/null || true)"
while IFS=$'\t' read -r extension_id version expected_sha download_url; do
    [ -n "$extension_id" ] || continue
    if printf '%s\n' "$INSTALLED" | grep -Fqx "$extension_id@$version"; then
        success "$extension_id@$version is already installed"
        continue
    fi

    vsix="$EXTENSION_CACHE/$extension_id-$version.vsix"
    if [ ! -f "$vsix" ] || [ "$(sha256sum "$vsix" | awk '{print $1}')" != "$expected_sha" ]; then
        # The Visual Studio Marketplace serves VSIX packages with gzip HTTP
        # content encoding. Decode that transport layer so the cached file is
        # the actual ZIP archive expected by Antigravity.
        run_as_target curl --compressed -fL --retry 3 -o "$vsix.part" "$download_url"
        archive_magic="$(od -An -tx1 -N4 "$vsix.part" | tr -d ' \n')"
        if [ "$archive_magic" != "504b0304" ]; then
            rm -f "$vsix.part"
            echo "Invalid VSIX archive for $extension_id@$version (expected ZIP data)" >&2
            exit 1
        fi
        actual_sha="$(sha256sum "$vsix.part" | awk '{print $1}')"
        if [ "$actual_sha" != "$expected_sha" ]; then
            rm -f "$vsix.part"
            echo "Checksum mismatch for $extension_id@$version" >&2
            exit 1
        fi
        mv "$vsix.part" "$vsix"
    fi

    run_as_target antigravity-ide --install-extension "$vsix" --force
    success "Installed $extension_id@$version (SHA-256 verified)"
done < <(jq -r '.extensions[] | select(.required == true) | [.id, .version, .sha256, .download_url] | @tsv' "$LOCK_FILE")

while IFS= read -r banned_id; do
    [ -n "$banned_id" ] || continue
    if printf '%s\n' "$INSTALLED" | grep -Eq "^${banned_id//./\.}(@|$)"; then
        run_as_target antigravity-ide --uninstall-extension "$banned_id"
        warn "Removed banned extension $banned_id"
    fi
done < <(jq -r '.banned_extensions[]' "$LOCK_FILE")

success "Antigravity extensions match the repo lockfile"
