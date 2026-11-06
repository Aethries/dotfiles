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

	# Only install packages whose dependencies/provides are not already satisfied
	local missing_packages=()
	for pkg in "${packages[@]}"; do
		if ! pacman -T "$pkg" >/dev/null 2>&1; then
			missing_packages+=("$pkg")
		fi
	done

	if [[ "${#missing_packages[@]}" -eq 0 ]]; then
		success "All pacman packages are already satisfied"
		return
	fi

	log "Installing ${#missing_packages[@]} missing pacman package(s)..."
	sudo pacman -Syu --needed --noconfirm "${missing_packages[@]}"
	success "Pacman packages installed"
}

# AUR 
install_aur_packages() {
	log "Installing and updating AUR packages"

	if ! command_exists yay; then
		error "yay is not installed"
	fi

	read_packages "$PACKAGES/aur.txt"
	if [[ "${#packages[@]}" -eq 0 ]]; then
		success "AUR packages list is empty"
		return
	fi

	# Filter out already installed packages (or satisfied provides / bin variants / custom prefixes)
	local missing_packages=()
	for pkg in "${packages[@]}"; do
		local alt_bin="${pkg%-bin}"
		local alt_src="${pkg}-bin"
		# Skip if bibata cursor is already installed (including local illogical-impulse variants)
		if [[ "$pkg" == "bibata-cursor-theme" ]] && (pacman -Q 2>/dev/null | grep -qi "bibata" || [[ -d "/usr/share/icons/Bibata-Modern-Classic" ]]); then
			continue
		fi
		if ! pacman -T "$pkg" >/dev/null 2>&1 && \
		   ! pacman -Q "$pkg" >/dev/null 2>&1 && \
		   ! pacman -Q "$alt_bin" >/dev/null 2>&1 && \
		   ! pacman -Q "$alt_src" >/dev/null 2>&1; then
			missing_packages+=("$pkg")
		fi
	done

	local failed_packages=()
	if [[ "${#missing_packages[@]}" -gt 0 ]]; then
		log "Found ${#missing_packages[@]} missing AUR package(s): ${missing_packages[*]}"
		for pkg in "${missing_packages[@]}"; do
			log "Installing AUR package: $pkg"
			if ! yay -S --needed --noconfirm --sudoloop "$pkg"; then
				warn "Failed to install AUR package '$pkg', continuing with next package"
				failed_packages+=("$pkg")
			fi
		done
	fi

	if [[ "${#failed_packages[@]}" -gt 0 ]]; then
		error "Failed to install AUR package(s): ${failed_packages[*]}"
	fi

	log "Upgrading AUR packages to latest"
	yay -Sua --noconfirm --sudoloop || warn "AUR upgrade encountered warnings"

	success "AUR package installation and upgrade completed"
}

# Main
install_pacman_packages
install_aur_packages
