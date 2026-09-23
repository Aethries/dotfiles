#!/usr/bin/env bash

# Isolated lifecycle test for scripts/agentmemory-vault.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX_DIR="$REPO_ROOT/.sandbox/agentmemory-wrapper-test-$$"
mkdir -p "$SANDBOX_DIR/home" "$SANDBOX_DIR/bin" "$SANDBOX_DIR/state"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

cat <<'EOS' > "$SANDBOX_DIR/bin/systemctl"
#!/usr/bin/env bash
set -euo pipefail
state_file="${TEST_SYSTEM_STATE:?}"
log_file="${TEST_SYSTEM_LOG:?}"
case "${1:-}" in
    is-active)
        [ -f "$state_file" ]
        ;;
    stop)
        printf '%s\n' stop >> "$log_file"
        rm -f "$state_file"
        ;;
    start)
        printf '%s\n' start >> "$log_file"
        : > "$state_file"
        ;;
    *)
        exit 1
        ;;
esac
EOS
chmod +x "$SANDBOX_DIR/bin/systemctl"

cat <<'EOS' > "$SANDBOX_DIR/bin/sudo"
#!/usr/bin/env bash
exec "$@"
EOS
chmod +x "$SANDBOX_DIR/bin/sudo"

cat <<'EOS' > "$SANDBOX_DIR/bin/pgrep"
#!/usr/bin/env bash
exit 1
EOS
chmod +x "$SANDBOX_DIR/bin/pgrep"

cat <<'EOS' > "$SANDBOX_DIR/bin/age"
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
export TEST_SYSTEM_STATE="$SANDBOX_DIR/agentmemory.active"
export TEST_SYSTEM_LOG="$SANDBOX_DIR/systemctl.log"
export AGENTMEMORY_DATA_DIR="$SANDBOX_DIR/state/agentmemory"

mkdir -p "$AGENTMEMORY_DATA_DIR" "$HOME/.agentmemory"
printf '%s\n' memory-record > "$AGENTMEMORY_DATA_DIR/memories.json"
printf '%s\n' private-setting > "$HOME/.agentmemory/.env"
: > "$TEST_SYSTEM_STATE"

BACKUP_FILE="$SANDBOX_DIR/agentmemory.vault"
"$REPO_ROOT/scripts/agentmemory-vault.sh" backup "$BACKUP_FILE" >/dev/null
[ -f "$BACKUP_FILE" ] || { echo "backup file was not created" >&2; exit 1; }
[ -f "$TEST_SYSTEM_STATE" ] || { echo "active service was not restarted" >&2; exit 1; }
[ "$(sed -n '1,2p' "$TEST_SYSTEM_LOG")" = $'stop\nstart' ] || {
    echo "service lifecycle was not stop/start" >&2
    exit 1
}

rm -rf "$AGENTMEMORY_DATA_DIR" "$HOME/.agentmemory"
"$REPO_ROOT/scripts/agentmemory-vault.sh" restore "$BACKUP_FILE" >/dev/null
[ "$(cat "$AGENTMEMORY_DATA_DIR/memories.json")" = "memory-record" ] || {
    echo "memory state was not restored" >&2
    exit 1
}
[ "$(cat "$HOME/.agentmemory/.env")" = "private-setting" ] || {
    echo "user settings were not restored" >&2
    exit 1
}

if "$REPO_ROOT/scripts/agentmemory-vault.sh" restore "$SANDBOX_DIR/missing.vault" >/dev/null 2>&1; then
    echo "restore unexpectedly succeeded for a missing vault" >&2
    exit 1
fi
[ -f "$TEST_SYSTEM_STATE" ] || { echo "service was not restarted after failure" >&2; exit 1; }

echo "Agentmemory Vault wrapper lifecycle tests passed."
