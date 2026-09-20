#!/usr/bin/env bash
# ==============================================================================
# scripts/lib/curate.sh: Domain Skills Curation & Semantic Dedup Subsystem
# ==============================================================================

set -euo pipefail

_CURATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$_CURATE_LIB_DIR/../.." && pwd)"
if [ -z "${REPO_ROOT:-}" ]; then
    REPO_ROOT="$DOTFILES_ROOT"
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
# License Detection & Normalization (Phase 14)
# ------------------------------------------------------------------------------
detect_license() {
    local skill_dir="$1"
    local lic_file=""

    for candidate in "$skill_dir/LICENSE" "$skill_dir/LICENSE.md" "$skill_dir/LICENSE.txt"; do
        if [ -f "$candidate" ]; then
            lic_file="$candidate"
            break
        fi
    done

    if [ -z "$lic_file" ]; then
        echo "unknown"
        return 0
    fi

    local content
    content="$(head -n 20 "$lic_file")"

    if echo "$content" | grep -qi "MIT License\|The MIT License"; then
        echo "MIT"
    elif echo "$content" | grep -qi "Apache License.*2\.0"; then
        echo "Apache-2.0"
    elif echo "$content" | grep -qi "BSD"; then
        echo "BSD"
    elif echo "$content" | grep -qi "ISC License"; then
        echo "ISC"
    elif echo "$content" | grep -qi "Mozilla Public License.*2\.0"; then
        echo "MPL-2.0"
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------------------------
# Metadata Extraction from SKILL.md (Phase 15)
# ------------------------------------------------------------------------------
extract_skill_metadata() {
    local skill_dir="$1"
    local skill_file="$skill_dir/SKILL.md"

    if [ ! -f "$skill_file" ]; then
        echo "{}"
        return 1
    fi

    # shellcheck disable=SC2016
    node -e '
const fs = require("fs");
const path = require("path");
const sFile = process.argv[1];
const content = fs.readFileSync(sFile, "utf8");

let name = path.basename(path.dirname(sFile));
let desc = "";
const fmM = content.match(/^---\s*\n([\s\S]*?)\n---/);
if (fmM) {
  const nm = fmM[1].match(/^name:\s*(.+)$/m);
  if (nm) name = nm[1].trim().replace(/^["'\''"]|["'\''"]$/g, "");
  const dm = fmM[1].match(/^description:\s*(.+)$/m);
  if (dm) desc = dm[1].trim().replace(/^["'\''"]|["'\''"]$/g, "");
}

// Propose capabilities from headings and keyword extraction
const headings = (content.match(/^##+\s+(.+)$/gm) || []).map(h => h.replace(/^##+\s+/, "").toLowerCase().replace(/[^a-z0-9]+/g, "-"));
const triggers = [name, ...name.split("-")].filter(w => w.length > 2);

let domain = "general";
if (content.match(/react|vue|dom|css|ui|component|html/i)) domain = "frontend";
else if (content.match(/sql|postgres|database|prisma|typeorm|redis/i)) domain = "backend";
else if (content.match(/docker|k8s|kubernetes|cloud|nix|terraform/i)) domain = "devops";

console.log(JSON.stringify({
  name,
  description: desc,
  domain,
  capabilities: Array.from(new Set(headings.slice(0, 5))),
  triggers: Array.from(new Set(triggers))
}));
' "$skill_file"
}

# ------------------------------------------------------------------------------
# Metadata Overlap Detection (Phase 5 / Phase 11)
# Returns JSON array of { existing, score, classification }
# Symmetric weighted scoring: capabilities (40%), triggers (30%), domain (10%), tokens (20%)
# ------------------------------------------------------------------------------
detect_metadata_overlap() {
    local cand_dir="$1"
    local reg_file="${2:-$REPO_ROOT/resources/skills/_registry.json}"

    if [ ! -f "$reg_file" ] || [ ! -f "$cand_dir/SKILL.md" ]; then
        echo "[]"
        return 0
    fi

    # shellcheck disable=SC2016
    node -e '
const fs = require("fs");
const path = require("path");
const candDir = process.argv[1];
const regFile = process.argv[2];

const reg = JSON.parse(fs.readFileSync(regFile, "utf8"));
const candContent = fs.readFileSync(path.join(candDir, "SKILL.md"), "utf8");

function wordTokens(str) {
  return new Set((str || "").toLowerCase().replace(/[^a-z0-9\s]/g, " ").split(/\s+/).filter(w => w.length > 3));
}

let candName = path.basename(candDir);
let candDesc = "";
const candCaps = new Set();
const candTrigs = new Set();

const fmM = candContent.match(/^---\s*\n([\s\S]*?)\n---/);
if (fmM) {
  const nm = fmM[1].match(/^name:\s*(.+)$/m);
  if (nm) candName = nm[1].trim().replace(/^["'\''"]|["'\''"]$/g, "");
  const dm = fmM[1].match(/^description:\s*(.+)$/m);
  if (dm) candDesc = dm[1].trim().replace(/^["'\''"]|["'\''"]$/g, "");

  const capMatches = fmM[1].match(/capabilities:\s*\n((?:\s*-[^\n]+\n?)+)/);
  if (capMatches) {
    capMatches[1].split("\n").map(l => l.replace(/^\s*-\s*/, "").trim().toLowerCase()).filter(Boolean).forEach(c => candCaps.add(c));
  }
  const trigMatches = fmM[1].match(/triggers:\s*\n((?:\s*-[^\n]+\n?)+)/);
  if (trigMatches) {
    trigMatches[1].split("\n").map(l => l.replace(/^\s*-\s*/, "").trim().toLowerCase()).filter(Boolean).forEach(t => candTrigs.add(t));
  }
}

const headings = (candContent.match(/^##+\s+(.+)$/gm) || []).map(h => h.replace(/^##+\s+/, "").toLowerCase().replace(/[^a-z0-9]+/g, "-"));
headings.forEach(h => candCaps.add(h));
[candName, ...candName.split("-")].filter(w => w.length > 2).forEach(t => candTrigs.add(t.toLowerCase()));

let candDomain = "general";
if (candContent.match(/react|vue|dom|css|ui|component|html/i)) candDomain = "frontend";
else if (candContent.match(/sql|postgres|database|prisma|typeorm|redis/i)) candDomain = "backend";
else if (candContent.match(/docker|k8s|kubernetes|cloud|nix|terraform/i)) candDomain = "devops";

const candWords = wordTokens(candContent + " " + candDesc);
const overlaps = [];

for (const [name, skill] of Object.entries(reg.skills || {})) {
  if (skill.status === "deprecated") continue;

  const existCaps = new Set((skill.capabilities || []).map(c => String(c).toLowerCase()));
  const existTrigs = new Set((skill.triggers || []).map(t => String(t).toLowerCase()));
  const existDomain = skill.domain || "general";
  const existWords = wordTokens((skill.description || "") + " " + (skill.capabilities || []).join(" ") + " " + (skill.triggers || []).join(" "));

  // Jaccard for capabilities (40%)
  const capUnion = new Set([...candCaps, ...existCaps]);
  const capInter = [...candCaps].filter(x => existCaps.has(x));
  const capJaccard = capUnion.size > 0 ? (capInter.length / capUnion.size) : 0;

  // Jaccard for triggers (30%)
  const trigUnion = new Set([...candTrigs, ...existTrigs]);
  const trigInter = [...candTrigs].filter(x => existTrigs.has(x));
  const trigJaccard = trigUnion.size > 0 ? (trigInter.length / trigUnion.size) : 0;

  // Domain match (10%)
  let domainScore = 0.0;
  if (candDomain === existDomain && candDomain !== "general") {
    domainScore = 1.0;
  } else if (candDomain === existDomain) {
    domainScore = 0.5;
  }

  // Token Jaccard (20%)
  const wordUnion = new Set([...candWords, ...existWords]);
  const wordInter = [...candWords].filter(w => existWords.has(w));
  const wordJaccard = wordUnion.size > 0 ? (wordInter.length / wordUnion.size) : 0;

  // Weighted total score
  let score = (0.40 * capJaccard) + (0.30 * trigJaccard) + (0.10 * domainScore) + (0.20 * wordJaccard);

  const candParts = candName.toLowerCase().split("-").filter(p => p.length > 2);
  const existParts = name.toLowerCase().split("-").filter(p => p.length > 2);
  const sharedName = candParts.filter(p => existParts.includes(p));

  if (candName.toLowerCase() === name.toLowerCase()) {
    score = 1.0;
  } else if (candParts.includes(name.toLowerCase()) || existParts.includes(candName.toLowerCase())) {
    score = Math.max(score, 0.75);
  } else if (sharedName.length > 0 && (candDomain === existDomain || trigInter.length > 0)) {
    score = Math.max(score, 0.60);
  }

  if (score >= 0.40) {
    overlaps.push({
      existing: name,
      score: Number(score.toFixed(2)),
      classification: score >= 0.70 ? "strong_review_candidate" : "review_candidate"
    });
  }
}

overlaps.sort((a, b) => b.score - a.score);
console.log(JSON.stringify(overlaps));
' "$cand_dir" "$reg_file"
}

# ------------------------------------------------------------------------------
# Heuristic Review & Textual Overlap Classification (Phase 12)
# Performs lexical similarity analysis, signal extraction, and action heuristics.
# ------------------------------------------------------------------------------
perform_heuristic_review() {
    local cand_dir="$1"
    local existing_target="$2"
    local reg_file="${3:-$REPO_ROOT/resources/skills/_registry.json}"

    local existing_path="$existing_target"
    if [ ! -f "$existing_path" ] && [ ! -d "$existing_path" ]; then
        if [ -d "$REPO_ROOT/resources/skills/$existing_target" ]; then
            existing_path="$REPO_ROOT/resources/skills/$existing_target"
        elif [ -d "$DOTFILES_ROOT/resources/skills/$existing_target" ]; then
            existing_path="$DOTFILES_ROOT/resources/skills/$existing_target"
        elif [ -f "$reg_file" ] && [ -d "$(dirname "$reg_file")/$existing_target" ]; then
            existing_path="$(dirname "$reg_file")/$existing_target"
        fi
    fi

    # shellcheck disable=SC2016
    node -e '
const fs = require("fs");
const path = require("path");
const candArg = process.argv[1];
const existArg = process.argv[2];

function readSkill(p) {
  let file = p;
  if (fs.existsSync(p) && fs.statSync(p).isDirectory()) file = path.join(p, "SKILL.md");
  if (!fs.existsSync(file)) return null;
  const content = fs.readFileSync(file, "utf8");
  let name = path.basename(path.dirname(file));
  let desc = "";
  const fmM = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (fmM) {
    const nm = fmM[1].match(/^name:\s*(.+)$/m);
    if (nm) name = nm[1].trim().replace(/^["'\''"]|["'\''"]$/g, "");
    const dm = fmM[1].match(/^description:\s*(.+)$/m);
    if (dm) desc = dm[1].trim().replace(/^["'\''"]|["'\''"]$/g, "");
  }
  return { name, desc, content };
}

const cand = readSkill(candArg);
const exist = readSkill(existArg);

if (!cand || !exist) {
  console.log(JSON.stringify({
    review_type: "heuristic",
    candidate: cand ? cand.name : "unknown",
    existing: exist ? exist.name : "unknown",
    heuristic_decision: "KEEP_BOTH",
    heuristic_action: "CREATE",
    similarity_score: 0.0,
    signals: ["unresolved_skill_path"],
    reason: "Skill details could not be resolved for comparison.",
    shared_capabilities: [],
    candidate_unique: [],
    existing_unique: []
  }, null, 2));
  process.exit(0);
}

function wordTokens(str) {
  return new Set((str || "").toLowerCase().replace(/[^a-z0-9\s]/g, " ").split(/\s+/).filter(w => w.length > 2));
}

const cWords = wordTokens(cand.content + " " + cand.desc);
const eWords = wordTokens(exist.content + " " + exist.desc);
const union = new Set([...cWords, ...eWords]);
const inter = [...cWords].filter(w => eWords.has(w));
const jaccard = union.size > 0 ? (inter.length / union.size) : 0;

const cNameParts = cand.name.toLowerCase().split("-");
const eNameParts = exist.name.toLowerCase().split("-");
const nameShared = cNameParts.filter(p => eNameParts.includes(p) && p.length > 3);

const signals = [];
if (nameShared.length > 0) signals.push(`shared_name_tokens: ${nameShared.join(", ")}`);
if (jaccard >= 0.40) signals.push(`high_token_overlap: ${(jaccard * 100).toFixed(0)}%`);
if (cand.name === exist.name) signals.push("exact_name_match");

let decision = "KEEP_BOTH";
let action = "CREATE";
let reason = "Complementary capabilities with minimal overlap.";

if (cand.name === exist.name || (jaccard >= 0.70 && nameShared.length >= 1)) {
  decision = "DUPLICATE";
  action = "REUSE";
  reason = `Candidate directly duplicates existing scope, tools, and triggers of "${exist.name}".`;
} else if (jaccard >= 0.25 || nameShared.length >= 1) {
  decision = "PARTIAL_OVERLAP";
  action = "COMPANION";
  reason = `Candidate shares domain and vocabulary with "${exist.name}", but focuses on specialized distinct workflow.`;
}

console.log(JSON.stringify({
  review_type: "heuristic",
  candidate: cand.name,
  existing: exist.name,
  heuristic_decision: decision,
  heuristic_action: action,
  similarity_score: Number(jaccard.toFixed(2)),
  signals,
  reason,
  shared_capabilities: inter.slice(0, 5),
  candidate_unique: [...cWords].filter(w => !eWords.has(w)).slice(0, 5),
  existing_unique: [...eWords].filter(w => !cWords.has(w)).slice(0, 5)
}, null, 2));
' "$cand_dir" "$existing_path"
}

classify_textual_overlap() {
    perform_heuristic_review "$@"
}

# ------------------------------------------------------------------------------
# Strict AI Semantic Review Validator
# Validates schema, decisions, recommended_actions, pairs, and target matching.
# ------------------------------------------------------------------------------
validate_semantic_review() {
    local review_json="$1"
    local cand_name="${2:-}"
    local existing_target="${3:-}"

    # shellcheck disable=SC2016
    node -e '
const raw = process.argv[1];
const candName = (process.argv[2] || "").trim();
const existName = (process.argv[3] || "").trim();

let data;
try {
  data = JSON.parse(raw);
} catch (e) {
  console.log(JSON.stringify({ valid: false, reason: "Malformed JSON payload: " + e.message }));
  process.exit(0);
}

if (!data || typeof data !== "object" || Array.isArray(data)) {
  console.log(JSON.stringify({ valid: false, reason: "Semantic review payload must be a JSON object" }));
  process.exit(0);
}

if (data.review_type !== "semantic") {
  console.log(JSON.stringify({ valid: false, reason: "Missing or invalid review_type (must be '\''semantic'\'')" }));
  process.exit(0);
}

if (data.status !== "completed") {
  console.log(JSON.stringify({ valid: false, reason: "Missing or invalid status (must be '\''completed'\'')" }));
  process.exit(0);
}

const ALLOWED_DECISIONS = ["KEEP_BOTH", "PARTIAL_OVERLAP", "DUPLICATE", "SUPERSEDES", "CONFLICT"];
if (!ALLOWED_DECISIONS.includes(data.decision)) {
  console.log(JSON.stringify({ valid: false, reason: `Invalid decision '\''${data.decision}'\''. Allowed: ${ALLOWED_DECISIONS.join(", ")}` }));
  process.exit(0);
}

const ALLOWED_ACTIONS = ["REUSE", "EXTEND", "COMPANION", "CREATE", "REPLACE"];
if (data.decision !== "CONFLICT" && !ALLOWED_ACTIONS.includes(data.recommended_action)) {
  console.log(JSON.stringify({ valid: false, reason: `Missing or invalid recommended_action '\''${data.recommended_action}'\''. Allowed: ${ALLOWED_ACTIONS.join(", ")}` }));
  process.exit(0);
}

// Decision & Action pair validation
const VALID_PAIRS = {
  KEEP_BOTH: ["CREATE", "COMPANION"],
  PARTIAL_OVERLAP: ["COMPANION", "EXTEND"],
  DUPLICATE: ["REUSE"],
  SUPERSEDES: ["REPLACE", "EXTEND"],
  CONFLICT: ["NONE", null, undefined, "REUSE"]
};

if (data.decision === "CONFLICT") {
  if (data.recommended_action && ["CREATE", "COMPANION", "REPLACE", "EXTEND"].includes(data.recommended_action)) {
    console.log(JSON.stringify({ valid: false, reason: `Invalid decision/action pair: CONFLICT cannot pair with '\''${data.recommended_action}'\''` }));
    process.exit(0);
  }
} else {
  const allowedForDec = VALID_PAIRS[data.decision] || [];
  if (!allowedForDec.includes(data.recommended_action)) {
    console.log(JSON.stringify({ valid: false, reason: `Invalid decision/action pair: ${data.decision} cannot pair with ${data.recommended_action}. Allowed for ${data.decision}: ${allowedForDec.join(", ")}` }));
    process.exit(0);
  }
}

if (!data.existing || typeof data.existing !== "string" || !data.existing.trim()) {
  console.log(JSON.stringify({ valid: false, reason: "Missing existing skill target" }));
  process.exit(0);
}

if (existName && data.existing.trim() !== existName) {
  console.log(JSON.stringify({ valid: false, reason: `Target mismatch: payload targets '\''${data.existing.trim()}'\'' but comparing against '\''${existName}'\''` }));
  process.exit(0);
}

if (candName && data.candidate && typeof data.candidate === "string" && data.candidate.trim() !== candName) {
  console.log(JSON.stringify({ valid: false, reason: `Candidate mismatch: payload candidate '\''${data.candidate.trim()}'\'' does not match '\''${candName}'\''` }));
  process.exit(0);
}

if (!data.reason || typeof data.reason !== "string" || !data.reason.trim()) {
  console.log(JSON.stringify({ valid: false, reason: "Missing or empty reason for semantic review decision" }));
  process.exit(0);
}

console.log(JSON.stringify({ valid: true }));
' "$review_json" "$cand_name" "$existing_target"
}

# ------------------------------------------------------------------------------
# AI Semantic Review Contract
# Evaluates external model review payload with strict validation and NO heuristic fallback.
# ------------------------------------------------------------------------------
perform_semantic_review() {
    local cand_dir="$1"
    local existing_target="$2"
    local reg_file="${3:-$REPO_ROOT/resources/skills/_registry.json}"

    local cand_name=""
    if [ -d "$cand_dir" ] && [ -f "$cand_dir/SKILL.md" ]; then
        cand_name="$(sed -n -e '/^name:[[:space:]]*/{ s///; p; q; }' "$cand_dir/SKILL.md" | tr -d '\r"' || true)"
    fi
    [ -z "$cand_name" ] && cand_name="$(basename "$cand_dir")"

    local raw_json=""
    if [ -n "${SEMANTIC_REVIEW_FILE:-}" ] && [ -f "$SEMANTIC_REVIEW_FILE" ]; then
        raw_json="$(cat "$SEMANTIC_REVIEW_FILE")"
    elif [ -n "${SEMANTIC_REVIEW_JSON:-}" ]; then
        raw_json="$SEMANTIC_REVIEW_JSON"
    fi

    if [ -z "$raw_json" ]; then
        jq -n \
            --arg target "$existing_target" \
            '{
                review_type: "semantic",
                status: "required",
                existing: $target,
                reason: "No semantic review payload provided"
            }'
        return 0
    fi

    if ! echo "$raw_json" | jq -e . >/dev/null 2>&1; then
        jq -n \
            --arg target "$existing_target" \
            '{
                review_type: "semantic",
                status: "required",
                existing: $target,
                reason: "Malformed JSON payload"
            }'
        return 0
    fi

    local target_item=""
    if echo "$raw_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
        target_item="$(echo "$raw_json" | jq -c --arg target "$existing_target" '.[] | select(.existing == $target or .target == $target)' 2>/dev/null || echo "")"
        if [ -z "$target_item" ] || [ "$target_item" = "null" ]; then
            jq -n \
                --arg target "$existing_target" \
                '{
                    review_type: "semantic",
                    status: "required",
                    existing: $target,
                    reason: "Target mismatch: no review entry matching target"
                }'
            return 0
        fi
    else
        target_item="$raw_json"
    fi

    local val_res
    val_res="$(validate_semantic_review "$target_item" "$cand_name" "$existing_target")"
    local is_valid
    is_valid="$(echo "$val_res" | jq -r '.valid // false')"

    if [ "$is_valid" = "true" ]; then
        echo "$target_item"
        return 0
    fi

    local val_reason
    val_reason="$(echo "$val_res" | jq -r '.reason // "Validation failed"')"
    jq -n \
        --arg target "$existing_target" \
        --arg reason "Invalid semantic review payload: $val_reason" \
        '{
            review_type: "semantic",
            status: "required",
            existing: $target,
            reason: $reason
        }'
}

# ------------------------------------------------------------------------------
# Multi-Overlap Review Evaluator (Phase 14 & Blocker 3)
# Evaluates candidate against all strong_review_candidate + top 3 review_candidate.
# ------------------------------------------------------------------------------
review_candidate_overlaps() {
    local cand_dir="$1"
    local reg_file="${2:-$REPO_ROOT/resources/skills/_registry.json}"

    if [ ! -f "$reg_file" ] || [ ! -f "$cand_dir/SKILL.md" ]; then
        echo "[]"
        return 0
    fi

    local overlaps
    overlaps="$(detect_metadata_overlap "$cand_dir" "$reg_file" 2>/dev/null || echo "[]")"

    if [ -z "$overlaps" ] || [ "$overlaps" = "[]" ]; then
        echo "[]"
        return 0
    fi

    # Select all strong_review_candidate and up to top 3 review_candidate
    # shellcheck disable=SC2016
    local targets_json
    targets_json="$(echo "$overlaps" | jq -c '
        ( [ .[] | select(.classification == "strong_review_candidate") ] ) as $strong |
        ( [ .[] | select(.classification == "review_candidate") ] | .[0:3] ) as $normal |
        ($strong + $normal) | unique_by(.existing)
    ')"

    local count
    count="$(echo "$targets_json" | jq 'length')"
    if [ "$count" -eq 0 ]; then
        echo "[]"
        return 0
    fi

    local results="[]"
    for (( i=0; i<count; i++ )); do
        local target_name target_score target_class
        target_name="$(echo "$targets_json" | jq -r ".[$i].existing")"
        target_score="$(echo "$targets_json" | jq -r ".[$i].score")"
        target_class="$(echo "$targets_json" | jq -r ".[$i].classification")"

        local heur sem
        heur="$(perform_heuristic_review "$cand_dir" "$target_name" "$reg_file")"
        sem="$(perform_semantic_review "$cand_dir" "$target_name" "$reg_file")"

        results="$(echo "$results" | jq --arg name "$target_name" \
                                       --argjson score "$target_score" \
                                       --arg cls "$target_class" \
                                       --argjson heur "$heur" \
                                       --argjson sem "$sem" \
            '. + [{ existing: $name, score: $score, classification: $cls, heuristic: $heur, review: $sem }]'
        )"
    done

    echo "$results"
}

# ------------------------------------------------------------------------------
# Aggregate Multi-Overlap Semantic Reviews
# Priority: CONFLICT > DUPLICATE > SUPERSEDES > PARTIAL_OVERLAP > KEEP_BOTH
# ------------------------------------------------------------------------------
aggregate_semantic_reviews() {
    local reviews_json="$1"

    # shellcheck disable=SC2016
    node -e '
const raw = process.argv[1];
let items = [];
try {
  const parsed = JSON.parse(raw);
  if (Array.isArray(parsed)) items = parsed;
  else if (parsed && typeof parsed === "object") items = [parsed];
} catch (e) {
  console.log(JSON.stringify({
    has_pending: true,
    decision: null,
    recommended_action: null,
    reason: "Malformed reviews payload: " + e.message,
    conflict_matches: [],
    duplicate_matches: [],
    supersedes_matches: [],
    partial_matches: [],
    keep_matches: []
  }));
  process.exit(0);
}

if (items.length === 0) {
  console.log(JSON.stringify({
    has_pending: false,
    decision: "KEEP_BOTH",
    recommended_action: "CREATE",
    reason: "No overlapping reviews.",
    conflict_matches: [],
    duplicate_matches: [],
    supersedes_matches: [],
    partial_matches: [],
    keep_matches: []
  }));
  process.exit(0);
}

const getReview = it => it.review || it;
const getExisting = it => {
  const r = getReview(it);
  return (it.existing || r.existing || "").trim();
};

// Check for pending reviews
const pending = items.filter(it => {
  const rev = getReview(it);
  return rev.status !== "completed" || !rev.decision;
});

if (pending.length > 0) {
  console.log(JSON.stringify({
    has_pending: true,
    decision: null,
    recommended_action: null,
    reason: "Semantic review is required because candidate overlaps existing skills.",
    conflict_matches: [],
    duplicate_matches: [],
    supersedes_matches: [],
    partial_matches: [],
    keep_matches: []
  }));
  process.exit(0);
}

const conflict = items.filter(it => getReview(it).decision === "CONFLICT");
const duplicate = items.filter(it => getReview(it).decision === "DUPLICATE");
const supersedes = items.filter(it => getReview(it).decision === "SUPERSEDES");
const partial = items.filter(it => getReview(it).decision === "PARTIAL_OVERLAP");
const keep = items.filter(it => getReview(it).decision === "KEEP_BOTH");

let decision = "KEEP_BOTH";
let action = "CREATE";
let reason = "Complementary capabilities with minimal overlap.";

if (conflict.length > 0) {
  decision = "CONFLICT";
  const r = getReview(conflict[0]);
  action = r.recommended_action || "NONE";
  reason = r.reason || "Conflict with existing canonical skill";
} else if (duplicate.length > 0) {
  decision = "DUPLICATE";
  const r = getReview(duplicate[0]);
  action = "REUSE";
  reason = r.reason || "Duplicate of existing skill";
} else if (supersedes.length > 0) {
  decision = "SUPERSEDES";
  const r = getReview(supersedes[0]);
  action = r.recommended_action || "REPLACE";
  reason = r.reason || "Supersedes existing canonical skill";
} else if (partial.length > 0) {
  decision = "PARTIAL_OVERLAP";
  const r = getReview(partial[0]);
  action = r.recommended_action || "COMPANION";
  reason = r.reason || "Partial overlap with existing skill";
} else if (keep.length > 0) {
  decision = "KEEP_BOTH";
  const r = getReview(keep[0]);
  action = r.recommended_action || "CREATE";
  reason = r.reason || "Complementary capabilities with minimal overlap.";
}

console.log(JSON.stringify({
  has_pending: false,
  decision: decision,
  recommended_action: action,
  reason: reason,
  conflict_matches: conflict.map(getExisting).filter(Boolean),
  duplicate_matches: duplicate.map(getExisting).filter(Boolean),
  supersedes_matches: supersedes.map(getExisting).filter(Boolean),
  partial_matches: partial.map(getExisting).filter(Boolean),
  keep_matches: keep.map(getExisting).filter(Boolean)
}));
' "$reviews_json"
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
        license)
            detect_license "${2:-$PWD}"
            ;;
        metadata)
            extract_skill_metadata "${2:-$PWD}"
            ;;
        overlap)
            detect_metadata_overlap "${2:-$PWD}" "${3:-$REPO_ROOT/resources/skills/_registry.json}"
            ;;
        heuristic)
            perform_heuristic_review "${2:-}" "${3:-}" "${4:-$REPO_ROOT/resources/skills/_registry.json}"
            ;;
        review)
            perform_semantic_review "${2:-}" "${3:-}" "${4:-$REPO_ROOT/resources/skills/_registry.json}"
            ;;
        overlaps-review)
            review_candidate_overlaps "${2:-$PWD}" "${3:-$REPO_ROOT/resources/skills/_registry.json}"
            ;;
        validate-semantic)
            validate_semantic_review "${2:-}" "${3:-}" "${4:-}"
            ;;
        aggregate-semantic)
            aggregate_semantic_reviews "${2:-[]}"
            ;;
        help|--help|-h)
            echo "Usage: $0 {audit [path]|dedup [registry]|license <path>|metadata <path>|overlap <cand_dir> [registry]|heuristic <cand_dir> <existing>|review <cand_dir> <existing>|validate-semantic <json> [cand] [exist]|overlaps-review <cand_dir> [registry]|aggregate-semantic <json>}"
            ;;
        *)
            echo "Unknown command: $CMD" >&2
            exit 1
            ;;
    esac
fi
