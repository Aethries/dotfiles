#!/usr/bin/env bash
# ==============================================================================
# Jira Standalone Web App Launcher
#
# Runs Jira in a completely isolated Chromium container with its own
# user-data-dir (~/.config/jira-app).
#
# Benefits:
# - 100% session isolation: immune to switching profiles or focusing other Chrome windows.
# - Zero multi-account conflict: never picks up personal Gmail or Google GIS One-Tap.
# - Independent window identity (--class=jira-app) for Niri WM window rules.
# - GNOME Keyring integration: cookies & tokens are encrypted and backed up via vault.sh.
# ==============================================================================

set -euo pipefail

DATA_DIR="${JIRA_DATA_DIR:-$HOME/.config/jira-app}"
DEFAULT_URL="https://id.atlassian.com"

# Resolve target URL
TARGET_URL="${1:-${JIRA_URL:-$DEFAULT_URL}}"

# Strip custom scheme if passed via x-scheme-handler/jira (e.g. jira://...)
if [[ "$TARGET_URL" =~ ^jira:// ]]; then
    TARGET_URL="https://${TARGET_URL#jira://}"
fi

# Ensure dedicated data directory exists
mkdir -p "$DATA_DIR"

# Launch isolated Chrome App instance
exec google-chrome \
    --user-data-dir="$DATA_DIR" \
    --class="jira-app" \
    --app="$TARGET_URL" \
    --password-store=gnome-libsecret \
    --no-first-run \
    --no-default-browser-check \
    "$@"
