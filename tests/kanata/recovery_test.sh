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

# 5. Test cheatsheet aliases in main config
if ! grep -q "cheat_help" "$REPO_ROOT/resources/kanata/kanata.kbd" || ! grep -q "nav_slash" "$REPO_ROOT/resources/kanata/kanata.kbd"; then
    echo "  [✗] Missing cheat_help or nav_slash alias in resources/kanata/kanata.kbd" >&2
    exit 1
fi
echo "  [✓] Modal cheatsheet aliases present in kanata.kbd"

# 6. Test Warpd oneshot_timeout configuration
if ! grep -q "oneshot_timeout: 400" "$REPO_ROOT/resources/warpd/config"; then
    echo "  [✗] Missing oneshot_timeout: 400 in resources/warpd/config" >&2
    exit 1
fi
echo "  [✓] Warpd oneshot_timeout configured correctly"

# 7. Test kill_warpd synchronization alias in main config
if ! grep -q "kill_warpd" "$REPO_ROOT/resources/kanata/kanata.kbd"; then
    echo "  [✗] Missing kill_warpd alias in resources/kanata/kanata.kbd" >&2
    exit 1
fi
echo "  [✓] Synchronous kill_warpd alias present in kanata.kbd"

echo "  [✓] All Kanata recovery tests passed successfully!"
