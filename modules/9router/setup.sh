#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up 9router Local AI Gateway & Proxy"

# Ensure user directories exist
mkdir -p "$HOME/.9router/mitm"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/.config/environment.d"

# Link systemd user service & environment
link_file \
	"$MODULE_DIR/files/9router.service" \
	"$HOME/.config/systemd/user/9router.service"

link_file \
	"$MODULE_DIR/files/20-9router.conf" \
	"$HOME/.config/environment.d/20-9router.conf"

# Sync Root CA certificate if present
CERT_SRC="$MODULE_DIR/files/certs/9router-rootCA.crt"
CERT_DEST="$HOME/.9router/mitm/rootCA.crt"
if [[ -f "$CERT_SRC" && ! -f "$CERT_DEST" ]]; then
	cp "$CERT_SRC" "$CERT_DEST"
	chmod 644 "$CERT_DEST"
	success "Synchronized 9router Root CA to $CERT_DEST"
fi

# Install Root CA into system trust store (Arch Linux)
if [[ -f "$CERT_SRC" ]] && command_exists update-ca-trust; then
	log "Updating system trust store with 9router Root CA"
	sudo cp "$CERT_SRC" /etc/ca-certificates/trust-source/anchors/9router-rootCA.crt
	sudo update-ca-trust
	success "System trust store updated"
fi

# Configure capability on Node.js binary for MITM port 443 binding without root
NODE_BIN="$(command -v node 2>/dev/null || true)"
if [[ -n "$NODE_BIN" ]] && command_exists setcap; then
	RESOLVED_NODE="$(readlink -f "$NODE_BIN")"
	log "Configuring network capabilities for Node.js: $RESOLVED_NODE"
	sudo setcap 'cap_net_bind_service=+ep' "$RESOLVED_NODE" 2>/dev/null || warn "Failed to set cap_net_bind_service on node binary"
	success "cap_net_bind_service capability configured"
fi

# Configure loopback DNS entries in /etc/hosts for MITM endpoints
log "Checking 9router MITM DNS entries in /etc/hosts"
REQUIRED_HOSTS=(
	"127.0.0.1 daily-cloudcode-pa.googleapis.com"
	"127.0.0.1 cloudcode-pa.googleapis.com"
)
for entry in "${REQUIRED_HOSTS[@]}"; do
	domain="$(echo "$entry" | awk '{print $2}')"
	if grep -qE "(^|\s)$domain(\s|$)" /etc/hosts; then
		success "DNS entry already present: $domain"
	else
		log "Adding $domain to /etc/hosts"
		echo "$entry" | sudo tee -a /etc/hosts >/dev/null
		success "Added $domain to /etc/hosts"
	fi
done

# Enable systemd user service
if command_exists systemctl; then
	log "Enabling 9router systemd user service"
	systemctl --user daemon-reload
	systemctl --user enable 9router.service
	success "9router.service enabled"
fi

success "9router configured"
