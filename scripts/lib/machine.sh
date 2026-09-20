#!/usr/bin/env bash

detect_machine() {
    info "Detecting machine..."

    ARCH="$(uname -m)"
    HOSTNAME="$(hostname)"
    USERNAME="$(id -un)"
    USER_HOME="${DOTFILES_USER_HOME:-$HOME}"

    if [ -z "${DOTFILES_USER_HOME:-}" ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        USERNAME="$SUDO_USER"
        USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    fi

    case "$ARCH" in
        x86_64)
            SYSTEM="x86_64-linux"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            ;;
    esac

    echo "  Repository : $REPO_ROOT"
    echo "  System     : $SYSTEM"
    echo "  Hostname   : $HOSTNAME"
    echo "  User       : $USERNAME"
    echo "  Home       : $USER_HOME"

    success "Machine detected"
}

prepare_machine_dir() {
    MACHINE_DIR="${DOTFILES_MACHINE_DIR:-$REPO_ROOT/.machine}"
    mkdir -p "$MACHINE_DIR"
}

detect_bootloader_policy() {
    if [ -n "${DOTFILES_BOOTLOADER:-}" ]; then
        case "$DOTFILES_BOOTLOADER" in
            systemd-boot|grub) printf '%s\n' "$DOTFILES_BOOTLOADER"; return 0 ;;
            *) error "Unsupported DOTFILES_BOOTLOADER: $DOTFILES_BOOTLOADER" ;;
        esac
    fi

    if [ -d /boot/loader/entries ] || { [ -d /sys/firmware/efi ] && command -v bootctl >/dev/null 2>&1 && bootctl is-installed >/dev/null 2>&1; }; then
        printf '%s\n' systemd-boot
    elif [ -d /boot/grub ] || [ -f /etc/default/grub ]; then
        printf '%s\n' grub
    else
        error "Could not detect the existing bootloader; set DOTFILES_BOOTLOADER=systemd-boot or grub."
    fi
}

bootloader_config() {
    case "$1" in
        systemd-boot)
            cat <<'EOF'
  boot.loader.systemd-boot.enable = true;
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
EOF
            ;;
        grub)
            cat <<'EOF'
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
EOF
            ;;
        *)
            error "Unsupported bootloader: $1"
            ;;
    esac
}

validate_state_version() {
    [[ "$1" =~ ^[0-9]{2}\.[0-9]{2}$ ]] \
        || error "Invalid NixOS stateVersion: $1 (expected YY.MM)"
}

migrate_machine_hardware_extra_import() {
    if grep -Fq './hardware-extra.nix' "$MACHINE_CONFIG"; then
        return 0
    fi

    if ! grep -Eq '^[[:space:]]*\./hardware-configuration\.nix[[:space:]]*$' "$MACHINE_CONFIG"; then
        error "Existing machine configuration does not import ./hardware-configuration.nix; add ./hardware-extra.nix to its imports manually."
    fi

    if [ ! -w "$MACHINE_CONFIG" ]; then
        error "Existing machine configuration is not writable; restore ownership, then rerun bootstrap so ./hardware-extra.nix can be imported."
    fi

    sed -i '/^[[:space:]]*\.\/hardware-configuration\.nix[[:space:]]*$/a\    ./hardware-extra.nix' "$MACHINE_CONFIG"
    success "Migrated existing machine configuration to import $HARDWARE_EXTRA"
}

detect_state_version() {
    local state_version
    local system_configuration
    local -a detected_versions=()
    DETECTED_STATE_VERSION=""

    if [ "${DOTFILES_STATE_VERSION+x}" = x ]; then
        state_version="$DOTFILES_STATE_VERSION"
        validate_state_version "$state_version"
        DETECTED_STATE_VERSION="$state_version"
        return 0
    fi

    system_configuration="${DOTFILES_SYSTEM_CONFIGURATION:-/etc/nixos/configuration.nix}"
    if [ -r "$system_configuration" ]; then
        while IFS= read -r state_version; do
            [ -n "$state_version" ] && detected_versions+=("$state_version")
        done < <(
            sed -nE \
                's/^[[:space:]]*system\.stateVersion[[:space:]]*=[[:space:]]*"([0-9]{2}\.[0-9]{2})"[[:space:]]*;.*$/\1/p' \
                "$system_configuration"
        )
    fi

    if [ "${#detected_versions[@]}" -eq 1 ]; then
        DETECTED_STATE_VERSION="${detected_versions[0]}"
        return 0
    fi

    error "$(cat <<'EOF'
Could not determine this machine's system.stateVersion.

Run bootstrap again with:

DOTFILES_STATE_VERSION=23.11 ./scripts/bootstrap.sh
EOF
)"
}

generate_machine_state() {
    HARDWARE_CONFIG="$MACHINE_DIR/hardware-configuration.nix"
    MACHINE_CONFIG="$MACHINE_DIR/configuration.nix"
    HARDWARE_EXTRA="$MACHINE_DIR/hardware-extra.nix"

    if [ ! -f "$HARDWARE_CONFIG" ]; then
        info "Generating hardware configuration..."
        # Keep the generated file owned by the invoking user; only hardware probing needs root.
        # shellcheck disable=SC2024
        sudo nixos-generate-config --show-hardware-config > "$HARDWARE_CONFIG"
        success "Hardware configuration generated"
    else
        info "Preserving existing hardware configuration at $HARDWARE_CONFIG"
    fi

    if [ ! -f "$HARDWARE_EXTRA" ]; then
        cat > "$HARDWARE_EXTRA" <<'EOF'
# Machine-local hardware opt-ins. Add imports only for hardware present here.
{
  imports = [
    # ../modules/hardware/intel-graphics.nix
    # ../modules/hardware/weikav-nut75.nix
  ];

  # Optional machine-specific kernel parameters.
  # boot.kernelParams = [
  #   "usbcore.autosuspend=-1"
  #   "hid_apple.fnmode=0"
  # ];
}
EOF
        success "Machine hardware opt-in template generated"
    else
        info "Preserving existing hardware opt-ins at $HARDWARE_EXTRA"
    fi

    if [ -f "$MACHINE_CONFIG" ]; then
        migrate_machine_hardware_extra_import
        success "Existing machine configuration preserved at $MACHINE_CONFIG"
        return 0
    fi

    info "Generating machine configuration for a new machine state..."
    local bootloader
    local state_version
    bootloader="$(detect_bootloader_policy)"
    detect_state_version
    state_version="$DETECTED_STATE_VERSION"
    cat > "$MACHINE_CONFIG" <<EOF
# ============================================================
# AUTO-GENERATED MACHINE CONFIGURATION
#
# Generated by:
#   scripts/bootstrap
#
# DO NOT EDIT MANUALLY.
# This file is machine-specific and should NOT be committed.
# ============================================================

{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
    ./hardware-extra.nix
  ];

  networking.hostName = "$HOSTNAME";
  dotfiles.primaryUser = "$USERNAME";

  # Detected machine-local boot policy; do not replace this file on later runs.
$(bootloader_config "$bootloader")
  system.stateVersion = "$state_version";

  users.users."$USERNAME" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
      "uinput"
      "docker"
      "video"
    ];
  };
}
EOF
    success "Machine configuration generated"
}

ensure_gitignore() {
    GITIGNORE="${DOTFILES_GITIGNORE:-$REPO_ROOT/.gitignore}"

    if [ ! -f "$GITIGNORE" ]; then
        touch "$GITIGNORE"
    fi

    if ! grep -qxF ".machine/" "$GITIGNORE"; then
        echo ".machine/" >> "$GITIGNORE"
    fi

    success ".machine/ added to .gitignore"
}

show_generated_state() {
    info "Generated configuration:"
    echo
    cat "$MACHINE_CONFIG"
    echo
}
