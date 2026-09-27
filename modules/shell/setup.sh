#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname $"${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log "Setting up shell"

# Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
	log "Installing oh my zsh"
	git clone https://github.com/ohmyzsh/ohmyzsh.git \
		"$HOME/.oh-my-zsh"

	success "Oh My Zsh Installed"
else 
	success "Oh My Zsh already installed"
fi

mkdir -p "$ZSH_CUSTOM/plugins"

# autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions"  ]]; then
	log "Installing zsh-autosuggestions"

	git clone https://github.com/zsh-users/zsh-autosuggestions.git \
		"$ZSH_CUSTOM/plugins/zsh-autosuggestions"

	success "zsh-autosuggestions installed"
else
	success "zsh-autosuggestions already installed"
fi

# syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"  ]]; then
	log "Installing zsh-syntax-highlighting"

	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
		"$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

	success "zsh-syntax-highlighting installed"
else
	success "zsh-syntax-highlighting already installed"
fi


# Config
link_file \
	"$MODULE_DIR/files/.zshrc" \
	"$HOME/.zshrc"

link_file \
	"$MODULE_DIR/files/starship.toml" \
	"$HOME/.config/starship.toml"

link_file \
	"$MODULE_DIR/files/yazi.toml" \
	"$HOME/.config/yazi/yazi.toml"

success "Shell configured"
