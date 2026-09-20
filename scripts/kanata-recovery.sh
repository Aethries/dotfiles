#!/usr/bin/env bash
# ==============================================================================
# kanata-recovery: Emergency recovery & management tool for Kanata key remapper
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KANATA_CONFIG="$REPO_ROOT/resources/kanata/kanata.kbd"
FALLBACK_CONFIG="$REPO_ROOT/resources/kanata/fallback.kbd"
SERVICE_NAME="kanata-internal.service"

usage() {
    echo -e "${BOLD}${CYAN}Kanata Emergency Recovery Tool${RESET}"
    echo
    echo "Usage: $(basename "$0") <command> [options]"
    echo
    echo "Commands:"
    echo "  status            Check systemd service, device node, and active process"
    echo "  check [file]      Validate .kbd configuration syntax (default: main config)"
    echo "  check-fallback    Validate fallback passthrough configuration"
    echo "  stop              Emergency stop the Kanata systemd service"
    echo "  start             Start the Kanata systemd service"
    echo "  restart           Restart the Kanata systemd service"
    echo "  logs              Display recent systemd journal logs for Kanata"
    echo "  help              Show this help menu"
    echo
    echo "Emergency hardware chord:"
    echo "  Press LeftShift + RightShift simultaneously to toggle raw bypass."
    echo "  Press LCtrl + Space + Esc for Kanata built-in emergency exit."
}

cmd_status() {
    echo -e "${BOLD}==> Kanata Service Status${RESET}"
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        echo -e "  Service ($SERVICE_NAME): [${GREEN}ACTIVE${RESET}]"
    else
        echo -e "  Service ($SERVICE_NAME): [${RED}INACTIVE / FAILED${RESET}]"
    fi

    echo -e "\n${BOLD}==> Device Node Status${RESET}"
    if [ -e "/dev/uinput" ]; then
        echo -e "  /dev/uinput: [${GREEN}EXISTS${RESET}] ($(ls -l /dev/uinput))"
    else
        echo -e "  /dev/uinput: [${RED}MISSING${RESET}] (uinput kernel module not loaded)"
    fi

    echo -e "\n${BOLD}==> Process Inspection${RESET}"
    if pgrep -a kanata >/dev/null 2>&1; then
        pgrep -a kanata | while read -r line; do
            echo -e "  [${GREEN}RUNNING${RESET}] $line"
        done
    else
        echo -e "  [${YELLOW}!${RESET}] No running kanata processes found"
    fi
}

cmd_check() {
    local target="${1:-$KANATA_CONFIG}"
    if [ ! -f "$target" ]; then
        echo -e "  [${RED}✗${RESET}] File not found: $target" >&2
        return 1
    fi

    echo -e "==> Validating configuration: ${CYAN}$target${RESET}"
    if command -v kanata >/dev/null 2>&1; then
        if kanata --check -c "$target"; then
            echo -e "  [${GREEN}✓${RESET}] Configuration is 100% valid."
        else
            echo -e "  [${RED}✗${RESET}] Validation failed!" >&2
            return 1
        fi
    else
        echo -e "  [${YELLOW}!${RESET}] 'kanata' binary not found in PATH; running via nix..."
        nix shell nixpkgs#kanata --command kanata --check -c "$target"
    fi
}

cmd_stop() {
    echo -e "==> ${YELLOW}Stopping $SERVICE_NAME...${RESET}"
    sudo systemctl stop "$SERVICE_NAME"
    echo -e "  [${GREEN}✓${RESET}] Service stopped. Keyboard returned to native kernel input."
}

cmd_start() {
    echo -e "==> ${CYAN}Starting $SERVICE_NAME...${RESET}"
    sudo systemctl start "$SERVICE_NAME"
    echo -e "  [${GREEN}✓${RESET}] Service started."
}

cmd_restart() {
    echo -e "==> ${CYAN}Restarting $SERVICE_NAME...${RESET}"
    sudo systemctl restart "$SERVICE_NAME"
    echo -e "  [${GREEN}✓${RESET}] Service restarted."
}

cmd_logs() {
    journalctl -u "$SERVICE_NAME" -n 50 --no-pager
}

COMMAND="${1:-help}"
shift || true # BEST_EFFORT: optional cleanup or probe failure is non-fatal.

case "$COMMAND" in
    status)
        cmd_status
        ;;
    check)
        cmd_check "${1:-}"
        ;;
    check-fallback)
        cmd_check "$FALLBACK_CONFIG"
        ;;
    stop)
        cmd_stop
        ;;
    start)
        cmd_start
        ;;
    restart)
        cmd_restart
        ;;
    logs)
        cmd_logs
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${RESET}\n" >&2
        usage
        exit 1
        ;;
esac
