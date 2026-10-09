#!/usr/bin/env bash

set -euo pipefail

# Ensure system binaries (/usr/bin) take precedence over user shims (mise, asdf) during installation
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$PATH"

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"

# Options
PROFILE="all"
DRY_RUN=false
SINGLE_MODULE=""

usage() {
	cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -p, --profile <name>   Installation profile: all, desktop, cli, ai (default: all)
  -m, --module <name>    Run setup for a single specific module
  -n, --dry-run          Preview what will be installed without making changes
  -h, --help             Show this help message
EOF
	exit 0
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-p|--profile)
			PROFILE="$2"
			shift 2
			;;
		-m|--module)
			SINGLE_MODULE="$2"
			shift 2
			;;
		-n|--dry-run)
			DRY_RUN=true
			shift
			;;
		-h|--help)
			usage
			;;
		*)
			error "Unknown option: $1"
			;;
	esac
done

# Define module lists
CLI_MODULES=(fonts git env shell zellij nvim mise docker vault)
DESKTOP_MODULES=(fonts fcitx5 kanata git env shell zellij ghostty nvim mise vault noctalia obsidian umbriel cheatsheet greeter audio ideavim)
AI_MODULES=(fonts git env shell zellij nvim mise vault vscode antigravity codex ai 9router)
ALL_MODULES=(fonts fcitx5 kanata git env shell zellij ghostty nvim mise docker vault noctalia obsidian umbriel cheatsheet greeter audio vscode antigravity codex ai 9router ideavim)

SELECTED_MODULES=()
if [[ -n "$SINGLE_MODULE" ]]; then
	if [[ ! -f "$DOTFILES/modules/$SINGLE_MODULE/setup.sh" ]]; then
		error "Module '$SINGLE_MODULE' does not exist in $DOTFILES/modules"
	fi
	SELECTED_MODULES=("$SINGLE_MODULE")
else
	case "$PROFILE" in
		cli)
			SELECTED_MODULES=("${CLI_MODULES[@]}")
			;;
		desktop)
			SELECTED_MODULES=("${DESKTOP_MODULES[@]}")
			;;
		ai)
			SELECTED_MODULES=("${AI_MODULES[@]}")
			;;
		all)
			SELECTED_MODULES=("${ALL_MODULES[@]}")
			;;
		*)
			error "Unknown profile '$PROFILE'. Choose from: all, desktop, cli, ai"
			;;
	esac
fi

if [[ "$DRY_RUN" == "true" ]]; then
	echo -e "\n${BLUE}${BOLD}==> Dotfiles Setup [DRY-RUN] <==${RESET}"
	echo "Profile: $PROFILE"
	echo "Selected modules (${#SELECTED_MODULES[@]}): ${SELECTED_MODULES[*]}"
	echo -e "\nWould execute:"
	echo "  1. Bootstrap dependencies & yay (if missing)"
	echo "  2. Package manifests (pacman.txt, aur.txt)"
	echo "  3. Shell configuration (zsh)"
	for mod in "${SELECTED_MODULES[@]}"; do
		echo "  + modules/$mod/setup.sh"
	done
	echo "  4. Diagnostics health-check (scripts/doctor.sh)"
	success "Dry-run complete. No changes made to system."
	exit 0
fi

log "Starting dotfiles setup (profile: $PROFILE)"

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
	error "Do not run install.sh as root/sudo! Please run as regular user: ./install.sh"
fi

# Bootstrap sudo credentials and keep alive
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_LOOP_PID=$!
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true' EXIT

install_yay() {
	if command_exists yay; then
		success "yay already installed"
		yay --version
		return
	fi

	log "Installing bootstrap dependencies"
	sudo pacman -S --noconfirm --needed \
		git \
		curl \
		wget \
		base-devel

	success "Bootstrap dependencies installed"
	log "Installing yay"

	local tmp_dir
	tmp_dir="$(mktemp -d)"

	git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

	(
		cd "$tmp_dir/yay"
		makepkg -si --noconfirm
	)

	rm -rf "$tmp_dir"
	yay --version

	success "yay installed"
}

if [[ -z "$SINGLE_MODULE" ]]; then
	install_yay
	bash "$SCRIPTS/packages.sh"

	# ZSH
	log "Configuring shell"
	zsh_path="$(command -v zsh || true)"
	if [[ -n "$zsh_path" && "$SHELL" != "$zsh_path" ]]; then
		chsh -s "$zsh_path" || warn "Could not change default shell to zsh"
	fi
	success "Zsh configured"
fi

# Run selected modules
for mod in "${SELECTED_MODULES[@]}"; do
	setup_script="$DOTFILES/modules/$mod/setup.sh"
	if [[ -f "$setup_script" ]]; then
		log "Configuring module: $mod"
		bash "$setup_script"
	else
		warn "Module setup script not found: $setup_script"
	fi
done

# Run doctor check
if [[ -f "$SCRIPTS/doctor.sh" ]]; then
	log "Running diagnostics doctor"
	bash "$SCRIPTS/doctor.sh" || warn "Doctor identified some warnings or issues"
fi

success "Dotfiles setup completed"
