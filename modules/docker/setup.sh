#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Docker Container Engine"

# 1. Ensure docker group exists
if ! getent group docker >/dev/null 2>&1; then
	if command_exists sudo && sudo -n true 2>/dev/null; then
		sudo groupadd docker
		success "Created docker system group"
	else
		warn "Run: sudo groupadd docker"
	fi
fi

# 2. Add current user to docker group (non-root access without sudo)
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
	if command_exists sudo && sudo -n true 2>/dev/null; then
		sudo usermod -aG docker "$USER"
		warn "Added $USER to docker group; run 'newgrp docker' or re-login for changes to take effect"
	else
		warn "Run: sudo usermod -aG docker $USER"
	fi
else
	success "User $USER is already in docker group"
fi

# 3. Setup /etc/docker/daemon.json with log rotation
if [[ -f "$MODULE_DIR/files/daemon.json" ]]; then
	if command_exists sudo && sudo -n true 2>/dev/null; then
		sudo mkdir -p /etc/docker
		if [[ ! -f /etc/docker/daemon.json ]]; then
			sudo cp "$MODULE_DIR/files/daemon.json" /etc/docker/daemon.json
			success "Configured /etc/docker/daemon.json (log rotation)"
		fi
	fi
fi

# 4. Enable and start docker.socket and docker.service
if command_exists systemctl; then
	if command_exists docker; then
		if command_exists sudo && sudo -n true 2>/dev/null; then
			sudo systemctl enable --now docker.socket docker.service 2>/dev/null || true
			success "docker.socket and docker.service enabled and started"
		else
			warn "Run: sudo systemctl enable --now docker.socket docker.service"
		fi
	else
		warn "docker package is not installed yet. Install with: sudo pacman -S docker docker-compose docker-buildx"
	fi
fi

success "Docker module configured"
