#!/usr/bin/env bash

# ============================================================
# NixOS Interactive Automated Installer
# Designed for Live ISO / USB installation
#
# Steps:
# 1. Wi-Fi & Network Connection Wizard (interactive selection)
# 2. Disk Selection, Partitioning & Formatting (EFI, Swap, Root)
# 3. Mount filesystem to /mnt
# 4. Generate NixOS hardware configuration & Clone dotfiles
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
    echo -e "Dotfiles: https://github.com/locbh3010/dotfiles"
    echo -e "============================================================"
    echo
}

# Ensure root
if [ "$(id -u)" -ne 0 ]; then
    error "This installer must be run as root (or via 'sudo $0')."
fi

check_connection() {
    if ! ping -c 1 -W 2 "${CHECK_HOST:-1.1.1.1}" >/dev/null 2>&1; then
        warn "No active internet connection detected!"
        echo "Make sure you connect to Wi-Fi/Ethernet first (e.g. via 'nmtui' or 'nmcli') so packages can be downloaded."
        read -r -p "Press Enter to proceed anyway, or Ctrl+C to abort: " _
    else
        success "Internet connection verified."
    fi
}

# ============================================================
# STEP 1: Disk Selection & Partitioning
# ============================================================
setup_disk() {
    echo
    info "Step 1: Detecting storage drives..."
    echo
    lsblk -d -e 7,11 -o NAME,SIZE,MODEL,TYPE,TRAN
    echo

    # Prompt user for disk
    local default_disk
    default_disk="$(lsblk -d -e 7,11 -n -o NAME | grep -E 'nvme0n1|sda|vda' | head -n 1 || true)"

    read -r -p "Enter disk name to install NixOS (e.g. nvme0n1, sda) [default: $default_disk]: " target_disk
    target_disk="${target_disk:-$default_disk}"

    [ -n "$target_disk" ] || error "No disk selected."
    [ -b "/dev/$target_disk" ] || error "Device /dev/$target_disk does not exist."

    local disk_path="/dev/$target_disk"

    echo
    echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${RESET}"
    echo -e "${RED}${BOLD}  WARNING: ALL DATA ON $disk_path WILL BE PERMANENTLY ERASED!${RESET}"
    echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${RESET}"
    echo
    read -r -p "Type 'YES' (in capital letters) to confirm formatting $disk_path: " confirm_wipe
    if [ "$confirm_wipe" != "YES" ]; then
        error "Installation aborted by user."
    fi

    echo
    info "Partition sizing options:"
    read -r -p "  EFI partition size (default: 1024MiB): " efi_size
    efi_size="${efi_size:-1024MiB}"

    read -r -p "  Swap partition size (e.g. 16GiB, 8GiB, or 0 for none) [default: 16GiB]: " swap_size
    swap_size="${swap_size:-16GiB}"

    local efi_mib efi_end_mib swap_mib=0 swap_end_mib
    efi_mib="$(size_to_mib "$efi_size")"
    efi_end_mib=$((efi_mib + 1))
    if [ "$swap_size" != "0" ] && [ "$swap_size" != "none" ]; then
        swap_mib="$(size_to_mib "$swap_size")"
    fi
    swap_end_mib=$((efi_end_mib + swap_mib))

    info "Unmounting any existing partitions on $disk_path..."
    swapoff -a 2>/dev/null || true
    umount -R /mnt 2>/dev/null || true
    for p in "${disk_path}"*; do
        umount "$p" 2>/dev/null || true
    done

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
    sleep 2
    partprobe "$disk_path" 2>/dev/null || true
    sleep 2

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
    info "Mounting filesystems to /mnt..."
    mount "$root_part" /mnt
    mkdir -p /mnt/boot
    mount "$efi_part" /mnt/boot

    success "Filesystems mounted successfully:"
    lsblk -f "$disk_path"
}

# ============================================================
# STEP 2: Config Generation & Dotfiles Integration
# ============================================================
setup_config() {
    echo
    info "Step 2: Generating NixOS configuration..."
    nixos-generate-config --root /mnt

    local suggested_user
    suggested_user="${SUDO_USER:-${USER:-loc}}"
    read -r -p "Enter primary user account name [default: $suggested_user]: " install_user
    install_user="${install_user:-$suggested_user}"
    [[ "$install_user" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] \
        || error "Invalid user name: $install_user"

    local user_home="/mnt/home/$install_user"
    local dotfiles_dir="$user_home/dotfiles"

    mkdir -p "$user_home"

    info "Cloning dotfiles repository..."
    if [ -d "$dotfiles_dir" ]; then
        info "Dotfiles already present at $dotfiles_dir."
    else
        nix-shell -p git --run "git clone \"${DOTFILES_REPO:-https://github.com/locbh3010/dotfiles.git}\" $dotfiles_dir"
    fi

    # Inject generated hardware config into .machine
    local machine_dir="$dotfiles_dir/.machine"
    mkdir -p "$machine_dir"
    cp /mnt/etc/nixos/hardware-configuration.nix "$machine_dir/hardware-configuration.nix"

    # Create machine-specific configuration.nix
    local hostname
    hostname="$(hostname)"
    [ "$hostname" = "nixos" ] && hostname="nixos-workstation"

    read -r -p "Enter system hostname [default: $hostname]: " chosen_host
    chosen_host="${chosen_host:-$hostname}"
    [[ "$chosen_host" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] \
        || error "Invalid hostname: $chosen_host"

    echo
    info "Set password for user '$install_user':"
    local user_pass="" user_pass_confirm=""
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

    local pass_hash
    pass_hash="$(printf '%s\n' "$user_pass" | nix-shell -p whois --run 'mkpasswd -m sha-512 -s')"
    unset user_pass user_pass_confirm

    cat > "$machine_dir/configuration.nix" << EOF
# ============================================================
# AUTO-GENERATED MACHINE CONFIGURATION
# ============================================================
{
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "$chosen_host";

  users.users."$install_user" = {
    isNormalUser = true;
    initialHashedPassword = "$pass_hash";
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
      "uinput"
      "docker"
    ];
  };
  users.users.root.initialHashedPassword = "!";
}
EOF

    success "Machine configuration generated in $machine_dir"

    # Fix ownership of cloned files in target home
    chown -R "${install_user}:users" "$user_home" 2>/dev/null || true
}

# ============================================================
# STEP 3: Installation Execution
# ============================================================
run_install() {
    echo
    info "Step 3: Ready to install NixOS!"
    echo "This will build and install the entire system using your dotfiles."
    read -r -p "Start nixos-install now? [Y/n]: " start_inst
    case "$start_inst" in
        [nN][oO]|[nN])
            warn "Skipped nixos-install. Configuration is ready at /mnt."
            return 0
            ;;
    esac

    local dotfiles_dir="/mnt/home/$install_user/dotfiles"
    local machine_config="$dotfiles_dir/.machine/configuration.nix"

    info "Running nixos-install (this may take several minutes)..."
    nixos-install --root /mnt -I "nixos-config=$machine_config" --no-root-password

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
            umount -R /mnt 2>/dev/null || true
            reboot
            ;;
        *)
            info "Reboot skipped. When ready, run 'reboot'."
            ;;
    esac
}

# Main flow
banner
check_connection
setup_disk
setup_config
run_install
