#!/usr/bin/env bash
# Dotfiles Environment & Health Diagnostics (doctor)
# Read-only health inspection for tools, symlinks, portability, and AI integrations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
if [[ -t 1 ]]; then
	RED="\033[1;31m"
	GREEN="\033[1;32m"
	YELLOW="\033[1;33m"
	BLUE="\033[1;34m"
	BOLD="\033[1m"
	RESET="\033[0m"
else
	RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET=""
fi

pass_count=0
warn_count=0
fail_count=0

report_pass() {
	echo -e "  ${GREEN}✓${RESET} $1"
	pass_count=$((pass_count + 1))
}

report_warn() {
	echo -e "  ${YELLOW}!${RESET} $1"
	warn_count=$((warn_count + 1))
}

report_fail() {
	echo -e "  ${RED}✗${RESET} $1"
	fail_count=$((fail_count + 1))
}

echo -e "\n${BLUE}${BOLD}==> Dotfiles Diagnostic Doctor <==${RESET}"

# 1. Core Tooling & Binaries
echo -e "\n${BOLD}[1/5] Core System & Binaries${RESET}"
CORE_BINS=(bash zsh git python3 node age zstd tar)
for b in "${CORE_BINS[@]}"; do
	if command -v "$b" >/dev/null 2>&1; then
		report_pass "Binary '$b' found: $(command -v "$b")"
	else
		report_fail "Required binary '$b' is missing"
	fi
done

if command -v pacman >/dev/null 2>&1 || command -v yay >/dev/null 2>&1; then
	report_pass "Package manager available ($(command -v yay 2>/dev/null || command -v pacman))"
else
	report_warn "Neither yay nor pacman found (non-Arch platform?)"
fi

if command -v mise >/dev/null 2>&1; then
	report_pass "Runtime manager 'mise' available"
else
	report_warn "'mise' runtime manager not found in PATH"
fi

# 2. Essential Symlinks & Utilities
echo -e "\n${BOLD}[2/5] Symlinks & Local Binaries${RESET}"
AI_UTILS=(rtk jev-mcp jev-preflight-hook)
for u in "${AI_UTILS[@]}"; do
	target="$HOME/.local/bin/$u"
	if [[ -e "$target" ]]; then
		if [[ -L "$target" && ! -e "$(readlink -f "$target")" ]]; then
			report_fail "Broken symlink for utility: $target"
		else
			report_pass "Local utility '$u' ready: $target"
		fi
	else
		report_warn "Local utility '$u' not found in ~/.local/bin"
	fi
done

# Scan ~/.config for dangling symlinks
broken_links=0
if [[ -d "$HOME/.config" ]]; then
	while IFS= read -r broken; do
		[[ -z "$broken" ]] && continue
		report_warn "Dangling symlink: $broken"
		broken_links=$((broken_links + 1))
	done < <(find "$HOME/.config" -maxdepth 2 -xtype l 2>/dev/null || true)
fi
if [[ "$broken_links" -eq 0 ]]; then
	report_pass "No dangling symlinks detected in ~/.config (maxdepth 2)"
fi

# 3. Portability Integrity
echo -e "\n${BOLD}[3/5] Portability & Hardcode Check${RESET}"
tracked_home_loc=$(cd "$DOTFILES" && git grep -n "/home/loc" 2>/dev/null || true)
if [[ -z "$tracked_home_loc" ]]; then
	report_pass "Zero hardcoded '/home/loc' literals in git-tracked source"
else
	report_fail "Found '/home/loc' in git-tracked files:\n$tracked_home_loc"
fi

if (cd "$DOTFILES" && git ls-files .autologin 2>/dev/null | grep -q '^\.autologin$'); then
	report_fail ".autologin is tracked in git index"
else
	report_pass ".autologin is not tracked in git index"
fi

# 4. Configuration Formats
echo -e "\n${BOLD}[4/5] Configuration Syntax & Parsers${RESET}"
if [[ -f "$DOTFILES/modules/codex/files/config.toml" ]]; then
	if python3 -c "import tomllib; tomllib.loads(open('$DOTFILES/modules/codex/files/config.toml', 'rb').read().decode('utf-8'))" 2>/dev/null; then
		report_pass "Codex base config.toml parses valid TOML"
	else
		report_fail "Codex base config.toml has invalid TOML syntax"
	fi
fi

if [[ -f "$DOTFILES/modules/antigravity/files/mcp_config.json" ]]; then
	if python3 -m json.tool "$DOTFILES/modules/antigravity/files/mcp_config.json" >/dev/null 2>&1; then
		report_pass "Antigravity base mcp_config.json parses valid JSON"
	else
		report_fail "Antigravity base mcp_config.json has invalid JSON syntax"
	fi
fi

if [[ -f "$DOTFILES/modules/noctalia/files/settings.toml" ]]; then
	if python3 -c "import tomllib; tomllib.loads(open('$DOTFILES/modules/noctalia/files/settings.toml', 'rb').read().decode('utf-8'))" 2>/dev/null; then
		report_pass "Noctalia base settings.toml parses valid TOML"
	else
		report_fail "Noctalia base settings.toml has invalid TOML syntax"
	fi
fi

# 5. AI Services & Endpoints (Advisory)
echo -e "\n${BOLD}[5/5] AI Endpoints & Integrations (Advisory)${RESET}"
if curl -s --connect-timeout 1 "http://localhost:20128/v1/systemone" >/dev/null 2>&1; then
	report_pass "JEV local gateway responding on port 20128"
else
	report_warn "JEV local gateway not responding on port 20128 (start 9router / JEV if needed)"
fi

if curl -s --connect-timeout 1 "http://127.0.0.1:3111/health" >/dev/null 2>&1; then
	report_pass "Agent Memory backend responding on port 3111"
else
	report_warn "Agent Memory backend not active on port 3111 (optional background service)"
fi

# Summary
echo -e "\n${BLUE}${BOLD}==> Diagnostic Summary <==${RESET}"
echo -e "Passed:   ${GREEN}$pass_count${RESET}"
echo -e "Warnings: ${YELLOW}$warn_count${RESET}"
echo -e "Failures: ${RED}$fail_count${RESET}"

if [[ "$fail_count" -gt 0 ]]; then
	echo -e "\n${RED}Doctor identified $fail_count issue(s) needing resolution.${RESET}"
	exit 1
else
	echo -e "\n${GREEN}Doctor checks passed successfully.${RESET}"
	exit 0
fi
