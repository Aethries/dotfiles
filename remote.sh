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
	command_exists start-umbriel || error "Install the Umbriel desktop with ./install.sh before running remote.sh"

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

# An SSH login has no DRM seat. Let greetd establish the native login session.
graphical_session_ready() {
	local umbriel_socket
	systemctl --user is-active --quiet umbriel.service || return 1
	systemctl --user is-active --quiet graphical-session.target || return 1
	umbriel_socket="$(systemctl --user show-environment | sed -n 's/^UMBRIEL_SOCKET=//p')"
	[[ -n "$umbriel_socket" && -S "$umbriel_socket" ]] || return 1
	env UMBRIEL_SOCKET="$umbriel_socket" umbriel outputs >/dev/null 2>&1
}

ensure_graphical_session() {
	if ! graphical_session_ready; then
		if ! systemctl --user is-active --quiet umbriel.service; then
			log "Starting a native Umbriel session through greetd"
			# greetd only runs initial_session once per boot. A previous compositor
			# exit leaves this marker behind, even if greetd itself is restarted.
			sudo rm -f /run/greetd.run
			sudo systemctl enable greetd.service
			sudo systemctl restart greetd.service
		fi
		local attempt
		for attempt in {1..30}; do
			if graphical_session_ready; then
				break
			fi
			sleep 1
		done
		if ! graphical_session_ready; then
			journalctl --user -u umbriel.service -n 30 --no-pager
			error "Umbriel did not become ready. Check sudo journalctl -u greetd.service; Sunshine cannot stream without a display"
		fi
	fi
	success "Native Umbriel session responds to IPC"
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
	echo "  Sunshine Process:  $(systemctl --user is-active sunshine.service 2>/dev/null || true)"
	echo "  Umbriel Session:   $(systemctl --user is-active umbriel.service 2>/dev/null || true)"
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
	echo "   - Mở Desktop để xác nhận hình và âm thanh; process active chưa chứng minh stream hoạt động."
	echo "   - Nếu lỗi 503: journalctl --user -u app-dev.lizardbyte.app.Sunshine.service -n 80 --no-pager"
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
configure_autologin
configure_sunshine
ensure_graphical_session
systemctl --user start sunshine.service
configure_coffee
configure_firewall
print_summary

success "Remote Workstation Setup Completed Successfully!"
