#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Kanata Keyboard Remapper"

mkdir -p "$HOME/.config/kanata"
mkdir -p "$HOME/.config/systemd/user"

# Link configuration
link_file \
	"$MODULE_DIR/files/kanata.kbd" \
	"$HOME/.config/kanata/kanata.kbd"

# Link systemd user service
link_file \
	"$MODULE_DIR/files/kanata.service" \
	"$HOME/.config/systemd/user/kanata.service"

# Link Warpd configuration & helper
mkdir -p "$HOME/.config/warpd"
mkdir -p "$HOME/.local/bin"

link_file \
	"$MODULE_DIR/files/config" \
	"$HOME/.config/warpd/config"

# Also symlink warpd.conf for backward compatibility
ln -sf "$HOME/.config/warpd/config" "$HOME/.config/warpd/warpd.conf"

link_file \
	"$MODULE_DIR/files/warpd-hint" \
	"$HOME/.local/bin/warpd-hint"

chmod +x "$MODULE_DIR/files/warpd-hint"
chmod +x "$HOME/.local/bin/warpd-hint" 2>/dev/null || true

# Install udev rule for uinput if sudo permissions are available
UDEV_TARGET="/etc/udev/rules.d/99-kanata.rules"
if [[ -f "$MODULE_DIR/files/99-kanata.rules" ]]; then
	if [[ ! -f "$UDEV_TARGET" ]]; then
		if command_exists sudo; then
			if sudo -n true 2>/dev/null; then
				sudo cp "$MODULE_DIR/files/99-kanata.rules" "$UDEV_TARGET"
				sudo groupadd -f uinput
				sudo usermod -aG input,uinput "$USER" 2>/dev/null || true
				sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=uinput 2>/dev/null || true
				success "uinput udev rules installed and groups configured"
			else
				warn "sudo requires password to install $UDEV_TARGET"
				warn "Run manually: sudo cp $MODULE_DIR/files/99-kanata.rules $UDEV_TARGET && sudo groupadd -f uinput && sudo usermod -aG input,uinput \$USER"
			fi
		fi
	fi
fi

# Enable and start user service if kanata binary is present
if command_exists systemctl; then
	systemctl --user daemon-reload
	if command_exists kanata; then
		systemctl --user enable kanata.service
		systemctl --user restart kanata.service || true
		success "kanata.service enabled and started"
	else
		warn "kanata binary not found. Install via: yay -S kanata-bin"
	fi
fi

# Check warpd status
if ! command_exists warpd && [[ ! -x "$HOME/.local/bin/warpd" ]]; then
	warn "warpd binary not found. Install via: yay -S warpd-git"
else
	success "warpd is installed"
fi

success "Kanata & Warpd configuration completed"
