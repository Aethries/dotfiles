#!/usr/bin/env bash
# ==============================================================================
# Isolated Vault Test Suite
# Verifies zero-knowledge local-only vault operation without network/cloud calls.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

# Setup isolated sandbox under REPO_ROOT/.sandbox/
SANDBOX_DIR="$REPO_ROOT/.sandbox/vault-test-$$"
mkdir -p "$SANDBOX_DIR/home" "$SANDBOX_DIR/bin"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# Create fake rclone and fake nix that MUST NOT be invoked
cat << 'EOS' > "$SANDBOX_DIR/bin/rclone"
#!/usr/bin/env bash
echo "CRITICAL ERROR: rclone was invoked!" >&2
exit 99
EOS
chmod +x "$SANDBOX_DIR/bin/rclone"

cat << 'EOS' > "$SANDBOX_DIR/bin/nix"
#!/usr/bin/env bash
echo "CRITICAL ERROR: nix was invoked!" >&2
exit 98
EOS
chmod +x "$SANDBOX_DIR/bin/nix"

# Mock daemons and process tools to prevent touching host session
cat << 'EOS' > "$SANDBOX_DIR/bin/gnome-keyring-daemon"
#!/usr/bin/env bash
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/gnome-keyring-daemon"

cat << 'EOS' > "$SANDBOX_DIR/bin/systemctl"
#!/usr/bin/env bash
if [ "${1:-}" = "is-active" ] || [ "${2:-}" = "is-active" ]; then
    exit 1
fi
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/systemctl"

cat << 'EOS' > "$SANDBOX_DIR/bin/pkill"
#!/usr/bin/env bash
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/pkill"

cat << 'EOS' > "$SANDBOX_DIR/bin/pgrep"
#!/usr/bin/env bash
exit 1
EOS
chmod +x "$SANDBOX_DIR/bin/pgrep"

# Create fake age to support non-interactive test execution while preserving
# real zstd and tar archive validation
cat << 'EOS' > "$SANDBOX_DIR/bin/age"
#!/usr/bin/env bash
if [ "${1:-}" = "--passphrase" ] && [ "${2:-}" = "--output" ]; then
    cat > "$3"
elif [ "${1:-}" = "--decrypt" ]; then
    cat "$2"
else
    cat
fi
EOS
chmod +x "$SANDBOX_DIR/bin/age"

export PATH="$SANDBOX_DIR/bin:$PATH"
export HOME="$SANDBOX_DIR/home"
TEST_VAULT="$SANDBOX_DIR/test.vault"

log_info "1. Testing backup creates local vault with zero calls to rclone and nix..."
mkdir -p "$HOME/.config/gh"
echo "gh-token-sample" > "$HOME/.config/gh/config.yml"
"$REPO_ROOT/scripts/vault.sh" backup "$TEST_VAULT" >/dev/null
[ -f "$TEST_VAULT" ] || log_fail "Backup did not create vault file"
log_ok "Backup created successfully without rclone or nix"

log_info "2. Testing resulting vault has mode 0600..."
PERM="$(stat -c "%a" "$TEST_VAULT")"
[ "$PERM" = "600" ] || log_fail "Vault permissions are $PERM, expected 600"
log_ok "Vault permissions are 0600"

log_info "3. Testing listing the synthetic vault succeeds..."
LIST_OUT="$("$REPO_ROOT/scripts/vault.sh" list "$TEST_VAULT")"
echo "$LIST_OUT" | grep -q "\.config/gh/config\.yml" || log_fail "List output missing .config/gh/config.yml"
log_ok "Listing contents succeeded"

log_info "4. Testing restore retains normal files..."
rm -rf "$HOME/.config/gh"
"$REPO_ROOT/scripts/vault.sh" restore "$TEST_VAULT" >/dev/null
[ -f "$HOME/.config/gh/config.yml" ] || log_fail "File was not restored"
[ "$(cat "$HOME/.config/gh/config.yml")" = "gh-token-sample" ] || log_fail "Restored content mismatch"
log_ok "Restore succeeded"

log_info "5. Testing restore with missing file fails immediately..."
MISSING_FILE="$SANDBOX_DIR/nonexistent/never.vault"
if "$REPO_ROOT/scripts/vault.sh" restore "$MISSING_FILE" 2>/dev/null; then
    log_fail "Restore of missing file unexpectedly succeeded"
fi
[ ! -d "$SANDBOX_DIR/nonexistent" ] || log_fail "Restore created nonexistent parent directory"
log_ok "Missing file restore failed cleanly"

log_info "6. Testing legacy archive with .config/rclone excludes rclone subtree..."
LEGACY_DIR="$SANDBOX_DIR/legacy-src"
mkdir -p "$LEGACY_DIR/.config/rclone" "$LEGACY_DIR/.config/gh"
echo "secret-rclone-token" > "$LEGACY_DIR/.config/rclone/rclone.conf"
echo "gh-valid" > "$LEGACY_DIR/.config/gh/hosts.yml"
LEGACY_VAULT="$SANDBOX_DIR/legacy.vault"
(cd "$LEGACY_DIR" && tar -cf - .config) | zstd -T0 -1 | "$SANDBOX_DIR/bin/age" --passphrase --output "$LEGACY_VAULT"
rm -rf "$HOME/.config/rclone" "$HOME/.config/gh"
"$REPO_ROOT/scripts/vault.sh" restore "$LEGACY_VAULT" >/dev/null
[ -f "$HOME/.config/gh/hosts.yml" ] || log_fail "Legit config was not restored"
[ ! -e "$HOME/.config/rclone" ] || log_fail ".config/rclone was restored from legacy vault!"
log_ok "Legacy archive restored with .config/rclone excluded"

log_info "7. Testing pre-existing synthetic rclone config is neither included nor deleted by backup..."
mkdir -p "$HOME/.config/rclone" "$HOME/.config/gh"
echo "existing-rclone" > "$HOME/.config/rclone/rclone.conf"
echo "gh-fresh" > "$HOME/.config/gh/hosts.yml"
NEW_VAULT="$SANDBOX_DIR/new.vault"
"$REPO_ROOT/scripts/vault.sh" backup "$NEW_VAULT" >/dev/null
[ -f "$HOME/.config/rclone/rclone.conf" ] || log_fail "Backup deleted pre-existing rclone.conf"
NEW_LIST="$("$REPO_ROOT/scripts/vault.sh" list "$NEW_VAULT")"
if echo "$NEW_LIST" | grep -q "rclone"; then
    log_fail "New vault includes rclone configuration"
fi
log_ok "Pre-existing rclone config preserved and omitted from backup"

log_info "8. Testing restore does not overwrite or delete pre-existing rclone config..."
echo "untouched-rclone" > "$HOME/.config/rclone/rclone.conf"
"$REPO_ROOT/scripts/vault.sh" restore "$NEW_VAULT" >/dev/null
[ "$(cat "$HOME/.config/rclone/rclone.conf")" = "untouched-rclone" ] || log_fail "Restore mutated pre-existing rclone config"
log_ok "Pre-existing rclone config remained untouched during restore"

log_info "9. Testing upload, push, download, pull return nonzero..."
for cmd in upload push download pull; do
    if "$REPO_ROOT/scripts/vault.sh" "$cmd" 2>/dev/null; then
        log_fail "Command '$cmd' unexpectedly succeeded"
    fi
done
log_ok "Removed commands return nonzero"

log_info "10. Testing aliases route to valid operations..."
"$REPO_ROOT/scripts/vault.sh" export "$SANDBOX_DIR/alias.vault" >/dev/null
"$REPO_ROOT/scripts/vault.sh" ls "$SANDBOX_DIR/alias.vault" >/dev/null
"$REPO_ROOT/scripts/vault.sh" import "$SANDBOX_DIR/alias.vault" >/dev/null
"$REPO_ROOT/scripts/vault.sh" clean -f -y all >/dev/null
log_ok "Aliases functional"

log_info "11. Testing re-exec does not contain RCLONE_REMOTE..."
if grep -q "RCLONE_REMOTE" "$REPO_ROOT/scripts/vault.sh"; then
    log_fail "vault.sh still contains RCLONE_REMOTE"
fi
log_ok "RCLONE_REMOTE absent from vault.sh"

log_info "12. Testing static search finds no unmanaged rclone/Google Drive references..."
# Allow only the legacy exclusion pattern in vault.sh (--exclude='.config/rclone')
matches="$(grep -riE "(rclone|gdrive|google drive)" "$REPO_ROOT/scripts" "$REPO_ROOT/modules" "$REPO_ROOT/README.md" \
    | grep -v -E "(exclude.*rclone|README.md.*rclone)" || true)"
if [ -n "$matches" ]; then
    echo "$matches" >&2
    log_fail "Found unmanaged rclone/gdrive references in scripts/modules/README.md"
fi
log_ok "No unmanaged rclone/Google Drive references in scripts/modules/README.md"

log_info "13. Testing Nix package list does not contain rclone..."
if grep -q "rclone" "$REPO_ROOT/modules/packages.nix"; then
    log_fail "rclone is still in modules/packages.nix"
fi
log_ok "rclone is absent from modules/packages.nix"

log_info "14. Testing restore overwrites pre-existing read-only files (0444/0555) without Permission denied..."
mkdir -p "$HOME/.codex/memories/.git/objects/4f" "$HOME/.codex/plugins/.plugin-appserver"
echo "vault-git-content" > "$HOME/.codex/memories/.git/objects/4f/obj1"
echo "vault-bin-content" > "$HOME/.codex/plugins/.plugin-appserver/codex"
chmod 444 "$HOME/.codex/memories/.git/objects/4f/obj1"
chmod 555 "$HOME/.codex/plugins/.plugin-appserver/codex"
RO_VAULT="$SANDBOX_DIR/ro.vault"
"$REPO_ROOT/scripts/vault.sh" backup "$RO_VAULT" >/dev/null

rm -f "$HOME/.codex/memories/.git/objects/4f/obj1" "$HOME/.codex/plugins/.plugin-appserver/codex"
echo "stale-git-content" > "$HOME/.codex/memories/.git/objects/4f/obj1"
echo "stale-bin-content" > "$HOME/.codex/plugins/.plugin-appserver/codex"
chmod 444 "$HOME/.codex/memories/.git/objects/4f/obj1"
chmod 555 "$HOME/.codex/plugins/.plugin-appserver/codex"

"$REPO_ROOT/scripts/vault.sh" restore "$RO_VAULT" >/dev/null
[ "$(cat "$HOME/.codex/memories/.git/objects/4f/obj1")" = "vault-git-content" ] || log_fail "Read-only file was not overwritten"
[ "$(cat "$HOME/.codex/plugins/.plugin-appserver/codex")" = "vault-bin-content" ] || log_fail "Read-only executable was not overwritten"
log_ok "Restore overwrites read-only files cleanly"

log_info "15. Testing agentmemory scope encrypts state and settings without runtime caches..."
AGENTMEMORY_DATA_DIR="$HOME/.local/share/agentmemory"
mkdir -p "$AGENTMEMORY_DATA_DIR" "$HOME/.agentmemory/cache" "$HOME/.agentmemory/logs"
echo "memory-record" > "$AGENTMEMORY_DATA_DIR/memories.json"
echo "agentmemory-secret" > "$HOME/.agentmemory/.env"
echo "runtime-cache" > "$HOME/.agentmemory/cache/ignored.txt"
echo "runtime-log" > "$HOME/.agentmemory/logs/ignored.log"
echo "runtime-pid" > "$HOME/.agentmemory/runtime.pid"
AGENTMEMORY_VAULT="$SANDBOX_DIR/agentmemory.vault"
AGENTMEMORY_DATA_DIR="$AGENTMEMORY_DATA_DIR" "$REPO_ROOT/scripts/vault.sh" backup --scope agentmemory "$AGENTMEMORY_VAULT" >/dev/null
[ -f "$AGENTMEMORY_VAULT" ] || log_fail "Agentmemory backup did not create a vault file"
AGENTMEMORY_LIST="$("$REPO_ROOT/scripts/vault.sh" list "$AGENTMEMORY_VAULT")"
echo "$AGENTMEMORY_LIST" | grep -q "data/agentmemory/memories.json" || log_fail "Agentmemory state missing from vault"
echo "$AGENTMEMORY_LIST" | grep -q "user/agentmemory/.env" || log_fail "Agentmemory settings missing from vault"
if echo "$AGENTMEMORY_LIST" | grep -Eq "cache/ignored|logs/ignored|runtime\.pid"; then
    log_fail "Agentmemory runtime cache/log/lock was included in vault"
fi
rm -rf "$AGENTMEMORY_DATA_DIR" "$HOME/.agentmemory"
AGENTMEMORY_DATA_DIR="$AGENTMEMORY_DATA_DIR" "$REPO_ROOT/scripts/vault.sh" restore --scope agentmemory "$AGENTMEMORY_VAULT" >/dev/null
[ "$(cat "$AGENTMEMORY_DATA_DIR/memories.json")" = "memory-record" ] || log_fail "Agentmemory state was not restored"
[ "$(cat "$HOME/.agentmemory/.env")" = "agentmemory-secret" ] || log_fail "Agentmemory settings were not restored"
[ ! -e "$HOME/.agentmemory/cache/ignored.txt" ] || log_fail "Agentmemory cache was restored"
log_ok "Agentmemory Vault scope is encrypted, portable, and cache-free"

log_info "16. Testing active agentmemory service is rejected for safe snapshots..."
cat << 'EOS' > "$SANDBOX_DIR/bin/systemctl"
#!/usr/bin/env bash
if [ "${1:-}" = "is-active" ] || [ "${2:-}" = "is-active" ]; then
    if [ "${3:-}" = "agentmemory.service" ]; then
        exit 0
    fi
    exit 1
fi
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/systemctl"
if AGENTMEMORY_DATA_DIR="$AGENTMEMORY_DATA_DIR" "$REPO_ROOT/scripts/vault.sh" backup --scope agentmemory "$SANDBOX_DIR/blocked.vault" >/dev/null 2>&1; then
    log_fail "Active agentmemory service was not rejected"
fi
log_ok "Active agentmemory service is rejected before backup"

echo
log_ok "ALL 16 VAULT TEST CASES PASSED SUCCESSFULLY."
