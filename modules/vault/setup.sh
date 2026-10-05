#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up vault and browser credentials integration"

mkdir -p "$HOME/.config"

link_file \
	"$MODULE_DIR/files/chrome-flags.conf" \
	"$HOME/.config/chrome-flags.conf"

# Link Noctalia theme for Chromium / Google Chrome
theme_dir="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/ungoogled-chromium/theme"
if [[ -d "$theme_dir" ]]; then
	mkdir -p "$HOME/.config/google-chrome"
	ln -sfn "$theme_dir" "$HOME/.config/google-chrome/noctalia-theme"
fi

# Link vault CLI
mkdir -p "$HOME/.local/bin"
link_file \
	"$DOTFILES/scripts/vault.sh" \
	"$HOME/.local/bin/vault"
chmod +x "$HOME/.local/bin/vault"

success "Vault integration configured"
