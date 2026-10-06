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

for flag_target in \
	"$HOME/.config/electron-flags.conf" \
	"$HOME/.config/code-flags.conf" \
	"$HOME/.config/antigravity-ide-flags.conf" \
	"$HOME/.config/obsidian/user-flags.conf" \
	"$HOME/.config/bks-flags.conf"; do
	link_file "$MODULE_DIR/files/electron-flags.conf" "$flag_target"
done

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

link_file \
	"$MODULE_DIR/files/gtk-3.0/settings.ini" \
	"$HOME/.config/gtk-3.0/settings.ini"

link_file \
	"$MODULE_DIR/files/gtk-4.0/settings.ini" \
	"$HOME/.config/gtk-4.0/settings.ini"

mkdir -p "$HOME/.icons/default"
link_file \
	"$MODULE_DIR/files/icons/default/index.theme" \
	"$HOME/.icons/default/index.theme"

# Ensure cursor themes exist in ~/.local/share/icons
setup_cursor_themes() {
	local icons_dir="$HOME/.local/share/icons"
	mkdir -p "$icons_dir"

	# Bibata cursors
	if [[ ! -d "$icons_dir/Bibata-Modern-Classic" || ! -d "$icons_dir/Bibata-Modern-Ice" || ! -d "$icons_dir/Bibata-Modern-Amber" ]]; then
		log "Downloading Bibata cursor themes..."
		local tmp_dir
		tmp_dir="$(mktemp -d)"
		curl -sSL -o "$tmp_dir/bibata-classic.tar.xz" "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz" 2>/dev/null && \
			tar -xf "$tmp_dir/bibata-classic.tar.xz" -C "$icons_dir" 2>/dev/null || true
		curl -sSL -o "$tmp_dir/bibata-ice.tar.xz" "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz" 2>/dev/null && \
			tar -xf "$tmp_dir/bibata-ice.tar.xz" -C "$icons_dir" 2>/dev/null || true
		curl -sSL -o "$tmp_dir/bibata-amber.tar.xz" "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Amber.tar.xz" 2>/dev/null && \
			tar -xf "$tmp_dir/bibata-amber.tar.xz" -C "$icons_dir" 2>/dev/null || true
		rm -rf "$tmp_dir"
	fi

	# Catppuccin cursors
	if [[ ! -d "$icons_dir/catppuccin-mocha-dark-cursors" || ! -d "$icons_dir/catppuccin-latte-light-cursors" ]]; then
		log "Downloading Catppuccin cursor themes..."
		local tmp_dir
		tmp_dir="$(mktemp -d)"
		curl -sSL -o "$tmp_dir/catppuccin-mocha.zip" "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-dark-cursors.zip" 2>/dev/null && \
			unzip -q -o "$tmp_dir/catppuccin-mocha.zip" -d "$icons_dir" 2>/dev/null || true
		curl -sSL -o "$tmp_dir/catppuccin-latte.zip" "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-latte-light-cursors.zip" 2>/dev/null && \
			unzip -q -o "$tmp_dir/catppuccin-latte.zip" -d "$icons_dir" 2>/dev/null || true
		rm -rf "$tmp_dir"
	fi
}
setup_cursor_themes

# Inject into active user session
if [[ -f "$MODULE_DIR/files/00-wayland.conf" ]]; then
	set -a
	# shellcheck disable=SC1090
	source "$MODULE_DIR/files/00-wayland.conf"
	set +a
fi

if command_exists systemctl; then
	systemctl --user import-environment PATH QT_USE_PORTAL QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION QT_AUTO_SCREEN_SCALE_FACTOR ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND QT_QPA_PLATFORM GDK_BACKEND CLUTTER_BACKEND SDL_VIDEODRIVER XMODIFIERS QT_IM_MODULE XCURSOR_THEME XCURSOR_SIZE GTK_THEME 2>/dev/null || true
fi

if command_exists dbus-update-activation-environment; then
	dbus-update-activation-environment --systemd PATH QT_USE_PORTAL QT_QPA_PLATFORMTHEME QT_WAYLAND_DISABLE_WINDOWDECORATION QT_AUTO_SCREEN_SCALE_FACTOR ELECTRON_OZONE_PLATFORM_HINT MOZ_ENABLE_WAYLAND QT_QPA_PLATFORM GDK_BACKEND CLUTTER_BACKEND SDL_VIDEODRIVER XMODIFIERS QT_IM_MODULE XCURSOR_THEME XCURSOR_SIZE GTK_THEME 2>/dev/null || true
fi

# Configure GNOME interface typography, dark mode & cursor for GTK/Portal
if command_exists gsettings; then
	gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
	gsettings set org.gnome.desktop.interface cursor-theme "${XCURSOR_THEME:-catppuccin-latte-light-cursors}" 2>/dev/null || true
	gsettings set org.gnome.desktop.interface cursor-size "${XCURSOR_SIZE:-24}" 2>/dev/null || true
fi

success "Session Environment and Portal configured"
