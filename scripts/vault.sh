#!/usr/bin/env bash

# ============================================================
# Dotfiles Secret Vault (Zero-Knowledge Session & Credential Sync)
#
# Encrypts and syncs:
# - Google Chrome (all profiles, sessions, cookies, 2FA states)
# - GNOME Keyring (master key needed to decrypt Chrome/Slack cookies)
# - Telegram Desktop (tdata sessions)
# - Slack (workspaces & session state)
# - Lark / Feishu (ByteDance credentials)
# - Obsidian (app settings & vaults)
# - SSH keys & GPG keys
# - GitHub CLI auth & Jira tokens
# - Docker authentication
# - Antigravity CLI & Antigravity IDE (sessions, credentials, conversation history)
# - 9router credentials, sessions, and MITM Root CA
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

info() {
    echo -e "\033[1;34m==>\033[0m \033[1m$1\033[0m"
}

success() {
    echo -e "\033[1;32m✓\033[0m $1"
}

warn() {
    echo -e "\033[1;33m!\033[0m $1"
}

error() {
    echo -e "\033[1;31m✗\033[0m $1" >&2
    exit 1
}

if [ "$EUID" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        warn "vault manages user-session data; continuing as '$SUDO_USER' instead of root."
        exec sudo -u "$SUDO_USER" -H env \
            RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:dotfiles-backup}" \
            "$SCRIPT_DIR/vault.sh" "$@"
    fi
    error "Do not run vault as root. Run it from the desktop user account."
fi

TARGET_USER="$(id -un)"
TARGET_GROUP="$(id -gn)"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:dotfiles-backup}"

if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
    error "Could not determine the home directory for '$TARGET_USER'."
fi

rclone_exec() {
    if command -v rclone >/dev/null 2>&1; then
        rclone "$@"
    elif command -v nix >/dev/null 2>&1; then
        nix run nixpkgs#rclone -- "$@"
    else
        return 1
    fi
}

rclone_is_configured() {
    local remote_name="${RCLONE_REMOTE%%:*}"
    rclone_exec listremotes 2>/dev/null | grep -q "^${remote_name}:"
}

decrypt_vault() {
    local in_file="$1"
    if [ "$(head -c 8 "$in_file")" = "Salted__" ]; then
        warn "Legacy OpenSSL vault detected; run 'vault backup' after restoring to migrate it to age." >&2
        openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "$in_file"
    else
        age --decrypt "$in_file"
    fi
}

# The candidate directories relative to USER_HOME to sync
CANDIDATE_PATHS=(
    ".config/google-chrome"
    ".config/jira-app"
    ".local/share/keyrings"
    ".local/share/TelegramDesktop"
    ".config/Slack"
    ".config/discord"
    ".config/feishu"
    ".local/share/feishu"
    ".config/LarkShell"
    ".config/kdeconnect"
    ".config/obsidian"
    ".config/Postman"
    ".config/beekeeper-studio"
    ".ssh"
    ".gnupg"
    ".config/gh"
    ".config/.jira"
    ".jira"
    ".docker/config.json"
    ".npmrc"
    ".gitconfig"
    ".zsh_history"
    ".config/rclone"
    ".gemini"
    ".antigravity-ide"
    ".antigravity"
    ".9router"
    ".codex"
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
    "*/CachedData/*"
    "*/CachedExtensionVSIXs/*"
    "*/DawnGraphiteCache/*"
    "*/DawnWebGPUCache/*"
    "*/presence/*"
    "*/crashes/*"
    "*/webm_encoder"
    "*/.9router/logs/*"
    "*/.9router/runtime/*"
    "*/.9router/model-catalog-raw.json"
    "*/.9router/**/*.pid"
)

ensure_user_owned() {
    local path="$1"

    [ -e "$path" ] || return 0
    if [ ! -w "$path" ] || find "$path" -xdev ! -user "$TARGET_USER" -print -quit 2>/dev/null | grep -q .; then
        warn "$path contains files not owned by $TARGET_USER; repairing ownership (sudo may prompt)..."
        sudo chown -R "$TARGET_USER:$TARGET_GROUP" "$path"
    fi
}

prepare_restore_permissions() {
    local path

    # These are user-owned trees. Repair them before dropping restored files into
    # place, including parent directories that are not themselves vault entries.
    for path in "$USER_HOME/.config" "$USER_HOME/.local"; do
        ensure_user_owned "$path"
    done

    for path in "${CANDIDATE_PATHS[@]}"; do
        ensure_user_owned "$USER_HOME/$path"
    done
}

RESTORE_TMP=""
RESTORE_RESTART_KEYRING=false
RESTORE_RESTART_9ROUTER=false

finish_restore_runtime() {
    local status="$1"

    if [ -n "$RESTORE_TMP" ] && [ -d "$RESTORE_TMP" ]; then
        rm -rf "$RESTORE_TMP"
    fi

    if [ "$RESTORE_RESTART_KEYRING" = true ] && command -v gnome-keyring-daemon >/dev/null 2>&1; then
        info "Restarting GNOME Keyring with the restored database..."
        if ! gnome-keyring-daemon --replace --daemonize --components=pkcs11,secrets,ssh >/dev/null; then
            warn "GNOME Keyring could not be restarted automatically. Log out and back in once."
        fi
    fi

    if [ "$RESTORE_RESTART_9ROUTER" = true ] && command -v systemctl >/dev/null 2>&1; then
        info "Restarting 9router service..."
        if ! systemctl --user start 9router.service; then
            warn "9router could not be restarted. Run 'init-9router' after this restore."
        fi
    fi

    return "$status"
}

cmd_backup() {
    local out_file="${1:-$REPO_ROOT/secrets.vault}"

    info "Starting Secret Vault backup for user '$TARGET_USER'..."

    # Find existing paths
    local existing_paths=()
    for rel_path in "${CANDIDATE_PATHS[@]}"; do
        if [ -e "$USER_HOME/$rel_path" ]; then
            existing_paths+=("$rel_path")
            echo "  + Found: $rel_path"
        fi
    done

    if [ ${#existing_paths[@]} -eq 0 ]; then
        error "No application profiles or secrets found in $USER_HOME."
    fi

    echo
    echo "This vault will contain sensitive credentials (cookies, 2FA sessions, SSH keys)."
    echo "Please set a strong Master Password to encrypt this vault:"
    
    # Run archiving, compression and encryption
    mkdir -p "$(dirname "$out_file")"
    local tmp_out="$out_file.tmp"
    rm -f "$tmp_out"

    if [ -f "$out_file" ]; then
        info "Overwriting existing vault file at $out_file..."
    fi

    local tmp_includes tmp_excludes
    tmp_includes="$(mktemp)"
    tmp_excludes="$(mktemp)"
    printf '%s\n' "${existing_paths[@]}" > "$tmp_includes"
    printf '%s\n' "${EXCLUDE_PATTERNS[@]}" > "$tmp_excludes"

    if ! (tar -C "$USER_HOME" --exclude-from="$tmp_excludes" -cf - --files-from="$tmp_includes" 2>/dev/null || [ $? -eq 1 ]) \
        | zstd -T0 -12 \
        | age --passphrase --output "$tmp_out"; then
        rm -f "$tmp_includes" "$tmp_excludes" "$tmp_out"
        error "Vault backup failed."
    fi

    rm -f "$tmp_includes" "$tmp_excludes"

    # Clean in-place overwrite
    mv -f "$tmp_out" "$out_file"
    chmod 600 "$out_file"

    local size
    size="$(du -h "$out_file" | cut -f1)"

    echo
    success "Vault created successfully: $out_file ($size)"

    local remote_name="${RCLONE_REMOTE%%:*}"
    if rclone_is_configured; then
        info "Uploading vault to Google Drive ($RCLONE_REMOTE/secrets.vault)..."
        if rclone_exec copyto "$out_file" "$RCLONE_REMOTE/secrets.vault" --progress; then
            success "Uploaded vault to Google Drive: $RCLONE_REMOTE/secrets.vault"
        else
            warn "Failed to upload to Google Drive. Check internet or credentials."
        fi
    else
        echo
        info "Google Drive remote '$remote_name' not configured. Skipped cloud sync."
        echo "  To auto-upload: run 'rclone config' (create remote named '$remote_name')."
    fi
}

cmd_restore() {
    local in_file="${1:-$REPO_ROOT/secrets.vault}"

    if [ ! -f "$in_file" ]; then
        local remote_name="${RCLONE_REMOTE%%:*}"
        if rclone_is_configured; then
            info "Local vault file not found ($in_file)."
            info "Attempting to download latest vault from Google Drive ($RCLONE_REMOTE/secrets.vault)..."
            mkdir -p "$(dirname "$in_file")"
            if rclone_exec copyto "$RCLONE_REMOTE/secrets.vault" "$in_file" --progress; then
                success "Downloaded latest vault from Google Drive to $in_file"
            else
                error "Failed to download $RCLONE_REMOTE/secrets.vault from Google Drive."
            fi
        else
            error "Vault file not found: $in_file (and Google Drive remote '$remote_name' not configured)."
        fi
    fi

    info "Restoring Secret Vault from: $in_file..."
    echo "Target home: $USER_HOME"
    echo

    prepare_restore_permissions

    # Preserve whether user-session services need to come back after the copy.
    if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet 9router.service; then
        RESTORE_RESTART_9ROUTER=true
        systemctl --user stop 9router.service
    elif pgrep -u "$UID" -f '[9]router/cli.js' >/dev/null 2>&1; then
        RESTORE_RESTART_9ROUTER=true
    fi

    if pgrep -u "$UID" -f '[g]nome-keyring-daemon' >/dev/null 2>&1; then
        RESTORE_RESTART_KEYRING=true
    fi

    trap 'finish_restore_runtime $?' EXIT

    # Terminate running apps to prevent lock conflicts and memory overwriting restored data
    local app_patterns=("chrome" "google-chrome" "jira-app" "slack" "telegram-desktop" "discord" "feishu" "lark" "kdeconnect" "beekeeper-studio" "obsidian" "antigravity-ide" "9router/cli.js")
    local closed_any=false
    for proc in "${app_patterns[@]}"; do
        if pgrep -u "$UID" -f "$proc" >/dev/null 2>&1; then
            info "Terminating running process before restore: $proc..."
            pkill -TERM -u "$UID" -f "$proc" 2>/dev/null || true
            closed_any=true
        fi
    done

    if pgrep -u "$UID" -x codex >/dev/null 2>&1; then
        info "Terminating running Codex process before restoring ~/.codex..."
        pkill -TERM -u "$UID" -x codex 2>/dev/null || true
        closed_any=true
    fi
    if [ "$closed_any" = true ]; then
        sleep 2
        pkill -9 -u "$UID" -f "chrome" 2>/dev/null || true
    fi

    if [ "$RESTORE_RESTART_KEYRING" = true ]; then
        info "Stopping GNOME Keyring before replacing its database..."
        pkill -TERM -u "$UID" -f '[g]nome-keyring-daemon' 2>/dev/null || true
        sleep 1
    fi

    RESTORE_TMP="$(mktemp -d)"

    if ! decrypt_vault "$in_file" \
        | zstd -d \
        | tar --no-same-owner --no-same-permissions -C "$RESTORE_TMP" -xf -; then
        echo
        error "Failed to decrypt or extract vault! Please check your Master Password or vault integrity."
    fi

    cp -a --no-preserve=ownership "$RESTORE_TMP"/. "$USER_HOME"/
    rm -rf "$RESTORE_TMP"
    RESTORE_TMP=""

    info "Securing restored permissions and cleaning lockfiles..."

    # SSH key permissions
    if [ -d "$USER_HOME/.ssh" ]; then
        chmod 700 "$USER_HOME/.ssh"
        chmod 600 "$USER_HOME/.ssh/id_*" 2>/dev/null || true
        chmod 644 "$USER_HOME/.ssh/*.pub" 2>/dev/null || true
    fi

    # GPG permissions
    if [ -d "$USER_HOME/.gnupg" ]; then
        chmod 700 "$USER_HOME/.gnupg"
    fi

    # Keyring permissions
    if [ -d "$USER_HOME/.local/share/keyrings" ]; then
        chmod 700 "$USER_HOME/.local/share/keyrings"
        chmod 600 "$USER_HOME/.local/share/keyrings"/* 2>/dev/null || true
    fi

    # Remove stale singleton lockfiles from Chrome, Slack, Discord, Antigravity, etc.
    find "$USER_HOME/.config" -maxdepth 3 -name "Singleton*" -delete 2>/dev/null || true
    rm -f "$USER_HOME/.antigravity-ide/code.lock" 2>/dev/null || true
    rm -f "$USER_HOME/.gemini/antigravity-cli/knowledge/knowledge.lock" 2>/dev/null || true
    rm -f "$USER_HOME/.gemini/antigravity-cli/presence"/*.lock 2>/dev/null || true

    echo
    success "Secret Vault restored successfully!"
    echo "  All Chrome profiles, Keyrings, Telegram, Slack, Antigravity CLI/IDE, and SSH keys are ready."
    echo "  Session services are being restarted; launch your apps again when this command finishes."

    finish_restore_runtime 0
    trap - EXIT
}

cmd_clean() {
    local force=false
    local categories=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force|-y|--yes)
                force=true
                shift
                ;;
            all|chrome|telegram|git|chat|ssh|gnupg|dev|notes|antigravity|router|phone|jira)
                categories+=("$1")
                shift
                ;;
            *)
                error "Unknown category or option: $1 (valid: chrome, telegram, git, chat, ssh, dev, jira, all)"
                ;;
        esac
    done

    declare -A cat_map=(
        ["chrome"]=".config/google-chrome .local/share/keyrings"
        ["jira"]=".config/jira-app .config/.jira .jira"
        ["telegram"]=".local/share/TelegramDesktop"
        ["git"]=".gitconfig .config/gh"
        ["chat"]=".config/Slack .config/discord .config/feishu .local/share/feishu .config/LarkShell"
        ["ssh"]=".ssh"
        ["gnupg"]=".gnupg"
        ["dev"]=".config/.jira .jira .config/jira-app .docker/config.json .npmrc .codex"
        ["notes"]=".config/obsidian .config/Postman .config/beekeeper-studio"
        ["antigravity"]=".gemini .antigravity-ide .antigravity"
        ["router"]=".9router"
        ["phone"]=".config/kdeconnect"
    )

    if [ ${#categories[@]} -eq 0 ]; then
        echo "No specific category passed. Options:"
        echo "  1) Core app sessions only (Chrome, Keyrings, Telegram, Git)"
        echo "  2) Full clean (All vault-managed credentials & sessions)"
        echo "  3) Cancel"
        read -r -p "Enter choice [1-3] (default 1): " choice
        case "${choice:-1}" in
            1) categories=("chrome" "telegram" "git") ;;
            2) categories=("chrome" "jira" "telegram" "git" "chat" "ssh" "gnupg" "dev" "notes" "antigravity" "router" "phone") ;;
            *) echo "Operation cancelled."; return 0 ;;
        esac
    elif [[ " ${categories[*]} " =~ " all " ]]; then
        categories=("chrome" "jira" "telegram" "git" "chat" "ssh" "gnupg" "dev" "notes" "antigravity" "router" "phone")
    fi

    local target_paths=()
    for cat in "${categories[@]}"; do
        if [ -n "${cat_map[$cat]:-}" ]; then
            for p in ${cat_map[$cat]}; do
                target_paths+=("$p")
            done
        fi
    done

    echo
    warn "The following local auth paths will be WIPED to test vault restore:"
    local found_any=false
    for p in "${target_paths[@]}"; do
        if [ -e "$USER_HOME/$p" ]; then
            local sz
            sz="$(du -sh "$USER_HOME/$p" 2>/dev/null | cut -f1 || echo "")"
            echo "  - ~/$p ($sz)"
            found_any=true
        fi
    done

    if [ "$found_any" = false ]; then
        warn "None of the selected credentials exist in $USER_HOME."
        return 0
    fi
    echo

    if [ "$force" = false ]; then
        read -r -p "Are you sure you want to delete these credentials? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted by user."
            return 0
        fi
    fi

    info "Terminating active applications..."
    local procs=("chrome" "google-chrome" "jira-app" "telegram-desktop" "slack" "discord" "feishu" "lark" "kdeconnect" "beekeeper-studio" "obsidian")
    for proc in "${procs[@]}"; do
        pkill -TERM -f "$proc" 2>/dev/null || true
    done
    sleep 1
    pkill -9 -f "chrome" 2>/dev/null || true

    info "Removing credential paths..."
    for p in "${target_paths[@]}"; do
        if [ -e "$USER_HOME/$p" ]; then
            rm -rf "${USER_HOME:?}/${p:?}"
            echo "  ✓ Removed: ~/$p"
        fi
    done

    mkdir -p "$USER_HOME/.local/share/keyrings"
    chmod 700 "$USER_HOME/.local/share/keyrings"

    echo
    success "Credentials cleaned! You are now in a clean state."
    echo "  Run 'vault restore' to test restoring your session."
}

cmd_list() {
    local in_file="${1:-$REPO_ROOT/secrets.vault}"

    [ -f "$in_file" ] || error "Vault file not found: $in_file"

    info "Inspecting contents of $in_file..."
    echo "  (Decrypting and decompressing archive, please wait...)"
    echo

    # Use interactive pager if stdout is a terminal, otherwise output directly
    local pager="cat"
    if [ -t 1 ] && command -v less >/dev/null 2>&1; then
        pager="less -RFX"
    fi

    # Temporarily disable pipefail so closing the pager or piping into head doesn't trigger SIGPIPE error
    set +o pipefail
    decrypt_vault "$in_file" \
        | zstd -d 2>/dev/null \
        | tar -tvf - 2>/dev/null \
        | $pager
    local statuses=("${PIPESTATUS[@]}")

    set -o pipefail

    if [ "${statuses[0]}" -ne 0 ] || [ "${statuses[1]}" -ne 0 ] || [ "${statuses[2]}" -ne 0 ]; then
        echo
        error "Decryption failed! Please check your Master Password."
    fi
}

cmd_upload() {
    local in_file="${1:-$REPO_ROOT/secrets.vault}"
    [ -f "$in_file" ] || error "Vault file not found: $in_file"
    local remote_name="${RCLONE_REMOTE%%:*}"
    if ! rclone_is_configured; then
        error "Google Drive remote '$remote_name' not configured. Run 'rclone config' first."
    fi
    local vault_basename
    vault_basename="$(basename "$in_file")"
    info "Uploading $in_file to $RCLONE_REMOTE/$vault_basename..."
    rclone_exec copyto "$in_file" "$RCLONE_REMOTE/$vault_basename" --progress
    if [ "$vault_basename" != "secrets.vault" ]; then
        rclone_exec copyto "$RCLONE_REMOTE/$vault_basename" "$RCLONE_REMOTE/secrets.vault" 2>/dev/null || true
    fi
    success "Upload completed successfully."
}

cmd_download() {
    local out_file="${1:-$REPO_ROOT/secrets.vault}"
    local remote_name="${RCLONE_REMOTE%%:*}"
    if ! rclone_is_configured; then
        error "Google Drive remote '$remote_name' not configured. Run 'rclone config' first."
    fi
    info "Downloading latest vault from $RCLONE_REMOTE/secrets.vault to $out_file..."
    mkdir -p "$(dirname "$out_file")"
    rclone_exec copyto "$RCLONE_REMOTE/secrets.vault" "$out_file" --progress
    success "Downloaded latest vault to: $out_file"
}

usage() {
    echo "Usage: $0 {backup|restore|clean|upload|download|list} [args]"
    echo
    echo "Commands:"
    echo "  backup   [file]   Encrypt and bundle (default: secrets.vault) & upload to Drive"
    echo "  restore  [file]   Decrypt and unpack vault (auto-download from Drive if not found locally)"
    echo "  upload   [file]   Explicitly upload a local vault file to Google Drive"
    echo "  download [file]   Download the latest vault from Google Drive to local file"
    echo "  list     [file]   List contents of encrypted vault"
    echo "  clean    [args]   Wipe local auth sessions to test vault restore"
    echo
    exit 1
}

case "${1:-}" in
    backup|export|save)
        shift
        cmd_backup "${1:-}"
        ;;
    restore|import|load)
        shift
        cmd_restore "${1:-}"
        ;;
    upload|push)
        shift
        cmd_upload "${1:-}"
        ;;
    download|pull)
        shift
        cmd_download "${1:-}"
        ;;
    list|ls)
        shift
        cmd_list "${1:-}"
        ;;
    clean|wipe|reset)
        shift
        cmd_clean "$@"
        ;;
    *)
        usage
        ;;
esac
