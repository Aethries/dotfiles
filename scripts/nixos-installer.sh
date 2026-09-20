#!/usr/bin/env bash

# ============================================================
# NixOS Interactive Automated Installer
# Designed for Live ISO / USB installation
#
# Steps:
# 1. Wi-Fi & Network Connection Wizard (interactive selection)
# 2. Collect and validate the complete installation plan
# 3. Disk Selection, Partitioning & Formatting (EFI, Swap, Root)
# 4. Generate final hardware configuration and validate it again
# 5. Execute nixos-install and finalize
# ============================================================

set -euo pipefail

# ANSI color codes
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${DOTFILES_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
INSTALLER_MOUNT_ROOT="${INSTALLER_MOUNT_ROOT:-/mnt}"

info() { echo -e "${BLUE}==>${RESET} ${BOLD}$1${RESET}"; }
success() { echo -e "${GREEN}✓${RESET} $1"; }
warn() { echo -e "${YELLOW}!${RESET} $1"; }
error() { echo -e "${RED}✗${RESET} $1" >&2; exit 1; }

size_to_mib() {
    [[ "$1" =~ ^([1-9][0-9]*)(MiB|GiB)$ ]] || error "Invalid partition size: $1 (use MiB or GiB)"
    if [ "${BASH_REMATCH[2]}" = "GiB" ]; then
        echo $((BASH_REMATCH[1] * 1024))
    else
        echo "${BASH_REMATCH[1]}"
    fi
}

[ "$(size_to_mib 1GiB)" -eq 1024 ] || error "Partition size conversion failed."

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  _   _ _       ___  ____    ___           _        _ _           
 | \ | (_)_  __/ _ \/ ___|  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 |  \| | \ \/ / | | \___ \   | || '_ \/ __| __/ _` | | |/ _ \ '__|
 | |\  | |>  <| |_| |___) |  | || | | \__ \ || (_| | | |  __/ |   
 |_| \_|_/_/\_\\___/|____/  |___|_| |_|___/\__\__,_|_|_|\___|_|   
EOF
    echo -e "${RESET}"
    echo -e "Dotfiles: https://github.com/Aethries/dotfiles"
    echo -e "============================================================"
    echo
}

check_connection() {
    if ! ping -c 1 -W 2 "${CHECK_HOST:-1.1.1.1}" >/dev/null 2>&1; then
        warn "No active internet connection detected!"
        echo "Make sure you connect to Wi-Fi/Ethernet first (e.g. via 'nmtui' or 'nmcli') so packages can be downloaded."
        read -r -p "Press Enter to proceed anyway, or Ctrl+C to abort: " _
    else
        success "Internet connection verified."
    fi
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This installer must be run as root (or via 'sudo $0')."
    fi
}

preflight() {
    bash "$SCRIPT_DIR/preflight.sh" installer
}

disk_path() {
    printf '%s/%s\n' "${INSTALLER_DEVICE_DIR:-/dev}" "$1"
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
            error "Unsupported bootloader: $1 (choose systemd-boot or grub)"
            ;;
    esac
}

validate_state_version() {
    [[ "$1" =~ ^[0-9]{2}\.[0-9]{2}$ ]] \
        || error "Invalid NixOS stateVersion: $1 (expected YY.MM)"
}

collect_install_config() {
    local suggested_user="${SUDO_USER:-${USER:-loc}}"
    local suggested_host
    suggested_host="$(hostname)"
    [ "$suggested_host" = "nixos" ] && suggested_host="nixos-workstation"

    read -r -p "Enter primary user account name [default: $suggested_user]: " INSTALL_USER
    INSTALL_USER="${INSTALL_USER:-$suggested_user}"
    [[ "$INSTALL_USER" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] \
        || error "Invalid user name: $INSTALL_USER"

    read -r -p "Enter system hostname [default: $suggested_host]: " INSTALL_HOSTNAME
    INSTALL_HOSTNAME="${INSTALL_HOSTNAME:-$suggested_host}"
    [[ "$INSTALL_HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] \
        || error "Invalid hostname: $INSTALL_HOSTNAME"

    local suggested_disk
    suggested_disk="$(lsblk -d -e 7,11 -n -o NAME | grep -E 'nvme0n1|sda|vda' | head -n 1 || true)" # BEST_EFFORT: no conventional disk name is a valid state; the user can enter it explicitly.
    read -r -p "Enter disk name to install NixOS (e.g. nvme0n1, sda) [default: $suggested_disk]: " INSTALL_DISK
    INSTALL_DISK="${INSTALL_DISK:-$suggested_disk}"
    [[ "$INSTALL_DISK" =~ ^[a-zA-Z0-9._-]+$ ]] || error "Invalid target disk name: $INSTALL_DISK"
    local target_disk_path
    target_disk_path="$(disk_path "$INSTALL_DISK")"
    [ -b "$target_disk_path" ] || error "Device $target_disk_path does not exist."

    echo
    echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${RESET}"
    echo -e "${RED}${BOLD}  WARNING: ALL DATA ON $target_disk_path WILL BE PERMANENTLY ERASED!${RESET}"
    echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${RESET}"
    echo
    read -r -p "Type 'YES' (in capital letters) to confirm formatting $target_disk_path: " INSTALL_WIPE_CONFIRMATION
    [ "$INSTALL_WIPE_CONFIRMATION" = "YES" ] || error "Installation aborted by user."

    read -r -p "EFI partition size (default: 1024MiB): " INSTALL_EFI_SIZE
    INSTALL_EFI_SIZE="${INSTALL_EFI_SIZE:-1024MiB}"
    size_to_mib "$INSTALL_EFI_SIZE" >/dev/null

    read -r -p "Swap partition size (e.g. 16GiB, 8GiB, or 0 for none) [default: 16GiB]: " INSTALL_SWAP_SIZE
    INSTALL_SWAP_SIZE="${INSTALL_SWAP_SIZE:-16GiB}"
    if [ "$INSTALL_SWAP_SIZE" != "0" ] && [ "$INSTALL_SWAP_SIZE" != "none" ]; then
        size_to_mib "$INSTALL_SWAP_SIZE" >/dev/null
    fi

    local default_repo="${DOTFILES_REPO:-https://github.com/Aethries/dotfiles.git}"
    read -r -p "Enter dotfiles Git repository URL [default: $default_repo]: " INSTALL_REPO
    INSTALL_REPO="${INSTALL_REPO:-$default_repo}"

    local default_bootloader="${NIXOS_BOOTLOADER:-systemd-boot}"
    read -r -p "Bootloader (systemd-boot/grub) [default: $default_bootloader]: " INSTALL_BOOTLOADER
    INSTALL_BOOTLOADER="${INSTALL_BOOTLOADER:-$default_bootloader}"
    case "$INSTALL_BOOTLOADER" in
        systemd-boot|grub) ;;
        *) error "Invalid bootloader: $INSTALL_BOOTLOADER" ;;
    esac

    local default_state_version="${NIXOS_STATE_VERSION:-26.05}"
    read -r -p "NixOS stateVersion for this new installation [default: $default_state_version]: " INSTALL_STATE_VERSION
    INSTALL_STATE_VERSION="${INSTALL_STATE_VERSION:-$default_state_version}"
    validate_state_version "$INSTALL_STATE_VERSION"

    if [ -n "${NIXOS_INSTALLER_PASSWORD_HASH:-}" ]; then
        INSTALL_PASSWORD_HASH="$NIXOS_INSTALLER_PASSWORD_HASH"
    else
        local user_pass="" user_pass_confirm=""
        info "Set password for user '$INSTALL_USER':"
        while [ -z "$user_pass" ]; do
            read -r -s -p "Enter password: " user_pass
            echo
            read -r -s -p "Confirm password: " user_pass_confirm
            echo
            if [ "$user_pass" != "$user_pass_confirm" ]; then
                warn "Passwords do not match. Please try again."
                user_pass=""
            fi
        done
        INSTALL_PASSWORD_HASH="$(printf '%s\n' "$user_pass" | nix-shell -p whois --run 'mkpasswd -m sha-512 -s')"
        unset user_pass user_pass_confirm
    fi
}

prepare_candidate_repository() {
    if [ "$INSTALL_REPO" = "$REPO_ROOT" ] || [ "$INSTALL_REPO" = "path:$REPO_ROOT" ]; then
        VALIDATED_REPO_ROOT="$REPO_ROOT"
        return 0
    fi

    VALIDATED_REPO_ROOT="$INSTALLER_WORK_DIR/repository"
    info "Preparing a temporary copy of the selected dotfiles repository..."
    # shellcheck disable=SC2016
    DOTFILES_REPO_SOURCE="$INSTALL_REPO" DOTFILES_REPO_DEST="$VALIDATED_REPO_ROOT" \
        nix-shell -p git --run 'git clone --depth=1 "$DOTFILES_REPO_SOURCE" "$DOTFILES_REPO_DEST"'
}

prepare_candidate_machine_config() {
    INSTALLER_WORK_DIR="${INSTALLER_WORK_DIR:-$(mktemp -d -t dotfiles-installer-preflight-XXXXXX)}"
    CANDIDATE_MACHINE_CONFIG="$INSTALLER_WORK_DIR/configuration.nix"
    CANDIDATE_HARDWARE_CONFIG="$INSTALLER_WORK_DIR/hardware-configuration.nix"
    CANDIDATE_HARDWARE_EXTRA="$INSTALLER_WORK_DIR/hardware-extra.nix"

    cat > "$CANDIDATE_HARDWARE_CONFIG" <<'EOF'
{
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
}
EOF
    cat > "$CANDIDATE_HARDWARE_EXTRA" <<'EOF'
{ }
EOF
    {
        printf '%s\n' '{'
        printf '  imports = [ %s/configuration.nix %s/hardware-configuration.nix %s/hardware-extra.nix ];\n' \
            "$VALIDATED_REPO_ROOT" "$INSTALLER_WORK_DIR" "$INSTALLER_WORK_DIR"
        printf '  networking.hostName = "%s";\n' "$INSTALL_HOSTNAME"
        printf '  dotfiles.primaryUser = "%s";\n' "$INSTALL_USER"
        bootloader_config "$INSTALL_BOOTLOADER"
        printf '  system.stateVersion = "%s";\n' "$INSTALL_STATE_VERSION"
        cat <<EOF
  users.users."$INSTALL_USER" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" "uinput" "docker" "video" ];
  };
EOF
        printf '}\n'
    } > "$CANDIDATE_MACHINE_CONFIG"
}

validate_candidate_machine_config() {
    info "Validating the candidate NixOS configuration before touching the target disk..."
    nix flake check "path:$VALIDATED_REPO_ROOT" --no-build
    DOTFILES_MACHINE_CONFIG="$CANDIDATE_MACHINE_CONFIG" \
        nix build "path:$VALIDATED_REPO_ROOT#nixosConfigurations.check.config.system.build.toplevel" \
            --dry-run --impure
    success "Candidate configuration validated; destructive disk operations are now allowed."
}

mounted_target_partition() {
    findmnt -rn -S "$1" >/dev/null 2>&1
}

unmount_target_partitions() {
    local disk_path="$1"
    local partition
    local active_swaps

    if findmnt -rn --mountpoint "$INSTALLER_MOUNT_ROOT" >/dev/null 2>&1; then
        umount -R "$INSTALLER_MOUNT_ROOT" || error "Could not unmount $INSTALLER_MOUNT_ROOT; refusing to wipe $disk_path."
    fi

    active_swaps="$(swapon --noheadings --show=NAME)" \
        || error "Could not inspect active swap devices; refusing to wipe $disk_path."
    while IFS= read -r partition; do
        [ -n "$partition" ] || continue
        case "$partition" in
            "$disk_path"*)
                swapoff "$partition" \
                    || error "Could not disable target swap $partition; refusing to wipe $disk_path."
                ;;
        esac
    done <<< "$active_swaps"

    for partition in "${disk_path}"?*; do
        [ -b "$partition" ] || continue
        if mounted_target_partition "$partition"; then
            umount "$partition" \
                || error "Could not unmount target partition $partition; refusing to wipe $disk_path."
        fi
        mounted_target_partition "$partition" \
            && error "Target partition $partition is still mounted; refusing to wipe $disk_path."
    done
}

# ============================================================
# STEP 1: Disk Selection & Partitioning
# ============================================================
setup_disk() {
    [ "$#" -eq 3 ] || error "setup_disk requires target disk, EFI size, and swap size"
    local target_disk="$1"
    local efi_size="$2"
    local swap_size="$3"
    echo
    info "Step 1: Detecting storage drives..."
    echo
    lsblk -d -e 7,11 -o NAME,SIZE,MODEL,TYPE,TRAN
    echo

    local disk_path
    disk_path="$(disk_path "$target_disk")"
    [ -b "$disk_path" ] || error "Device $disk_path does not exist."

    local efi_mib efi_end_mib swap_mib=0 swap_end_mib
    efi_mib="$(size_to_mib "$efi_size")"
    efi_end_mib=$((efi_mib + 1))
    if [ "$swap_size" != "0" ] && [ "$swap_size" != "none" ]; then
        swap_mib="$(size_to_mib "$swap_size")"
    fi
    swap_end_mib=$((efi_end_mib + swap_mib))

    info "Unmounting any existing partitions on $disk_path..."
    unmount_target_partitions "$disk_path"

    info "Wiping existing partition table and signatures on $disk_path..."
    wipefs -a -f "$disk_path"
    parted --script "$disk_path" mklabel gpt

    # Determine partition prefix (p1 for nvme, 1 for sda)
    local part_pfx=""
    if [[ "$target_disk" =~ [0-9]$ ]]; then
        part_pfx="p"
    fi

    local p_num=1
    local efi_part="${disk_path}${part_pfx}${p_num}"
    info "Creating EFI system partition ($efi_size)..."
    parted --script "$disk_path" mkpart ESP fat32 1MiB "${efi_end_mib}MiB"
    parted --script "$disk_path" set "$p_num" esp on
    ((p_num++))

    local swap_part=""
    if [ "$swap_size" != "0" ] && [ "$swap_size" != "none" ]; then
        swap_part="${disk_path}${part_pfx}${p_num}"
        info "Creating Swap partition ($swap_size)..."
        parted --script "$disk_path" mkpart swap linux-swap "${efi_end_mib}MiB" "${swap_end_mib}MiB"
        ((p_num++))
    fi

    local root_part="${disk_path}${part_pfx}${p_num}"
    info "Creating Root partition (remaining space)..."
    if [ -n "$swap_part" ]; then
        parted --script "$disk_path" mkpart root ext4 "${swap_end_mib}MiB" 100%
    else
        parted --script "$disk_path" mkpart root ext4 "${efi_end_mib}MiB" 100%
    fi

    # Wait for kernel to register partitions
    sleep "${INSTALLER_PARTITION_SETTLE_SECONDS:-2}"
    partprobe "$disk_path"
    sleep "${INSTALLER_PARTITION_SETTLE_SECONDS:-2}"

    info "Formatting partitions..."
    echo "  -> Formatting EFI: $efi_part (FAT32, label: NIXBOOT)"
    mkfs.fat -F 32 -n NIXBOOT "$efi_part"

    if [ -n "$swap_part" ]; then
        echo "  -> Formatting Swap: $swap_part (label: NIXSWAP)"
        mkswap -L NIXSWAP "$swap_part"
        swapon "$swap_part"
    fi

    echo "  -> Formatting Root: $root_part (ext4, label: NIXROOT)"
    mkfs.ext4 -F -L NIXROOT "$root_part"

    # Mounting
    info "Mounting filesystems to $INSTALLER_MOUNT_ROOT..."
    mount "$root_part" "$INSTALLER_MOUNT_ROOT"
    mkdir -p "$INSTALLER_MOUNT_ROOT/boot"
    mount "$efi_part" "$INSTALLER_MOUNT_ROOT/boot"

    success "Filesystems mounted successfully:"
    lsblk -f "$disk_path"

}

# ============================================================
# STEP 2: Final Config Generation & Dotfiles Integration
# ============================================================
generate_hardware_config() {
    echo
    info "Generating NixOS hardware configuration..."
    nixos-generate-config --root "$INSTALLER_MOUNT_ROOT"
}

finalize_machine_config() {
    [ "$#" -eq 6 ] || error "finalize_machine_config requires user, hostname, repository, bootloader, stateVersion, and password hash"
    local install_user="$1"
    local chosen_host="$2"
    local chosen_repo="$3"
    local bootloader="$4"
    local state_version="$5"
    local pass_hash="$6"

    local user_home="$INSTALLER_MOUNT_ROOT/home/$install_user"
    local dotfiles_dir="$user_home/dotfiles"
    local machine_dir="$dotfiles_dir/.machine"

    mkdir -p "$user_home"
    info "Cloning dotfiles repository from $chosen_repo..."
    if [ -d "$dotfiles_dir" ]; then
        info "Dotfiles already present at $dotfiles_dir."
    else
        # shellcheck disable=SC2016
        DOTFILES_REPO_SOURCE="$chosen_repo" DOTFILES_REPO_DEST="$dotfiles_dir" \
            nix-shell -p git --run 'git clone "$DOTFILES_REPO_SOURCE" "$DOTFILES_REPO_DEST"'
    fi

    mkdir -p "$machine_dir"
    cp "$INSTALLER_MOUNT_ROOT/etc/nixos/hardware-configuration.nix" "$machine_dir/hardware-configuration.nix"
    if [ ! -f "$machine_dir/hardware-extra.nix" ]; then
        cat > "$machine_dir/hardware-extra.nix" <<'EOF'
# Machine-local hardware opt-ins. Add imports only for hardware present here.
{
  imports = [
    # ../modules/hardware/intel-graphics.nix
    # ../modules/hardware/weikav-nut75.nix
  ];
}
EOF
    fi

    {
        cat <<'EOF'
# ============================================================
# AUTO-GENERATED MACHINE CONFIGURATION
# ============================================================
{
    imports = [
      ../configuration.nix
      ./hardware-configuration.nix
      ./hardware-extra.nix
    ];

EOF
        printf '    networking.hostName = "%s";\n' "$chosen_host"
        printf '    dotfiles.primaryUser = "%s";\n' "$install_user"
        bootloader_config "$bootloader"
        printf '    system.stateVersion = "%s";\n\n' "$state_version"
        cat <<EOF
    users.users."$install_user" = {
      isNormalUser = true;
      initialHashedPassword = "$pass_hash";
      extraGroups = [
        "wheel"
        "networkmanager"
        "input"
        "uinput"
        "docker"
        "video"
      ];
    };
    users.users.root.initialHashedPassword = "!";
}
EOF
    } > "$machine_dir/configuration.nix"

    info "Applying initial configuration to $INSTALLER_MOUNT_ROOT/etc/nixos..."
    mkdir -p "$INSTALLER_MOUNT_ROOT/etc/nixos"
    cat > "$INSTALLER_MOUNT_ROOT/etc/nixos/configuration.nix" <<EOF
# Auto-generated by nixos-installer.sh; machine policy lives in the dotfiles repository.
{
  imports = [ /home/$install_user/dotfiles/.machine/configuration.nix ];
}
EOF

    info "Configuring Nix experimental features and Cachix cache in $INSTALLER_MOUNT_ROOT..."
    mkdir -p "$INSTALLER_MOUNT_ROOT/etc/nix"
    cat > "$INSTALLER_MOUNT_ROOT/etc/nix/nix.conf" <<'EOF'
experimental-features = nix-command flakes
auto-optimise-store = true
extra-substituters = https://noctalia.cachix.org https://cache.nixos.org
extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
EOF

    mkdir -p ~/.config/nix
    if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
    fi

    # The repository clone is created by this installer; do not recurse through the user's home.
    chown -R "${install_user}:users" "$dotfiles_dir"

    FINAL_DOTFILES_DIR="$dotfiles_dir"
    FINAL_MACHINE_CONFIG="$machine_dir/configuration.nix"
}

validate_final_machine_config() {
    [ "$#" -eq 1 ] || error "validate_final_machine_config requires the final dotfiles directory"
    local dotfiles_dir="$1"

    info "Validating the final hardware-backed NixOS configuration before installation..."
    DOTFILES_MACHINE_CONFIG="$FINAL_MACHINE_CONFIG" \
        nix build "path:$dotfiles_dir#nixosConfigurations.check.config.system.build.toplevel" \
            --dry-run --impure
    success "Final machine configuration validated."
}

# ============================================================
# STEP 3: Installation Execution
# ============================================================
run_install() {
    [ "$#" -eq 2 ] || error "run_install requires install_user and dotfiles directory"
    local install_user="$1"
    local dotfiles_dir="$2"

    echo
    info "Step 3: Ready to install NixOS!"
    echo "This will build and install the entire system using your dotfiles."
    read -r -p "Start nixos-install now? [Y/n]: " start_inst
    case "$start_inst" in
        [nN][oO]|[nN])
            warn "Skipped nixos-install. Configuration is ready at $INSTALLER_MOUNT_ROOT."
            return 0
            ;;
    esac

    local machine_config="$dotfiles_dir/.machine/configuration.nix"

    info "Running nixos-install (this may take several minutes)..."
    DOTFILES_MACHINE_CONFIG="$machine_config" \
        nixos-install --root "$INSTALLER_MOUNT_ROOT" --flake "$dotfiles_dir#check" --impure --no-root-password

    echo
    echo -e "${GREEN}${BOLD}============================================================${RESET}"
    echo -e "${GREEN}${BOLD}  NixOS Installation Complete!                              ${RESET}"
    echo -e "${GREEN}${BOLD}============================================================${RESET}"
    echo
    echo "Next steps upon booting into your new system:"
    echo "  1. Login with user '$install_user' and your password."
    echo "  2. cd ~/dotfiles"
    echo "  3. ./scripts/bootstrap.sh"
    echo "  4. ./scripts/vault.sh restore   (to restore Google Chrome, SSH keys, Telegram, Slack)"
    echo
    read -r -p "Do you want to reboot the system now? [y/N]: " reboot_ans
    case "$reboot_ans" in
        [yY][eE][sS]|[yY])
            umount -R "$INSTALLER_MOUNT_ROOT" || error "Could not unmount $INSTALLER_MOUNT_ROOT before reboot."
            reboot
            ;;
        *)
            info "Reboot skipped. When ready, run 'reboot'."
            ;;
    esac
}

main() {
    require_root
    preflight

    banner
    check_connection
    collect_install_config
    INSTALLER_WORK_DIR="$(mktemp -d -t dotfiles-installer-preflight-XXXXXX)"
    trap 'rm -rf -- "$INSTALLER_WORK_DIR"' EXIT
    prepare_candidate_repository
    prepare_candidate_machine_config
    validate_candidate_machine_config
    setup_disk "$INSTALL_DISK" "$INSTALL_EFI_SIZE" "$INSTALL_SWAP_SIZE"
    generate_hardware_config
    finalize_machine_config \
        "$INSTALL_USER" \
        "$INSTALL_HOSTNAME" \
        "$INSTALL_REPO" \
        "$INSTALL_BOOTLOADER" \
        "$INSTALL_STATE_VERSION" \
        "$INSTALL_PASSWORD_HASH"
    validate_final_machine_config "$FINAL_DOTFILES_DIR"
    run_install "$INSTALL_USER" "$FINAL_DOTFILES_DIR"
}

if [ "${NIXOS_INSTALLER_SOURCE_ONLY:-0}" -ne 1 ]; then
    main "$@"
fi
