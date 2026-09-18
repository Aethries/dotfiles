#!/usr/bin/env bash

# ============================================================
# Dotfiles Secrets Encryptor / Decryptor
#
# Authenticated passphrase encryption (age + Zstd)
# Used to store sensitive project configurations (.env, provider settings, etc.)
# ============================================================

set -euo pipefail

# ANSI colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
BOLD="\033[1m"
RESET="\033[0m"

info() {
    echo -e "${BLUE}==>${RESET} ${BOLD}$1${RESET}"
}

success() {
    echo -e "${GREEN}✓${RESET} $1"
}

warn() {
    echo -e "${YELLOW}!${RESET} $1"
}

error() {
    echo -e "${RED}✗${RESET} $1" >&2
    exit 1
}

# Resolve canonical script and repo path (follows symlinks)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SECRETS_DIR="${SECRETS_DIR:-$REPO_ROOT/secrets}"
ENC_FILE="${ENC_FILE:-$REPO_ROOT/secrets.enc}"

decrypt_stream() {
    if [ "$(head -c 8 "$ENC_FILE")" = "Salted__" ]; then
        warn "Legacy OpenSSL vault detected; re-run 'secrets encrypt' after restoring to migrate it to age." >&2
        local pass="${SECRETS_PASSWORD:-${PASSWORD:-}}"
        if [ -z "$pass" ]; then
            read -r -s -p "  Master Password: " pass </dev/tty
            echo >&2
        fi
        SECRET_PASS="$pass" openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
            -pass env:SECRET_PASS -in "$ENC_FILE"
    else
        age --decrypt "$ENC_FILE"
    fi
}

cmd_encrypt() {
    if [ ! -d "$SECRETS_DIR" ]; then
        error "Secrets directory not found: $SECRETS_DIR"
    fi

    local file_count
    file_count="$(find "$SECRETS_DIR" -type f ! -name ".gitkeep" | wc -l | tr -d ' ')"
    if [ "$file_count" -eq 0 ]; then
        error "No secret files found in $SECRETS_DIR to encrypt."
    fi

    info "Encrypting $file_count file(s) from: $SECRETS_DIR"
    echo "Target output: $ENC_FILE"

    local tmp_out="$ENC_FILE.tmp"
    mkdir -p "$(dirname "$ENC_FILE")"
    rm -f "$tmp_out"

    # age authenticates encrypted data before it is accepted as a valid archive.
    if tar -C "$SECRETS_DIR" --exclude=".gitkeep" -cf - . \
        | zstd -T0 -9 \
        | age --passphrase --output "$tmp_out"; then

        mv -f "$tmp_out" "$ENC_FILE"
        chmod 600 "$ENC_FILE"

        local size
        size="$(du -h "$ENC_FILE" | cut -f1)"

        echo
        success "Secrets encrypted successfully -> $ENC_FILE ($size)"
        info "You can now safely commit or sync $ENC_FILE to another machine."
    else
        rm -f "$tmp_out"
        echo
        error "Encryption failed!"
    fi
}

cmd_decrypt() {
    if [ ! -f "$ENC_FILE" ]; then
        error "Encrypted secrets file not found: $ENC_FILE"
    fi

    info "Decrypting secrets from: $ENC_FILE"
    echo "Target destination: $SECRETS_DIR"

    local tmp_extract
    tmp_extract="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp_extract'" EXIT

    # Safe extraction pipeline: decrypt to temporary directory first
    if decrypt_stream \
        | zstd -d 2>/dev/null \
        | tar -C "$tmp_extract" -xf - 2>/dev/null; then

        mkdir -p "$SECRETS_DIR"
        chmod 700 "$SECRETS_DIR"

        # Copy decrypted files into destination
        cp -a --remove-destination "$tmp_extract"/. "$SECRETS_DIR"/

        # Secure file permissions (directories 700, files 600)
        find "$SECRETS_DIR" -type d -exec chmod 700 {} +
        find "$SECRETS_DIR" -type f -exec chmod 600 {} +

        local count
        count="$(find "$SECRETS_DIR" -type f ! -name ".gitkeep" | wc -l | tr -d ' ')"

        echo
        success "Decryption successful! $count file(s) restored into $SECRETS_DIR"
    else
        echo
        error "Decryption failed! Incorrect password or corrupted file."
    fi
}

usage() {
    echo -e "${BOLD}Dotfiles Secrets Manager${RESET}"
    echo "Usage: $(basename "$0") {encrypt|decrypt}"
    echo
    echo "Commands:"
    echo "  encrypt   Encrypt all files in 'secrets/' into 'secrets.enc' with a Master Password"
    echo "  decrypt   Decrypt 'secrets.enc' back into 'secrets/'"
    echo
    exit 1
}

case "${1:-}" in
    encrypt|enc|lock|pack)
        cmd_encrypt
        ;;
    decrypt|dec|unlock|unpack)
        cmd_decrypt
        ;;
    *)
        usage
        ;;
esac
