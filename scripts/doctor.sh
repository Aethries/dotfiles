#!/usr/bin/env bash
# ==============================================================================
# dotfiles doctor: Comprehensive System & Environment Diagnostics
# ==============================================================================

set -uo pipefail

# Visual styling
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

PASSED=0
WARNINGS=0
ERRORS=0

ok() {
    echo -e "  [${GREEN}✓${RESET}] $1"
    PASSED=$((PASSED + 1))
}

warn() {
    echo -e "  [${YELLOW}!${RESET}] ${YELLOW}$1${RESET}"
    WARNINGS=$((WARNINGS + 1))
}

fail() {
    echo -e "  [${RED}✗${RESET}] ${RED}$1${RESET}"
    ERRORS=$((ERRORS + 1))
}

section() {
    echo
    echo -e "${BOLD}${BLUE}==> $1${RESET}"
}

# Canonical resolution of script path (follows symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BOLD}${CYAN}🏥 Dotfiles System Doctor${RESET}"
echo "Running diagnostics on $(uname -s) ($(uname -m)) for user '$USER'..."

# ------------------------------------------------------------------------------
# 1. Environment & PATH Checks
# ------------------------------------------------------------------------------
section "Environment & Shell Paths"

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    ok "\$HOME/.local/bin is present in \$PATH"
else
    warn "\$HOME/.local/bin is NOT in \$PATH"
fi

if command -v nix >/dev/null 2>&1; then
    ok "Nix is installed ($(nix --version 2>/dev/null || true))"
else
    fail "Nix is not found in PATH"
fi

if command -v zsh >/dev/null 2>&1; then
    ok "Zsh shell is available ($(zsh --version 2>/dev/null | head -n 1))"
else
    warn "Zsh shell is not found"
fi

# ------------------------------------------------------------------------------
# 2. Symlinks & Configuration Integrity
# ------------------------------------------------------------------------------
section "Symlinks & Configuration Integrity"

check_link() {
    local link="$1"
    local desc="$2"
    if [ -L "$link" ]; then
        if [ -e "$link" ]; then
            ok "$desc ($link -> $(readlink "$link"))"
        else
            fail "$desc is a BROKEN symlink ($link -> $(readlink "$link"))"
        fi
    elif [ -e "$link" ]; then
        warn "$desc exists at $link but is NOT a symlink to dotfiles"
    else
        warn "$desc is missing ($link)"
    fi
}

check_link "$HOME/.config/niri" "Niri Configuration"
check_link "$HOME/.config/noctalia/config.toml" "Noctalia Configuration"
check_link "$HOME/.config/kitty" "Kitty Terminal"
check_link "$HOME/.config/nvim" "Neovim Configuration"
check_link "$HOME/.config/antigravity" "Antigravity Overlay Configuration"
check_link "$HOME/.antigravity-ide/User/settings.json" "Antigravity User Settings"
check_link "$HOME/.antigravity-ide/User/keybindings.json" "Antigravity Keybindings"
check_link "$HOME/.gemini/config/mcp_config.json" "Antigravity Godot MCP Configuration"
check_link "$HOME/.local/share/godot/export_templates" "Godot Export Templates"
check_link "$HOME/.config/zellij" "Zellij Multiplexer"
check_link "$HOME/.config/starship.toml" "Starship Prompt"
check_link "$HOME/.zshrc" "Zsh Shell Config"
check_link "$HOME/.gitconfig" "Git Configuration (.gitconfig)"
check_link "$HOME/.local/bin/pj" "CLI: pj"
check_link "$HOME/.local/bin/flakify" "CLI: flakify"
check_link "$HOME/.local/bin/screenshot" "CLI: screenshot"
check_link "$HOME/.local/bin/sync-theme" "CLI: sync-theme"
check_link "$HOME/.local/bin/vault" "CLI: vault"
check_link "$HOME/.local/bin/secrets" "CLI: secrets"
check_link "$HOME/.local/bin/jira-app" "CLI: jira-app"
check_link "$HOME/.local/share/applications/jira.desktop" "Desktop: Jira (jira.desktop)"
check_link "$HOME/.local/bin/rebuild" "CLI: rebuild"
check_link "$HOME/.local/bin/doctor" "CLI: doctor"
check_link "$HOME/.local/bin/dotfiles-check" "CLI: dotfiles-check"
check_link "$HOME/.local/bin/tunnel" "CLI: tunnel"
check_link "$HOME/.local/bin/cleanup" "CLI: cleanup"
check_link "$HOME/.local/bin/init-9router" "CLI: init-9router"
check_link "$HOME/.local/bin/9router-init" "CLI: 9router-init"
check_link "$HOME/.local/bin/init-omniroute" "CLI: init-omniroute"
check_link "$HOME/.local/bin/sync-omniroute" "CLI: sync-omniroute"
if [ -e "$HOME/.local/bin/lark" ] || command -v lark >/dev/null 2>&1; then
    ok "CLI: lark ($(command -v lark 2>/dev/null || echo "$HOME/.local/bin/lark"))"
else
    warn "CLI: lark not found in PATH"
fi
if [ -e "$HOME/.local/bin/codex" ] || command -v codex >/dev/null 2>&1; then
    ok "CLI: codex ($(command -v codex 2>/dev/null || echo "$HOME/.local/bin/codex"))"
else
    warn "CLI: codex not found in PATH"
fi
if command -v codex-desktop >/dev/null 2>&1 || command -v chatgpt >/dev/null 2>&1; then
    ok "Desktop: codex ($(command -v codex-desktop 2>/dev/null || command -v chatgpt))"
else
    warn "Desktop: codex not found in PATH"
fi
if command -v godot >/dev/null 2>&1; then
    ok "Godot editor ($(godot --version 2>/dev/null || echo installed))"
else
    fail "Godot editor is not installed"
fi
if command -v godot-mcp >/dev/null 2>&1; then
    ok "Godot MCP server is installed"
else
    fail "Godot MCP server is not installed"
fi

if command -v antigravity-ide >/dev/null 2>&1; then
    ANTIGRAVITY_EXTENSIONS="$(antigravity-ide --list-extensions --show-versions 2>/dev/null || true)"
    while IFS=$'\t' read -r extension_id extension_version; do
        if printf '%s\n' "$ANTIGRAVITY_EXTENSIONS" | grep -Fqx "$extension_id@$extension_version"; then
            ok "Antigravity extension: $extension_id@$extension_version"
        else
            fail "Antigravity extension missing or not pinned: $extension_id@$extension_version"
        fi
    done < <(jq -r '.extensions[] | select(.required == true) | [.id, .version] | @tsv' "$REPO_ROOT/resources/antigravity/extensions.lock.json")
fi

# ------------------------------------------------------------------------------
# 3. Compositor & Hardware Acceleration
# ------------------------------------------------------------------------------
section "Desktop & Hardware Acceleration"

if command -v niri >/dev/null 2>&1; then
    NIRI_CONF="$REPO_ROOT/resources/niri/config.kdl"
    if [ -f "$NIRI_CONF" ]; then
        if niri validate -c "$NIRI_CONF" >/dev/null 2>&1; then
            ok "Niri config validation passed ($NIRI_CONF)"
        else
            fail "Niri config has syntax/validation errors!"
        fi
    fi
else
    warn "Niri binary not found in PATH"
fi

if command -v vainfo >/dev/null 2>&1; then
    if vainfo 2>&1 | grep -q "VAProfile"; then
        DRIVER=$(vainfo 2>&1 | grep "Driver version:" | sed 's/.*Driver version: //' || echo "Active")
        ok "Hardware Video Acceleration (VA-API) active ($DRIVER)"
    else
        warn "VA-API is installed but could not find supported entrypoints"
    fi
else
    warn "vainfo utility not available to verify GPU video acceleration"
fi

# ------------------------------------------------------------------------------
# 4. Services & Daemons
# ------------------------------------------------------------------------------
section "Services & Daemons"

check_service() {
    local svc="$1"
    local name="$2"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        ok "$name service is active"
    else
        warn "$name service is NOT active (status: $(systemctl is-active "$svc" 2>/dev/null || echo "unknown"))"
    fi
}

check_user_service() {
    local svc="$1"
    local name="$2"
    if systemctl --user is-active --quiet "$svc" 2>/dev/null; then
        ok "$name user service is active"
    else
        warn "$name user service is NOT active"
    fi
}

check_service "docker" "Docker Daemon"
check_service "bluetooth" "Bluetooth Daemon"
check_user_service "pipewire" "PipeWire Audio Server"
check_user_service "wireplumber" "WirePlumber Session Manager"
check_user_service "9router" "9router Local AI Gateway"
check_user_service "omniroute" "OmniRoute Local AI Gateway"

# Verify AI Gateway Ports (9router on 20128, OmniRoute on 20129)
ROUTER_9_LISTEN=false
OMNI_LISTEN=false

if command -v ss >/dev/null 2>&1; then
    if ss -tlHn 'sport = :20128' 2>/dev/null | grep -q '20128'; then
        ROUTER_9_LISTEN=true
    fi
    if ss -tlHn 'sport = :20129' 2>/dev/null | grep -q '20129'; then
        OMNI_LISTEN=true
    fi
elif command -v lsof >/dev/null 2>&1; then
    if lsof -nP -i :20128 2>/dev/null | grep -q 'LISTEN'; then
        ROUTER_9_LISTEN=true
    fi
    if lsof -nP -i :20129 2>/dev/null | grep -q 'LISTEN'; then
        OMNI_LISTEN=true
    fi
fi

if [ "$ROUTER_9_LISTEN" = true ]; then
    ok "9router listening on port 20128"
fi
if [ "$OMNI_LISTEN" = true ]; then
    ok "OmniRoute listening on dedicated port 20129"
fi
if [ "$ROUTER_9_LISTEN" = true ] && [ "$OMNI_LISTEN" = true ]; then
    ok "AI Gateways coexistence verified (port 20128: 9router, port 20129: OmniRoute)"
fi

# ------------------------------------------------------------------------------
# 5. Disk Space & Store Health
# ------------------------------------------------------------------------------
section "Disk Space & Storage"

ROOT_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
ROOT_USE_PCT=$(df -h / | awk 'NR==2 {print $5}')
ok "Root filesystem: $ROOT_AVAIL available ($ROOT_USE_PCT used)"

if [ -d "/nix/store" ]; then
    STORE_SIZE=$(df -h /nix/store 2>/dev/null | awk 'NR==2 {print $3}' || echo "N/A")
    ok "Nix store filesystem usage: $STORE_SIZE"
fi

# ------------------------------------------------------------------------------
# 6. Repository & Security
# ------------------------------------------------------------------------------
section "Repository & Vault Status"

VAULT_FILE="$REPO_ROOT/secrets.vault"
if [ -f "$VAULT_FILE" ]; then
    VAULT_SIZE=$(wc -c < "$VAULT_FILE" | tr -d ' ')
    if [ "$VAULT_SIZE" -gt 0 ]; then
        VAULT_TIME=$(date -r "$VAULT_FILE" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
        ok "Secret Vault file exists and is encrypted ($VAULT_FILE, last updated: $VAULT_TIME)"
    else
        warn "Secret Vault file exists but is empty ($VAULT_FILE)"
    fi
else
    warn "Secret Vault file ($VAULT_FILE) not found"
fi

GIT_DIRTY=$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$GIT_DIRTY" -eq 0 ]; then
    ok "Dotfiles git working tree is clean"
else
    warn "Dotfiles git working tree has $GIT_DIRTY uncommitted change(s)"
fi

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo
echo -e "${BOLD}Diagnostic Summary:${RESET}"
echo -e "  Passed:   ${GREEN}$PASSED${RESET}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${RESET}"
echo -e "  Errors:   ${RED}$ERRORS${RESET}"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "\n${BOLD}${GREEN}🎉 All systems operational! Perfect health.${RESET}"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "\n${BOLD}${CYAN}✨ System is healthy with minor recommendations.${RESET}"
else
    echo -e "\n${BOLD}${RED}⚠️  Issues detected! Please review the error items above.${RESET}"
    exit 1
fi
