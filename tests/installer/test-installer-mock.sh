#!/usr/bin/env bash
# Exercise the real installer orchestration with mocked external commands.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/nixos-installer.sh"
TEST_ROOT="$(mktemp -d -t dotfiles-installer-test-XXXXXX)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

make_mock_bin() {
    local mock_bin="$1"
    mkdir -p "$mock_bin"

    cat > "$mock_bin/id" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-u" ]; then
    echo 0
else
    exec /usr/bin/id "$@"
fi
EOF
    cat > "$mock_bin/hostname" <<'EOF'
#!/usr/bin/env bash
echo fixture-host
EOF
    cat > "$mock_bin/ping" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat > "$mock_bin/clear" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    cat > "$mock_bin/lsblk" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *" -f "* ]]; then
    echo '/dev/loop7'
elif [[ " $* " == *" -n "* ]]; then
    echo 'loop7'
else
    echo 'NAME SIZE MODEL TYPE TRAN'
    echo 'loop7 20G fixture loop '
fi
EOF
    cat > "$mock_bin/findmnt" <<'EOF'
#!/usr/bin/env bash
if [ "${FINDMNT_MOUNTED:-0}" = 1 ] && [[ " $* " == *" --mountpoint "* ]]; then
    exit 0
fi
exit 1
EOF
    cat > "$mock_bin/swapon" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *" --show="* ]]; then
    exit 0
fi
echo "swapon $*" >> "$INSTALLER_TEST_LOG"
EOF
    cat > "$mock_bin/umount" <<'EOF'
#!/usr/bin/env bash
echo "umount $*" >> "$INSTALLER_TEST_LOG"
[ "${UNMOUNT_FAIL:-0}" = 1 ] && exit 42
exit 0
EOF
    cat > "$mock_bin/nix" <<'EOF'
#!/usr/bin/env bash
echo "nix $*" >> "$INSTALLER_TEST_LOG"
if [ "${NIX_FAIL_BUILD:-0}" = 1 ] && [ "${1:-}" = build ]; then
    exit 44
fi
exit 0
EOF
    cat > "$mock_bin/nix-shell" <<'EOF'
#!/usr/bin/env bash
echo "nix-shell $*" >> "$INSTALLER_TEST_LOG"
if [ "${1:-}" = -p ] && [ "${2:-}" = git ]; then
    mkdir -p "$DOTFILES_REPO_DEST"
    cp -a "$DOTFILES_REPO_SOURCE/." "$DOTFILES_REPO_DEST/"
fi
exit 0
EOF
    cat > "$mock_bin/nixos-generate-config" <<'EOF'
#!/usr/bin/env bash
echo "nixos-generate-config $*" >> "$INSTALLER_TEST_LOG"
mkdir -p "$INSTALLER_MOUNT_ROOT/etc/nixos"
printf '%s\n' '{ fileSystems."/" = { device = "fixture"; }; }' > "$INSTALLER_MOUNT_ROOT/etc/nixos/hardware-configuration.nix"
EOF
    cat > "$mock_bin/nixos-install" <<'EOF'
#!/usr/bin/env bash
echo "nixos-install $*" >> "$INSTALLER_TEST_LOG"
EOF
    for command_name in wipefs parted mkfs.fat mkswap mkfs.ext4 partprobe mount chown reboot; do
        cat > "$mock_bin/$command_name" <<EOF
#!/usr/bin/env bash
echo "$command_name \$*" >> "\$INSTALLER_TEST_LOG"
exit 0
EOF
    done
    chmod +x "$mock_bin"/*
}

run_case() {
    local case_name="$1"
    local nix_fail="$2"
    local findmnt_mounted="$3"
    local case_dir="$TEST_ROOT/$case_name"
    local mock_bin="$case_dir/bin"
    local log_file="$case_dir/commands.log"
    local output_file="$case_dir/output.log"
    mkdir -p "$case_dir/mnt"
    make_mock_bin "$mock_bin"

    set +e
    printf 'fixture-user\nfixture-host\nloop7\nYES\n1024MiB\n0\n%s\nsystemd-boot\n26.05\ny\nn\n' "$REPO_ROOT" |
        env \
            PATH="$mock_bin:$PATH" \
            HOME="$case_dir/home" \
            TERM=xterm \
            INSTALLER_TEST_LOG="$log_file" \
            INSTALLER_DEVICE_DIR=/dev \
            INSTALLER_MOUNT_ROOT="$case_dir/mnt" \
            INSTALLER_PARTITION_SETTLE_SECONDS=0 \
            NIXOS_INSTALLER_PASSWORD_HASH=fixture-hash \
            NIX_FAIL_BUILD="$nix_fail" \
            FINDMNT_MOUNTED="$findmnt_mounted" \
            UNMOUNT_FAIL="$findmnt_mounted" \
            bash "$INSTALLER" >"$output_file" 2>&1
    local status=$?
    set -e
    if [ "$status" -ne 0 ]; then
        sed -n '1,220p' "$output_file" >&2
        cat "$log_file" >&2 || true
    fi
    printf '%s\n' "$status"
    printf '%s\n' "$case_dir"
}

happy_result="$(run_case happy 0 0)"
happy_status="$(printf '%s\n' "$happy_result" | sed -n '1p')"
happy_dir="$(printf '%s\n' "$happy_result" | sed -n '2p')"
[ "$happy_status" -eq 0 ]
grep -q '^wipefs ' "$happy_dir/commands.log"
grep -q '^parted ' "$happy_dir/commands.log"
grep -q '^mkfs.fat ' "$happy_dir/commands.log"
grep -q '^nixos-generate-config ' "$happy_dir/commands.log"
grep -q '^nixos-install ' "$happy_dir/commands.log"
grep -q 'fixture-user' "$happy_dir/mnt/home/fixture-user/dotfiles/.machine/configuration.nix"
if [ "$(awk '/^nix build/{print NR; exit}' "$happy_dir/commands.log")" -ge "$(awk '/^wipefs/{print NR; exit}' "$happy_dir/commands.log")" ]; then
    echo 'candidate validation did not precede wipefs' >&2
    exit 1
fi
candidate_build_line="$(awk '/^nix build/{print NR; exit}' "$happy_dir/commands.log")"
wipe_line="$(awk '/^wipefs/{print NR; exit}' "$happy_dir/commands.log")"
hardware_line="$(awk '/^nixos-generate-config/{print NR; exit}' "$happy_dir/commands.log")"
final_build_line="$(awk '/^nix build/{if (++count == 2) print NR}' "$happy_dir/commands.log")"
[ "$candidate_build_line" -lt "$wipe_line" ]
[ "$wipe_line" -lt "$hardware_line" ]
[ "$hardware_line" -lt "$final_build_line" ]

config_before="$(sha256sum "$happy_dir/mnt/home/fixture-user/dotfiles/.machine/configuration.nix")"
PATH="$happy_dir/bin:$PATH" \
    INSTALLER_TEST_LOG="$happy_dir/commands.log" \
    INSTALLER_MOUNT_ROOT="$happy_dir/mnt" \
    HOME="$happy_dir/home" \
    NIXOS_INSTALLER_SOURCE_ONLY=1 \
    bash -s -- "$INSTALLER" "$happy_dir/mnt/home/fixture-user/dotfiles" <<'EOF'
set -euo pipefail
source "$1"
finalize_machine_config fixture-user fixture-host "$2" systemd-boot 26.05 fixture-hash
finalize_machine_config fixture-user fixture-host "$2" systemd-boot 26.05 fixture-hash
EOF
config_after="$(sha256sum "$happy_dir/mnt/home/fixture-user/dotfiles/.machine/configuration.nix")"
[ "$config_before" = "$config_after" ]

invalid_result="$(run_case invalid-candidate 1 0)"
invalid_status="$(printf '%s\n' "$invalid_result" | sed -n '1p')"
invalid_dir="$(printf '%s\n' "$invalid_result" | sed -n '2p')"
[ "$invalid_status" -ne 0 ]
if grep -q '^wipefs ' "$invalid_dir/commands.log"; then exit 1; fi
if grep -q '^parted ' "$invalid_dir/commands.log"; then exit 1; fi
if grep -q '^mkfs.ext4 ' "$invalid_dir/commands.log"; then exit 1; fi

unmount_result="$(run_case unmount-failure 0 1)"
unmount_status="$(printf '%s\n' "$unmount_result" | sed -n '1p')"
unmount_dir="$(printf '%s\n' "$unmount_result" | sed -n '2p')"
[ "$unmount_status" -ne 0 ]
if grep -q '^wipefs ' "$unmount_dir/commands.log"; then exit 1; fi

echo "[✓] real installer orchestration validates before wipe, aborts on unmount failure, propagates fixture-user, and remains idempotent"
