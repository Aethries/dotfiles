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

# fzf-tab
if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
	log "Installing fzf-tab"

	git clone https://github.com/Aloxaf/fzf-tab.git \
		"$ZSH_CUSTOM/plugins/fzf-tab"

	success "fzf-tab installed"
else
	success "fzf-tab already installed"
fi

# you-should-use
if [[ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]]; then
	log "Installing you-should-use"

	git clone https://github.com/MichaelAquilina/zsh-you-should-use.git \
		"$ZSH_CUSTOM/plugins/you-should-use"

	success "you-should-use installed"
else
	success "you-should-use already installed"
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

link_file \
	"$MODULE_DIR/files/yazi/theme.toml" \
	"$HOME/.config/yazi/theme.toml"

link_dir \
	"$MODULE_DIR/files/yazi/flavors" \
	"$HOME/.config/yazi/flavors"

link_file \
	"$MODULE_DIR/files/fastfetch/config.jsonc" \
	"$HOME/.config/fastfetch/config.jsonc"

link_dir \
	"$MODULE_DIR/files/fastfetch/themes" \
	"$HOME/.config/fastfetch/themes"

link_file \
	"$MODULE_DIR/files/lazygit/config.yml" \
	"$HOME/.config/lazygit/config.yml"

link_dir \
	"$MODULE_DIR/files/lazygit/themes" \
	"$HOME/.config/lazygit/themes"

link_dir \
	"$MODULE_DIR/files/fzf/themes" \
	"$HOME/.config/fzf/themes"

link_file \
	"$MODULE_DIR/files/superfile/config.toml" \
	"$HOME/.config/superfile/config.toml"

link_dir \
	"$MODULE_DIR/files/superfile/theme" \
	"$HOME/.config/superfile/theme"

link_file \
	"$MODULE_DIR/files/lazydocker/config.yml" \
	"$HOME/.config/lazydocker/config.yml"

link_file \
	"$MODULE_DIR/files/bat/config" \
	"$HOME/.config/bat/config"

# Link CLI utilities (RTK Ultra, etc.)
if [[ -d "$MODULE_DIR/files/bin" ]]; then
	mkdir -p "$HOME/.local/bin"
	for bin_file in "$MODULE_DIR/files/bin"/*; do
		if [[ -f "$bin_file" ]]; then
			chmod +x "$bin_file"
			link_file "$bin_file" "$HOME/.local/bin/$(basename "$bin_file")"
		fi
	done
fi

success "Shell configured"
