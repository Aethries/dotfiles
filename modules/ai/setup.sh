#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up AI Skills & Tooling"

SKILLS_DIR="$MODULE_DIR/files/skills"
if [[ ! -d "$SKILLS_DIR" ]]; then
	error "Skills directory not found at $SKILLS_DIR"
fi

TARGET_SKILL_DIRS=(
	"$HOME/.gemini/config/skills"
	"$HOME/.gemini/antigravity-cli/skills"
	"$HOME/.gemini/antigravity/skills"
	"$HOME/.codex/skills"
	"$HOME/.claude/skills"
)

# 1. Clean up dangling and obsolete skill symlinks in target skill directories
log "Pruning dangling and unmanaged skill symlinks"
for target_dir in "${TARGET_SKILL_DIRS[@]}"; do
	mkdir -p "$target_dir"
	find "$target_dir" -maxdepth 1 -xtype l -delete 2>/dev/null || true
	for existing in "$target_dir"/*; do
		if [[ -L "$existing" ]]; then
			skill_name="$(basename "$existing")"
			if [[ ! -d "$SKILLS_DIR/$skill_name" ]]; then
				rm -f "$existing"
			fi
		fi
	done
done

# 2. Link all skills from modules/ai/files/skills/
log "Linking skills from $SKILLS_DIR"
skill_count=0
for skill_path in "$SKILLS_DIR"/*; do
	if [[ -d "$skill_path" ]]; then
		skill_name="$(basename "$skill_path")"
		for target_dir in "${TARGET_SKILL_DIRS[@]}"; do
			target="$target_dir/$skill_name"
			if [[ -L "$target" ]]; then
				if [[ "$(readlink -f "$target")" == "$(readlink -f "$skill_path")" ]]; then
					continue
				fi
				rm -f "$target"
			elif [[ -d "$target" ]]; then
				mv "$target" "$target.backup"
			fi
			ln -sf "$skill_path" "$target"
		done
		skill_count=$((skill_count + 1))
	fi
done
success "Linked $skill_count skills to Antigravity and Codex"

# 3. Link AI CLI utilities (rtk)
log "Linking AI CLI utilities to ~/.local/bin"
mkdir -p "$HOME/.local/bin"

if [[ -f "$DOTFILES/modules/shell/files/bin/rtk" ]]; then
	chmod +x "$DOTFILES/modules/shell/files/bin/rtk"
	link_file "$DOTFILES/modules/shell/files/bin/rtk" "$HOME/.local/bin/rtk"
fi

success "AI skills module configured"
