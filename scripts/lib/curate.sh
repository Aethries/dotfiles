#!/usr/bin/env bash
# ==============================================================================
# scripts/lib/curate.sh: Domain Skills Curation & Semantic Dedup Subsystem
# ==============================================================================

set -euo pipefail

if [ -z "${REPO_ROOT:-}" ]; then
    _CURATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$_CURATE_LIB_DIR/../.." && pwd)"
fi

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_warn() { echo -e "  [${YELLOW}!${RESET}] $1"; }
log_err() { echo -e "  [${RED}✗${RESET}] $1" >&2; }

# ------------------------------------------------------------------------------
# Security Audit Protocol (Section 51)
# Scans skill files for dangerous shell executions, telemetry, and injection.
# ------------------------------------------------------------------------------
audit_skill_security() {
    local skill_dir="$1"
    local violations=0

    if [ ! -d "$skill_dir" ]; then
        log_err "Directory not found: $skill_dir"
        return 1
    fi

    # 1. Check for arbitrary shell pipe execution (curl ... | sh, wget ... | sh)
    if grep -rEi '(curl|wget)[[:space:]].*\|[[:space:]]*(sh|bash)' "$skill_dir" 2>/dev/null; then
        log_err "Security violation in $(basename "$skill_dir"): Arbitrary piped shell execution detected."
        violations=$((violations + 1))
    fi

    # 2. Check for dynamic eval usage
    if grep -rE '\beval[[:space:]]+(\$|\"[^\"]*\$)' "$skill_dir" 2>/dev/null; then
        log_err "Security violation in $(basename "$skill_dir"): Dynamic eval execution detected."
        violations=$((violations + 1))
    fi

    # 3. Check for obvious telemetry / data exfiltration webhooks
    if grep -rEi 'https?://(api\.mixpanel\.com|telemetry\.|analytics\.|webhook\.site)' "$skill_dir" 2>/dev/null; then
        log_err "Security violation in $(basename "$skill_dir"): External telemetry endpoint detected."
        violations=$((violations + 1))
    fi

    # 4. Check for adversarial prompt injection signatures
    if grep -rEi '(ignore previous instructions|disregard system prompt|bypass guardrails)' "$skill_dir" 2>/dev/null; then
        log_err "Security violation in $(basename "$skill_dir"): Prompt injection payload detected."
        violations=$((violations + 1))
    fi

    return "$violations"
}

audit_all_skills() {
    local skills_root="${1:-$REPO_ROOT/resources/skills}"
    local failed=0

    for dir in "$skills_root"/*; do
        if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
            if ! audit_skill_security "$dir"; then
                failed=$((failed + 1))
            fi
        fi
    done

    return "$failed"
}

# ------------------------------------------------------------------------------
# Semantic Deduplication & Name Integrity (Section 49)
# ------------------------------------------------------------------------------
check_semantic_dedup() {
    local reg_file="${1:-$REPO_ROOT/resources/skills/_registry.json}"
    if [ ! -f "$reg_file" ]; then
        log_err "Registry file not found: $reg_file"
        return 1
    fi

    # Ensure no duplicate skill names registered
    local count
    count="$(jq '.skills | keys | length' "$reg_file")"
    local unique_count
    unique_count="$(jq '.skills | keys | unique | length' "$reg_file")"

    if [ "$count" -ne "$unique_count" ]; then
        log_err "Registry contains duplicate keys ($count total vs $unique_count unique)"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# CLI Dispatcher when run standalone
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CMD="${1:-help}"
    case "$CMD" in
        audit)
            TARGET="${2:-$REPO_ROOT/resources/skills}"
            if [ -d "$TARGET" ] && [ -f "$TARGET/SKILL.md" ]; then
                audit_skill_security "$TARGET"
                log_ok "Skill security audit passed: $TARGET"
            else
                audit_all_skills "$TARGET"
                log_ok "All skills passed security audit in: $TARGET"
            fi
            ;;
        dedup)
            check_semantic_dedup "${2:-$REPO_ROOT/resources/skills/_registry.json}"
            log_ok "Semantic deduplication check passed"
            ;;
        help|--help|-h)
            echo "Usage: $0 {audit [path]|dedup [registry.json]}"
            ;;
        *)
            echo "Unknown command: $CMD" >&2
            exit 1
            ;;
    esac
fi
