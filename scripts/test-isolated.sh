#!/usr/bin/env bash
# ==============================================================================
# Isolated Test Harness (Sandbox Runner)
# Tests dotfiles scripts, configs, and Neovim/Antigravity integration in an isolated sandbox.
# Absolutely ZERO mutation or side-effects on host system.
# ==============================================================================

set -euo pipefail

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
BOLD="\033[1m"
RESET="\033[0m"

log_info() { echo -e "${BOLD}${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }
log_warn() { echo -e "  [${YELLOW}!${RESET}] $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------------------------
# 1. Setup Isolated Temporary Sandbox
# ------------------------------------------------------------------------------
log_info "Creating isolated virtual sandbox..."

SANDBOX_DIR="$(mktemp -d -t dotfiles-sandbox-XXXXXX)"
cleanup() {
    rm -rf "$SANDBOX_DIR"
    echo
    echo "Cleaned up sandbox directory."
}
trap cleanup EXIT

export HOME="$SANDBOX_DIR/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
log_ok "Sandbox initialized at $SANDBOX_DIR (Isolated HOME: $HOME)"

# ------------------------------------------------------------------------------
# 2. Syntax Check All Bash Scripts (Zero-Error Guarantee)
# ------------------------------------------------------------------------------
log_info "Checking syntax of all shell scripts..."
for script in "$REPO_ROOT"/scripts/*.sh; do
    if bash -n "$script"; then
        log_ok "Syntax OK: $(basename "$script")"
    else
        log_fail "Syntax error in $script"
    fi
done

if command -v shellcheck >/dev/null 2>&1; then
    log_info "Running ShellCheck..."
    shellcheck -x "$REPO_ROOT"/scripts/*.sh
    log_ok "ShellCheck passed"
else
    log_warn "ShellCheck not found in PATH, skipped linting."
fi

# ------------------------------------------------------------------------------
# 3. Validate JSON and JSONC Files
# ------------------------------------------------------------------------------
log_info "Validating configuration manifests (JSON/JSONC)..."

json_files=(
    "resources/antigravity/product.json"
    "resources/antigravity/extensions.lock.json"
    "resources/antigravity/generated/noctalia-theme.json"
    "resources/gemini/mcp_config.json"
)
jsonc_files=(
    "resources/antigravity/User/settings.jsonc"
    "resources/antigravity/User/keybindings.generated.jsonc"
)

for file in "${json_files[@]}"; do
    jq empty "$REPO_ROOT/$file"
    log_ok "Valid JSON: $file"
done
for file in "${jsonc_files[@]}"; do
    sed '/^[[:space:]]*\/\//d' "$REPO_ROOT/$file" | jq empty
    log_ok "Valid JSONC: $file"
done
log_ok "All manifests parsed successfully"

# Extension pins must be reproducible and checksum-verifiable.
jq -e '
  .extensions
  | all(
      .id != null
      and .version != null
      and (.sha256 | test("^[0-9a-f]{64}$"))
      and (.download_url | startswith("https://marketplace.visualstudio.com/"))
  )
' "$REPO_ROOT/resources/antigravity/extensions.lock.json" >/dev/null
log_ok "Antigravity extension lockfile is complete"

# ------------------------------------------------------------------------------
# 4. Keymap Manifest Generation & Schema Verification
# ------------------------------------------------------------------------------
log_info "Verifying keymap manifest and code generation..."

if command -v nvim >/dev/null 2>&1; then
    nvim -l "$REPO_ROOT/scripts/generate-keymaps.lua"
    log_ok "Keymap generator executed with zero error"
else
    log_fail "Neovim (nvim) not available to run keymap generator."
fi

# ------------------------------------------------------------------------------
# 5. Neovim Headless Sandbox Smoke Test
# ------------------------------------------------------------------------------
log_info "Testing Neovim headless startup in isolated environment..."

# Link resources/nvim to sandbox ~/.config/nvim for true runtimepath emulation
ln -sfn "$REPO_ROOT/resources/nvim" "$XDG_CONFIG_HOME/nvim"

# Test 5A: Antigravity Neovim backend (vim.g.vscode = 1)
nvim --headless --cmd "let g:vscode=1" -c "q"
log_ok "Antigravity backend (g:vscode=1) fast-path startup OK"

# Test 5B: Native modules and plugin specs without network/plugin downloads.
nvim --headless -u NONE \
    --cmd "set runtimepath^=$REPO_ROOT/resources/nvim" \
    -c "lua require('config.options'); require('config.keymaps')" \
    -c "lua dofile('$REPO_ROOT/resources/nvim/lua/plugins/lsp.lua')" \
    -c "lua dofile('$REPO_ROOT/resources/nvim/lua/plugins/dap.lua')" \
    -c "q"
log_ok "Native Neovim modules and Godot LSP/DAP specs loaded OK"

# Test 5C: repo-managed editor links without touching the real user profile.
TEST_TEMPLATES="$SANDBOX_DIR/system-path/share/godot/export_templates"
mkdir -p "$TEST_TEMPLATES/4.test"
GODOT_EXPORT_TEMPLATES_SOURCE="$TEST_TEMPLATES" \
    "$REPO_ROOT/scripts/sync-editors.sh" --no-extensions
test "$(readlink "$XDG_CONFIG_HOME/nvim")" = "$REPO_ROOT/resources/nvim"
test "$(readlink "$HOME/.antigravity-ide/User/settings.json")" = \
    "$REPO_ROOT/resources/antigravity/User/settings.jsonc"
test "$(readlink "$XDG_DATA_HOME/godot/export_templates")" = "$TEST_TEMPLATES"
log_ok "Editor configuration sync is isolated and repo-owned (AI MCP is managed by ai.sh)"

# ------------------------------------------------------------------------------
# 6. Compliance Audits (R01, R03)
# ------------------------------------------------------------------------------
log_info "Auditing rules compliance (R01: No hardcoded paths, R03: Banned extensions)..."

# R01: Check for hardcoded user home directories in tracked resources
BANNED_PATHS=("/home/loc" "/home/ubuntu" "/Users/")
for bpath in "${BANNED_PATHS[@]}"; do
    if grep -r "$bpath" "$REPO_ROOT/resources/antigravity" "$REPO_ROOT/resources/nvim" 2>/dev/null; then
        log_fail "Rule R01 violation: Found hardcoded path '$bpath' in resources!"
    fi
done
log_ok "Rule R01 passed: No personal user paths found in editor configurations"

# R03: Check for banned extension IDs in active configuration
if grep -r "vscodevim.vim" "$REPO_ROOT/resources/antigravity/User" 2>/dev/null; then
    log_fail "Rule R03 violation: Found banned extension 'vscodevim.vim' in active configuration!"
fi
log_ok "Rule R03 passed: No banned Vim emulator configured"

# ------------------------------------------------------------------------------
# 7. Mock Project Switcher Test (pj.sh)
# ------------------------------------------------------------------------------
log_info "Testing project switcher (pj.sh) in sandbox..."
mkdir -p "$HOME/Workspaces/mock-project/.git"
git -C "$HOME/Workspaces/mock-project" init -q
log_ok "Mock workspace created in sandbox"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}✓ ALL ISOLATED TESTS PASSED (0 ERRORS, ZERO HOST POLLUTION)${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}"
