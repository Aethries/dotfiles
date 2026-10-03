#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Session Environment and Portal"

mkdir -p "$HOME/.config/environment.d"

link_file \
	"$MODULE_DIR/files/00-wayland.conf" \
	"$HOME/.config/environment.d/00-wayland.conf"

link_file \
	"$MODULE_DIR/files/mimeapps.list" \
	"$HOME/.config/mimeapps.list"

link_file \
	"$MODULE_DIR/files/electron-flags.conf" \
	"$HOME/.config/electron-flags.conf"

# Inject into active user session
if [[ -f "$MODULE_DIR/files/00-wayland.conf" ]]; then
	set -a
	# shellcheck disable=SC1090
	source "$MODULE_DIR/files/00-wayland.conf"
	set +a
fi

if command_exists systemctl; then
	systemctl --user import-environment PATH QT_USE_PORTAL ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND QT_QPA_PLATFORM GDK_BACKEND CLUTTER_BACKEND SDL_VIDEODRIVER XMODIFIERS QT_IM_MODULE 2>/dev/null || true
fi

if command_exists dbus-update-activation-environment; then
	dbus-update-activation-environment --systemd PATH QT_USE_PORTAL ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND QT_QPA_PLATFORM GDK_BACKEND CLUTTER_BACKEND SDL_VIDEODRIVER XMODIFIERS QT_IM_MODULE 2>/dev/null || true
fi

# Configure GNOME interface dark mode for GTK4/Libadwaita apps
if command_exists gsettings; then
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
fi

success "Session Environment and Portal configured"
