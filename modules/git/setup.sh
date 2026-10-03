#!/usr/bin/env bash

set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$MODULE_DIR/../.." && pwd)"

source "$DOTFILES/scripts/common.sh"
source "$DOTFILES/scripts/links.sh"

log "Setting up Git identity, commit signing and security"

# Ensure directories exist
mkdir -p "$HOME/.config/git/hooks"
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

# Link global Git configuration (generic, zero PII)
link_file \
	"$MODULE_DIR/files/.gitconfig" \
	"$HOME/.gitconfig"

# Clean up deprecated or unused work config if exists
rm -f "$HOME/.gitconfig-work"

# Initialize ~/.gitconfig.local if it doesn't exist
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [[ ! -f "$GITCONFIG_LOCAL" ]]; then
	cat > "$GITCONFIG_LOCAL" <<'EOF'
[user]
	name = Your Name
	email = your.email@example.com
	signingkey = ~/.ssh/id_ed25519.pub
EOF
	chmod 600 "$GITCONFIG_LOCAL"
	warn "Created template at $GITCONFIG_LOCAL. Please update your name and email."
fi

# Link global pre-commit hook
link_file \
	"$MODULE_DIR/files/hooks/pre-commit" \
	"$HOME/.config/git/hooks/pre-commit"
chmod +x "$MODULE_DIR/files/hooks/pre-commit"
chmod +x "$HOME/.config/git/hooks/pre-commit" 2>/dev/null || true

# Also link into dotfiles repository hooks as fallback
if [[ -d "$DOTFILES/.git" ]]; then
	mkdir -p "$DOTFILES/.git/hooks"
	link_file \
		"$MODULE_DIR/files/hooks/pre-commit" \
		"$DOTFILES/.git/hooks/pre-commit"
	chmod +x "$DOTFILES/.git/hooks/pre-commit" 2>/dev/null || true
fi

# Configure allowed signers for local signature verification
ALLOWED_SIGNERS="$HOME/.config/git/allowed_signers"
touch "$ALLOWED_SIGNERS"

USER_EMAIL="$(git config user.email 2>/dev/null || echo "")"
SSH_PUB_KEY="$HOME/.ssh/id_ed25519.pub"

if [[ -f "$SSH_PUB_KEY" ]]; then
	PUB_CONTENT="$(cat "$SSH_PUB_KEY")"
	if [[ -n "$USER_EMAIL" ]]; then
		if ! grep -q "$PUB_CONTENT" "$ALLOWED_SIGNERS" 2>/dev/null; then
			echo "$USER_EMAIL $PUB_CONTENT" >> "$ALLOWED_SIGNERS"
			log "Added local signing key to $ALLOWED_SIGNERS"
		fi
	fi
	success "SSH signing key detected: $SSH_PUB_KEY"
else
	warn "No SSH signing key found at $SSH_PUB_KEY."
	warn "Generate one using: ssh-keygen -t ed25519 -C \"your.email@example.com\""
fi

# Configure GPG agent pinentry for GUI Wayland prompt
GPG_AGENT_CONF="$HOME/.gnupg/gpg-agent.conf"
if [[ -x /usr/bin/pinentry-gnome3 ]]; then
	touch "$GPG_AGENT_CONF"
	if ! grep -q "pinentry-program" "$GPG_AGENT_CONF" 2>/dev/null; then
		echo "pinentry-program /usr/bin/pinentry-gnome3" >> "$GPG_AGENT_CONF"
		log "Configured pinentry-gnome3 in $GPG_AGENT_CONF"
	fi
	chmod 600 "$GPG_AGENT_CONF"
fi

# Check for gitleaks
if command_exists gitleaks; then
	success "gitleaks is available and active in pre-commit hook"
else
	warn "gitleaks is not yet installed. Install it with: sudo pacman -S gitleaks"
fi

success "Git module configuration completed"
