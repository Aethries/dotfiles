set -euo pipefail

MODULE_DIR="$(cd "$(dirname $"${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Configuring umbriel"

# Umbriel
sudo mkdir -p "$HOME/.config/umbriel"

success "Umbriel configured"

# Config
link_file \
	"$MODULE_DIR/files/config.toml" \
	"$HOME/config/umbriel/config.toml"

link_file \
	"$MODULE_DIR/files/appereance.toml" \
	"$HOME/config/umbriel/appereance.toml"

link_file \
	"$MODULE_DIR/files/keybinds.toml" \
	"$HOME/config/umbriel/keybinds.toml"

link_file \
	"$MODULE_DIR/files/noctalia.toml" \
	"$HOME/config/umbriel/noctalia.toml"
