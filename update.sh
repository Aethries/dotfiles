#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

log "==> Starting Dotfiles & System Update <=="

# 1. Pull latest dotfiles changes if git repository is clean
if [[ -d "$DOTFILES/.git" ]]; then
	if git -C "$DOTFILES" diff-index --quiet HEAD -- 2>/dev/null; then
		log "Pulling latest changes from Git..."
		git -C "$DOTFILES" pull --rebase || warn "Git pull encountered issues, continuing..."
	else
		warn "Dotfiles repository has uncommitted changes; skipping git pull"
	fi
fi

# 2. Update System & AUR Packages
log "Updating Pacman & AUR packages..."
bash "$SCRIPTS/packages.sh"

# 3. Update Runtimes (mise) if available
if command_exists mise; then
	log "Updating mise tools and plugins..."
	mise upgrade --yes || true
fi

# 4. Run Doctor Check
log "Running dotfiles health check..."
bash "$SCRIPTS/doctor.sh"

success "==> System & Dotfiles successfully updated! <=="
