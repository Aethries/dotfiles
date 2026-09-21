#!/usr/bin/env bash
# ==============================================================================
# Reset Zellij: Terminate all processes and delete all session states
# ==============================================================================

set -euo pipefail

info() {
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

info "Resetting Zellij environment..."

# 1. Delete all tracked sessions cleanly via zellij CLI
if command -v zellij >/dev/null 2>&1; then
    zellij delete-all-sessions --yes --force >/dev/null 2>&1 || true # BEST_EFFORT: delete-all-sessions may return non-zero if no sessions exist.
fi

# 2. Kill any hung or orphaned zellij processes
pkill -9 -x zellij >/dev/null 2>&1 || true # BEST_EFFORT: pkill returns 1 when no matching process is found.

# 3. Clean up stale runtime sockets and locks for current user
if [ -d "/tmp/zellij-$UID" ]; then
    rm -rf "/tmp/zellij-$UID" || true # BEST_EFFORT: stale socket cleanup is advisory.
fi

success "All Zellij sessions and processes have been completely reset."
