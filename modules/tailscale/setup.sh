#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Tailscale & SSH Client Configuration"

# 1. SSH sockets & config.d directory setup
mkdir -p "$HOME/.ssh/sockets"
chmod 0700 "$HOME/.ssh" "$HOME/.ssh/sockets"
mkdir -p "$HOME/.ssh/config.d"

# Link tailscale ssh_config snippet
link_file \
	"$MODULE_DIR/files/ssh_config" \
	"$HOME/.ssh/config.d/tailscale.conf"

# Ensure ~/.ssh/config includes config.d/*
if [[ ! -f "$HOME/.ssh/config" ]]; then
	cat << 'EOF' > "$HOME/.ssh/config"
Include ~/.ssh/config.d/*
EOF
	chmod 0600 "$HOME/.ssh/config"
	success "Created ~/.ssh/config with Include ~/.ssh/config.d/*"
elif ! grep -q "Include ~/.ssh/config.d/\*" "$HOME/.ssh/config" 2>/dev/null; then
	sed -i '1i Include ~/.ssh/config.d/*\n' "$HOME/.ssh/config"
	success "Prepend Include ~/.ssh/config.d/* to ~/.ssh/config"
fi

# 2. Kernel packet forwarding for Tailscale subnet/mesh routing
SYSCTL_FILE="/etc/sysctl.d/99-tailscale.conf"
if [[ ! -f "$SYSCTL_FILE" ]]; then
	if command_exists sudo && sudo -n true 2>/dev/null; then
		sudo tee "$SYSCTL_FILE" > /dev/null << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
		sudo sysctl -p "$SYSCTL_FILE" >/dev/null 2>&1 || true
		success "Enabled IP packet forwarding in $SYSCTL_FILE"
	fi
fi

# 3. Enable tailscaled system service
if command_exists systemctl; then
	if command_exists tailscale; then
		if sudo -n true 2>/dev/null; then
			sudo systemctl enable --now tailscaled.service 2>/dev/null || true
			success "tailscaled.service enabled and started"
		else
			warn "Run 'sudo systemctl enable --now tailscaled.service' to start Tailscale daemon"
		fi
	else
		warn "tailscale package is not installed yet. Install with: sudo pacman -S tailscale"
	fi
fi

# 4. Check Tailscale connection status
if command_exists tailscale; then
	if tailscale status >/dev/null 2>&1; then
		ts_ip="$(tailscale ip -4 2>/dev/null || echo "unknown")"
		success "Tailscale is connected (IP: $ts_ip)"
	else
		warn "Tailscale is not authenticated yet."
		warn "To connect and enable Tailscale SSH, run:"
		warn "  sudo tailscale up --ssh --operator=$USER"
	fi
fi

success "Tailscale module configured"
