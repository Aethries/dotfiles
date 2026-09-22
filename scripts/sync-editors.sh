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
FORCE_REPLACE=false
ALLOW_BACKUP=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --no-extensions)
            SYNC_EXTENSIONS=false
            shift
            ;;
        --replace|--force|-f)
            FORCE_REPLACE=true
            shift
            ;;
        --backup|-b)
            ALLOW_BACKUP=true
            shift
            ;;
        *)
            echo "Usage: $0 [--no-extensions] [--replace|--force] [--backup]" >&2
            exit 2
            ;;
    esac
done

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
        if [ "$FORCE_REPLACE" != true ] && [ "$ALLOW_BACKUP" != true ]; then
            warn "Unmanaged non-symlink file/directory exists at '$dest'. Skipping to prevent silent mutation. Use --replace or --backup to update."
            return 0
        fi
        if [ "$ALLOW_BACKUP" = true ]; then
            local backup
            backup="${dest}.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
            mv -- "$dest" "$backup"
            warn "Moved existing $dest to $backup"
        else
            rm -rf -- "$dest"
            warn "Replaced unmanaged $dest (--replace/--force specified)"
        fi
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
    "$REPO_ROOT/resources/antigravity/User/keybindings.jsonc" \
    "$TARGET_HOME/.antigravity-ide/User/keybindings.json"
safe_link \
    "$REPO_ROOT/resources/vscode/User/settings.jsonc" \
    "$TARGET_HOME/.config/Code/User/settings.json"
safe_link \
    "$REPO_ROOT/resources/vscode/User/keybindings.jsonc" \
    "$TARGET_HOME/.config/Code/User/keybindings.json"
safe_link \
    "$REPO_ROOT/resources/gemini/mcp_config.json" \
    "$TARGET_HOME/.gemini/config/mcp_config.json"
safe_link \
    "$REPO_ROOT/resources/gemini/mcp_config.json" \
    "$TARGET_HOME/.gemini/antigravity/mcp_config.json"

if [ -d "$TARGET_HOME/.antigravity-ide/extensions/noctalia.noctaliatheme-0.0.5-universal" ]; then
    safe_link \
        "$TARGET_HOME/.antigravity-ide/extensions/noctalia.noctaliatheme-0.0.5-universal" \
        "$TARGET_HOME/.vscode/extensions/noctalia.noctaliatheme-0.0.5"
fi

if [ -f "$REPO_ROOT/resources/git/ignore" ]; then
    safe_link "$REPO_ROOT/resources/git/ignore" "$TARGET_HOME/.config/git/ignore"
fi

if [ -f "$REPO_ROOT/resources/git/.gitconfig" ]; then
    safe_link "$REPO_ROOT/resources/git/.gitconfig" "$TARGET_HOME/.gitconfig"
fi

if [ -f "$REPO_ROOT/resources/codex/config.toml" ]; then
    safe_link \
        "$REPO_ROOT/resources/codex/config.toml" \
        "$TARGET_HOME/.codex/config.toml"
fi

if [ -x "$REPO_ROOT/scripts/ai-skills.sh" ]; then
    info "Synchronizing global-core AI agent skills"
    "$REPO_ROOT/scripts/ai-skills.sh" sync --profile global-core

    info "Exporting baseline AI orchestration rules for editors"
    RULES_CONTENT="$("$REPO_ROOT/scripts/ai-skills.sh" export-rules)"

    write_rule_file() {
        local target_file="$1"
        mkdir -p "$(dirname "$target_file")"
        if [ -f "$target_file" ] && ! grep -q "<!-- managed-by: Aethries/dotfiles ai-skills -->" "$target_file" 2>/dev/null; then
            if [ "$FORCE_REPLACE" != true ] && [ "$ALLOW_BACKUP" != true ]; then
                warn "Unmanaged rule file exists at '$target_file'. Skipping write to prevent overwriting user edits. Pass --replace or --backup to update."
                return 0
            fi
            if [ "$ALLOW_BACKUP" = true ]; then
                local backup
                backup="${target_file}.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
                mv "$target_file" "$backup"
                warn "Backed up unmanaged existing rule file $target_file to $backup"
            fi
        fi
        echo "$RULES_CONTENT" > "$target_file"
    }

    # 1. Claude Code (CLAUDE.md)
    write_rule_file "$TARGET_HOME/.claude/CLAUDE.md"

    # 2. Neovim (AGENTS.md)
    write_rule_file "$TARGET_HOME/.config/nvim/AGENTS.md"

    # 3. Zed
    write_rule_file "$TARGET_HOME/.config/zed/prompts/AGENTS.md"

    # 4. VSCode / Antigravity IDE
    write_rule_file "$TARGET_HOME/.antigravity-ide/User/prompts/AGENTS.md"
    write_rule_file "$TARGET_HOME/.config/Code/User/prompts/AGENTS.md"
fi

TEMPLATE_SOURCE="${GODOT_EXPORT_TEMPLATES_SOURCE:-/run/current-system/sw/share/godot/export_templates}"
if [ -d "$TEMPLATE_SOURCE" ]; then
    safe_link "$TEMPLATE_SOURCE" "$TARGET_DATA/godot/export_templates"
else
    warn "Godot export templates are not in the active system profile yet"
fi

if [ "$TARGET_USER" != "$(id -un)" ]; then
    for managed_path in \
        "$TARGET_HOME/.config/nvim" \
        "$TARGET_HOME/.config/antigravity" \
        "$TARGET_HOME/.antigravity-ide/User/settings.json" \
        "$TARGET_HOME/.antigravity-ide/User/keybindings.json" \
        "$TARGET_HOME/.antigravity-ide/User/prompts/AGENTS.md" \
        "$TARGET_HOME/.config/Code/User/settings.json" \
        "$TARGET_HOME/.config/Code/User/keybindings.json" \
        "$TARGET_HOME/.config/Code/User/prompts/AGENTS.md" \
        "$TARGET_HOME/.codex/config.toml" \
        "$TARGET_HOME/.vscode/extensions/noctalia.noctaliatheme-0.0.5" \
        "$TARGET_HOME/.gemini/config/mcp_config.json" \
        "$TARGET_HOME/.gemini/antigravity/mcp_config.json" \
        "$TARGET_HOME/.claude/CLAUDE.md" \
        "$TARGET_HOME/.config/nvim/AGENTS.md" \
        "$TARGET_HOME/.config/zed/prompts/AGENTS.md"; do
        [ -e "$managed_path" ] || [ -L "$managed_path" ] || continue
        # REQUIRED: these exact files/symlinks are written by this synchronization run.
        chown -h "$TARGET_USER:" "$managed_path"
    done
fi
success "Neovim, Antigravity, VS Code, Codex, Godot MCP, AI skills and template links are synchronized"

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
    # REQUIRED: this cache subtree is created exclusively by the extension synchronizer.
    chown -R "$TARGET_USER:" "$EXTENSION_CACHE"
fi

INSTALLED="$(run_as_target antigravity-ide --list-extensions --show-versions 2>/dev/null || true)" # OPTIONAL_FEATURE: extension listing is unavailable when the IDE CLI is not ready.
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
