#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Sunshine Remote Desktop"

mkdir -p "$HOME/.config/sunshine"

# Link configuration
link_file \
	"$MODULE_DIR/files/sunshine.conf" \
	"$HOME/.config/sunshine/sunshine.conf"

# Setup udev rule for uinput emulation
UDEV_RULE="/etc/udev/rules.d/85-sunshine-input.rules"
if [[ ! -f "$UDEV_RULE" ]]; then
	if command_exists sudo && sudo -n true 2>/dev/null; then
		sudo tee "$UDEV_RULE" > /dev/null << 'EOF'
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
EOF
		sudo udevadm control --reload-rules
		sudo udevadm trigger --subsystem-match=misc
		success "Sunshine uinput udev rule configured"
	else
		warn "sudo requires password to install $UDEV_RULE"
		warn "Run manually: echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", OPTIONS+=\"static_node=uinput\", TAG+=\"uaccess\"' | sudo tee $UDEV_RULE && sudo usermod -aG input \$USER"
	fi
fi

# Device groups also apply when the udev rule was installed previously.
for device_group in input video render; do
	if ! id -nG "$USER" | tr ' ' '\n' | grep -qx "$device_group"; then
		if command_exists sudo && sudo -n true 2>/dev/null; then
			sudo usermod -aG "$device_group" "$USER"
			warn "Added $USER to $device_group; existing processes keep their old groups until a new session/reboot"
		else
			warn "Run: sudo usermod -aG $device_group $USER"
		fi
	fi
done

# Umbriel uses wlr screencopy, which does not need KMS capabilities.
# Remove the file capabilities granted by the previous setup script.
if command_exists sunshine && command_exists getcap; then
	sunshine_bin="$(command -v sunshine)"
	if [[ "$(getcap "$sunshine_bin")" == *cap_sys_admin* ]]; then
		if command_exists sudo && sudo -n true 2>/dev/null; then
			sudo setcap -r "$sunshine_bin"
			success "Removed legacy Sunshine KMS file capabilities"
		else
			warn "Run: sudo setcap -r $sunshine_bin"
		fi
	fi
fi

# Enable systemd user service if sunshine is installed
if command_exists systemctl; then
	systemctl --user daemon-reload
	if command_exists sunshine; then
		sunshine_service=app-dev.lizardbyte.app.Sunshine.service
		if [[ "$(systemctl --user show -p LoadState --value "$sunshine_service")" == not-found ]]; then
			sunshine_service=sunshine.service
		fi
		systemctl --user enable "$sunshine_service"
		systemctl --user reset-failed "$sunshine_service"
		success "$sunshine_service enabled for graphical sessions"
		# SSH environment variables cannot create a graphical session. Use the
		# environment published by the managed Umbriel session instead.
		wayland_display="$(systemctl --user show-environment | sed -n 's/^WAYLAND_DISPLAY=//p')"
		runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
		if systemctl --user is-active --quiet umbriel.service &&
			systemctl --user is-active --quiet graphical-session.target &&
			[[ -n "$wayland_display" && -S "$runtime_dir/$wayland_display" ]]; then
			systemctl --user restart "$sunshine_service"
			success "$sunshine_service restarted; verify capture/encoder in its journal and connect with Moonlight"
		else
			warn "No active Umbriel Wayland session; Sunshine will start with the graphical session"
			warn "For SSH provisioning/recovery, run ./remote.sh"
		fi
	else
		warn "sunshine binary not found yet. Install via: yay -S sunshine-bin"
	fi
fi

success "Sunshine module configured"
