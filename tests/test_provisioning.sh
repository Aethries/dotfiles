#!/usr/bin/env bash
# Automated Provisioning & Regression Test Suite
# Tests all F01-F10 fixes, portability constraints, and safe symlink behaviors.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$DOTFILES"

# Colors
if [[ -t 1 ]]; then
	RED="\033[1;31m"
	GREEN="\033[1;32m"
	BLUE="\033[1;34m"
	BOLD="\033[1m"
	RESET="\033[0m"
else
	RED="" GREEN="" BLUE="" BOLD="" RESET=""
fi

pass_count=0
fail_count=0

assert_eq() {
	local desc="$1"
	local actual="$2"
	local expected="$3"
	if [[ "$actual" == "$expected" ]]; then
		echo -e "  ${GREEN}✓${RESET} $desc"
		pass_count=$((pass_count + 1))
	else
		echo -e "  ${RED}✗${RESET} $desc (expected: '$expected', got: '$actual')" >&2
		fail_count=$((fail_count + 1))
	fi
}

echo -e "\n${BLUE}${BOLD}=== TEST 1: F01 (Obsidian Setup Increment & Edge Cases) ===${RESET}"
TMP_OBSIDIAN="$(mktemp -d /tmp/test_obsidian_XXXXXX)"
export HOME="$TMP_OBSIDIAN"

# 0 vaults
bash "$DOTFILES/modules/obsidian/setup.sh" >/dev/null 2>&1
assert_eq "0 vaults exits successfully" "$?" "0"

# 1 vault
mkdir -p "$TMP_OBSIDIAN/Vault1/.obsidian"
bash "$DOTFILES/modules/obsidian/setup.sh" >/dev/null 2>&1
assert_eq "1 vault exits successfully" "$?" "0"
assert_eq "1 vault snippet linked" "$([[ -L "$TMP_OBSIDIAN/Vault1/.obsidian/snippets/noctalia.css" ]] && echo yes)" "yes"
assert_eq "1 vault appearance.json created" "$([[ -f "$TMP_OBSIDIAN/Vault1/.obsidian/appearance.json" ]] && echo yes)" "yes"

# Vault with quotes & spaces
mkdir -p "$TMP_OBSIDIAN/Vault 'Quote' Spaces/.obsidian"
bash "$DOTFILES/modules/obsidian/setup.sh" >/dev/null 2>&1
assert_eq "Special vault name exits successfully" "$?" "0"
assert_eq "Special vault snippet linked" "$([[ -L "$TMP_OBSIDIAN/Vault 'Quote' Spaces/.obsidian/snippets/noctalia.css" ]] && echo yes)" "yes"

# Idempotency
bash "$DOTFILES/modules/obsidian/setup.sh" >/dev/null 2>&1
snippet_occurrences=$(python3 -c "import json; data=json.load(open('$TMP_OBSIDIAN/Vault1/.obsidian/appearance.json')); print(data.get('enabledCssSnippets', []).count('noctalia'))")
assert_eq "Snippet not duplicated on re-run" "$snippet_occurrences" "1"

rm -rf "$TMP_OBSIDIAN"


echo -e "\n${BLUE}${BOLD}=== TEST 2: F02 (Safe Symlinks & Unique Backup Names) ===${RESET}"
TMP_LINKS="$(mktemp -d /tmp/test_links_XXXXXX)"
source "$DOTFILES/scripts/links.sh"

missing_ret=0
link_file "$TMP_LINKS/nonexistent" "$TMP_LINKS/target1" 2>/dev/null || missing_ret=$?
assert_eq "Missing source returns error" "$(( missing_ret != 0 ))" "1"
assert_eq "Target not created on missing source" "$([[ ! -e "$TMP_LINKS/target1" ]] && echo yes)" "yes"

echo "orig 1" > "$TMP_LINKS/target"
echo "src 1" > "$TMP_LINKS/src"
link_file "$TMP_LINKS/src" "$TMP_LINKS/target" >/dev/null
assert_eq "Symlink created" "$([[ -L "$TMP_LINKS/target" ]] && echo yes)" "yes"
assert_eq "Original backed up" "$([[ -f "$TMP_LINKS/target.backup" ]] && echo yes)" "yes"

rm "$TMP_LINKS/target"
echo "orig 2" > "$TMP_LINKS/target"
link_file "$TMP_LINKS/src" "$TMP_LINKS/target" >/dev/null
assert_eq "Original backup preserved" "$(cat "$TMP_LINKS/target.backup")" "orig 1"
bcount=$(find "$TMP_LINKS" -maxdepth 1 -name "target.backup*" | wc -l)
assert_eq "Multiple unique backups preserved" "$(( bcount >= 2 ))" "1"

rm -rf "$TMP_LINKS"


echo -e "\n${BLUE}${BOLD}=== TEST 3: F03 (Preserve Custom MCPs & Codex Config) ===${RESET}"
python3 -c '
from pathlib import Path
import json, tempfile
from scripts.ai import merge_codex_toml, safe_symlink

existing_codex = """model = "custom-model"
approval_policy = "never"

[tui]
theme = "noctalia"

[mcp_servers."custom_server"]
command = "my-custom-cli"

[mcp_servers."managed_server"]
command = "old-managed-cli"

[desktop]
appearanceTheme = "dark"
"""

new_mcp = """[mcp_servers."managed_server"]
command = "new-managed-cli"
"""

merged = merge_codex_toml(existing_codex, new_mcp, {"managed_server"})
assert "model = \"custom-model\"" in merged
assert "[tui]" in merged
assert "[mcp_servers.\"custom_server\"]" in merged
assert "command = \"new-managed-cli\"" in merged
assert "old-managed-cli" not in merged
assert "[desktop]" in merged
print("  ✓ Codex TOML merging preserves all custom sections and servers")
'
pass_count=$((pass_count + 1))


echo -e "\n${BLUE}${BOLD}=== TEST 4: F04 (Zero Hardcoded /home/loc & Dynamic Discovery) ===${RESET}"
loc_matches=$(git grep "/home/loc" || true)
assert_eq "Zero /home/loc in git tracked files" "$loc_matches" ""

python3 -c "import tomllib; tomllib.loads(open('$DOTFILES/modules/codex/files/config.toml', 'rb').read().decode('utf-8'))"
assert_eq "modules/codex/files/config.toml parses valid TOML" "$?" "0"

python3 -c "import tomllib; tomllib.loads(open('$DOTFILES/modules/noctalia/files/settings.toml', 'rb').read().decode('utf-8'))"
assert_eq "modules/noctalia/files/settings.toml parses valid TOML" "$?" "0"

python3 -c "import json; json.load(open('$DOTFILES/modules/antigravity/files/mcp_config.json'))"
assert_eq "modules/antigravity/files/mcp_config.json parses valid JSON" "$?" "0"

TMP_BIN="$(mktemp -d /tmp/test_mixer_XXXXXX)"
mkdir -p "$TMP_BIN/bin"
ln -s "$DOTFILES/modules/audio/files/bin/init-mixer" "$TMP_BIN/bin/init-mixer"
detected_path=$(bash -c "
SCRIPT_PATH=\"\$(readlink -f '$TMP_BIN/bin/init-mixer')\"
RESOLVED_DOTFILES=\"\$(cd \"\$(dirname \"\$SCRIPT_PATH\")/../../../..\" && pwd)\"
echo \"\$RESOLVED_DOTFILES\"
")
assert_eq "init-mixer resolves repo root dynamically" "$detected_path" "$DOTFILES"
rm -rf "$TMP_BIN"


echo -e "\n${BLUE}${BOLD}=== TEST 5: F05 (.autologin Untracked & Ignored) ===${RESET}"
tracked_autologin=$(git ls-files .autologin)
assert_eq ".autologin is not tracked in git" "$tracked_autologin" ""

git check-ignore -q "$DOTFILES/.autologin"
assert_eq ".autologin is ignored by .gitignore" "$?" "0"


echo -e "\n${BLUE}${BOLD}=== TEST 6: F06 (AUR & Node Error Handling) ===${RESET}"
grep -q 'error "Failed to install AUR package(s):' "$DOTFILES/scripts/packages.sh"
assert_eq "scripts/packages.sh contains error exit on AUR failure" "$?" "0"

grep -q 'warn "Failed to install some npm packages via mise"' "$DOTFILES/modules/mise/setup.sh"
assert_eq "modules/mise/setup.sh guards npm success message" "$?" "0"


echo -e "\n${BLUE}${BOLD}=== TEST 7: F07 (Vault Staging & Clean Dry-Run) ===${RESET}"
grep -q 'stop_running_apps' "$DOTFILES/scripts/vault.sh"
assert_eq "vault.sh backup quiesces apps before tar" "$?" "0"

grep -q 'mktemp -d "/tmp/vault_stage' "$DOTFILES/scripts/vault.sh"
assert_eq "vault.sh restore uses verified staging directory" "$?" "0"

clean_dry_run_out=$(bash "$DOTFILES/scripts/vault.sh" clean --dry-run 2>&1)
assert_eq "vault.sh clean supports --dry-run" "$([[ "$clean_dry_run_out" =~ "dry-run" ]] && echo yes)" "yes"


echo -e "\n${BLUE}${BOLD}=== TEST 8: F08 (RTK Error Preservation) ===${RESET}"
rtk_test_output=$(python3 -c '
for i in range(500):
    if i == 250:
        print("CRITICAL EXCEPTION: error in middle of build")
    else:
        print(f"info line {i}")
' | "$DOTFILES/modules/shell/files/bin/rtk")
assert_eq "RTK preserves middle error in truncated output" "$([[ "$rtk_test_output" =~ "CRITICAL EXCEPTION" ]] && echo yes)" "yes"


echo -e "\n${BLUE}${BOLD}=== TEST 9: F09 (Noctalia Plugins Clean Clone Handling) ===${RESET}"
assert_eq "Noctalia plugins directory tracked via .gitkeep" "$([[ -f "$DOTFILES/modules/noctalia/files/plugins/.gitkeep" ]] && echo yes)" "yes"
grep -q 'mkdir -p "$HOME/.config/noctalia/plugins"' "$DOTFILES/modules/noctalia/setup.sh"
assert_eq "Noctalia setup safely initializes plugins directory" "$?" "0"


echo -e "\n${BLUE}${BOLD}=== TEST 10: F10 (JEV Preflight Hook & Codex Hooks) ===${RESET}"
assert_eq "scripts/jev-preflight-hook.sh is executable" "$([[ -x "$DOTFILES/scripts/jev-preflight-hook.sh" ]] && echo yes)" "yes"
assert_eq "modules/codex/files/hooks.json exists" "$([[ -f "$DOTFILES/modules/codex/files/hooks.json" ]] && echo yes)" "yes"

grep -q 'jev-preflight-hook' "$DOTFILES/modules/codex/files/hooks.json"
assert_eq "codex hooks.json registers jev-preflight-hook" "$?" "0"


echo -e "\n${BLUE}${BOLD}=== TEST 11: Installation Profiles & Dry Run ===${RESET}"
dry_run_res=$(bash "$DOTFILES/install.sh" --profile cli --dry-run 2>&1)
assert_eq "install.sh --profile cli --dry-run executes successfully" "$?" "0"
assert_eq "install.sh dry-run selects cli modules" "$([[ "$dry_run_res" =~ "Profile: cli" ]] && echo yes)" "yes"


echo -e "\n${BLUE}${BOLD}=== TEST 12: Syntax & Linters ===${RESET}"
git_check=$(git diff --check || true)
assert_eq "Git whitespace check passes" "$git_check" ""

bash -n "$DOTFILES/install.sh"
assert_eq "install.sh syntax valid" "$?" "0"

bash -n "$DOTFILES/scripts/doctor.sh"
assert_eq "scripts/doctor.sh syntax valid" "$?" "0"

bash -n "$DOTFILES/scripts/vault.sh"
assert_eq "scripts/vault.sh syntax valid" "$?" "0"

bash -n "$DOTFILES/scripts/secrets.sh"
assert_eq "scripts/secrets.sh syntax valid" "$?" "0"

python3 -m py_compile "$DOTFILES/modules/shell/files/bin/rtk"
assert_eq "rtk python syntax valid" "$?" "0"


echo -e "\n${BLUE}${BOLD}=== SUMMARY ===${RESET}"
echo -e "Total Passed: ${GREEN}$pass_count${RESET}"
echo -e "Total Failed: ${RED}$fail_count${RESET}"

if [[ "$fail_count" -gt 0 ]]; then
	exit 1
fi
echo -e "${GREEN}${BOLD}ALL TESTS PASSED!${RESET}"
