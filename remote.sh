#!/usr/bin/env bash
# ==============================================================================
# Remote Workstation Provisioner (Tailscale Mesh, Sunshine Desktop & Keep-Awake)
# ==============================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"
source "$SCRIPTS/common.sh"
source "$SCRIPTS/links.sh"

log "Starting Remote Workstation Setup (Tailscale + Sunshine + Coffee + Autologin)"

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
	error "Do not run remote.sh as root/sudo! Please run as regular user: ./remote.sh"
fi

# Bootstrap sudo credentials and keep alive
log "Authenticating sudo credentials for system setup"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_LOOP_PID=$!
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true' EXIT

# ------------------------------------------------------------------------------
# 1. Package Installation
# ------------------------------------------------------------------------------
install_remote_packages() {
	log "Checking remote packages (pacman & AUR)"

	local pacman_pkgs=("tailscale" "sshfs" "mosh" "moonlight-qt")
	local missing_pacman=()

	for pkg in "${pacman_pkgs[@]}"; do
		if ! pacman -Q "$pkg" >/dev/null 2>&1; then
			missing_pacman+=("$pkg")
		fi
	done

	if [[ ${#missing_pacman[@]} -gt 0 ]]; then
		log "Installing missing pacman packages: ${missing_pacman[*]}"
		sudo pacman -S --needed --noconfirm "${missing_pacman[@]}"
		success "Pacman packages installed"
	else
		success "All pacman remote packages are installed"
	fi

	# Sunshine from AUR
	if ! pacman -Q sunshine >/dev/null 2>&1 && ! pacman -Q sunshine-bin >/dev/null 2>&1; then
		if command_exists yay; then
			log "Installing sunshine-bin from AUR"
			yay -S --needed --noconfirm --sudoloop sunshine-bin
			success "sunshine-bin installed from AUR"
		else
			error "yay is not installed. Please install yay or install sunshine manually."
		fi
	else
		success "Sunshine is already installed"
	fi
}

# ------------------------------------------------------------------------------
# 2. Tailscale & SSH Client Setup
# ------------------------------------------------------------------------------
configure_tailscale() {
	log "Configuring Tailscale & SSH helpers"
	bash "$DOTFILES/modules/tailscale/setup.sh"
}

# ------------------------------------------------------------------------------
# 3. Sunshine Remote Desktop Setup
# ------------------------------------------------------------------------------
configure_sunshine() {
	log "Configuring Sunshine Remote Desktop"
	bash "$DOTFILES/modules/sunshine/setup.sh"
}

# ------------------------------------------------------------------------------
# 4. Coffee Keep-Awake / Sleep Inhibitor Setup
# ------------------------------------------------------------------------------
configure_coffee() {
	log "Configuring Coffee Sleep Inhibitor (Noctalia Native Caffeine)"

	mkdir -p "$HOME/.local/bin"

	link_file \
		"$DOTFILES/modules/shell/files/bin/coffee" \
		"$HOME/.local/bin/coffee"
	chmod +x "$HOME/.local/bin/coffee"

	# Enable caffeine keep-awake
	"$HOME/.local/bin/coffee" on
	success "Coffee keep-awake configured (reusing Noctalia native caffeine)"
}


# ------------------------------------------------------------------------------
# 5. Autologin Setup (Survive Power Loss / Smartplug Reboot)
# ------------------------------------------------------------------------------
configure_autologin() {
	log "Configuring Greetd Autologin (No Password on Boot)"

	local greetd_conf="/etc/greetd/config.toml"
	if [[ -f "$greetd_conf" && ! -f "$greetd_conf.pre-autologin.bak" ]]; then
		sudo cp "$greetd_conf" "$greetd_conf.pre-autologin.bak"
	fi

	cat << EOF | sudo tee "$greetd_conf" > /dev/null
[terminal]
vt = 1

[initial_session]
command = "start-umbriel"
user = "$USER"

[default_session]
command = "/usr/bin/noctalia-greeter-session -- --session Umbriel"
user = "greeter"
EOF

	touch "$DOTFILES/.autologin"
	success "Greetd autologin configured for user '$USER' -> start-umbriel"
}

# ------------------------------------------------------------------------------
# 6. Firewall & Port Opening (Tailscale & Sunshine)
# ------------------------------------------------------------------------------
configure_firewall() {
	log "Configuring Firewall Rules"

	# If UFW is active
	if command_exists ufw && sudo ufw status | grep -q "Status: active"; then
		log "Configuring UFW firewall rules"
		sudo ufw allow in on tailscale0 comment "Tailscale Mesh Interface"
		# Sunshine ports on Tailscale & LAN
		sudo ufw allow 47984:48010/tcp comment "Sunshine Web & Stream TCP"
		sudo ufw allow 47984:48010/udp comment "Sunshine Audio & Video UDP"
		success "UFW rules configured for Sunshine & Tailscale"
	else
		success "No active firewall blocking ports (UFW is inactive or not present)"
	fi
}

# ------------------------------------------------------------------------------
# 7. Final Verification & Guidance
# ------------------------------------------------------------------------------
print_summary() {
	log "Remote Workstation Summary"

	local ts_ip
	ts_ip="$(tailscale ip -4 2>/dev/null || echo "Not Connected")"

	echo "======================================================================"
	echo "  Tailscale IP:      $ts_ip"
	echo "  Sunshine Web UI:   https://localhost:47990 (or https://$ts_ip:47990)"
	echo "  Keep-Awake:        $("$DOTFILES/modules/shell/files/bin/coffee" status | tr '\n' ' ')"
	echo "  Sunshine Status:   $(systemctl --user is-active sunshine.service 2>/dev/null || echo "inactive")"
	echo "  Autologin:         Configured (User: $USER)"
	echo "======================================================================"
	echo ""
	echo "HƯỚNG DẪN KẾT NỐI TỪ NGOÀI MẠNG LAN:"
	echo "1. Đảm bảo máy trạm đã kết nối Tailnet:"
	echo "   sudo tailscale up --ssh --operator=$USER"
	echo ""
	echo "2. Truy cập Web UI cấu hình Sunshine (lần đầu tạo tài khoản Admin):"
	echo "   Mở trình duyệt: https://localhost:47990"
	echo ""
	echo "3. Trên máy client (Laptop / Tablet ngoài mạng LAN):"
	echo "   - Cài Tailscale và Moonlight (moonlight-qt)."
	echo "   - Đăng nhập cùng tài khoản Tailscale."
	echo "   - Mở Moonlight -> Add Host -> Nhập IP Tailscale của máy trạm ($ts_ip)."
	echo "   - Nhập PIN 4 số trên giao diện web Sunshine (tab PIN) để ghép đôi."
	echo ""
	echo "4. Quản lý Keep-Awake (Chống ngủ):"
	echo "   - Phím tắt:     Mod+Shift+I (bật/tắt nhanh qua Noctalia OSD)"
	echo "   - coffee status : Xem trạng thái chống ngủ"
	echo "   - coffee on/off : Bật / tắt chống ngủ"
	echo "======================================================================"

}

# Execution Flow
install_remote_packages
configure_tailscale
configure_sunshine
configure_coffee
configure_autologin
configure_firewall
print_summary

success "Remote Workstation Setup Completed Successfully!"
