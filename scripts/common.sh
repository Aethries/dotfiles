#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$DOTFILES/scripts"
PACKAGES="$DOTFILES/packages"

# Colors
if [[ -t 1 ]]; then
	RED="\033[1;31m"
	GREEN="\033[1;32m"
	YELLOW="\033[1;33m"
	BLUE="\033[1;34m"
	BOLD="\033[1m"
	RESET="\033[0m"
else
	RED=""
	GREEN=""
	YELLOW=""
	BLUE=""
	BOLD=""
	RESET=""
fi

log() {
	echo -e "\n${BLUE}==>${RESET} ${BOLD}$1${RESET}"
}

warn() {
	echo -e "${YELLOW}!${RESET} $1"
}

success() {
	echo -e "${GREEN}✓${RESET} $1"
}

error() {
	echo -e "${RED}✗${RESET} $1" >&2
	exit 1
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}
