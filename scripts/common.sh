#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$DOTFILES/scripts"
PACKAGES="$DOTFILES/packages"

log() {
	echo
	echo "==> $1"
}

success() {
	echo "$1"
}

error() {
	echo "$1"
	exit 1
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}
