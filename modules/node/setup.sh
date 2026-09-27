#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"

log "Setting up Node.js"

# NVM is not compatible with 'set -u'
set +u

# Clean up incompatible prefix/globalconfig settings in ~/.npmrc that break NVM initialization
if [[ -f "$HOME/.npmrc" ]]; then
	sed -i -E '/^\s*(prefix|globalconfig)\s*=/d' "$HOME/.npmrc"
fi

# Initialize NVM
if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
	source /usr/share/nvm/init-nvm.sh
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
	source "$HOME/.nvm/nvm.sh"
else
	set -u
	error "NVM is not installed"
fi

log "Configuring Node.js LTS"
nvm install --lts
nvm use --delete-prefix 'lts/*'
nvm alias default 'lts/*'

set -u
success "Node.js LTS configured"

# Global npm packages
NODE_PACKAGES_FILE="$DOTFILES/packages/node.txt"
if [[ -f "$NODE_PACKAGES_FILE" ]]; then
	log "Installing npm packages from packages/node.txt"

	mapfile -t packages < <(
		grep -vE '^\s*(#|$)' "$NODE_PACKAGES_FILE"
	)

	if [[ "${#packages[@]}" -gt 0 ]]; then
		npm install -g "${packages[@]}"
		success "Global npm packages installed: ${packages[*]}"
	else
		success "packages/node.txt is empty"
	fi
fi

success "Node module setup completed"
