#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

log "Starting dotfiles setup"

# Bootstrap
sudo -v

install_yay() {
	if command_exists yay; then
		success "yay altrady installed"
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
"$SCRIPTS/packages.sh"

# Install Node / NVM / npm
log "Configuring Node.js"
if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
	source /usr/share/nvm/init-nvm.sh
else
	error "NVM is not installed"
fi

nvm install --lts
nvm alias default 'lts/*'

success "Node.js LTS configured"

# ZSH
log "Configuring shell"

zsh_path="$(command -v zsh)"

if [[ "$SHELL" != "$zsh_path" ]]; then
	chsh -s "$zsh_path"
fi

success "Zsh configured"

# Link
"$SCRIPTS/links.sh"

"$DOTFILES/modules/shell/setup.sh"
"$DOTFILES/modules/umbriel/setup.sh"

# Done
success "Dotfiles setup completed"
