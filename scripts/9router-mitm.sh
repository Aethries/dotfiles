#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/common.sh"

MITM_DIR="$HOME/.9router/mitm"
ROOT_CA="$MITM_DIR/rootCA.crt"
SYSTEM_ANCHORS="/etc/ca-certificates/trust-source/anchors"
SYSTEM_CA_FILE="$SYSTEM_ANCHORS/9router-rootCA.crt"
DISABLED_MARKER="$MITM_DIR/.disabled"
ROUTER_API_BASE="http://localhost:20128"
MITM_DOMAINS=(
	"daily-cloudcode-pa.googleapis.com"
	"cloudcode-pa.googleapis.com"
)

get_cli_token() {
	if [[ -f "$HOME/.9router/machine-id" && -f "$HOME/.9router/auth/cli-secret" ]]; then
		local m s
		m="$(tr -d '\r\n' < "$HOME/.9router/machine-id")"
		s="$(tr -d '\r\n' < "$HOME/.9router/auth/cli-secret")"
		printf "%s" "${m}9r-cli-auth${s}" | sha256sum | head -c 16
	fi
}

is_gateway_up() {
	curl -s -m 2 "$ROUTER_API_BASE/api/health" >/dev/null 2>&1 || \
	curl -s -m 2 "$ROUTER_API_BASE/v1/models" >/dev/null 2>&1
}

clean_nss_db() {
	if command -v certutil >/dev/null 2>&1; then
		local nss_dirs=("$HOME/.pki/nssdb" "$HOME/snap/chromium/current/.pki/nssdb")
		if [[ -d "$HOME/.mozilla/firefox" ]]; then
			for f in "$HOME/.mozilla/firefox"/*/; do
				if [[ -f "${f}cert9.db" || -f "${f}cert8.db" ]]; then
					nss_dirs+=("$f")
				fi
			done
		fi
		for db in "${nss_dirs[@]}"; do
			if [[ -d "$db" ]]; then
				certutil -d sql:"$db" -D -n "9Router MITM Root CA" 2>/dev/null || \
				certutil -d "$db" -D -n "9Router MITM Root CA" 2>/dev/null || true
			fi
		done
	fi
}

install_nss_db() {
	local cert_path="$1"
	if command -v certutil >/dev/null 2>&1 && [[ -f "$cert_path" ]]; then
		local nss_dirs=("$HOME/.pki/nssdb" "$HOME/snap/chromium/current/.pki/nssdb")
		if [[ -d "$HOME/.mozilla/firefox" ]]; then
			for f in "$HOME/.mozilla/firefox"/*/; do
				if [[ -f "${f}cert9.db" || -f "${f}cert8.db" ]]; then
					nss_dirs+=("$f")
				fi
			done
		fi
		for db in "${nss_dirs[@]}"; do
			if [[ -d "$db" ]]; then
				certutil -d sql:"$db" -A -t "C,," -n "9Router MITM Root CA" -i "$cert_path" 2>/dev/null || \
				certutil -d "$db" -A -t "C,," -n "9Router MITM Root CA" -i "$cert_path" 2>/dev/null || true
			fi
		done
	fi
}

cmd_status() {
	echo -e "\n${BLUE}${BOLD}==> 9router MITM & Certificate Status <==${RESET}"

	# 1. Gateway Status
	local token
	token="$(get_cli_token)"
	if is_gateway_up; then
		echo -e "• 9router Gateway (port 20128): ${GREEN}Running${RESET}"
		if [[ -n "$token" ]]; then
			local api_resp
			api_resp="$(curl -s -m 2 -H "x-9r-cli-token: $token" "$ROUTER_API_BASE/api/cli-tools/antigravity-mitm" 2>/dev/null || true)"
			if [[ -n "$api_resp" && "$api_resp" =~ "running" ]]; then
				echo "  - API Status: $api_resp"
			fi
		fi
	else
		echo -e "• 9router Gateway (port 20128): ${YELLOW}Not running${RESET}"
	fi

	# 2. Port 443 Process
	local p443_pid="" p443_name=""
	if command -v ss >/dev/null 2>&1; then
		p443_pid="$(ss -tlpn 2>/dev/null | grep ':443 ' | grep -o 'pid=[0-9]*' | cut -d= -f2 | head -n1 || true)"
	fi
	if [[ -z "$p443_pid" ]] && command -v lsof >/dev/null 2>&1; then
		p443_pid="$(sudo -n lsof -nP -iTCP:443 -sTCP:LISTEN -t 2>/dev/null | head -n1 || true)"
	fi
	if [[ -n "$p443_pid" ]]; then
		p443_name="$(ps -p "$p443_pid" -o comm= 2>/dev/null || echo "unknown")"
		echo -e "• Port 443 MITM Proxy: ${GREEN}Listening (PID: $p443_pid, Name: $p443_name)${RESET}"
	else
		echo -e "• Port 443 MITM Proxy: ${RED}Inactive${RESET}"
	fi

	# 3. /etc/hosts Hijack Status
	local hosts_active=false
	for domain in "${MITM_DOMAINS[@]}"; do
		if grep -qE "(^|\s)$domain(\s|$)" /etc/hosts 2>/dev/null; then
			hosts_active=true
			break
		fi
	done
	if [[ "$hosts_active" == "true" ]]; then
		echo -e "• /etc/hosts Redirection: ${YELLOW}ACTIVE (Endpoints redirected to 127.0.0.1)${RESET}"
		grep -E "(daily-cloudcode-pa|cloudcode-pa)" /etc/hosts 2>/dev/null | sed 's/^/    /' || true
	else
		echo -e "• /etc/hosts Redirection: ${GREEN}CLEAN (Default DNS)${RESET}"
	fi

	# 4. System Certificate Trust
	local cert_found=false
	for cert_file in "$SYSTEM_ANCHORS"/9router* /usr/local/share/ca-certificates/9router*; do
		if [[ -f "$cert_file" ]]; then
			cert_found=true
			echo -e "• System Certificate: ${YELLOW}Installed ($cert_file)${RESET}"
		fi
	done
	if [[ "$cert_found" == "false" ]]; then
		echo -e "• System Certificate: ${GREEN}CLEAN (No 9router root cert in system anchors)${RESET}"
	fi

	# 5. Overall State
	echo ""
	if [[ "$hosts_active" == "true" || "$cert_found" == "true" || -n "$p443_pid" ]]; then
		echo -e "Current State: ${YELLOW}${BOLD}MITM ACTIVE${RESET}"
		echo "To disable MITM and restore default system config: $0 stop"
	else
		echo -e "Current State: ${GREEN}${BOLD}DEFAULT (MITM DISABLED)${RESET}"
		echo "To enable MITM for Antigravity: $0 start"
	fi
}

cmd_stop() {
	log "Stopping 9router MITM and restoring default system configuration..."
	local token
	token="$(get_cli_token)"

	# 1. Tell 9router API to disable Antigravity DNS & stop server
	if is_gateway_up && [[ -n "$token" ]]; then
		log "Notifying 9router gateway to disable MITM..."
		curl -s -m 3 -X PATCH -H "x-9r-cli-token: $token" -H "Content-Type: application/json" \
			-d '{"tool":"antigravity","action":"disable"}' "$ROUTER_API_BASE/api/cli-tools/antigravity-mitm" >/dev/null 2>&1 || true
		curl -s -m 3 -X DELETE -H "x-9r-cli-token: $token" "$ROUTER_API_BASE/api/cli-tools/antigravity-mitm" >/dev/null 2>&1 || true
	fi

	# 2. Terminate any MITM server process on port 443
	log "Terminating port 443 MITM processes..."
	sudo pkill -SIGTERM -f "[s]erver\.js" 2>/dev/null || true
	sudo pkill -SIGTERM -f "mitm/server\.js" 2>/dev/null || true
	sleep 1
	sudo pkill -SIGKILL -f "mitm/server\.js" 2>/dev/null || true
	rm -f "$MITM_DIR/.mitm.pid" "$MITM_DIR/.mitm.lock" 2>/dev/null || true

	# 3. Clean /etc/hosts
	log "Cleaning MITM domain redirections from /etc/hosts..."
	sudo sed -i -E '/(daily-cloudcode-pa\.googleapis\.com|cloudcode-pa\.googleapis\.com)/d' /etc/hosts
	if command_exists resolvectl; then
		resolvectl flush-caches 2>/dev/null || true
	fi

	# 4. Remove Root CA from system trust store
	log "Removing 9router root certificate from system trust anchors..."
	sudo rm -f "$SYSTEM_ANCHORS"/9router* /usr/local/share/ca-certificates/9router* 2>/dev/null || true
	if command_exists update-ca-trust; then
		sudo update-ca-trust
	elif command_exists update-ca-certificates; then
		sudo update-ca-certificates --fresh 2>/dev/null || true
	fi

	# 5. Clean NSS user DBs
	clean_nss_db

	# 6. Mark disabled state
	mkdir -p "$MITM_DIR"
	touch "$DISABLED_MARKER"

	success "9router MITM stopped. System certificates and /etc/hosts restored to default."
}

cmd_start() {
	log "Enabling 9router MITM for Antigravity IDE..."
	local token
	token="$(get_cli_token)"

	mkdir -p "$MITM_DIR"

	# 1. Ensure Root CA exists
	if [[ ! -f "$ROOT_CA" ]]; then
		local backup_cert="$DOTFILES/modules/9router/files/certs/9router-rootCA.crt"
		if [[ -f "$backup_cert" ]]; then
			cp "$backup_cert" "$ROOT_CA"
			chmod 644 "$ROOT_CA"
		else
			error "Root CA not found at $ROOT_CA or in dotfiles. Start 9router UI to generate it."
		fi
	fi

	# 2. Install Root CA into system trust store
	log "Installing Root CA into system trust store..."
	sudo mkdir -p "$SYSTEM_ANCHORS"
	sudo cp "$ROOT_CA" "$SYSTEM_CA_FILE"
	sudo chmod 644 "$SYSTEM_CA_FILE"
	if command_exists update-ca-trust; then
		sudo update-ca-trust
	elif command_exists update-ca-certificates; then
		sudo update-ca-certificates 2>/dev/null || true
	fi

	# 3. Install into browser NSS databases
	install_nss_db "$ROOT_CA"

	# 4. Configure loopback DNS in /etc/hosts
	log "Configuring /etc/hosts loopback entries for Antigravity endpoints..."
	for domain in "${MITM_DOMAINS[@]}"; do
		if ! grep -qE "(^|\s)$domain(\s|$)" /etc/hosts; then
			echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts >/dev/null
		fi
	done
	if command_exists resolvectl; then
		resolvectl flush-caches 2>/dev/null || true
	fi

	# 5. Ensure aliases.json
	local aliases_file="$MITM_DIR/aliases.json"
	if [[ ! -f "$aliases_file" ]]; then
		cat << 'EOF' > "$aliases_file"
{
  "antigravity": {
    "gemini-3.8-flash-high": "ag/gemini-3.8-flash-high",
    "gemini-3.8-flash-medium": "ag/gemini-3.8-flash-medium",
    "claude-sonnet-4-6": "ag/claude-sonnet-5-5-medium",
    "claude-opus-4-6-thinking": "ag/claude-opus-5-5-medium"
  }
}
EOF
	fi

	# 6. Start MITM Server
	log "Starting MITM proxy server..."
	local started=false
	if is_gateway_up && [[ -n "$token" ]]; then
		log "Triggering 9router gateway to launch MITM..."
		local resp
		resp="$(curl -s -m 5 -X POST -H "x-9r-cli-token: $token" -H "Content-Type: application/json" \
			-d '{"apiKey":"sk_9router","forceKillPort443":true}' "$ROUTER_API_BASE/api/cli-tools/antigravity-mitm" 2>/dev/null || true)"
		if [[ "$resp" =~ "running\":true" ]]; then
			started=true
		fi
		curl -s -m 3 -X PATCH -H "x-9r-cli-token: $token" -H "Content-Type: application/json" \
			-d '{"tool":"antigravity","action":"enable"}' "$ROUTER_API_BASE/api/cli-tools/antigravity-mitm" >/dev/null 2>&1 || true
	fi

	if [[ "$started" == "false" ]]; then
		local server_js="$HOME/.9router/runtime/mitm/server.js"
		if [[ -f "$server_js" ]]; then
			log "Launching MITM runtime directly via sudo..."
			sudo -b env HOME="$HOME" ROUTER_API_KEY="sk_9router" MITM_ROUTER_BASE="$ROUTER_API_BASE" NODE_ENV=production \
				"$(which node 2>/dev/null || command -v node)" "$server_js" >/dev/null 2>&1
			sleep 1
		fi
	fi

	# Remove disabled marker
	rm -f "$DISABLED_MARKER"

	success "9router MITM started and active for Antigravity."
}

usage() {
	cat << EOF
Usage: $(basename "$0") <command>

Commands:
  status             Show current MITM proxy, DNS, and certificate status
  stop, disable, off Stop MITM proxy and restore system default DNS & certificates
  start, enable, on  Start MITM proxy and configure certificates & DNS for Antigravity
  restart            Restart MITM proxy
  help, -h, --help   Show this help message
EOF
	exit 0
}

case "${1:-status}" in
	status)
		cmd_status
		;;
	stop|disable|off)
		cmd_stop
		;;
	start|enable|on)
		cmd_start
		;;
	restart)
		cmd_stop
		cmd_start
		;;
	help|-h|--help)
		usage
		;;
	*)
		error "Unknown command: $1. Use: status | stop | start | restart"
		;;
esac
