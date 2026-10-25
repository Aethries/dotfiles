#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up mise & uv runtime management"

mkdir -p "$HOME/.config/mise"

# Link global mise config
link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/.config/mise/config.toml"

# Verify mise installation
if ! command_exists mise; then
	warn "mise is not installed in PATH. Install via 'sudo pacman -S mise uv' or run ./install.sh"
	exit 0
fi

# Clean up incompatible prefix/globalconfig in ~/.npmrc that breaks version managers
if [[ -f "$HOME/.npmrc" ]]; then
	sed -i -E '/^\s*(prefix|globalconfig)\s*=/d' "$HOME/.npmrc"
fi

# Install & update default tools defined in ~/.config/mise/config.toml
log "Installing and updating runtimes configured in ~/.config/mise/config.toml to latest"
mise install --yes || warn "mise install encountered warnings or incomplete downloads"
mise upgrade --yes || warn "mise upgrade encountered warnings"

# Global npm packages
NODE_PACKAGES_FILE="$DOTFILES/packages/node.txt"
if [[ -f "$NODE_PACKAGES_FILE" ]]; then
	log "Installing and updating npm packages from packages/node.txt via mise"

	mapfile -t packages < <(
		grep -vE '^\s*(#|$)' "$NODE_PACKAGES_FILE"
	)

	if [[ "${#packages[@]}" -gt 0 ]]; then
		if mise exec -- npm install -g "${packages[@]}" 2>/dev/null; then
			mise reshim 2>/dev/null || true
			success "Global npm packages installed: ${packages[*]}"
		else
			warn "Failed to install some npm packages via mise"
		fi
	else
		success "packages/node.txt is empty"
	fi
fi

success "mise & uv runtime setup completed"
