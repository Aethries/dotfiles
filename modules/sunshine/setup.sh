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
		sudo usermod -aG input "$USER" 2>/dev/null || true
		sudo udevadm control --reload-rules && sudo udevadm trigger 2>/dev/null || true
		success "Sunshine uinput udev rule configured"
	else
		warn "sudo requires password to install $UDEV_RULE"
		warn "Run manually: echo 'KERNEL==\"uinput\", SUBSYSTEM==\"misc\", OPTIONS+=\"static_node=uinput\", TAG+=\"uaccess\"' | sudo tee $UDEV_RULE && sudo usermod -aG input \$USER"
	fi
fi

# Set capabilities for KMS capture if sunshine binary exists
if command_exists sunshine; then
	local sunshine_bin
	sunshine_bin="$(command -v sunshine)"
	if [[ -n "$sunshine_bin" && -x "$sunshine_bin" ]]; then
		if sudo -n true 2>/dev/null; then
			sudo setcap cap_sys_admin+p "$sunshine_bin" 2>/dev/null || true
			success "Granted cap_sys_admin capability to sunshine"
		fi
	fi
fi

# Enable systemd user service if sunshine is installed
if command_exists systemctl; then
	systemctl --user daemon-reload
	if command_exists sunshine; then
		systemctl --user enable --now sunshine.service 2>/dev/null || true
		success "sunshine.service enabled and started"
	else
		warn "sunshine binary not found yet. Install via: yay -S sunshine-bin"
	fi
fi

success "Sunshine module configured"
