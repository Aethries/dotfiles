#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"

log "Configuring greeter (greetd + noctalia-greeter)"

# Create greeter user if not exists
if ! id "greeter" >/dev/null 2>&1; then
	log "Creating greeter system user"
	sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter 2>/dev/null || true
fi

# Ensure greeter is in video and input groups
sudo usermod -aG video,input greeter 2>/dev/null || true

# Prepare state directory for noctalia-greeter
sudo mkdir -p /var/lib/noctalia-greeter
sudo chown -R greeter:greeter /var/lib/noctalia-greeter
sudo chmod 0750 /var/lib/noctalia-greeter

# Deploy greetd configuration
sudo mkdir -p /etc/greetd
if [[ -f /etc/greetd/config.toml && ! -f /etc/greetd/config.toml.bak ]]; then
	sudo cp -a /etc/greetd/config.toml /etc/greetd/config.toml.bak
fi

TARGET_USER="${AUTOLOGIN_USER:-${SUDO_USER:-$USER}}"
if [[ "${AUTOLOGIN:-false}" == "true" || -f "$DOTFILES/.autologin" ]]; then
	log "Configuring greetd autologin for user $TARGET_USER"
	cat << EOF | sudo tee /etc/greetd/config.toml > /dev/null
[terminal]
vt = 1

[initial_session]
command = "start-umbriel"
user = "$TARGET_USER"

[default_session]
command = "/usr/bin/noctalia-greeter-session -- --session Umbriel"
user = "greeter"
EOF
else
	sudo cp "$MODULE_DIR/files/config.toml" /etc/greetd/config.toml
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

success "Greeter configured (greetd -> noctalia-greeter -> Umbriel)"