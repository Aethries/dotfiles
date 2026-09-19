#!/usr/bin/env bash
# ==============================================================================
# OmniRoute Integration, Security & Port Isolation Test Suite
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

OMNI_SERVICE="$REPO_ROOT/resources/systemd/user/omniroute.service"
ROUTER_SERVICE="$REPO_ROOT/resources/systemd/user/9router.service"

# ------------------------------------------------------------------------------
# 1. Port Configuration & Loopback Binding Verification
# ------------------------------------------------------------------------------
log_info "1. Verifying OmniRoute dedicated port 20129 and loopback binding..."
[ -f "$OMNI_SERVICE" ] || log_fail "OmniRoute service template missing at $OMNI_SERVICE"

grep -q 'Environment="PORT=20129"' "$OMNI_SERVICE" || log_fail "PORT=20129 missing in omniroute.service"
grep -q 'Environment="DASHBOARD_PORT=20129"' "$OMNI_SERVICE" || log_fail "DASHBOARD_PORT=20129 missing in omniroute.service"
grep -q 'Environment="HOST=127.0.0.1"' "$OMNI_SERVICE" || log_fail "HOST=127.0.0.1 missing in omniroute.service"
grep -q 'Environment="OMNIROUTE_SERVER_HOST=127.0.0.1"' "$OMNI_SERVICE" || log_fail "OMNIROUTE_SERVER_HOST=127.0.0.1 missing in omniroute.service"
grep -q 'Environment="API_HOST=127.0.0.1"' "$OMNI_SERVICE" || log_fail "API_HOST=127.0.0.1 missing in omniroute.service"
grep -q 'Environment="LIVE_WS_HOST=127.0.0.1"' "$OMNI_SERVICE" || log_fail "LIVE_WS_HOST=127.0.0.1 missing in omniroute.service"

log_ok "Dedicated port (20129) and strict loopback host bindings verified in systemd service."

# ------------------------------------------------------------------------------
# 2. Port Coexistence & No-MITM Verification
# ------------------------------------------------------------------------------
log_info "2. Verifying dual-gateway coexistence and MITM isolation..."
[ -f "$ROUTER_SERVICE" ] || log_fail "9Router service template missing at $ROUTER_SERVICE"
grep -q 'ExecStart=%h/\.local/bin/9router' "$ROUTER_SERVICE" || log_fail "9Router service ExecStart invalid"
grep -q '20128' "$REPO_ROOT/scripts/init-9router.sh" || log_fail "9Router port 20128 missing in init-9router.sh"

# Verify OmniRoute does NOT touch MITM or Root CA
if grep -riE '(rootCA|mitm|generate-ca)' "$OMNI_SERVICE"; then
    log_fail "OmniRoute service unexpectedly contains MITM Root CA configuration!"
fi

log_ok "Dual-gateway port separation (20128 vs 20129) and no-MITM policy verified."

# ------------------------------------------------------------------------------
# 3. Secret Leakage Prevention (.gitignore & Vault)
# ------------------------------------------------------------------------------
log_info "3. Verifying secret leakage prevention in Git and resources/omniroute..."
GITIGNORE="$REPO_ROOT/resources/omniroute/.gitignore"
[ -f "$GITIGNORE" ] || log_fail "Missing .gitignore in resources/omniroute"

grep -q '\*\.json' "$GITIGNORE" || log_fail "*.json exclusion missing in resources/omniroute/.gitignore"
grep -q '\*\.sqlite' "$GITIGNORE" || log_fail "*.sqlite exclusion missing in resources/omniroute/.gitignore"
grep -q '\*\.env' "$GITIGNORE" || log_fail "*.env exclusion missing in resources/omniroute/.gitignore"

# Verify git check-ignore confirms bundle and sqlite ignores
git -C "$REPO_ROOT" check-ignore -q "resources/omniroute/bundle.json" || log_fail "bundle.json is NOT ignored by git"
git -C "$REPO_ROOT" check-ignore -q "resources/omniroute/storage.sqlite" || log_fail "storage.sqlite is NOT ignored by git"

log_ok "Git secret exclusion patterns verified."

# ------------------------------------------------------------------------------
# 4. Key Desync Guard & Orphan DB Protection
# ------------------------------------------------------------------------------
log_info "4. Verifying database encryption key guard in init-omniroute..."
INIT_SCRIPT="$REPO_ROOT/scripts/init-omniroute.sh"

grep -q 'STORAGE_ENCRYPTION_KEY' "$INIT_SCRIPT" || log_fail "STORAGE_ENCRYPTION_KEY missing in init-omniroute"
grep -q 'ORPHAN_BACKUP' "$INIT_SCRIPT" || log_fail "Orphan database backup logic missing in init-omniroute"
grep -q -- '--force' "$INIT_SCRIPT" || log_fail "--force flag support missing in init-omniroute"

log_ok "Key desync protection and orphan database safeguard verified."

# ------------------------------------------------------------------------------
# 5. Vault SQLite WAL & Candidate Paths Integration
# ------------------------------------------------------------------------------
log_info "5. Verifying Vault backup SQLite consistency and exclusions..."
VAULT_SCRIPT="$REPO_ROOT/scripts/vault.sh"

grep -q '"\.omniroute"' "$VAULT_SCRIPT" || log_fail ".omniroute missing from CANDIDATE_PATHS in vault.sh"
grep -q 'omniroute\.service' "$VAULT_SCRIPT" || log_fail "omniroute.service pause missing from vault.sh"
grep -q 'wal_checkpoint' "$VAULT_SCRIPT" || log_fail "wal_checkpoint missing from vault.sh"
grep -q '\*/\.omniroute/logs/\*' "$VAULT_SCRIPT" || log_fail "OmniRoute logs exclusion missing from vault.sh"
grep -q '\*/\.omniroute/\*\.sock' "$VAULT_SCRIPT" || log_fail "OmniRoute socket exclusion missing from vault.sh"

log_ok "Vault database consistency and exclusion rules verified."

echo
log_ok "ALL OMNIROUTE INTEGRATION & SECURITY TESTS PASSED."
