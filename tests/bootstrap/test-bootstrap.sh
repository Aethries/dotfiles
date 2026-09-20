#!/usr/bin/env bash
# Run the real bootstrap orchestration against a temporary home and machine state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d -t dotfiles-bootstrap-test-XXXXXX)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

MACHINE_DIR="$TEST_ROOT/machine"
USER_HOME="$TEST_ROOT/home"
GITIGNORE="$TEST_ROOT/gitignore"
MOCK_BIN="$TEST_ROOT/bin"
LOG_FILE="$TEST_ROOT/commands.log"
SYNC_SCRIPT="$TEST_ROOT/sync-editors.sh"
GATEWAY_SCRIPT="$TEST_ROOT/reconcile-gateways.sh"
mkdir -p "$MACHINE_DIR" "$USER_HOME" "$MOCK_BIN"
: > "$GITIGNORE"

cat > "$MOCK_BIN/id" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
    -u) echo 0 ;;
    -un) echo fixture-user ;;
    *) exec /usr/bin/id "$@" ;;
esac
EOF
cat > "$MOCK_BIN/hostname" <<'EOF'
#!/usr/bin/env bash
echo fixture-host
EOF
cat > "$MOCK_BIN/nix" <<'EOF'
#!/usr/bin/env bash
echo "nix $*" >> "$BOOTSTRAP_TEST_LOG"
exit 0
EOF
cat > "$MOCK_BIN/nixos-generate-config" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$MOCK_BIN/npm" <<'EOF'
#!/usr/bin/env bash
echo "npm $*" >> "$BOOTSTRAP_TEST_LOG"
exit 0
EOF
cat > "$MOCK_BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "systemctl $*" >> "$BOOTSTRAP_TEST_LOG"
exit 0
EOF
cat > "$MOCK_BIN/sudo" <<'EOF'
#!/usr/bin/env bash
echo "sudo $*" >> "$BOOTSTRAP_TEST_LOG"
if [ "${1:-}" = nixos-generate-config ]; then
    printf '%s\n' '{ fileSystems."/" = { device = "fixture"; }; }'
fi
exit 0
EOF
cat > "$SYNC_SCRIPT" <<'EOF'
#!/usr/bin/env bash
echo sync-editors >> "$BOOTSTRAP_TEST_LOG"
EOF
cat > "$GATEWAY_SCRIPT" <<'EOF'
#!/usr/bin/env bash
echo reconcile-gateways >> "$BOOTSTRAP_TEST_LOG"
EOF
chmod +x "$MOCK_BIN"/* "$SYNC_SCRIPT" "$GATEWAY_SCRIPT"

export PATH="$MOCK_BIN:$PATH"
export HOME="$USER_HOME"
export BOOTSTRAP_TEST_LOG="$LOG_FILE"
export DOTFILES_REPO_ROOT="$REPO_ROOT"
export DOTFILES_MACHINE_DIR="$MACHINE_DIR"
export DOTFILES_USER_HOME="$USER_HOME"
export DOTFILES_GITIGNORE="$GITIGNORE"
export DOTFILES_BOOTLOADER=systemd-boot
export DOTFILES_STATE_VERSION=23.11
export DOTFILES_SYNC_EDITORS_SCRIPT="$SYNC_SCRIPT"
export DOTFILES_RECONCILE_GATEWAYS_SCRIPT="$GATEWAY_SCRIPT"
export DOTFILES_BOOTSTRAP_SOURCE_ONLY=1

source "$REPO_ROOT/scripts/bootstrap.sh"
main

test -s "$MACHINE_DIR/hardware-configuration.nix"
test -s "$MACHINE_DIR/configuration.nix"
test -s "$MACHINE_DIR/hardware-extra.nix"
grep -q 'dotfiles.primaryUser = "fixture-user"' "$MACHINE_DIR/configuration.nix"
grep -q 'system.stateVersion = "23.11"' "$MACHINE_DIR/configuration.nix"
grep -q 'boot.loader.systemd-boot.enable = true' "$MACHINE_DIR/configuration.nix"
if grep -q '"seat"' "$MACHINE_DIR/configuration.nix"; then
    exit 1
fi
grep -q '^nix flake check' "$LOG_FILE"
grep -q '^sudo nixos-generate-config' "$LOG_FILE"
grep -q '^sudo env' "$LOG_FILE"
grep -q '^sync-editors$' "$LOG_FILE"
grep -q '^reconcile-gateways$' "$LOG_FILE"

cat > "$MACHINE_DIR/custom.nix" <<'EOF'
{ boot.kernelParams = [ "fixture-custom" ]; }
EOF
cat > "$MACHINE_DIR/hardware-extra.nix" <<'EOF'
{
  imports = [ ../modules/hardware/intel-graphics.nix ];
}
EOF
cat > "$MACHINE_DIR/configuration.nix" <<'EOF'
{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
    ./hardware-extra.nix
    ./custom.nix
  ];
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  system.stateVersion = "23.11";
  networking.hostName = "preserved-host";
}
EOF
existing_hash="$(sha256sum "$MACHINE_DIR/configuration.nix")"
main
existing_hash_after="$(sha256sum "$MACHINE_DIR/configuration.nix")"

test "$existing_hash" = "$existing_hash_after"
grep -q 'boot.loader.grub.enable = true' "$MACHINE_DIR/configuration.nix"
grep -q 'system.stateVersion = "23.11"' "$MACHINE_DIR/configuration.nix"
grep -q './custom.nix' "$MACHINE_DIR/configuration.nix"
grep -q 'intel-graphics.nix' "$MACHINE_DIR/hardware-extra.nix"

detected_machine_dir="$TEST_ROOT/detected-machine"
detected_configuration="$TEST_ROOT/detected-configuration.nix"
cat > "$detected_configuration" <<'EOF'
{
  system.stateVersion = "24.11";
}
EOF
unset DOTFILES_STATE_VERSION
export DOTFILES_SYSTEM_CONFIGURATION="$detected_configuration"
export DOTFILES_MACHINE_DIR="$detected_machine_dir"
main
grep -q 'system.stateVersion = "24.11"' "$detected_machine_dir/configuration.nix"

no_detect_machine_dir="$TEST_ROOT/no-detect-machine"
export DOTFILES_SYSTEM_CONFIGURATION="$TEST_ROOT/missing-configuration.nix"
export DOTFILES_MACHINE_DIR="$no_detect_machine_dir"
if (main >"$TEST_ROOT/no-detect-output.log" 2>&1); then
    echo "bootstrap unexpectedly succeeded without a trustworthy stateVersion source" >&2
    exit 1
fi
grep -q "Could not determine this machine's system.stateVersion." "$TEST_ROOT/no-detect-output.log"
test ! -e "$no_detect_machine_dir/configuration.nix"
if grep -q '26.05' "$no_detect_machine_dir/configuration.nix" 2>/dev/null; then
    exit 1
fi

echo "[✓] real bootstrap orchestration preserves existing machine config, detects or requires stateVersion, and remains idempotent"
