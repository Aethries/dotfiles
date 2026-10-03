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

# Install default tools defined in ~/.config/mise/config.toml
log "Installing default runtimes configured in ~/.config/mise/config.toml"
mise install --yes || warn "mise install encountered warnings or incomplete downloads"

# Global npm packages
NODE_PACKAGES_FILE="$DOTFILES/packages/node.txt"
if [[ -f "$NODE_PACKAGES_FILE" ]]; then
	log "Installing npm packages from packages/node.txt via mise"

	mapfile -t packages < <(
		grep -vE '^\s*(#|$)' "$NODE_PACKAGES_FILE"
	)

	if [[ "${#packages[@]}" -gt 0 ]]; then
		mise exec -- npm install -g "${packages[@]}" 2>/dev/null || warn "Failed to install some npm packages via mise"
		mise reshim 2>/dev/null || true
		success "Global npm packages installed: ${packages[*]}"
	else
		success "packages/node.txt is empty"
	fi
fi

# Configure capability on Node.js binary for MITM port 443 binding without root (for 9router)
NODE_BIN="$(mise which node 2>/dev/null || command -v node 2>/dev/null || true)"
if [[ -n "$NODE_BIN" ]] && command_exists setcap; then
	RESOLVED_NODE="$(readlink -f "$NODE_BIN")"
	if [[ -f "$RESOLVED_NODE" ]]; then
		log "Configuring network capabilities for Node.js: $RESOLVED_NODE"
		if sudo -n true 2>/dev/null; then
			sudo -n setcap 'cap_net_bind_service=+ep' "$RESOLVED_NODE" 2>/dev/null && success "cap_net_bind_service capability configured" || warn "Failed to set cap_net_bind_service on node binary"
		else
			warn "Sudo session not active; run 'sudo setcap cap_net_bind_service=+ep $RESOLVED_NODE' if 9router port 443 binding is needed"
		fi
	fi
fi

success "mise & uv runtime setup completed"
