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

    # 5. Check for reverse shell and base64 encoded pipe executions
    if grep -rEi '(/dev/tcp/|nc[[:space:]]+-[ecl]|mkfifo.*sh|base64[[:space:]]+-[dD][[:space:]]*\|[[:space:]]*(sh|bash))' "$skill_dir" 2>/dev/null; then
        log_err "Security violation in $(basename "$skill_dir"): Reverse shell or base64 decoded execution detected."
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
# Semantic Deduplication & Capability Overlap Analysis (Section 49)
# ------------------------------------------------------------------------------
check_semantic_dedup() {
    local reg_file="${1:-$REPO_ROOT/resources/skills/_registry.json}"
    if [ ! -f "$reg_file" ]; then
        log_err "Registry file not found: $reg_file"
        return 1
    fi

    # 1. Unique keys check
    local count
    count="$(jq '.skills | keys | length' "$reg_file")"
    local unique_count
    unique_count="$(jq '.skills | keys | unique | length' "$reg_file")"

    if [ "$count" -ne "$unique_count" ]; then
        log_err "Registry contains duplicate keys ($count total vs $unique_count unique)"
        return 1
    fi

    # 2. Capability, Trigger & SKILL.md Semantic Overlap Analysis
    if command -v node >/dev/null 2>&1; then
        local overlap_report
        # shellcheck disable=SC2016
        overlap_report="$(node -e '
const fs = require("fs");
const path = require("path");
const regFile = process.argv[1];
const skillsBase = path.dirname(regFile);
const reg = JSON.parse(fs.readFileSync(regFile, "utf8"));
const skills = reg.skills || {};
const entries = Object.entries(skills).filter(([_, s]) => s.status !== "deprecated");

function getSkillText(name) {
  const p = path.join(skillsBase, name, "SKILL.md");
  if (fs.existsSync(p)) return fs.readFileSync(p, "utf8").toLowerCase();
  return "";
}

function wordTokens(str) {
  return new Set((str || "").toLowerCase().replace(/[^a-z0-9\s]/g, " ").split(/\s+/).filter(w => w.length > 3));
}

let violations = 0;
for (let i = 0; i < entries.length; i++) {
  for (let j = i + 1; j < entries.length; j++) {
    const [name1, s1] = entries[i];
    const [name2, s2] = entries[j];

    const isDep = (s1.dependencies && s1.dependencies.includes(name2)) ||
                  (s2.dependencies && s2.dependencies.includes(name1));
    if (isDep) continue;

    const caps1 = new Set(s1.capabilities || []);
    const caps2 = new Set(s2.capabilities || []);
    const capUnion = new Set([...caps1, ...caps2]);
    const capInter = [...caps1].filter(x => caps2.has(x));
    const capJaccard = capUnion.size > 0 ? (capInter.length / capUnion.size) : 0;

    const trigs1 = new Set(s1.triggers || []);
    const trigs2 = new Set(s2.triggers || []);
    const trigUnion = new Set([...trigs1, ...trigs2]);
    const trigInter = [...trigs1].filter(x => trigs2.has(x));
    const trigJaccard = trigUnion.size > 0 ? (trigInter.length / trigUnion.size) : 0;

    // Prefilter: high capability or trigger Jaccard
    if (capJaccard >= 0.65 || trigJaccard >= 0.65) {
      const text1 = getSkillText(name1);
      const text2 = getSkillText(name2);
      const words1 = wordTokens(text1 || s1.description);
      const words2 = wordTokens(text2 || s2.description);
      const wordUnion = new Set([...words1, ...words2]);
      const wordInter = [...words1].filter(w => words2.has(w));
      const wordJaccard = wordUnion.size > 0 ? (wordInter.length / wordUnion.size) : 0;

      const outputs1 = (text1.match(/docs\/(specs|plans|reviews|architecture|incidents)\/[a-z0-9_.-]+/g) || []);
      const outputs2 = (text2.match(/docs\/(specs|plans|reviews|architecture|incidents)\/[a-z0-9_.-]+/g) || []);
      const sharedOutputs = outputs1.filter(o => outputs2.includes(o));

      if (wordJaccard >= 0.60 || sharedOutputs.length > 0 || (capJaccard >= 0.70 && trigJaccard >= 0.70)) {
        console.error(`Conflict: high semantic overlap between "${name1}" and "${name2}":`);
        console.error(`  Capabilities Jaccard: ${(capJaccard * 100).toFixed(0)}%`);
        console.error(`  Triggers Jaccard:     ${(trigJaccard * 100).toFixed(0)}%`);
        console.error(`  Body Token Jaccard:   ${(wordJaccard * 100).toFixed(0)}%`);
        if (sharedOutputs.length > 0) {
          console.error(`  Colliding Artifacts:  ${sharedOutputs.join(", ")}`);
        }
        violations++;
      }
    }
  }
}
process.exit(violations > 0 ? 1 : 0);
' "$reg_file" 2>&1)" || {
            log_err "Semantic overlap detected in registry:\n$overlap_report"
            return 1
        }
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
