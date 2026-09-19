#!/usr/bin/env bash
# ==============================================================================
# Kanata Recovery & Configuration Test Suite
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "==> Testing Kanata recovery CLI & configuration integrity..."

# 1. Test help output
output="$("$REPO_ROOT/scripts/kanata-recovery.sh" help)"
if ! echo "$output" | grep -q "Kanata Emergency Recovery Tool"; then
    echo "  [✗] Failed to display help menu" >&2
    exit 1
fi
echo "  [✓] kanata-recovery.sh help menu works"

# 2. Test configuration syntax check for main config
if ! "$REPO_ROOT/scripts/kanata-recovery.sh" check >/dev/null 2>&1; then
    echo "  [✗] Validation failed for resources/kanata/kanata.kbd" >&2
    exit 1
fi
echo "  [✓] kanata-recovery.sh check validates main config"

# 3. Test configuration syntax check for fallback config
if ! "$REPO_ROOT/scripts/kanata-recovery.sh" check-fallback >/dev/null 2>&1; then
    echo "  [✗] Validation failed for resources/kanata/fallback.kbd" >&2
    exit 1
fi
echo "  [✓] kanata-recovery.sh check-fallback validates fallback config"

# 4. Test error handling on non-existent config
if "$REPO_ROOT/scripts/kanata-recovery.sh" check "/nonexistent/path.kbd" >/dev/null 2>&1; then
    echo "  [✗] Expected failure on non-existent config but got success" >&2
    exit 1
fi
echo "  [✓] kanata-recovery.sh rejects non-existent config path"

echo "  [✓] All Kanata recovery tests passed successfully!"
