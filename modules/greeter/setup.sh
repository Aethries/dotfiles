#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"

log "Configuring greeter (greetd -> Hyprland)"

# Deploy greetd configuration
sudo mkdir -p /etc/greetd
if [[ -f /etc/greetd/config.toml && ! -f /etc/greetd/config.toml.bak ]]; then
	sudo cp -a /etc/greetd/config.toml /etc/greetd/config.toml.bak
fi

TARGET_USER="${AUTOLOGIN_USER:-${SUDO_USER:-$USER}}"

write_greetd_config() {
	local autologin="$1"
	local tmp
	tmp="$(mktemp)"

	{
		echo "[terminal]"
		echo "vt = 1"
		echo
		if [[ "$autologin" == "true" ]]; then
			echo "[initial_session]"
			echo "command = \"Hyprland\""
			echo "user = \"$TARGET_USER\""
			echo
		fi
		echo "[default_session]"
		echo "command = \"Hyprland\""
		echo "user = \"$TARGET_USER\""
	} >"$tmp"

	sudo install -m 0644 "$tmp" /etc/greetd/config.toml
	rm -f "$tmp"
}

if [[ "${AUTOLOGIN:-false}" == "true" || -f "$DOTFILES/.autologin" ]]; then
	log "Configuring greetd autologin for user $TARGET_USER"
	write_greetd_config true
else
	log "Configuring greetd to launch Hyprland for user $TARGET_USER"
	write_greetd_config false
fi

# Deploy greetd PAM configuration (auto-unlock gnome-keyring)
if [[ -f /etc/pam.d/greetd && ! -f /etc/pam.d/greetd.bak ]]; then
	sudo cp -a /etc/pam.d/greetd /etc/pam.d/greetd.bak
fi
sudo cp "$MODULE_DIR/files/pam-greetd" /etc/pam.d/greetd

# Enable greetd service
if command_exists systemctl; then
	sudo systemctl enable greetd.service
fi

success "Greeter configured (greetd -> Hyprland)"
