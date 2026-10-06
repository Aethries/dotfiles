#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

SECRETS_DIR="${SECRETS_DIR:-$DOTFILES/secrets}"
ENC_FILE="${ENC_FILE:-$DOTFILES/secrets.enc}"

# Helpers
check_dependencies() {
	for cmd in age zstd tar; do
		if ! command_exists "$cmd"; then
			error "Required command '$cmd' is not installed"
		fi
	done
}

# Encrypt
encrypt_secrets() {
	check_dependencies

	if [[ ! -d "$SECRETS_DIR" ]]; then
		error "Secrets directory not found: $SECRETS_DIR"
	fi

	log "Encrypting secrets to $ENC_FILE"
	mkdir -p "$(dirname "$ENC_FILE")"

	local tmp_file
	tmp_file="$(mktemp "${ENC_FILE}.tmp.XXXXXX")"

	if ! (tar -C "$SECRETS_DIR" --exclude=".gitkeep" -cf - . \
		| zstd -T0 -9 \
		| age --passphrase --output "$tmp_file"); then
		rm -f "$tmp_file"
		error "Failed to encrypt secrets"
	fi

	chmod 600 "$tmp_file"
	mv -f "$tmp_file" "$ENC_FILE"
	success "Secrets encrypted successfully -> $ENC_FILE"
}

# Decrypt
decrypt_secrets() {
	check_dependencies

	if [[ ! -f "$ENC_FILE" ]]; then
		error "Encrypted secrets file not found: $ENC_FILE"
	fi

	log "Verifying and decrypting secrets from $ENC_FILE"

	local stage_dir
	stage_dir="$(mktemp -d "/tmp/secrets_stage_XXXXXX")"

	if ! (age --decrypt "$ENC_FILE" \
		| zstd -d \
		| tar -C "$stage_dir" -xf -); then
		rm -rf "$stage_dir"
		error "Failed to decrypt secrets: invalid passphrase or corrupt archive"
	fi

	mkdir -p "$SECRETS_DIR"
	cp -a "$stage_dir"/. "$SECRETS_DIR"/
	rm -rf "$stage_dir"

	chmod 700 "$SECRETS_DIR"
	find "$SECRETS_DIR" -type d -exec chmod 700 {} +
	find "$SECRETS_DIR" -type f -exec chmod 600 {} +

	success "Secrets decrypted successfully -> $SECRETS_DIR"
}

# Usage
usage() {
	echo "Usage: $(basename "$0") {encrypt|decrypt}"
	exit 1
}

# Main
case "${1:-}" in
	encrypt)
		encrypt_secrets
		;;
	decrypt)
		decrypt_secrets
		;;
	*)
		usage
		;;
esac
