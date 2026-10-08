#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring IdeaVim"

link_file \
	"$MODULE_DIR/files/.ideavimrc" \
	"$HOME/.ideavimrc"

success "IdeaVim configured"
