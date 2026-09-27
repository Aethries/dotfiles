#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGES="$DOTFILES/packages"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

# Helpers
read_packages() {
	local file="$1"

	mapfile -t packages < <(
		grep -vE '^\s*(#|$)' "$file"
	)
}

# Pacman
install_pacman_packages() {
	log "Installing pacman packages"

	read_packages "$PACKAGES/pacman.txt"
	if [[ "${#packages[@]}" -eq 0 ]]; then
		success "pacman packages is emtpy"
		return
	fi

	sudo pacman -S --needed --noconfirm "${packages[@]}"
	success "Pacman packages installed"
}

# AUR 
install_aur_packages() {
	log "Installing AUR packages"

	if ! command_exists yay; then
		error "yay is not installed"
	fi

	read_packages "$PACKAGES/aur.txt"
	if [[ "${#packages[@]}" -eq 0 ]]; then
		success "AUR packages is emtpy"
		return
	fi

	yay -S --needed --noconfirm "${packages[@]}"

	success "AUR packages installed"
}

# Main
install_pacman_packages
install_aur_packages
