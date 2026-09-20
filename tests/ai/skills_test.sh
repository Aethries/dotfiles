#!/usr/bin/env bash
# ==============================================================================
# Isolated AI Skills & Ponytail Ruleset Test Suite
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

SANDBOX_DIR="$(mktemp -d)"
MOCK_HOME="$SANDBOX_DIR/home"
MOCK_PROJECT="$SANDBOX_DIR/project"
mkdir -p "$MOCK_HOME" "$MOCK_PROJECT"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# 1. Validate Ponytail SKILL.md and references
# ------------------------------------------------------------------------------
log_info "Validating canonical Ponytail skill schema..."

SKILL_FILE="$REPO_ROOT/resources/skills/ponytail/SKILL.md"
[ -f "$SKILL_FILE" ] || log_fail "Missing $SKILL_FILE"

# Assert YAML frontmatter structure
HEAD_FIRST=$(head -n 1 "$SKILL_FILE")
[ "$HEAD_FIRST" = "---" ] || log_fail "SKILL.md must start with YAML frontmatter delimiter '---'"

# Assert name: ponytail
grep -Eiq '^name:[[:space:]]*ponytail' "$SKILL_FILE" || log_fail "SKILL.md missing 'name: ponytail'"

# Assert description is present and non-empty
grep -Eiq '^description:' "$SKILL_FILE" || log_fail "SKILL.md missing description"

# Assert Core Rules and 6-step filter reference
grep -Fq "## Core Rules" "$SKILL_FILE" || log_fail "SKILL.md missing '## Core Rules'"
grep -Fq "6-Step Code Filter" "$SKILL_FILE" || log_fail "SKILL.md missing '6-Step Code Filter'"
grep -Fq "Granular Laziness Tiers" "$SKILL_FILE" || log_fail "SKILL.md missing 'Granular Laziness Tiers'"
grep -Eiq 'Ultra.*\(Default\)' "$SKILL_FILE" || log_fail "SKILL.md missing 'Ultra (Default)'"
grep -Fq "Safety & Quality Guardrails" "$SKILL_FILE" || log_fail "SKILL.md missing 'Safety & Quality Guardrails'"

REF_FILE="$REPO_ROOT/resources/skills/ponytail/references/code-filter.md"
[ -f "$REF_FILE" ] || log_fail "Missing $REF_FILE"
grep -Fq "Rung 1: YAGNI Check" "$REF_FILE" || log_fail "Missing Rung 1 in code-filter.md"
grep -Fq "Rung 6: Minimum Working Code" "$REF_FILE" || log_fail "Missing Rung 6 in code-filter.md"
grep -Fq "ponytail:" "$REF_FILE" || log_fail "Missing comment convention in code-filter.md"

JUNIOR_FILE="$REPO_ROOT/resources/skills/junior-coding-agent/SKILL.md"
[ -f "$JUNIOR_FILE" ] || log_fail "Missing $JUNIOR_FILE"
grep -Eiq '^name:[[:space:]]*junior-coding-agent' "$JUNIOR_FILE" || log_fail "junior-coding-agent SKILL.md missing valid name"
[ -f "$REPO_ROOT/resources/skills/junior-coding-agent/references/approval-and-workflow.md" ] || log_fail "Missing approval-and-workflow.md"

RELEASE_NOTES_FILE="$REPO_ROOT/resources/skills/release-notes/SKILL.md"
[ -f "$RELEASE_NOTES_FILE" ] || log_fail "Missing $RELEASE_NOTES_FILE"
grep -Eiq '^name:[[:space:]]*release-notes' "$RELEASE_NOTES_FILE" || log_fail "release-notes SKILL.md missing valid name"
grep -Fq "SemVer" "$RELEASE_NOTES_FILE" || log_fail "release-notes SKILL.md missing SemVer"

CAVEMAN_FILE="$REPO_ROOT/resources/skills/caveman/SKILL.md"
[ -f "$CAVEMAN_FILE" ] || log_fail "Missing $CAVEMAN_FILE"
grep -Eiq '^name:[[:space:]]*caveman' "$CAVEMAN_FILE" || log_fail "caveman SKILL.md missing valid name"
grep -Eiq 'Ultra.*\(Default\)' "$CAVEMAN_FILE" || log_fail "caveman SKILL.md missing Ultra (Default)"
[ -f "$REPO_ROOT/resources/skills/caveman/references/modes.md" ] || log_fail "Missing modes.md"
grep -Eiq 'Ultra Mode.*\(Default\)' "$REPO_ROOT/resources/skills/caveman/references/modes.md" || log_fail "Missing Ultra Mode (Default) in modes.md"

RTK_FILE="$REPO_ROOT/resources/skills/rtk/SKILL.md"
[ -f "$RTK_FILE" ] || log_fail "Missing $RTK_FILE"
grep -Eiq '^name:[[:space:]]*rtk' "$RTK_FILE" || log_fail "rtk SKILL.md missing valid name"

CBM_FILE="$REPO_ROOT/resources/skills/codebase-memory/SKILL.md"
[ -f "$CBM_FILE" ] || log_fail "Missing $CBM_FILE"
grep -Eiq '^name:[[:space:]]*codebase-memory' "$CBM_FILE" || log_fail "codebase-memory SKILL.md missing valid name"
[ -f "$REPO_ROOT/resources/skills/codebase-memory/references/memory-guide.md" ] || log_fail "Missing memory-guide.md"

CODEGRAPH_FILE="$REPO_ROOT/resources/skills/codegraph/SKILL.md"
[ -f "$CODEGRAPH_FILE" ] || log_fail "Missing $CODEGRAPH_FILE"
grep -Eiq '^name:[[:space:]]*codegraph' "$CODEGRAPH_FILE" || log_fail "codegraph SKILL.md missing valid name"
[ -f "$REPO_ROOT/resources/skills/codegraph/references/ast-workflow.md" ] || log_fail "Missing ast-workflow.md"

# Assert MCP servers registered in resources/gemini/mcp_config.json
grep -Fq '"codebase-memory"' "$REPO_ROOT/resources/gemini/mcp_config.json" || log_fail "mcp_config.json missing codebase-memory"
grep -Fq '"codegraph"' "$REPO_ROOT/resources/gemini/mcp_config.json" || log_fail "mcp_config.json missing codegraph"

# Assert global gitignore has .codegraph/
[ -f "$REPO_ROOT/resources/git/ignore" ] || log_fail "Missing resources/git/ignore"
grep -Fq ".codegraph/" "$REPO_ROOT/resources/git/ignore" || log_fail "resources/git/ignore missing .codegraph/"

# Assert Zsh CLI has cg function
grep -Fq "function cg()" "$REPO_ROOT/resources/zsh/.zshrc" || log_fail "resources/zsh/.zshrc missing cg() function"

# Assert Nix package exists
[ -f "$REPO_ROOT/pkgs/codebase-memory-mcp.nix" ] || log_fail "Missing pkgs/codebase-memory-mcp.nix"
grep -Fq "codebase-memory-mcp" "$REPO_ROOT/modules/packages.nix" || log_fail "modules/packages.nix missing codebase-memory-mcp"

# Assert OmniRoute cavemanEnabled is false by default
grep -Eiq '^OMNIROUTE_CAVEMAN_ENABLED="false"' "$REPO_ROOT/resources/ai/gateway.env" || log_fail "OMNIROUTE_CAVEMAN_ENABLED must be false"

# Assert metadata registry seeds and lockfile schema validity
[ -f "$REPO_ROOT/resources/skills/_sources.json" ] || log_fail "Missing _sources.json"
[ -f "$REPO_ROOT/resources/skills/_registry.json" ] || log_fail "Missing _registry.json"
[ -f "$REPO_ROOT/resources/skills/_profiles.json" ] || log_fail "Missing _profiles.json"
[ -f "$REPO_ROOT/resources/skills/_lock.schema.json" ] || log_fail "Missing _lock.schema.json"
jq empty "$REPO_ROOT/resources/skills/_sources.json" || log_fail "Invalid _sources.json JSON"
jq empty "$REPO_ROOT/resources/skills/_registry.json" || log_fail "Invalid _registry.json JSON"
jq empty "$REPO_ROOT/resources/skills/_profiles.json" || log_fail "Invalid _profiles.json JSON"
jq empty "$REPO_ROOT/resources/skills/_lock.schema.json" || log_fail "Invalid _lock.schema.json JSON"

# Assert agent adapter configuration and schema validity
[ -f "$REPO_ROOT/resources/skills/_agents.schema.json" ] || log_fail "Missing _agents.schema.json"
[ -f "$REPO_ROOT/resources/skills/_agents.json" ] || log_fail "Missing _agents.json"
jq empty "$REPO_ROOT/resources/skills/_agents.schema.json" || log_fail "Invalid _agents.schema.json JSON"
jq empty "$REPO_ROOT/resources/skills/_agents.json" || log_fail "Invalid _agents.json JSON"
jq -e '.agents["claude-code"]' "$REPO_ROOT/resources/skills/_agents.json" >/dev/null || log_fail "_agents.json missing claude-code"
jq -e '.agents["antigravity-cli"]' "$REPO_ROOT/resources/skills/_agents.json" >/dev/null || log_fail "_agents.json missing antigravity-cli"
jq -e '.agents["codex-cli"]' "$REPO_ROOT/resources/skills/_agents.json" >/dev/null || log_fail "_agents.json missing codex-cli"

# Assert agent library and path resolution
[ -f "$REPO_ROOT/scripts/lib/agents.sh" ] || log_fail "Missing scripts/lib/agents.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib/agents.sh"
CLAUDE_TEST_PATH="$(resolve_agent_global_path claude-code "/test/home")"
[ "$CLAUDE_TEST_PATH" = "/test/home/.claude/skills" ] || log_fail "resolve_agent_global_path failed for claude-code"
GEMINI_TEST_PATH="$(resolve_agent_global_path antigravity-cli "/test/home")"
[ "$GEMINI_TEST_PATH" = "/test/home/.gemini/config/skills" ] || log_fail "resolve_agent_global_path failed for antigravity-cli"

# Assert Claude Code package in packages.nix
grep -Fq "claudeCode" "$REPO_ROOT/modules/packages.nix" || log_fail "modules/packages.nix missing claudeCode"

log_ok "Ponytail, Junior, Release Notes, Caveman, RTK, Codebase Memory, CodeGraph, and Metadata Registries are valid"

# ------------------------------------------------------------------------------
# 1.1 Validate Layer 0 Core Guardrails
# ------------------------------------------------------------------------------
log_info "Validating Layer 0 Core Guardrails schema & token economy..."

GUARDRAIL_SKILLS=(
    "project-context"
    "source-quality"
    "architecture-guardrails"
    "system-design-guardrails"
    "security-guardrails"
    "quality-gate"
)

for g in "${GUARDRAIL_SKILLS[@]}"; do
    g_file="$REPO_ROOT/resources/skills/$g/SKILL.md"
    [ -f "$g_file" ] || log_fail "Missing guardrail skill: $g_file"

    # Frontmatter check
    head_line=$(head -n 1 "$g_file")
    [ "$head_line" = "---" ] || log_fail "$g/SKILL.md missing frontmatter start '---'"
    grep -Eiq "^name:[[:space:]]*$g" "$g_file" || log_fail "$g/SKILL.md missing valid name"
    grep -Eiq '^description:[[:space:]]*"?Internal guardrail' "$g_file" || log_fail "$g/SKILL.md description must start with 'Internal guardrail' to prevent auto-triggering"

    # Token economy audit: ensure concise, actionable rules (under 350 words)
    w_count=$(wc -w < "$g_file" | tr -d ' ')
    [ "$w_count" -le 350 ] || log_fail "$g/SKILL.md word count ($w_count) exceeds token economy limit (350 words)"

    # Registry integrity
    jq -e --arg g "$g" '.skills[$g]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $g"
done

# Invariant & rule content verification
grep -Fq "Strict Precedence Hierarchy" "$REPO_ROOT/resources/skills/project-context/SKILL.md" || log_fail "project-context missing precedence hierarchy"
grep -Fq "project convention > generic best practice" "$REPO_ROOT/resources/skills/project-context/SKILL.md" || log_fail "project-context missing precedence rule"
grep -Fq "Zero Duplication" "$REPO_ROOT/resources/skills/source-quality/SKILL.md" || log_fail "source-quality missing zero duplication"
grep -Fq "Unidirectional Dependency Flow" "$REPO_ROOT/resources/skills/architecture-guardrails/SKILL.md" || log_fail "architecture-guardrails missing dependency flow"
grep -Fq "Write Idempotency" "$REPO_ROOT/resources/skills/system-design-guardrails/SKILL.md" || log_fail "system-design-guardrails missing idempotency"
grep -Fq "Zero Hardcoded Secrets" "$REPO_ROOT/resources/skills/security-guardrails/SKILL.md" || log_fail "security-guardrails missing secrets rule"
grep -Fq "Mandatory 5-Step Verification Sequence" "$REPO_ROOT/resources/skills/quality-gate/SKILL.md" || log_fail "quality-gate missing verification sequence"

# Profile check
jq -e '.profiles["core-guardrails"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'core-guardrails' profile"
for g in "${GUARDRAIL_SKILLS[@]}"; do
    jq -e --arg g "$g" '.profiles["core-guardrails"].skills | index($g)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "core-guardrails profile missing $g"
done

log_ok "All 6 Layer 0 Core Guardrail skills verified (frontmatter, token economy, content & registry)"

# ------------------------------------------------------------------------------
# 1.2 Validate Layer 1 Senior Leadership Skills
# ------------------------------------------------------------------------------
log_info "Validating Layer 1 Senior Leadership skills & trigger boundaries..."

LEADERSHIP_SKILLS=(
    "feature-spec-writer"
    "technical-planner"
    "skill-author"
)

for l in "${LEADERSHIP_SKILLS[@]}"; do
    l_file="$REPO_ROOT/resources/skills/$l/SKILL.md"
    [ -f "$l_file" ] || log_fail "Missing leadership skill: $l_file"

    # Frontmatter check
    head_line=$(head -n 1 "$l_file")
    [ "$head_line" = "---" ] || log_fail "$l/SKILL.md missing frontmatter start '---'"
    grep -Eiq "^name:[[:space:]]*$l" "$l_file" || log_fail "$l/SKILL.md missing valid name"
    grep -Eiq '^description:' "$l_file" || log_fail "$l/SKILL.md missing description"

    # Registry integrity
    jq -e --arg l "$l" '.skills[$l]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $l"
done

# Check templates
[ -f "$REPO_ROOT/resources/skills/feature-spec-writer/references/spec-template.md" ] || log_fail "Missing spec-template.md"
[ -f "$REPO_ROOT/resources/skills/technical-planner/references/plan-template.md" ] || log_fail "Missing plan-template.md"

# Behavioral Invariant Check: technical-planner must forbid writing code / modifying files
grep -Fq "STRICTLY ANALYTICAL ROLE" "$REPO_ROOT/resources/skills/technical-planner/SKILL.md" || log_fail "technical-planner missing STRICTLY ANALYTICAL ROLE"
grep -Fq "MUST NOT write or edit project source code" "$REPO_ROOT/resources/skills/technical-planner/SKILL.md" || log_fail "technical-planner missing code edit prohibition"

# Question Policy Check: feature-spec-writer must have strict question policy
grep -Fq "Strict Question Policy" "$REPO_ROOT/resources/skills/feature-spec-writer/SKILL.md" || log_fail "feature-spec-writer missing Strict Question Policy"
grep -Fq "Proposal" "$REPO_ROOT/resources/skills/feature-spec-writer/SKILL.md" || log_fail "feature-spec-writer missing proposal default convention"

# Trigger Boundary Disambiguation Tests
SPEC_DESC=$(jq -r '.skills["feature-spec-writer"].description' "$REPO_ROOT/resources/skills/_registry.json")
PLAN_DESC=$(jq -r '.skills["technical-planner"].description' "$REPO_ROOT/resources/skills/_registry.json")

# Input 1: "Write a specification for user authentication."
echo "$SPEC_DESC" | grep -Eiq "spec|specification" || log_fail "feature-spec-writer description fails to match specification request"
echo "$PLAN_DESC" | grep -Eiq "^(Write a specification|specifications)" && log_fail "technical-planner description collided with specification request"

# Input 2: "Create implementation plan from docs/specs/auth.md."
echo "$PLAN_DESC" | grep -Eiq "plan|implementation plan" || log_fail "technical-planner description fails to match planning request"

# Profile check
jq -e '.profiles["senior-leadership"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'senior-leadership' profile"
for l in "${LEADERSHIP_SKILLS[@]}"; do
    jq -e --arg l "$l" '.profiles["senior-leadership"].skills | index($l)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "senior-leadership profile missing $l"
done

log_ok "All 3 Layer 1 Senior Leadership skills verified (templates, invariants, trigger boundaries & registry)"

# ------------------------------------------------------------------------------
# 1.3 Validate Layer 1 Architecture & Systems Design Skills
# ------------------------------------------------------------------------------
log_info "Validating Layer 1 Architecture & Systems Design skills..."

ARCH_DESIGN_SKILLS=(
    "architecture-designer"
    "data-model-architect"
    "api-contract-designer"
    "test-strategist"
)

for a in "${ARCH_DESIGN_SKILLS[@]}"; do
    a_file="$REPO_ROOT/resources/skills/$a/SKILL.md"
    [ -f "$a_file" ] || log_fail "Missing architecture/design skill: $a_file"

    # Frontmatter check
    head_line=$(head -n 1 "$a_file")
    [ "$head_line" = "---" ] || log_fail "$a/SKILL.md missing frontmatter start '---'"
    grep -Eiq "^name:[[:space:]]*$a" "$a_file" || log_fail "$a/SKILL.md missing valid name"
    grep -Eiq '^description:' "$a_file" || log_fail "$a/SKILL.md missing description"

    # Registry integrity
    jq -e --arg a "$a" '.skills[$a]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $a"
done

# Check reference templates
[ -f "$REPO_ROOT/resources/skills/architecture-designer/references/adr-template.md" ] || log_fail "Missing adr-template.md"
[ -f "$REPO_ROOT/resources/skills/data-model-architect/references/schema-checklist.md" ] || log_fail "Missing schema-checklist.md"
[ -f "$REPO_ROOT/resources/skills/api-contract-designer/references/api-standards.md" ] || log_fail "Missing api-standards.md"
[ -f "$REPO_ROOT/resources/skills/test-strategist/references/test-matrix-template.md" ] || log_fail "Missing test-matrix-template.md"

# Invariant checks
grep -Fq "Modular Monolith First" "$REPO_ROOT/resources/skills/architecture-designer/SKILL.md" || log_fail "architecture-designer missing Modular Monolith First rule"
grep -Fq "docs/architecture/adr" "$REPO_ROOT/resources/skills/architecture-designer/SKILL.md" || log_fail "architecture-designer missing ADR path"
grep -Fq "Expand-Contract" "$REPO_ROOT/resources/skills/data-model-architect/SKILL.md" || log_fail "data-model-architect missing Expand-Contract rule"
grep -Fq "Idempotency-Key" "$REPO_ROOT/resources/skills/api-contract-designer/SKILL.md" || log_fail "api-contract-designer missing Idempotency-Key rule"
grep -Fq "Strict Test Pyramid Distribution" "$REPO_ROOT/resources/skills/test-strategist/SKILL.md" || log_fail "test-strategist missing Test Pyramid rule"

# Trigger Boundary Fixtures
SCHEMA_DESC=$(jq -r '.skills["data-model-architect"].description' "$REPO_ROOT/resources/skills/_registry.json")
API_DESC=$(jq -r '.skills["api-contract-designer"].description' "$REPO_ROOT/resources/skills/_registry.json")

# Input: "Design database schema and migration strategy for billing subscriptions." -> triggers data-model-architect
echo "$SCHEMA_DESC" | grep -Eiq "schema|database" || log_fail "data-model-architect description fails to match database schema query"

# Input: "Define REST API contract and error format for payment webhooks." -> triggers api-contract-designer
echo "$API_DESC" | grep -Eiq "api|contract" || log_fail "api-contract-designer description fails to match API contract query"

# Profile check
jq -e '.profiles["architecture-design"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'architecture-design' profile"
for a in "${ARCH_DESIGN_SKILLS[@]}"; do
    jq -e --arg a "$a" '.profiles["architecture-design"].skills | index($a)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "architecture-design profile missing $a"
done

log_ok "All 4 Layer 1 Architecture & Systems Design skills verified (templates, invariants, trigger boundaries & registry)"

# ------------------------------------------------------------------------------
# 1.4 Validate Layer 2 Implementation Engine Skills
# ------------------------------------------------------------------------------
log_info "Validating Layer 2 Implementation Engine skills & deprecation mapping..."

L2_SKILLS=(
    "senior-implementer"
    "pixel-perfect-ui"
)

for l2 in "${L2_SKILLS[@]}"; do
    l2_file="$REPO_ROOT/resources/skills/$l2/SKILL.md"
    [ -f "$l2_file" ] || log_fail "Missing layer 2 skill: $l2_file"

    # Frontmatter check
    head_line=$(head -n 1 "$l2_file")
    [ "$head_line" = "---" ] || log_fail "$l2/SKILL.md missing frontmatter start '---'"
    grep -Eiq "^name:[[:space:]]*$l2" "$l2_file" || log_fail "$l2/SKILL.md missing valid name"
    grep -Eiq '^description:' "$l2_file" || log_fail "$l2/SKILL.md missing description"

    # Registry integrity
    jq -e --arg s "$l2" '.skills[$s]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $l2"
done

# Check reference templates
[ -f "$REPO_ROOT/resources/skills/senior-implementer/references/implementation-checklist.md" ] || log_fail "Missing implementation-checklist.md"
[ -f "$REPO_ROOT/resources/skills/pixel-perfect-ui/references/ui-states-checklist.md" ] || log_fail "Missing ui-states-checklist.md"

# Deprecation verification for junior-coding-agent
grep -Fq "DEPRECATED" "$REPO_ROOT/resources/skills/junior-coding-agent/SKILL.md" || log_fail "junior-coding-agent missing DEPRECATED warning"
grep -Fq "senior-implementer" "$REPO_ROOT/resources/skills/junior-coding-agent/SKILL.md" || log_fail "junior-coding-agent missing pointer to senior-implementer"
jq -r '.skills["junior-coding-agent"].description' "$REPO_ROOT/resources/skills/_registry.json" | grep -Fq "DEPRECATED" || log_fail "_registry.json junior-coding-agent missing DEPRECATED tag"

# Toolchain integration invariants in senior-implementer
grep -Fq "Codebase Memory & CodeGraph" "$REPO_ROOT/resources/skills/senior-implementer/SKILL.md" || log_fail "senior-implementer missing CodeGraph/Codebase Memory rule"
grep -Fq "RTK (Rust Token Killer)" "$REPO_ROOT/resources/skills/senior-implementer/SKILL.md" || log_fail "senior-implementer missing RTK rule"
grep -Fq "Ponytail Minimalism" "$REPO_ROOT/resources/skills/senior-implementer/SKILL.md" || log_fail "senior-implementer missing Ponytail rule"
grep -Fq "quality-gate" "$REPO_ROOT/resources/skills/senior-implementer/SKILL.md" || log_fail "senior-implementer missing quality-gate rule"

# Invariants in pixel-perfect-ui
grep -Fq "Design System & Token Fidelity" "$REPO_ROOT/resources/skills/pixel-perfect-ui/SKILL.md" || log_fail "pixel-perfect-ui missing token fidelity rule"
grep -Fq "Exhaustive UI State Coverage" "$REPO_ROOT/resources/skills/pixel-perfect-ui/SKILL.md" || log_fail "pixel-perfect-ui missing UI state coverage rule"

# Trigger Boundary Fixtures
IMPL_DESC=$(jq -r '.skills["senior-implementer"].description' "$REPO_ROOT/resources/skills/_registry.json")
PLAN_DESC=$(jq -r '.skills["technical-planner"].description' "$REPO_ROOT/resources/skills/_registry.json")
UI_DESC=$(jq -r '.skills["pixel-perfect-ui"].description' "$REPO_ROOT/resources/skills/_registry.json")

# Input: "Implement docs/plans/auth.md according to the plan." -> triggers senior-implementer, NOT technical-planner
echo "$IMPL_DESC" | grep -Eiq "implement|execut" || log_fail "senior-implementer description fails to match implementation query"
echo "$PLAN_DESC" | grep -Eiq "^(Implement docs/plans|implementation engineer)" && log_fail "technical-planner description falsely matched implementation query"

# Input: "Build this card component from the Figma screenshot." -> triggers pixel-perfect-ui
echo "$UI_DESC" | grep -Eiq "ui|component" || log_fail "pixel-perfect-ui description fails to match UI component query"

# Profile check
jq -e '.profiles["implementation"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'implementation' profile"
jq -e '.profiles["core"].skills | index("senior-implementer")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "core profile missing senior-implementer"
jq -e '.profiles["frontend"].skills | index("pixel-perfect-ui")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "frontend profile missing pixel-perfect-ui"

log_ok "All Layer 2 Implementation Engine skills verified (templates, invariants, deprecation & registry)"

# ------------------------------------------------------------------------------
# 1.5 Validate Layer 1 Operations & Verification Skills
# ------------------------------------------------------------------------------
log_info "Validating Layer 1 Operations & Verification skills..."

OPS_SKILLS=(
    "engineering-review"
    "incident-investigator"
    "reliability-engineer"
    "migration-strategist"
    "technical-researcher"
)

for o in "${OPS_SKILLS[@]}"; do
    o_file="$REPO_ROOT/resources/skills/$o/SKILL.md"
    [ -f "$o_file" ] || log_fail "Missing operations skill: $o_file"

    # Frontmatter check
    head_line=$(head -n 1 "$o_file")
    [ "$head_line" = "---" ] || log_fail "$o/SKILL.md missing frontmatter start '---'"
    grep -Eiq "^name:[[:space:]]*$o" "$o_file" || log_fail "$o/SKILL.md missing valid name"
    grep -Eiq '^description:' "$o_file" || log_fail "$o/SKILL.md missing description"

    # Registry integrity
    jq -e --arg s "$o" '.skills[$s]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $o"
done

# Check reference templates
[ -f "$REPO_ROOT/resources/skills/engineering-review/references/review-checklist.md" ] || log_fail "Missing review-checklist.md"
[ -f "$REPO_ROOT/resources/skills/incident-investigator/references/postmortem-template.md" ] || log_fail "Missing postmortem-template.md"
[ -f "$REPO_ROOT/resources/skills/reliability-engineer/references/resilience-patterns.md" ] || log_fail "Missing resilience-patterns.md"
[ -f "$REPO_ROOT/resources/skills/migration-strategist/references/migration-plan-template.md" ] || log_fail "Missing migration-plan-template.md"
[ -f "$REPO_ROOT/resources/skills/technical-researcher/references/evaluation-matrix.md" ] || log_fail "Missing evaluation-matrix.md"

# Invariant checks
grep -Fq "BLOCKER" "$REPO_ROOT/resources/skills/engineering-review/SKILL.md" || log_fail "engineering-review missing BLOCKER classification"
grep -Fq "5 Whys" "$REPO_ROOT/resources/skills/incident-investigator/SKILL.md" || log_fail "incident-investigator missing 5 Whys rule"
grep -Fq "Exponential Backoff with Full Jitter" "$REPO_ROOT/resources/skills/reliability-engineer/SKILL.md" || log_fail "reliability-engineer missing jitter rule"
grep -Fq "Mandatory Expand-Contract Pattern" "$REPO_ROOT/resources/skills/migration-strategist/SKILL.md" || log_fail "migration-strategist missing Expand-Contract rule"
grep -Fq "Objective, Bias-Free Evaluation" "$REPO_ROOT/resources/skills/technical-researcher/SKILL.md" || log_fail "technical-researcher missing bias-free rule"

# Trigger Boundary Fixtures
REV_DESC=$(jq -r '.skills["engineering-review"].description' "$REPO_ROOT/resources/skills/_registry.json")
INC_DESC=$(jq -r '.skills["incident-investigator"].description' "$REPO_ROOT/resources/skills/_registry.json")

# Input: "Review PR 42 against the auth specification." -> triggers engineering-review
echo "$REV_DESC" | grep -Eiq "review|pull request" || log_fail "engineering-review description fails to match PR review query"

# Input: "Production API is throwing 500 errors on checkout, investigate immediately." -> triggers incident-investigator
echo "$INC_DESC" | grep -Eiq "incident|triage|outage" || log_fail "incident-investigator description fails to match incident query"

# Profile check
jq -e '.profiles["senior-operations"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'senior-operations' profile"
for o in "${OPS_SKILLS[@]}"; do
    jq -e --arg o "$o" '.profiles["senior-operations"].skills | index($o)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "senior-operations profile missing $o"
done

log_ok "All 5 Layer 1 Operations & Verification skills verified (templates, invariants, trigger boundaries & registry)"

# ------------------------------------------------------------------------------
# 1.6 Validate Layer 4 Artifact & Diagram Authoring Skills
# ------------------------------------------------------------------------------
log_info "Validating Layer 4 Artifact & Diagram Authoring skills..."

DIAGRAM_SKILL="diagram-author"
d_file="$REPO_ROOT/resources/skills/$DIAGRAM_SKILL/SKILL.md"
[ -f "$d_file" ] || log_fail "Missing diagram skill: $d_file"

# Frontmatter check
head_line=$(head -n 1 "$d_file")
[ "$head_line" = "---" ] || log_fail "$DIAGRAM_SKILL/SKILL.md missing frontmatter start '---'"
grep -Eiq "^name:[[:space:]]*$DIAGRAM_SKILL" "$d_file" || log_fail "$DIAGRAM_SKILL/SKILL.md missing valid name"
grep -Eiq '^description:' "$d_file" || log_fail "$DIAGRAM_SKILL/SKILL.md missing description"

# Registry integrity
jq -e --arg s "$DIAGRAM_SKILL" '.skills[$s]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $DIAGRAM_SKILL"

# Reference guides
[ -f "$REPO_ROOT/resources/skills/diagram-author/references/dbml-guide.md" ] || log_fail "Missing dbml-guide.md"
[ -f "$REPO_ROOT/resources/skills/diagram-author/references/mermaid-guide.md" ] || log_fail "Missing mermaid-guide.md"
[ -f "$REPO_ROOT/resources/skills/diagram-author/references/plantuml-guide.md" ] || log_fail "Missing plantuml-guide.md"
[ -f "$REPO_ROOT/resources/skills/diagram-author/references/drawio-guide.md" ] || log_fail "Missing drawio-guide.md"

# Invariants & format coverage
grep -Fq "Mermaid.js" "$REPO_ROOT/resources/skills/diagram-author/SKILL.md" || log_fail "diagram-author missing Mermaid rule"
grep -Fq "DBML" "$REPO_ROOT/resources/skills/diagram-author/SKILL.md" || log_fail "diagram-author missing DBML rule"
grep -Fq "PlantUML" "$REPO_ROOT/resources/skills/diagram-author/SKILL.md" || log_fail "diagram-author missing PlantUML rule"
grep -Fq "draw.io XML" "$REPO_ROOT/resources/skills/diagram-author/SKILL.md" || log_fail "diagram-author missing draw.io rule"

# Trigger Boundary Fixture
DIAG_DESC=$(jq -r '.skills["diagram-author"].description' "$REPO_ROOT/resources/skills/_registry.json")
echo "$DIAG_DESC" | grep -Eiq "diagram|visual|mermaid|dbml" || log_fail "diagram-author description fails to match diagramming query"

# Profile check
jq -e '.profiles["artifacts"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'artifacts' profile"
jq -e '.profiles["artifacts"].skills | index("diagram-author")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "artifacts profile missing diagram-author"

log_ok "Layer 4 Artifact & Diagram Authoring skills verified (templates, invariants, trigger boundaries & registry)"

# ------------------------------------------------------------------------------
# 1.7 Validate Layer 3 Domain Skills Curation & Semantic Dedup
# ------------------------------------------------------------------------------
log_info "Validating Layer 3 Domain Skills Curation & Semantic Dedup..."

CURATE_LIB="$REPO_ROOT/scripts/lib/curate.sh"
[ -f "$CURATE_LIB" ] || log_fail "Missing scripts/lib/curate.sh"
[ -x "$CURATE_LIB" ] || log_fail "scripts/lib/curate.sh is not executable"

# Run security audit on all skills
"$CURATE_LIB" audit "$REPO_ROOT/resources/skills" || log_fail "curate.sh audit failed on resources/skills"

# Run semantic deduplication check
"$CURATE_LIB" dedup "$REPO_ROOT/resources/skills/_registry.json" || log_fail "curate.sh dedup detected registry collisions"

DOMAIN_SKILLS=(
    "nestjs"
    "centrifugo"
    "bullmq"
    "postgresql"
    "redis"
    "vps-hardening"
    "docker"
    "cloud-infra"
    "nixos"
    "neovim-lua"
    "rust"
    "chrome-extension"
)

for d in "${DOMAIN_SKILLS[@]}"; do
    d_file="$REPO_ROOT/resources/skills/$d/SKILL.md"
    [ -f "$d_file" ] || log_fail "Missing domain skill: $d_file"

    # Frontmatter check
    head_line=$(head -n 1 "$d_file")
    [ "$head_line" = "---" ] || log_fail "$d/SKILL.md missing frontmatter start '---'"
    grep -Eiq "^name:[[:space:]]*$d" "$d_file" || log_fail "$d/SKILL.md missing valid name"
    grep -Eiq '^description:' "$d_file" || log_fail "$d/SKILL.md missing description"

    # Registry integrity
    jq -e --arg s "$d" '.skills[$s]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "_registry.json missing entry for $d"
done

# Profile memberships
for s in nestjs centrifugo bullmq postgresql redis; do
    jq -e --arg s "$s" '.profiles["backend"].skills | index($s)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "backend profile missing $s"
done

for s in vps-hardening docker cloud-infra; do
    jq -e --arg s "$s" '.profiles["devops"].skills | index($s)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "devops profile missing $s"
done

jq -e '.profiles["frontend"].skills | index("chrome-extension")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "frontend profile missing chrome-extension"

jq -e '.profiles["nixos"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'nixos' profile"
jq -e '.profiles["nixos"].skills | index("nixos")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "nixos profile missing nixos"
jq -e '.profiles["nixos"].skills | index("neovim-lua")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "nixos profile missing neovim-lua"

jq -e '.profiles["rust"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing 'rust' profile"
jq -e '.profiles["rust"].skills | index("rust")' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "rust profile missing rust"

log_ok "All 12 Layer 3 Domain Skills verified (security audit, dedup, frontmatter, registry & profiles)"

# ------------------------------------------------------------------------------
# 1.8 Validate Trigger Boundary Fixtures
# ------------------------------------------------------------------------------
log_info "Validating Trigger Boundary Fixtures from JSON..."

FIXTURE_FILE="$REPO_ROOT/tests/ai/fixtures/trigger_boundaries.json"
[ -f "$FIXTURE_FILE" ] || log_fail "Missing $FIXTURE_FILE"
jq empty "$FIXTURE_FILE" || log_fail "Invalid JSON in trigger_boundaries.json"

fixture_count=$(jq '. | length' "$FIXTURE_FILE")
# shellcheck disable=SC2016
ROUTING_TEST_RESULT=$(node -e '
const fs = require("fs");
const reg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const fixtures = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));

function routeSkill(input, skills) {
  const normInput = input.toLowerCase();
  let bestSkill = null;
  let bestScore = -1;

  for (const [name, skill] of Object.entries(skills)) {
    if (skill.status === "deprecated") continue;
    let score = 0;
    
    for (const t of (skill.triggers || [])) {
      const tNorm = t.toLowerCase().replace(/-/g, " ");
      if (normInput.includes(tNorm) || normInput.includes(t.toLowerCase())) {
        score += 10;
      } else {
        const words = t.toLowerCase().split("-");
        if (words.length > 1 && words.every(w => normInput.includes(w))) {
          score += 8;
        } else {
          score += words.filter(w => w.length > 3 && normInput.includes(w)).length * 2;
        }
      }
    }

    for (const c of (skill.capabilities || [])) {
      const cNorm = c.toLowerCase().replace(/-/g, " ");
      if (normInput.includes(cNorm) || normInput.includes(c.toLowerCase())) {
        score += 5;
      } else {
        const words = c.toLowerCase().split("-");
        if (words.length > 1 && words.every(w => normInput.includes(w))) {
          score += 4;
        }
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestSkill = name;
    }
  }
  return { bestSkill, bestScore };
}

let failed = 0;
for (const f of fixtures) {
  const { bestSkill } = routeSkill(f.input, reg.skills);
  const isExpected = (bestSkill === f.expected_skill);
  const isForbidden = (f.forbidden_skills || []).includes(bestSkill);
  if (!isExpected || isForbidden) {
    console.error(`Route mismatch for "${f.input}": got ${bestSkill}, expected ${f.expected_skill}`);
    failed++;
  }
}
process.exit(failed > 0 ? 1 : 0);
' "$REPO_ROOT/resources/skills/_registry.json" "$FIXTURE_FILE" 2>&1) || log_fail "Trigger boundary behavioral routing failed: $ROUTING_TEST_RESULT"

log_ok "All $fixture_count trigger boundary fixtures verified via metadata routing heuristic (does not prove actual model runtime behavior)"








# ------------------------------------------------------------------------------
# 2. Test ai-skills.sh CLI in Sandbox
# ------------------------------------------------------------------------------
log_info "Testing ai-skills.sh CLI in isolated sandbox..."

AI_SKILLS_BIN="$REPO_ROOT/scripts/ai-skills.sh"
[ -x "$AI_SKILLS_BIN" ] || log_fail "ai-skills.sh is not executable"

# Test 2.1: list command
LIST_OUTPUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" list)
echo "$LIST_OUTPUT" | grep -Fq "ponytail" || log_fail "list command did not include 'ponytail'"
# Ensure metadata files prefixed with _ are never listed as skills
echo "$LIST_OUTPUT" | grep -Eq '^[[:space:]]*_[a-zA-Z0-9]+' && log_fail "list command included metadata file prefixed with _"
log_ok "ai-skills.sh list outputs available skills and filters metadata files"

# Test 2.2: preview command
PREVIEW_OUTPUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" preview ponytail)
echo "$PREVIEW_OUTPUT" | grep -Fq "name: ponytail" || log_fail "preview command did not display skill content"
log_ok "ai-skills.sh preview works"

# Test 2.3: add command (global symlinks for gemini, codex, claude)
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target gemini >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "Failed to link ponytail to gemini"
[ -f "$MOCK_HOME/.gemini/config/skills/ponytail/SKILL.md" ] || log_fail "Linked skill file not accessible"

HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target codex >/dev/null
[ -L "$MOCK_HOME/.agents/skills/ponytail" ] || log_fail "Failed to link ponytail to codex primary path (~/.agents/skills)"
[ -L "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "Failed to link ponytail to codex compatibility path (~/.codex/skills)"

HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --global claude >/dev/null
[ -L "$MOCK_HOME/.claude/skills/ponytail" ] || log_fail "Failed to link ponytail to claude via --global"

# Test 2.4: add command (project target: physical copy + lockfile)
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --project >/dev/null)
[ ! -L "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail "Project skill must NOT be a symlink (invariant violation)"
[ -d "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail "Project skill directory missing"
[ -f "$MOCK_PROJECT/.agents/skills/ponytail/SKILL.md" ] || log_fail "Project skill SKILL.md missing"
[ -f "$MOCK_PROJECT/.agents/skills/ponytail/references/code-filter.md" ] || log_fail "Project skill references/ not copied intact"

# Assert lockfile generation
[ -f "$MOCK_PROJECT/.agent-skills.lock.json" ] || log_fail "Missing .agent-skills.lock.json"
jq empty "$MOCK_PROJECT/.agent-skills.lock.json" || log_fail "Invalid lockfile JSON"
jq -e '.skills["ponytail"]' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null || log_fail "Lockfile missing ponytail entry"
jq -e '.skills["ponytail"].content_hash' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null || log_fail "Lockfile missing content_hash"
log_ok "ai-skills.sh add enforces global=symlink, project=physical copy and writes lockfile"

# Test 2.5: export command
EXPORT_OUTPUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" export ponytail)
echo "$EXPORT_OUTPUT" | grep -Fq "Ponytail Anti-Overengineering Rule Snippet" || log_fail "export failed"
log_ok "ai-skills.sh export produces markdown snippet"

# Test 2.6: remove command (global and project)
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove ponytail --target gemini >/dev/null
[ ! -e "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "remove command failed to unlink gemini target"

HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove ponytail --target claude >/dev/null
[ ! -e "$MOCK_HOME/.claude/skills/ponytail" ] || log_fail "remove command failed to unlink claude target"

HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove ponytail --target all >/dev/null
[ ! -e "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "remove command failed to unlink codex target"

# Remove project skill and check lockfile update
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove ponytail --project >/dev/null)
[ ! -e "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail "remove command failed to remove project skill directory"
jq -e '.skills["ponytail"]' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null && log_fail "Lockfile still has ponytail after removal"
log_ok "ai-skills.sh remove cleans global targets and project directories with lockfile update"

# Test 2.7: sync command (default: global-core profile)
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" sync >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "sync command failed to link gemini ponytail"
[ -L "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "sync command failed to link codex ponytail"
[ -L "$MOCK_HOME/.claude/skills/ponytail" ] || log_fail "sync command failed to link claude ponytail"
[ -L "$MOCK_HOME/.gemini/config/skills/senior-implementer" ] || log_fail "sync command failed to link gemini senior-implementer"
[ -L "$MOCK_HOME/.gemini/config/skills/caveman" ] || log_fail "sync command failed to link gemini caveman"
[ -L "$MOCK_HOME/.codex/skills/caveman" ] || log_fail "sync command failed to link codex caveman"
[ -L "$MOCK_HOME/.claude/skills/caveman" ] || log_fail "sync command failed to link claude caveman"
[ -L "$MOCK_HOME/.gemini/config/skills/rtk" ] || log_fail "sync command failed to link gemini rtk"
[ -L "$MOCK_HOME/.codex/skills/rtk" ] || log_fail "sync command failed to link codex rtk"
[ -L "$MOCK_HOME/.claude/skills/rtk" ] || log_fail "sync command failed to link claude rtk"
# Verify junior-coding-agent is NOT linked in default global-core sync
[ ! -e "$MOCK_HOME/.gemini/config/skills/junior-coding-agent" ] || log_fail "default sync should not install deprecated junior-coding-agent"

# Test 2.7b: sync --all-canonical links entire registry
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" sync --all-canonical >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/release-notes" ] || log_fail "sync --all-canonical failed to link release-notes"
[ -L "$MOCK_HOME/.codex/skills/release-notes" ] || log_fail "sync --all-canonical failed to link codex release-notes"
[ -L "$MOCK_HOME/.claude/skills/release-notes" ] || log_fail "sync --all-canonical failed to link claude release-notes"
log_ok "ai-skills.sh sync synchronizes global-core by default and supports --all-canonical"

# Test 2.8: Batch selection & collision deduplication
log_info "Testing batch skill installation and path deduplication..."
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail caveman junior-coding-agent --global all >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/caveman" ] || log_fail "Batch add failed for gemini caveman"
[ -L "$MOCK_HOME/.claude/skills/junior-coding-agent" ] || log_fail "Batch add failed for claude junior-coding-agent"

# Project batch installation
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail caveman --project >/dev/null)
[ -d "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail "Batch project copy failed for ponytail"
[ -d "$MOCK_PROJECT/.agents/skills/caveman" ] || log_fail "Batch project copy failed for caveman"
jq -e '.skills["ponytail"]' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null || log_fail "Batch add missing ponytail in lockfile"
jq -e '.skills["caveman"]' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null || log_fail "Batch add missing caveman in lockfile"

# Test path collision deduplication engine
DEDUP_PROJECT_PATHS=$(resolve_target_paths "project" "$MOCK_PROJECT" antigravity-cli antigravity-ide)
DEDUP_COUNT=$(echo "$DEDUP_PROJECT_PATHS" | wc -l | tr -d ' ')
[ "$DEDUP_COUNT" -eq 1 ] || log_fail "Path deduplication failed to collapse duplicate project paths: $DEDUP_PROJECT_PATHS"
[ "$DEDUP_PROJECT_PATHS" = "$MOCK_PROJECT/.agents/skills" ] || log_fail "Path deduplication returned unexpected path: $DEDUP_PROJECT_PATHS"
log_ok "Batch installation and path deduplication engine passed"

# Test 2.9: diff and update commands
log_info "Testing diff and update drift management..."
# Clean project copy has diff 0
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" diff ponytail >/dev/null) || log_fail "Prinstine skill reported diff"

# Inject drift into project skill
echo "# Local modification for drift test" >> "$MOCK_PROJECT/.agents/skills/ponytail/SKILL.md"
if (cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" diff ponytail >/dev/null); then
    log_fail "diff failed to detect local modifications (expected non-zero exit)"
fi

# Run update with force to refresh
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" update ponytail --force >/dev/null) || log_fail "update --force failed"
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" diff ponytail >/dev/null) || log_fail "Skill still has diff after update"
grep -Fq "Local modification for drift test" "$MOCK_PROJECT/.agents/skills/ponytail/SKILL.md" && log_fail "Local modification persisted after update"
log_ok "ai-skills.sh diff and update detect drift and refresh lockfile"

# Test 2.10: doctor command and broken symlink detection
log_info "Testing doctor diagnostic subsystem..."
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" doctor >/dev/null) || log_fail "doctor reported errors on healthy system"

# Inject broken symlink in test home
ln -s "/nonexistent/test/path/broken-skill" "$MOCK_HOME/.gemini/config/skills/broken-test-skill"
if (cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" doctor >/dev/null); then
    log_fail "doctor failed to report error on broken symlink"
fi
rm -f "$MOCK_HOME/.gemini/config/skills/broken-test-skill"
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" doctor >/dev/null) || log_fail "doctor failed after removing broken link"
log_ok "ai-skills.sh doctor catches broken symlinks and verifies system integrity"

# Test 2.11: Unmanaged target protection for safe_link
log_info "Testing unmanaged target protection in safe_link..."
mkdir -p "$MOCK_HOME/.gemini/config/skills"
rm -rf "$MOCK_HOME/.gemini/config/skills/ponytail"
echo "unmanaged local content" > "$MOCK_HOME/.gemini/config/skills/ponytail"
# Attempt to link ponytail over unmanaged file without --replace must fail
if HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target gemini >/dev/null 2>&1; then
    log_fail "safe_link silently overwrote unmanaged file without --replace"
fi
[ -f "$MOCK_HOME/.gemini/config/skills/ponytail" ] && [ ! -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "Unmanaged file was replaced prematurely"
grep -Fq "unmanaged local content" "$MOCK_HOME/.gemini/config/skills/ponytail" || log_fail "Unmanaged file content was modified"

# With --replace, it must succeed and convert to symlink
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target gemini --replace >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "safe_link failed to replace unmanaged file when --replace was passed"
log_ok "safe_link protects unmanaged targets and mutates only with explicit --replace flag"

# Test 2.12: Unmanaged directory protection for project install
log_info "Testing unmanaged directory protection in install_project..."
mkdir -p "$MOCK_PROJECT/.agents/skills/docker"
echo "manual docker configuration" > "$MOCK_PROJECT/.agents/skills/docker/SKILL.md"
# docker exists on disk but is not recorded in .agent-skills.lock.json
if (cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add docker --project >/dev/null 2>&1); then
    log_fail "install_project silently overwrote unmanaged directory without --force"
fi
grep -Fq "manual docker configuration" "$MOCK_PROJECT/.agents/skills/docker/SKILL.md" || log_fail "Unmanaged directory was modified without --force"

# With --force, it must succeed and copy canonical docker skill
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add docker --project --force >/dev/null)
[ -f "$MOCK_PROJECT/.agents/skills/docker/SKILL.md" ] || log_fail "docker SKILL.md missing after forced install"
grep -Fq "Docker containerization" "$MOCK_PROJECT/.agents/skills/docker/SKILL.md" || log_fail "docker skill not updated with canonical content"
jq -e '.skills["docker"]' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null || log_fail "Lockfile missing docker entry after forced install"
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove docker --project >/dev/null)
log_ok "install_project protects unmanaged directories and overwrites only with explicit --force flag"

# Test 2.13: Path-prefix confinement escape test
log_info "Testing path-prefix confinement escape security..."
FAKE_ESCAPE_DIR="${MOCK_PROJECT}-sibling"
mkdir -p "$FAKE_ESCAPE_DIR"
# Direct invocation of assert_path_inside_project with sibling directory
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/ai-skills.sh"
if assert_path_inside_project "$FAKE_ESCAPE_DIR/.agents/skills/ponytail" "$MOCK_PROJECT" >/dev/null 2>&1; then
    log_fail "assert_path_inside_project allowed prefix escape to sibling path: $FAKE_ESCAPE_DIR"
fi
rm -rf "$FAKE_ESCAPE_DIR"
log_ok "assert_path_inside_project strictly rejects sibling prefix escape attempts"

# Test 2.14: Multi-agent project resolution test
log_info "Testing multi-agent project resolution engine..."
rm -rf "$MOCK_PROJECT/.agents/skills" "$MOCK_PROJECT/.claude/skills" "$MOCK_PROJECT/.agent-skills.lock.json"
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --project >/dev/null)
[ -d "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail "Missing .agents/skills/ponytail"
[ -d "$MOCK_PROJECT/.claude/skills/ponytail" ] || log_fail "Missing .claude/skills/ponytail"
[ ! -L "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail ".agents/skills/ponytail must not be symlink"
[ ! -L "$MOCK_PROJECT/.claude/skills/ponytail" ] || log_fail ".claude/skills/ponytail must not be symlink"
jq -e '.skills["ponytail"]' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null || log_fail "Lockfile missing ponytail"
log_ok "ai-skills.sh add --project installs to both .agents/skills and .claude/skills"

# Test 2.15: External import overwrite protection
log_info "Testing external import overwrite protection..."
MOCK_IMPORT_DIR="$SANDBOX_DIR/external-import-skill"
mkdir -p "$MOCK_IMPORT_DIR"
cat << 'EOF' > "$MOCK_IMPORT_DIR/SKILL.md"
---
name: ponytail
description: Duplicate external ponytail attempt
---
# Duplicate
EOF
if HOME="$MOCK_HOME" "$AI_SKILLS_BIN" import "$MOCK_IMPORT_DIR" ponytail >/dev/null 2>&1; then
    log_fail "import silently overwrote canonical skill 'ponytail' without --force"
fi
grep -Fq "Ponytail / Lazy Senior Developer" "$REPO_ROOT/resources/skills/ponytail/SKILL.md" || log_fail "Canonical ponytail was modified"
rm -rf "$MOCK_IMPORT_DIR"
log_ok "ai-skills.sh import rejects overwriting canonical skills without explicit --force"

# ------------------------------------------------------------------------------
# 3. Test sync-editors.sh integration
# ------------------------------------------------------------------------------
log_info "Testing sync-editors.sh skill synchronization in sandbox..."
SYNC_EDITORS_BIN="$REPO_ROOT/scripts/sync-editors.sh"

MOCK_SYNC_HOME="$SANDBOX_DIR/sync_home"
mkdir -p "$MOCK_SYNC_HOME"
HOME="$MOCK_SYNC_HOME" "$SYNC_EDITORS_BIN" --no-extensions >/dev/null 2>&1
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/ponytail" ] || log_fail "sync-editors.sh did not link ponytail skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/ponytail" ] || log_fail "sync-editors.sh did not link codex skill"
[ -L "$MOCK_SYNC_HOME/.claude/skills/ponytail" ] || log_fail "sync-editors.sh did not link claude skill"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/senior-implementer" ] || log_fail "sync-editors.sh did not link senior-implementer skill"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/caveman" ] || log_fail "sync-editors.sh did not link caveman skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/caveman" ] || log_fail "sync-editors.sh did not link codex caveman skill"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/rtk" ] || log_fail "sync-editors.sh did not link rtk skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/rtk" ] || log_fail "sync-editors.sh did not link codex rtk skill"
[ -L "$MOCK_SYNC_HOME/.claude/skills/rtk" ] || log_fail "sync-editors.sh did not link claude rtk skill"
# Verify junior-coding-agent is NOT linked by sync-editors.sh (uses global-core profile)
[ ! -e "$MOCK_SYNC_HOME/.gemini/config/skills/junior-coding-agent" ] || log_fail "sync-editors.sh linked deprecated junior-coding-agent"

# Verify Editor Export Integration (CLAUDE.md, Neovim AGENTS.md, Zed AGENTS.md, VSCode/Antigravity AGENTS.md)
[ -f "$MOCK_SYNC_HOME/.claude/CLAUDE.md" ] || log_fail "Missing .claude/CLAUDE.md"
[ -f "$MOCK_SYNC_HOME/.config/nvim/AGENTS.md" ] || log_fail "Missing .config/nvim/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.config/zed/prompts/AGENTS.md" ] || log_fail "Missing .config/zed/prompts/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.antigravity-ide/User/prompts/AGENTS.md" ] || log_fail "Missing .antigravity-ide/User/prompts/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.config/Code/User/prompts/AGENTS.md" ] || log_fail "Missing .config/Code/User/prompts/AGENTS.md"
grep -Fq "AI Agent Guidelines" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing header"
grep -Fq "ponytail" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing ponytail rule"
grep -Fq "<!-- managed-by: Aethries/dotfiles ai-skills -->" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing ownership marker"

log_ok "sync-editors.sh links skills and exports editor rules automatically"

echo
log_ok "All AI Skills test assertions passed successfully!"

