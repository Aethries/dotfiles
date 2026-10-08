#!/usr/bin/env bash

set -euo pipefail

# Ensure system binaries (/usr/bin) take precedence over user shims (mise, asdf) during package builds
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
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
		success "pacman packages list is empty"
		return
	fi

	sudo pacman -Syu --needed --noconfirm "${packages[@]}"
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
		success "AUR packages list is empty"
		return
	fi

	# Filter out already installed packages to prevent excessive AUR RPC requests and rate limiting
	local missing_packages=()
	for pkg in "${packages[@]}"; do
		if ! pacman -Q "$pkg" >/dev/null 2>&1; then
			missing_packages+=("$pkg")
		fi
	done

	if [[ "${#missing_packages[@]}" -eq 0 ]]; then
		success "All AUR packages are already installed"
		return
	fi

	log "Found ${#missing_packages[@]} missing AUR package(s): ${missing_packages[*]}"
	local failed_packages=()
	for pkg in "${missing_packages[@]}"; do
		log "Installing AUR package: $pkg"
		if ! yay -S --needed --noconfirm --sudoloop "$pkg"; then
			warn "Failed to install AUR package '$pkg', continuing with next package"
			failed_packages+=("$pkg")
		fi
	done

	if [[ "${#failed_packages[@]}" -gt 0 ]]; then
		error "Failed to install AUR package(s): ${failed_packages[*]}"
	fi

	success "AUR package installation completed"
}

# Main
install_pacman_packages
install_aur_packages
