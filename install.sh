#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

log "Starting dotfiles setup"

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
	error "Do not run install.sh as root/sudo! Please run as regular user: ./install.sh"
fi

# Bootstrap sudo credentials and keep alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_LOOP_PID=$!
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true' EXIT

install_yay() {
	if command_exists yay; then
		success "yay already installed"
		yay --version
		return
	fi

	log "Installing bootstrap dependencies"
	sudo pacman -S --noconfirm --needed \
		git \
		curl \
		wget \
		base-devel

	success "Bootstrap dependencies installed"
	log "Installing yay"

	local tmp_dir
	tmp_dir="$(mktemp -d)"

	git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

	(
		cd "$tmp_dir/yay"
		makepkg -si --noconfirm
	)

	rm -rf "$tmp_dir"
	yay --version

	success "yay installed"
}

install_yay
bash "$SCRIPTS/packages.sh"

# ZSH
log "Configuring shell"

zsh_path="$(command -v zsh)"

if [[ "$SHELL" != "$zsh_path" ]]; then
	chsh -s "$zsh_path"
fi

success "Zsh configured"

# Modules setup
bash "$DOTFILES/modules/fonts/setup.sh"
bash "$DOTFILES/modules/fcitx5/setup.sh"
bash "$DOTFILES/modules/shell/setup.sh"
bash "$DOTFILES/modules/zellij/setup.sh"
bash "$DOTFILES/modules/kitty/setup.sh"
bash "$DOTFILES/modules/node/setup.sh"
bash "$DOTFILES/modules/vault/setup.sh"
bash "$DOTFILES/modules/umbriel/setup.sh"
bash "$DOTFILES/modules/greeter/setup.sh"
bash "$DOTFILES/modules/antigravity/setup.sh"

# Done
success "Dotfiles setup completed"
