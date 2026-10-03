#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If python3 is available, run interactive / CLI python provisioner
if command -v python3 >/dev/null 2>&1; then
	exec python3 "$DOTFILES/scripts/ai.py" "$@"
fi

# Fallback bash execution if python is not installed
source "$DOTFILES/scripts/common.sh"
log "Configuring AI Tooling Environment (Antigravity & Codex - Fallback Mode)"

bash "$DOTFILES/modules/ai/setup.sh"
bash "$DOTFILES/modules/antigravity/setup.sh"
bash "$DOTFILES/modules/codex/setup.sh"

success "AI Environment Setup Complete!"
