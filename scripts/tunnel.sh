#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: tunnel [port] [protocol]"
    echo ""
    echo "Expose local port publicly via temporary Cloudflare Tunnel (TryCloudflare)."
    echo ""
    echo "Arguments:"
    echo "  port       Local port number (default: 3000)"
    echo "  protocol   Protocol: http | https (default: http)"
    echo ""
    echo "Examples:"
    echo "  tunnel               # Exposes http://localhost:3000"
    echo "  tunnel 8080          # Exposes http://localhost:8080"
    echo "  tunnel 5173 https    # Exposes https://localhost:5173"
    exit 0
fi

PORT="${1:-3000}"
PROTO="${2:-http}"
TARGET="${PROTO}://localhost:${PORT}"

if ! command -v cloudflared &>/dev/null; then
    echo "Error: 'cloudflared' is not installed." >&2
    echo "Run './scripts/build.sh switch' to install it." >&2
    exit 1
fi

echo "=================================================="
echo " Cloudflare Quick Tunnel"
echo " Target : $TARGET"
echo "=================================================="
echo "Starting tunnel... Press Ctrl+C to stop."
echo ""

exec cloudflared tunnel --url "$TARGET"
