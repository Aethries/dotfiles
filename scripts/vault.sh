#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

if [[ $EUID -eq 0 ]]; then
	error "Do not run vault.sh as root"
fi

DEFAULT_VAULT="$DOTFILES/secrets.vault"

CANDIDATE_PATHS=(
	".config/google-chrome"
	".local/share/keyrings"
	".local/share/TelegramDesktop"
	".config/Slack"
	".config/feishu"
	".local/share/feishu"
	".config/LarkShell"
	".config/Postman"
	".config/beekeeper-studio"
	".ssh"
	".gnupg"
	".config/gh"
	".docker/config.json"
	".gitconfig"
	".config/git"
	".zsh_history"
	".gemini"
	".antigravity-ide"
	".antigravity"
	".config/Antigravity IDE"
	".9router"
	".codex"
	".config/ChatGPT"
)

EXCLUDE_PATTERNS=(
	"*/Cache/*"
	"*/cache2/*"
	"*/startupCache/*"
	"*/jumpListCache/*"
	"*/Code Cache/*"
	"*/GPUCache/*"
	"*/Service Worker/*"
	"*/File System/*"
	"*/optimization_guide_model_store/*"
	"*/component_crx_cache/*"
	"*/Safe Browsing/*"
	"*/WasmTtsEngine/*"
	"*/GPUPersistentCache/*"
	"*/extensions_crx_cache/*"
	"*/google-chrome/*/Extensions/*"
	"*/Crashpad/*"
	"*/BrowserMetrics/*"
	"*/Singleton*"
	"*/logs/*"
	"*/log/*"
	"*.log"
	"*/blob_storage/*"
	"*/Media Cache/*"
	"*/DawnGraphiteCache/*"
	"*/DawnWebGPUCache/*"
	"*/presence/*"
	"*/crashes/*"
	"*/webm_encoder"
	"*/.9router/logs"
	".9router/logs"
	"*/.9router/runtime"
	".9router/runtime"
	"*/.9router/model-catalog-raw.json"
	".9router/model-catalog-raw.json"
	"*.bak*"
	"*.pre-*"
	"*.pid"
	"*.sock"
)

APP_PROCESSES=(
	"google-chrome"
	"slack"
	"telegram-desktop"
	"feishu"
	"lark"
	"beekeeper-studio"
	"postman"
	"antigravity"
	"chatgpt"
	"codex"
	"9router"
)

# Helpers
check_dependencies() {
	for cmd in age zstd tar; do
		if ! command_exists "$cmd"; then
			error "Required command '$cmd' is not installed"
		fi
	done
}

stop_running_apps() {
	for proc in "${APP_PROCESSES[@]}"; do
		if pgrep -u "$UID" -f "$proc" >/dev/null 2>&1; then
			log "Stopping running process: $proc"
			pkill -TERM -u "$UID" -f "$proc" 2>/dev/null || true
		fi
	done
}

# Backup
backup_vault() {
	check_dependencies

	local target_file="${1:-$DEFAULT_VAULT}"

	log "Starting vault backup"

	local existing_paths=()
	for rel_path in "${CANDIDATE_PATHS[@]}"; do
		if [[ -e "$HOME/$rel_path" ]]; then
			existing_paths+=("$rel_path")
			echo "  + ~/$rel_path"
		fi
	done

	if [[ "${#existing_paths[@]}" -eq 0 ]]; then
		error "No candidate profiles or secrets found to backup"
	fi

	local exclude_args=()
	for pat in "${EXCLUDE_PATTERNS[@]}"; do
		exclude_args+=("--exclude=$pat")
	done

	mkdir -p "$(dirname "$target_file")"

	tar -C "$HOME" "${exclude_args[@]}" -cf - "${existing_paths[@]}" 2>/dev/null \
		| zstd -T0 -12 \
		| age --passphrase --output "$target_file"

	chmod 600 "$target_file"
	success "Vault created -> $target_file"
}

# Restore
restore_vault() {
	check_dependencies

	local source_file="${1:-$DEFAULT_VAULT}"

	if [[ ! -f "$source_file" ]]; then
		error "Vault file not found: $source_file"
	fi

	log "Restoring vault from $source_file"

	stop_running_apps

	if command_exists gnome-keyring-daemon && pgrep -u "$UID" -f '[g]nome-keyring-daemon' >/dev/null 2>&1; then
		pkill -TERM -u "$UID" -f '[g]nome-keyring-daemon' 2>/dev/null || true
	fi

	# Preserve standalone ssh config and gitconfig if they exist as regular files
	local saved_ssh_config=""
	if [[ -f "$HOME/.ssh/config" && ! -L "$HOME/.ssh/config" ]]; then
		saved_ssh_config="$(cat "$HOME/.ssh/config")"
	fi

	local saved_gitconfig=""
	if [[ -f "$HOME/.gitconfig" && ! -L "$HOME/.gitconfig" ]]; then
		saved_gitconfig="$(cat "$HOME/.gitconfig")"
	fi

	age --decrypt "$source_file" \
		| zstd -d \
		| tar --no-same-owner -C "$HOME" -xf -

	# Restore preserved standalone configs if archive contained legacy broken symlinks
	if [[ -n "$saved_ssh_config" ]]; then
		rm -f "$HOME/.ssh/config"
		echo "$saved_ssh_config" > "$HOME/.ssh/config"
	fi

	if [[ -n "$saved_gitconfig" ]]; then
		rm -f "$HOME/.gitconfig"
		echo "$saved_gitconfig" > "$HOME/.gitconfig"
	fi


	# Permissions
	if [[ -d "$HOME/.ssh" ]]; then
		chmod 700 "$HOME/.ssh"
		chmod 600 "$HOME/.ssh"/id_* 2>/dev/null || true
		chmod 644 "$HOME/.ssh"/*.pub 2>/dev/null || true
		chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
		chmod 644 "$HOME/.ssh/known_hosts" 2>/dev/null || true
	fi

	if [[ -d "$HOME/.gnupg" ]]; then
		chmod 700 "$HOME/.gnupg"
		find "$HOME/.gnupg" -type f -exec chmod 600 {} + 2>/dev/null || true
		find "$HOME/.gnupg" -type d -exec chmod 700 {} + 2>/dev/null || true
	fi

	if [[ -d "$HOME/.local/share/keyrings" ]]; then
		chmod 700 "$HOME/.local/share/keyrings"
		chmod 600 "$HOME/.local/share/keyrings"/* 2>/dev/null || true
	fi

	if [[ -d "$HOME/.9router" ]]; then
		chmod 700 "$HOME/.9router"
	fi

	find "$HOME/.config" -maxdepth 3 -name "Singleton*" -delete 2>/dev/null || true

	if command_exists gnome-keyring-daemon; then
		gnome-keyring-daemon --replace --daemonize --components=pkcs11,secrets,ssh >/dev/null 2>&1 || true
	fi

	success "Vault restored successfully"
}

# List
list_vault() {
	check_dependencies

	local source_file="${1:-$DEFAULT_VAULT}"

	if [[ ! -f "$source_file" ]]; then
		error "Vault file not found: $source_file"
	fi

	log "Listing vault contents from $source_file"

	age --decrypt "$source_file" \
		| zstd -d \
		| tar -tvf -
}

# Clean
clean_sessions() {
	log "Wiping local session data"

	stop_running_apps

	for rel_path in "${CANDIDATE_PATHS[@]}"; do
		if [[ -e "$HOME/$rel_path" ]]; then
			rm -rf "${HOME:?}/${rel_path:?}"
			echo "  - Removed: ~/$rel_path"
		fi
	done

	mkdir -p "$HOME/.local/share/keyrings"
	chmod 700 "$HOME/.local/share/keyrings"

	success "Local session data cleaned"
}

# Usage
usage() {
	echo "Usage: $(basename "$0") {backup|restore|list|clean} [file]"
	exit 1
}

# Main
case "${1:-}" in
	backup)
		backup_vault "${2:-}"
		;;
	restore)
		restore_vault "${2:-}"
		;;
	list)
		list_vault "${2:-}"
		;;
	clean)
		clean_sessions
		;;
	*)
		usage
		;;
esac
