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
grep -Fq '"agentmemory"' "$REPO_ROOT/resources/gemini/mcp_config.json" || log_fail "mcp_config.json missing agentmemory"
grep -Fq '[mcp_servers.agentmemory]' "$REPO_ROOT/resources/codex/config.toml" || log_fail "Codex config missing agentmemory"
[ -f "$REPO_ROOT/.mcp.json" ] || log_fail "Missing Claude project MCP config"
[ -f "$REPO_ROOT/pkgs/iii-engine.nix" ] || log_fail "Missing pkgs/iii-engine.nix"
[ -f "$REPO_ROOT/resources/agent-memory/start.sh" ] || log_fail "Missing agentmemory service launcher"
grep -Fq 'iii-engine.nix' "$REPO_ROOT/modules/packages.nix" || log_fail "modules/packages.nix missing iii-engine"
grep -Fq 'systemd.services.agentmemory' "$REPO_ROOT/modules/services/agent-memory.nix" || log_fail "Missing agentmemory system service"
grep -Fq '@agentmemory/mcp@0.9.29' "$REPO_ROOT/resources/codex/config.toml" || log_fail "Codex config missing pinned agentmemory MCP"
grep -Fq '@agentmemory/mcp@0.9.29' "$REPO_ROOT/resources/gemini/mcp_config.json" || log_fail "Gemini config missing pinned agentmemory MCP"
grep -Fq '@agentmemory/mcp@0.9.29' "$REPO_ROOT/.mcp.json" || log_fail "Claude config missing pinned agentmemory MCP"

# Assert global gitignore has .codegraph/
[ -f "$REPO_ROOT/resources/git/ignore" ] || log_fail "Missing resources/git/ignore"
grep -Fq ".codegraph/" "$REPO_ROOT/resources/git/ignore" || log_fail "resources/git/ignore missing .codegraph/"

# Assert Zsh CLI has cg function
grep -Fq "function cg()" "$REPO_ROOT/resources/zsh/.zshrc" || log_fail "resources/zsh/.zshrc missing cg() function"
grep -Fq "function agentmemory-vault()" "$REPO_ROOT/resources/zsh/.zshrc" || log_fail "resources/zsh/.zshrc missing agentmemory-vault() function"
grep -Fq "alias amvault='agentmemory-vault'" "$REPO_ROOT/resources/zsh/.zshrc" || log_fail "resources/zsh/.zshrc missing amvault alias"

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
# 1.1.1 Validate lean cross-agent senior global baseline
# ------------------------------------------------------------------------------
log_info "Validating lean senior global baseline and project source-quality companion..."

MEMORY_BOOTSTRAP_FILE="$REPO_ROOT/resources/skills/agent-memory-bootstrap/SKILL.md"
[ -f "$MEMORY_BOOTSTRAP_FILE" ] || log_fail "Missing agent-memory-bootstrap skill"
grep -Eiq '^name:[[:space:]]*agent-memory-bootstrap' "$MEMORY_BOOTSTRAP_FILE" || log_fail "agent-memory-bootstrap has invalid name"
grep -Fq "If an Agent Memory MCP server is available" "$MEMORY_BOOTSTRAP_FILE" || log_fail "agent-memory-bootstrap missing MCP fallback rule"
grep -Fq "Do not store secrets" "$MEMORY_BOOTSTRAP_FILE" || log_fail "agent-memory-bootstrap missing sensitive-data rule"
grep -Fq "Current repository behavior and explicit task requirements outrank stale memory" "$MEMORY_BOOTSTRAP_FILE" || log_fail "agent-memory-bootstrap missing conflict precedence"
[ "$(wc -w < "$MEMORY_BOOTSTRAP_FILE" | tr -d ' ')" -le 450 ] || log_fail "agent-memory-bootstrap exceeds token economy limit"

REPO_FIRST_FILE="$REPO_ROOT/resources/skills/repo-first-implementation/SKILL.md"
[ -f "$REPO_FIRST_FILE" ] || log_fail "Missing repo-first-implementation skill"
grep -Eiq '^name:[[:space:]]*repo-first-implementation' "$REPO_FIRST_FILE" || log_fail "repo-first-implementation has invalid name"
grep -Fq "Inspect at least two neighboring implementations" "$REPO_FIRST_FILE" || log_fail "repo-first-implementation missing local convention evidence"
grep -Fq "Apply SOLID as a diagnostic" "$REPO_FIRST_FILE" || log_fail "repo-first-implementation missing SOLID boundary rule"
grep -Fq "Report passed, failed, blocked, and not-run checks separately" "$REPO_FIRST_FILE" || log_fail "repo-first-implementation missing evidence reporting rule"
[ "$(wc -w < "$REPO_FIRST_FILE" | tr -d ' ')" -le 450 ] || log_fail "repo-first-implementation exceeds token economy limit"

PROJECT_QUALITY_FILE="$REPO_ROOT/resources/skills/project-source-quality/SKILL.md"
[ -f "$PROJECT_QUALITY_FILE" ] || log_fail "Missing project-source-quality skill"
grep -Eiq '^name:[[:space:]]*project-source-quality' "$PROJECT_QUALITY_FILE" || log_fail "project-source-quality has invalid name"
grep -Eiq '^description:[[:space:]]*"?Internal guardrail' "$PROJECT_QUALITY_FILE" || log_fail "project-source-quality description must start with Internal guardrail"
[ "$(wc -w < "$PROJECT_QUALITY_FILE" | tr -d ' ')" -le 350 ] || log_fail "project-source-quality exceeds token economy limit"
grep -Fq "Inspect at least two nearby implementations" "$PROJECT_QUALITY_FILE" || log_fail "project-source-quality missing convention evidence rule"
grep -Fq "Derive names and placement from neighboring code" "$PROJECT_QUALITY_FILE" || log_fail "project-source-quality missing naming rule"
grep -Fq "State the input, output, error, and side-effect contract" "$PROJECT_QUALITY_FILE" || log_fail "project-source-quality missing functional contract rule"
grep -Fq "update CodeGraph/Codebase Memory" "$PROJECT_QUALITY_FILE" || log_fail "project-source-quality missing graph synchronization rule"
jq -e '.skills["project-source-quality"]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "registry missing project-source-quality"
jq -e '.skills["detect-stack"].source == "external" and .skills["detect-stack"].provenance.license == "MIT"' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "registry missing trusted detect-stack provenance"
[ -f "$REPO_ROOT/resources/skills/detect-stack/SKILL.md" ] || log_fail "Missing imported detect-stack skill"

SENIOR_GLOBAL_SKILLS=(
    "ponytail"
    "caveman"
    "rtk"
    "codegraph"
    "codebase-memory"
    "agent-memory-bootstrap"
    "repo-first-implementation"
    "senior-implementer"
    "junior-coding-agent"
    "project-context"
    "source-quality"
    "quality-gate"
    "security-guardrails"
    "architecture-guardrails"
    "project-source-quality"
    "detect-stack"
)
jq -e '.profiles["senior-global"]' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "_profiles.json missing senior-global profile"
for global_skill in "${SENIOR_GLOBAL_SKILLS[@]}"; do
    jq -e --arg s "$global_skill" '.profiles["senior-global"].skills | index($s)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "senior-global profile missing $global_skill"
done

for workflow_skill in "agent-memory-bootstrap" "repo-first-implementation"; do
    jq -e --arg s "$workflow_skill" '.skills[$s]' "$REPO_ROOT/resources/skills/_registry.json" >/dev/null || log_fail "registry missing $workflow_skill"
    jq -e --arg s "$workflow_skill" '.profiles["senior-global"].skills | index($s)' "$REPO_ROOT/resources/skills/_profiles.json" >/dev/null || log_fail "senior-global profile missing $workflow_skill"
done

log_ok "Senior-global workflow, memory bootstrap, project-source-quality, and external detect-stack verified"

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

# Test 2.7: sync command (default: senior-global profile)
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
[ -L "$MOCK_HOME/.gemini/config/skills/project-context" ] || log_fail "sync command failed to link project-context"
[ -L "$MOCK_HOME/.gemini/config/skills/agent-memory-bootstrap" ] || log_fail "sync command failed to link agent-memory-bootstrap"
[ -L "$MOCK_HOME/.codex/skills/repo-first-implementation" ] || log_fail "sync command failed to link repo-first-implementation"
[ -L "$MOCK_HOME/.codex/skills/project-source-quality" ] || log_fail "sync command failed to link project-source-quality"
[ -L "$MOCK_HOME/.claude/skills/detect-stack" ] || log_fail "sync command failed to link detect-stack"
[ -L "$MOCK_HOME/.gemini/config/skills/junior-coding-agent" ] || log_fail "senior-global sync failed to preserve requested junior-coding-agent"

# Test 2.7b: sync --all-canonical links entire registry
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" sync --all-canonical >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/release-notes" ] || log_fail "sync --all-canonical failed to link release-notes"
[ -L "$MOCK_HOME/.codex/skills/release-notes" ] || log_fail "sync --all-canonical failed to link codex release-notes"
[ -L "$MOCK_HOME/.claude/skills/release-notes" ] || log_fail "sync --all-canonical failed to link claude release-notes"
log_ok "ai-skills.sh sync synchronizes senior-global by default and supports --all-canonical"

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
if bash -c "source '$REPO_ROOT/scripts/ai-skills.sh' && assert_path_inside_project '$FAKE_ESCAPE_DIR/.agents/skills/ponytail' '$MOCK_PROJECT'" >/dev/null 2>&1; then
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
if HOME="$MOCK_HOME" "$AI_SKILLS_BIN" import "$MOCK_IMPORT_DIR" ponytail --approve >/dev/null 2>&1; then
    log_fail "import silently overwrote canonical skill 'ponytail' without --force"
fi
grep -Fq "Ponytail / Lazy Senior Developer" "$REPO_ROOT/resources/skills/ponytail/SKILL.md" || log_fail "Canonical ponytail was modified"
rm -rf "$MOCK_IMPORT_DIR"
log_ok "ai-skills.sh import rejects overwriting canonical skills without explicit --force"

# Test 2.16: Local search vs external discovery vs sources
log_info "Testing search (local only) vs discover vs sources..."
# Local search succeeds on canonical skill
SEARCH_OUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" search redis)
echo "$SEARCH_OUT" | grep -Fq "redis" || log_fail "ai-skills search failed to find canonical 'redis' skill"

# Local search on non-existent query outputs guidance to use discover
SEARCH_MISSING=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" search "nonexistent-skill-xyz")
echo "$SEARCH_MISSING" | grep -Fq "ai-skills discover nonexistent-skill-xyz" || log_fail "ai-skills search did not suggest ai-skills discover"

# Sources command lists trusted sources
SOURCES_OUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" sources)
echo "$SOURCES_OUT" | grep -Fq "official-vendor" || log_fail "ai-skills sources missing official-vendor"
echo "$SOURCES_OUT" | grep -Fq "anthropic-skills" || log_fail "ai-skills sources missing anthropic-skills"

# In production mode (DISCOVERY_FIXTURE_DIR unset), discovery must enforce fixture isolation
DISCOVER_PROD=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" discover nextjs)
echo "$DISCOVER_PROD" | grep -Fq "No verified deterministic candidate found" || log_fail "Production discovery leaked fixture data"

# When DISCOVERY_FIXTURE_DIR is set, discovery uses fixture candidates
DISCOVER_OUT=$(DISCOVERY_FIXTURE_DIR="$REPO_ROOT/tests/ai/fixtures/discovery" HOME="$MOCK_HOME" "$AI_SKILLS_BIN" discover nextjs)
echo "$DISCOVER_OUT" | grep -Fq "nextjs-runtime-debugging" || log_fail "ai-skills discover failed to find nextjs candidate"
log_ok "search is local only, sources lists sources, discover enforces fixture isolation"

# Test 2.17: Multi-skill repo import with --path and preview mode
log_info "Testing multi-skill repo import with --path..."
MULTI_REPO="$REPO_ROOT/tests/ai/fixtures/import-repos/multi-skill-repo"
SINGLE_REPO="$REPO_ROOT/tests/ai/fixtures/import-repos/single-skill-repo"

# Importing multi-skill repo without --path must abort and list candidates
if HOME="$MOCK_HOME" "$AI_SKILLS_BIN" import "$MULTI_REPO" >/dev/null 2>&1; then
    log_fail "ai-skills import allowed multi-skill repo without --path"
fi

MULTI_ERR=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" import "$MULTI_REPO" 2>&1 || true)
echo "$MULTI_ERR" | grep -Fq "Specify which skill to import using --path" || log_fail "ai-skills import did not prompt for --path"
echo "$MULTI_ERR" | grep -Fq "skills/skill-alpha" || log_fail "ai-skills import did not list skill-alpha"

# Importing with --path in preview mode must succeed without modifying canonical library
MULTI_PREVIEW=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" import "$MULTI_REPO" --path "skills/skill-alpha" --preview 2>&1)
echo "$MULTI_PREVIEW" | grep -Fq "STATUS: PREVIEW ONLY" || log_fail "Preview mode did not show PREVIEW ONLY"
[ ! -d "$REPO_ROOT/resources/skills/skill-alpha" ] || log_fail "Preview mode wrote to canonical library"

# Single skill repo import in preview mode
SINGLE_PREVIEW=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" import "$SINGLE_REPO" --preview 2>&1)
echo "$SINGLE_PREVIEW" | grep -Fq "STATUS: PREVIEW ONLY" || log_fail "Single repo preview failed"
[ ! -d "$REPO_ROOT/resources/skills/single-test-skill" ] || log_fail "Single repo preview wrote to canonical library"
log_ok "Multi-skill repo import requires --path and preview mode is strictly non-mutating"

# Test 2.18: Heuristic review fixture validation (Cases A, B, C)
log_info "Testing AI heuristic review fixtures..."
# Case A: browser-debugging vs nextjs-runtime-debugging -> PARTIAL_OVERLAP / COMPANION
CASE_A_REV=$(bash "$REPO_ROOT/scripts/lib/curate.sh" heuristic "$REPO_ROOT/tests/ai/fixtures/semantic/browser-debugging" "$REPO_ROOT/tests/ai/fixtures/semantic/nextjs-runtime-debugging")
echo "$CASE_A_REV" | jq -e '.heuristic_decision == "PARTIAL_OVERLAP" and .heuristic_action == "COMPANION"' >/dev/null || log_fail "Case A did not yield PARTIAL_OVERLAP / COMPANION: $CASE_A_REV"

# Case B: nestjs-transactions vs nestjs-database-transaction-best-practices -> DUPLICATE / REUSE
CASE_B_REV=$(bash "$REPO_ROOT/scripts/lib/curate.sh" heuristic "$REPO_ROOT/tests/ai/fixtures/semantic/nestjs-transactions" "$REPO_ROOT/tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices")
echo "$CASE_B_REV" | jq -e '.heuristic_decision == "DUPLICATE" and .heuristic_action == "REUSE"' >/dev/null || log_fail "Case B did not yield DUPLICATE / REUSE: $CASE_B_REV"

# Case C: prisma-transactions vs canonical postgresql -> KEEP_BOTH / CREATE
CASE_C_REV=$(bash "$REPO_ROOT/scripts/lib/curate.sh" heuristic "$REPO_ROOT/tests/ai/fixtures/semantic/prisma-transactions" "$REPO_ROOT/resources/skills/postgresql")
echo "$CASE_C_REV" | jq -e '.heuristic_decision == "KEEP_BOTH" and .heuristic_action == "CREATE"' >/dev/null || log_fail "Case C did not yield KEEP_BOTH / CREATE: $CASE_C_REV"
log_ok "All heuristic review cases (PARTIAL_OVERLAP, DUPLICATE, KEEP_BOTH) evaluated correctly"

# Test 2.19: Exact target path ownership protection in remove_project
log_info "Testing exact target path ownership protection in remove_project..."
OWN_PROJ="$SANDBOX_DIR/own_proj"
mkdir -p "$OWN_PROJ/.agents/skills" "$OWN_PROJ/.claude/skills"
# Set up managed .agents/skills/docker and unmanaged .claude/skills/docker
cp -a "$REPO_ROOT/resources/skills/docker" "$OWN_PROJ/.agents/skills/docker"
cp -a "$REPO_ROOT/resources/skills/docker" "$OWN_PROJ/.claude/skills/docker"
# Lockfile records only .agents/skills/docker
cat << EOF > "$OWN_PROJ/.agent-skills.lock.json"
{
  "version": 2,
  "generated_at": "2026-09-20T00:00:00Z",
  "skills": {
    "docker": {
      "version": "1.0.0",
      "source": "canonical",
      "content_hash": "dummyhash",
      "target_path": ".agents/skills/docker",
      "targets": [
        { "path": ".agents/skills/docker", "agents": ["codex-cli", "antigravity-cli"] }
      ]
    }
  }
}
EOF

# Direct invocation of remove_project on unmanaged target must fail without --force
if bash -c "source '$REPO_ROOT/scripts/ai-skills.sh' && remove_project 'docker' '$OWN_PROJ/.claude/skills' '$OWN_PROJ'" >/dev/null 2>&1; then
    log_fail "remove_project deleted unmanaged .claude target without --force"
fi
[ -d "$OWN_PROJ/.claude/skills/docker" ] || log_fail "Unmanaged .claude/skills/docker was deleted prematurely"

# With FORCE_REPLACE=true, it succeeds
bash -c "source '$REPO_ROOT/scripts/ai-skills.sh' && FORCE_REPLACE=true remove_project 'docker' '$OWN_PROJ/.claude/skills' '$OWN_PROJ'" >/dev/null
[ ! -d "$OWN_PROJ/.claude/skills/docker" ] || log_fail "Forced remove_project failed to remove .claude/skills/docker"
rm -rf "$OWN_PROJ"
log_ok "remove_project strictly enforces exact target path ownership and protects unmanaged targets"

# Test 2.20: Explicit remove scopes (default: global only; --project: project only; --all-scopes: both)
log_info "Testing explicit remove scopes (global only vs --project vs --all-scopes)..."
SCOPE_HOME="$SANDBOX_DIR/scope_home"
SCOPE_PROJ="$SANDBOX_DIR/scope_proj"
mkdir -p "$SCOPE_HOME" "$SCOPE_PROJ"

# 1. Setup: install globally to claude and locally to project
HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" add ponytail --global claude >/dev/null
(cd "$SCOPE_PROJ" && HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" add ponytail --project >/dev/null)
[ -L "$SCOPE_HOME/.claude/skills/ponytail" ] || log_fail "Global symlink missing before scope test"
[ -d "$SCOPE_PROJ/.agents/skills/ponytail" ] || log_fail "Project copy missing before scope test"

# 2. Test default remove (global only): project copy must remain intact!
(cd "$SCOPE_PROJ" && HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" remove ponytail --global claude >/dev/null)
[ ! -e "$SCOPE_HOME/.claude/skills/ponytail" ] || log_fail "Global symlink was not removed by default remove"
[ -d "$SCOPE_PROJ/.agents/skills/ponytail" ] || log_fail "Default remove mistakenly deleted project copy!"

# 3. Test remove --project: global symlink must remain intact!
HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" add ponytail --global claude >/dev/null
[ -L "$SCOPE_HOME/.claude/skills/ponytail" ] || log_fail "Failed to re-add global symlink"
(cd "$SCOPE_PROJ" && HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" remove ponytail --project >/dev/null)
[ ! -d "$SCOPE_PROJ/.agents/skills/ponytail" ] || log_fail "remove --project failed to delete project copy"
[ -L "$SCOPE_HOME/.claude/skills/ponytail" ] || log_fail "remove --project mistakenly deleted global symlink!"

# 4. Test remove --all-scopes: both must be removed!
(cd "$SCOPE_PROJ" && HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" add ponytail --project >/dev/null)
(cd "$SCOPE_PROJ" && HOME="$SCOPE_HOME" "$AI_SKILLS_BIN" remove ponytail --all-scopes >/dev/null)
[ ! -e "$SCOPE_HOME/.claude/skills/ponytail" ] || log_fail "remove --all-scopes did not remove global symlink"
[ ! -d "$SCOPE_PROJ/.agents/skills/ponytail" ] || log_fail "remove --all-scopes did not remove project copy"
rm -rf "$SCOPE_HOME" "$SCOPE_PROJ"
log_ok "Explicit remove scopes verified: default=global, --project=project, --all-scopes=both"

# Test 2.21: Project-aware recommendation engine
log_info "Testing project-aware recommendation engine..."
REC_PROJ="$SANDBOX_DIR/rec_proj"
mkdir -p "$REC_PROJ"
cat << 'EOF' > "$REC_PROJ/package.json"
{
  "name": "mock-service",
  "dependencies": {
    "@nestjs/core": "^10.0.0",
    "bullmq": "^5.0.0",
    "next": "^14.0.0"
  }
}
EOF

REC_OUT=$(DISCOVERY_FIXTURE_DIR="$REPO_ROOT/tests/ai/fixtures/discovery" HOME="$MOCK_HOME" "$AI_SKILLS_BIN" recommend --project "$REC_PROJ")
CLEAN_OUT=$(echo "$REC_OUT" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
if ! echo "$CLEAN_OUT" | grep -q "NestJS (local: nestjs)"; then
    log_fail "recommendation missed covered NestJS"
fi
if ! echo "$CLEAN_OUT" | grep -q "BullMQ (local: bullmq)"; then
    log_fail "recommendation missed covered BullMQ"
fi
if ! echo "$CLEAN_OUT" | grep -q "Next.js (local: nextjs-app-router)"; then
    log_fail "recommendation missed covered Next.js"
fi
if ! echo "$CLEAN_OUT" | grep -q "Recommendation is advisory only"; then
    log_fail "recommendation missing advisory policy"
fi
rm -rf "$REC_PROJ"
log_ok "Project-aware recommendation engine accurately analyzes stack and proposes advisory candidates"

# Test 2.22: Candidate verification engine (verify_candidate)
log_info "Testing candidate verification engine (verify_candidate)..."
VERIFY_VALID=$(bash -c "source '$REPO_ROOT/scripts/lib/discovery.sh' && verify_candidate '$REPO_ROOT/tests/ai/fixtures/import-repos/single-skill-repo'")
echo "$VERIFY_VALID" | jq -e '.verified == true' >/dev/null || log_fail "verify_candidate rejected valid local skill bundle: $VERIFY_VALID"

VERIFY_MISSING=$(bash -c "source '$REPO_ROOT/scripts/lib/discovery.sh' && verify_candidate '$SANDBOX_DIR'")
echo "$VERIFY_MISSING" | jq -e '.verified == false and (.reason | contains("SKILL.md not found"))' >/dev/null || log_fail "verify_candidate did not reject missing SKILL.md: $VERIFY_MISSING"

BAD_SKILL_DIR="$SANDBOX_DIR/bad-skill"
mkdir -p "$BAD_SKILL_DIR"
echo "# Bad Skill Without Frontmatter" > "$BAD_SKILL_DIR/SKILL.md"
VERIFY_BAD=$(bash -c "source '$REPO_ROOT/scripts/lib/discovery.sh' && verify_candidate '$BAD_SKILL_DIR'")
echo "$VERIFY_BAD" | jq -e '.verified == false and (.reason | contains("YAML frontmatter"))' >/dev/null || log_fail "verify_candidate did not reject missing frontmatter: $VERIFY_BAD"
rm -rf "$BAD_SKILL_DIR"
log_ok "verify_candidate accurately verifies valid bundles and rejects invalid/unformatted candidates"

# Test 2.23: .git and VCS exclusion during copy_skill_bundle and import
log_info "Testing .git and VCS cache exclusion during skill bundle copy..."
VCS_TEST_DIR="$SANDBOX_DIR/vcs-source-skill"
mkdir -p "$VCS_TEST_DIR/.git/objects" "$VCS_TEST_DIR/.cache" "$VCS_TEST_DIR/node_modules"
cat << 'EOF' > "$VCS_TEST_DIR/SKILL.md"
---
name: vcs-clean-skill
description: Skill testing VCS exclusion during import
---
## Usage
Test body
EOF
touch "$VCS_TEST_DIR/.git/HEAD" "$VCS_TEST_DIR/.cache/temp.log" "$VCS_TEST_DIR/node_modules/dummy.js"

VCS_DEST_DIR="$SANDBOX_DIR/vcs-copied-skill"
bash -c "source '$REPO_ROOT/scripts/ai-skills.sh' && copy_skill_bundle '$VCS_TEST_DIR' '$VCS_DEST_DIR'"

[ -f "$VCS_DEST_DIR/SKILL.md" ] || log_fail "copy_skill_bundle failed to copy SKILL.md"
[ ! -d "$VCS_DEST_DIR/.git" ] || log_fail "copy_skill_bundle leaked .git directory"
[ ! -d "$VCS_DEST_DIR/.cache" ] || log_fail "copy_skill_bundle leaked .cache directory"
[ ! -d "$VCS_DEST_DIR/node_modules" ] || log_fail "copy_skill_bundle leaked node_modules directory"
rm -rf "$VCS_TEST_DIR" "$VCS_DEST_DIR"
log_ok "copy_skill_bundle strictly excludes VCS internals, caches, and dependency directories"

# Test 2.24: Provenance schema validation and multi-overlap review
log_info "Testing provenance schema validation and multi-overlap review..."
IMPORT_PROV_HOME="$SANDBOX_DIR/prov_home"
mkdir -p "$IMPORT_PROV_HOME"

MOCK_REG_DIR="$SANDBOX_DIR/mock_registry"
mkdir -p "$MOCK_REG_DIR"
cp "$REPO_ROOT/resources/skills/_registry.json" "$MOCK_REG_DIR/_registry.json"

IMPORT_OUT=$(HOME="$IMPORT_PROV_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$MOCK_REG_DIR" "$AI_SKILLS_BIN" import "$SINGLE_REPO" test-imported-skill --approve 2>&1)
echo "$IMPORT_OUT" | grep -Fq "Successfully imported skill" || log_fail "ai-skills import failed to approve import: $IMPORT_OUT"

IMPORTED_ENTRY=$(jq '.skills["test-imported-skill"]' "$MOCK_REG_DIR/_registry.json")
echo "$IMPORTED_ENTRY" | jq -e '.provenance.upstream_url != null' >/dev/null || log_fail "Provenance missing upstream_url"
echo "$IMPORTED_ENTRY" | jq -e '.provenance.license != null' >/dev/null || log_fail "Provenance missing license"
echo "$IMPORTED_ENTRY" | jq -e '.provenance.security_review.status == "passed"' >/dev/null || log_fail "Provenance missing security_review.status"
echo "$IMPORTED_ENTRY" | jq -e '.provenance.security_review.checked_by == "curate.sh-security-audit"' >/dev/null || log_fail "Provenance missing security_review.checked_by"
echo "$IMPORTED_ENTRY" | jq -e '.provenance.semantic_review.decision != null' >/dev/null || log_fail "Provenance missing semantic_review.decision"
echo "$IMPORTED_ENTRY" | jq -e '.provenance.imported_at != null' >/dev/null || log_fail "Provenance missing imported_at"

MULTI_OVERLAP_CAND="$SANDBOX_DIR/multi-overlap-candidate"
mkdir -p "$MULTI_OVERLAP_CAND"
cat << 'EOF' > "$MULTI_OVERLAP_CAND/SKILL.md"
---
name: redis-queue-worker
description: Redis caching patterns, eviction policies, atomic primitives, pubsub messaging, distributed job queues, background workers, scheduled jobs, and BullMQ retry policies with distributed locks.
capabilities:
  - cache-patterns
  - eviction-policies
  - atomic-primitives
  - pubsub-messaging
  - job-queues
  - worker-concurrency
  - scheduled-jobs
  - redis-retry-policies
triggers:
  - redis-cache
  - distributed-lock
  - redis-pubsub
  - job-queue
  - bullmq
  - redis-queue
---
## Background Workers
Combines Redis and BullMQ.
EOF

OVERLAPS_REV=$(bash "$REPO_ROOT/scripts/lib/curate.sh" overlaps-review "$MULTI_OVERLAP_CAND" "$REPO_ROOT/resources/skills/_registry.json")
echo "$OVERLAPS_REV" | jq -e 'map(.existing) | contains(["redis"]) and contains(["bullmq"])' >/dev/null || log_fail "overlaps-review failed to review both redis and bullmq: $OVERLAPS_REV"
rm -rf "$MOCK_REG_DIR" "$MULTI_OVERLAP_CAND" "$IMPORT_PROV_HOME"
log_ok "Import records expanded provenance schema and multi-overlap review evaluates all colliding skills"

# Test 2.25: Registry-driven recommendation coverage analysis
log_info "Testing registry-driven recommendation coverage..."
REG_PROJ="$SANDBOX_DIR/reg_proj"
mkdir -p "$REG_PROJ"
cat << 'EOF' > "$REG_PROJ/package.json"
{
  "name": "registry-driven-test",
  "dependencies": {
    "bullmq": "^5.0.0"
  }
}
EOF

REC_CANONICAL=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" recommend --project "$REG_PROJ")
CLEAN_CANONICAL=$(echo "$REC_CANONICAL" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
echo "$CLEAN_CANONICAL" | grep -Fq "BullMQ (local: bullmq)" || log_fail "Canonical recommendation missed bullmq coverage"

MOCK_EMPTY_REG="$SANDBOX_DIR/empty_reg"
mkdir -p "$MOCK_EMPTY_REG"
cat << 'EOF' > "$MOCK_EMPTY_REG/_registry.json"
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "version": 1,
  "skills": {}
}
EOF

REC_MISSING=$(HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$MOCK_EMPTY_REG" "$AI_SKILLS_BIN" recommend --project "$REG_PROJ")
CLEAN_MISSING=$(echo "$REC_MISSING" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
echo "$CLEAN_MISSING" | grep -Fq "Missing Coverage: bullmq" || log_fail "Mock empty registry failed to detect missing bullmq"
rm -rf "$REG_PROJ" "$MOCK_EMPTY_REG"
log_ok "Recommendation engine coverage is dynamically driven by registry state"

# Test 2.26: Discovery candidate verification filter (Blocker 1)
log_info "Testing discovery candidate verification filter..."
VALID_CAND_JSON=$(jq -n --arg repo "$SINGLE_REPO" '{
    name: "sample-single",
    source: "local-test",
    upstream_url: $repo,
    skill_path: ".",
    revision: null
}')
CHECKED_VALID=$(bash "$REPO_ROOT/scripts/lib/discovery.sh" verify-discovery "$VALID_CAND_JSON")
echo "$CHECKED_VALID" | jq -e '.verification.status == "verified"' >/dev/null || log_fail "verify_discovery_candidate rejected valid bundle: $CHECKED_VALID"

INVALID_CAND_JSON=$(jq -n --arg repo "$SINGLE_REPO" '{
    name: "missing-path-skill",
    source: "local-test",
    upstream_url: $repo,
    skill_path: "nonexistent/subpath",
    revision: null
}')
CHECKED_INVALID=$(bash "$REPO_ROOT/scripts/lib/discovery.sh" verify-discovery "$INVALID_CAND_JSON")
echo "$CHECKED_INVALID" | jq -e '.verification.status == "rejected"' >/dev/null || log_fail "verify_discovery_candidate accepted invalid path: $CHECKED_INVALID"
log_ok "verify_discovery_candidate validates reachable bundles and rejects missing paths"

# Test 2.27: Heuristic vs Semantic review schema separation (Blocker 3)
log_info "Testing heuristic vs semantic review schema separation..."
HEUR_OUT=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && perform_heuristic_review '$REPO_ROOT/tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices' 'nestjs' '$REPO_ROOT/resources/skills/_registry.json'")
echo "$HEUR_OUT" | jq -e '.review_type == "heuristic"' >/dev/null || log_fail "Heuristic review missing review_type=heuristic: $HEUR_OUT"
echo "$HEUR_OUT" | jq -e '.heuristic_decision != null and .heuristic_action != null and .similarity_score != null' >/dev/null || log_fail "Heuristic review missing heuristic fields: $HEUR_OUT"
echo "$HEUR_OUT" | jq -e '.decision == null and .recommended_action == null' >/dev/null || log_fail "Heuristic review emitted reserved semantic fields (decision/recommended_action): $HEUR_OUT"

# Semantic review without input returns status=required (no heuristic fallback)
SEM_REQUIRED=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && unset SEMANTIC_REVIEW_FILE SEMANTIC_REVIEW_JSON && perform_semantic_review '$REPO_ROOT/tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices' 'nestjs' '$REPO_ROOT/resources/skills/_registry.json'")
echo "$SEM_REQUIRED" | jq -e '.review_type == "semantic" and .status == "required"' >/dev/null || log_fail "perform_semantic_review did not return status=required without input: $SEM_REQUIRED"
log_ok "Heuristic review strictly separates schema from semantic review and omits decision/recommended_action"

# Test 2.28: Import gate on overlapping candidate (Blocker 3)
log_info "Testing import gate on overlapping candidate..."
GATE_REG_DIR="$SANDBOX_DIR/gate_registry"
mkdir -p "$GATE_REG_DIR"
cp "$REPO_ROOT/resources/skills/_registry.json" "$GATE_REG_DIR/_registry.json"

NEST_CAND_PATH="$REPO_ROOT/tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices"

# Preview on overlapping candidate succeeds and marks Semantic Review: REQUIRED
OVERLAP_PREVIEW=$(HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$GATE_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_CAND_PATH" --preview 2>&1)
CLEAN_OVERLAP=$(echo "$OVERLAP_PREVIEW" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
echo "$CLEAN_OVERLAP" | grep -Fq "Semantic Review: REQUIRED" || log_fail "Preview failed to indicate Semantic Review: REQUIRED: $OVERLAP_PREVIEW"

# Approve on overlapping candidate WITHOUT semantic review MUST FAIL
if HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$GATE_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_CAND_PATH" --approve >/dev/null 2>&1; then
    log_fail "ai-skills import --approve succeeded on overlapping candidate without semantic review"
fi

# Approve on overlapping candidate WITH completed semantic review succeeds
MOCK_SEM_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "candidate": "nestjs-database-transaction-best-practices",
  "existing": "nestjs",
  "decision": "PARTIAL_OVERLAP",
  "recommended_action": "COMPANION",
  "reason": "Specialized companion for transaction boundaries",
  "evidence": ["Both touch NestJS transactions"]
}'
APPROVE_SEM_OUT=$(SEMANTIC_REVIEW_JSON="$MOCK_SEM_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$GATE_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_CAND_PATH" --approve 2>&1)
echo "$APPROVE_SEM_OUT" | grep -Fq "Successfully imported skill" || log_fail "Approve with valid semantic review failed: $APPROVE_SEM_OUT"

rm -rf "$GATE_REG_DIR"
log_ok "Import gate blocks approval of overlapping candidates until semantic review is completed"

# Test 2.29: Curation document structure and verification audit (Blocker 4)
log_info "Testing curation document evidence separation..."
CURATION_DOC="$REPO_ROOT/docs/ai-skills-curation.md"
[ -f "$CURATION_DOC" ] || log_fail "Missing docs/ai-skills-curation.md"
grep -Fq "Section A: Verified Real-World Curation Audit" "$CURATION_DOC" || log_fail "Curation doc missing Section A"
grep -Fq "Section B: Test Fixture Validation" "$CURATION_DOC" || log_fail "Curation doc missing Section B"
grep -Fq "NOT REAL UPSTREAM EVIDENCE" "$CURATION_DOC" || log_fail "Curation doc missing test fixture disclaimer"
grep -Fq "No verified candidate found" "$CURATION_DOC" || log_fail "Curation doc missing No verified candidate found entries"
log_ok "Curation document strictly segregates verified real-world evidence from test fixtures"

# Test 2.30: Semantic review strict schema validation and decision handling (Blocker 3 / Tests A - J)
log_info "Testing semantic review strict schema validation and decision handling..."

T30_REG_DIR="$SANDBOX_DIR/sem_test_registry"
mkdir -p "$T30_REG_DIR"
cp "$REPO_ROOT/resources/skills/_registry.json" "$T30_REG_DIR/_registry.json"
NEST_FIXTURE_PATH="$REPO_ROOT/tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices"

# Test A — Unknown Decision
TEST_A_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "BANANA",
  "recommended_action": "CREATE",
  "reason": "test"
}'
TEST_A_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_A_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_A_VAL" | jq -e '.valid == false' >/dev/null || log_fail "Test A: validate_semantic_review accepted unknown decision BANANA"
TEST_A_SEM=$(SEMANTIC_REVIEW_JSON="$TEST_A_JSON" bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && perform_semantic_review '$NEST_FIXTURE_PATH' 'nestjs' '$T30_REG_DIR/_registry.json'")
echo "$TEST_A_SEM" | jq -e '.status == "required"' >/dev/null || log_fail "Test A: perform_semantic_review did not return status=required for unknown decision"
if SEMANTIC_REVIEW_JSON="$TEST_A_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve >/dev/null 2>&1; then
    log_fail "Test A: import --approve succeeded with unknown decision BANANA"
fi

# Test B — Missing Status
TEST_B_JSON='{
  "review_type": "semantic",
  "existing": "nestjs",
  "decision": "KEEP_BOTH",
  "recommended_action": "CREATE",
  "reason": "test"
}'
TEST_B_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_B_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_B_VAL" | jq -e '.valid == false' >/dev/null || log_fail "Test B: validate_semantic_review accepted missing status"
TEST_B_SEM=$(SEMANTIC_REVIEW_JSON="$TEST_B_JSON" bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && perform_semantic_review '$NEST_FIXTURE_PATH' 'nestjs' '$T30_REG_DIR/_registry.json'")
echo "$TEST_B_SEM" | jq -e '.status == "required"' >/dev/null || log_fail "Test B: perform_semantic_review did not return status=required for missing status"
if SEMANTIC_REVIEW_JSON="$TEST_B_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve >/dev/null 2>&1; then
    log_fail "Test B: import --approve succeeded with missing status"
fi

# Test C — Missing Action
TEST_C_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "KEEP_BOTH",
  "reason": "test"
}'
TEST_C_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_C_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_C_VAL" | jq -e '.valid == false' >/dev/null || log_fail "Test C: validate_semantic_review accepted missing recommended_action"
TEST_C_SEM=$(SEMANTIC_REVIEW_JSON="$TEST_C_JSON" bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && perform_semantic_review '$NEST_FIXTURE_PATH' 'nestjs' '$T30_REG_DIR/_registry.json'")
echo "$TEST_C_SEM" | jq -e '.status == "required"' >/dev/null || log_fail "Test C: perform_semantic_review did not return status=required for missing recommended_action"
if SEMANTIC_REVIEW_JSON="$TEST_C_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve >/dev/null 2>&1; then
    log_fail "Test C: import --approve succeeded with missing action"
fi

# Test D — Wrong Existing Skill Target
TEST_D_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "postgresql",
  "decision": "KEEP_BOTH",
  "recommended_action": "CREATE",
  "reason": "test"
}'
TEST_D_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_D_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_D_VAL" | jq -e '.valid == false' >/dev/null || log_fail "Test D: validate_semantic_review accepted wrong existing skill target"
TEST_D_SEM=$(SEMANTIC_REVIEW_JSON="$TEST_D_JSON" bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && perform_semantic_review '$NEST_FIXTURE_PATH' 'nestjs' '$T30_REG_DIR/_registry.json'")
echo "$TEST_D_SEM" | jq -e '.status == "required"' >/dev/null || log_fail "Test D: perform_semantic_review did not return status=required for wrong existing skill target"
if SEMANTIC_REVIEW_JSON="$TEST_D_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve >/dev/null 2>&1; then
    log_fail "Test D: import --approve succeeded with wrong existing skill target"
fi

# Test E — Invalid Decision/Action Pair
TEST_E_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "DUPLICATE",
  "recommended_action": "CREATE",
  "reason": "test"
}'
TEST_E_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_E_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_E_VAL" | jq -e '.valid == false' >/dev/null || log_fail "Test E: validate_semantic_review accepted invalid decision/action pair DUPLICATE+CREATE"
TEST_E_SEM=$(SEMANTIC_REVIEW_JSON="$TEST_E_JSON" bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && perform_semantic_review '$NEST_FIXTURE_PATH' 'nestjs' '$T30_REG_DIR/_registry.json'")
echo "$TEST_E_SEM" | jq -e '.status == "required"' >/dev/null || log_fail "Test E: perform_semantic_review did not return status=required for invalid pair DUPLICATE+CREATE"
if SEMANTIC_REVIEW_JSON="$TEST_E_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve >/dev/null 2>&1; then
    log_fail "Test E: import --approve succeeded with invalid pair DUPLICATE+CREATE"
fi

# Test F — CONFLICT: preview succeeds without mutation, approve is rejected
TEST_F_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "CONFLICT",
  "recommended_action": "REUSE",
  "reason": "Conflicting ownership and workflow rules"
}'
TEST_F_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_F_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_F_VAL" | jq -e '.valid == true' >/dev/null || log_fail "Test F: validate_semantic_review rejected valid CONFLICT payload"

# F1: Preview succeeds (exit 0), shows conflict reason, prints NO approve command, does not mutate
TEST_F_PREVIEW=$(SEMANTIC_REVIEW_JSON="$TEST_F_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --preview 2>&1)
F_PREV_STATUS=$?
[ $F_PREV_STATUS -eq 0 ] || log_fail "Test F: preview failed with exit code $F_PREV_STATUS: $TEST_F_PREVIEW"
echo "$TEST_F_PREVIEW" | grep -Fq "Conflicting ownership and workflow rules" || log_fail "Test F: preview did not show conflict reason"
echo "$TEST_F_PREVIEW" | grep -Fq "Automatic import blocked due to CONFLICT" || log_fail "Test F: preview did not show conflict block message"
echo "$TEST_F_PREVIEW" | grep -Fq "To import into canonical library, execute:" && log_fail "Test F: preview generated approve command for CONFLICT"
[ ! -d "$T30_REG_DIR/nestjs-database-transaction-best-practices" ] || log_fail "Test F: preview mutated filesystem"
jq -e '.skills["nestjs-database-transaction-best-practices"]' "$T30_REG_DIR/_registry.json" >/dev/null 2>&1 && log_fail "Test F: preview mutated registry"

# F2: Approve fails (exit 1) and does not mutate
if TEST_F_OUT=$(SEMANTIC_REVIEW_JSON="$TEST_F_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve 2>&1); then
    log_fail "Test F: import --approve succeeded despite CONFLICT decision"
fi
echo "$TEST_F_OUT" | grep -Fq "semantic review found a conflict" || log_fail "Test F: missing conflict explanation in error output: $TEST_F_OUT"
[ ! -d "$T30_REG_DIR/nestjs-database-transaction-best-practices" ] || log_fail "Test F: skill was imported despite CONFLICT"
jq -e '.skills["nestjs-database-transaction-best-practices"]' "$T30_REG_DIR/_registry.json" >/dev/null 2>&1 && log_fail "Test F: skill was added to registry despite CONFLICT"

# Test G — SUPERSEDES decision handling
TEST_G_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "SUPERSEDES",
  "recommended_action": "REPLACE",
  "reason": "Candidate fully replaces the existing scope"
}'
TEST_G_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_G_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_G_VAL" | jq -e '.valid == true' >/dev/null || log_fail "Test G: validate_semantic_review rejected valid SUPERSEDES payload"

# G1: Preview indicates SUPERSEDES and REPLACE with target name indicating replacement
TEST_G_PREVIEW=$(SEMANTIC_REVIEW_JSON="$TEST_G_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --preview 2>&1)
CLEAN_G_PREVIEW=$(echo "$TEST_G_PREVIEW" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
echo "$CLEAN_G_PREVIEW" | grep -Fq "decision: SUPERSEDES" || log_fail "Test G: preview missing decision: SUPERSEDES: $TEST_G_PREVIEW"
echo "$CLEAN_G_PREVIEW" | grep -Fq "action: REPLACE" || log_fail "Test G: preview missing action: REPLACE: $TEST_G_PREVIEW"
echo "$CLEAN_G_PREVIEW" | grep -Fq "replaces existing canonical skill" || log_fail "Test G: preview missing replacement target notice: $TEST_G_PREVIEW"

# G2: Real before/after test of SUPERSEDES + REPLACE mutation
# Setup initial existing canonical skill directory in sandbox
mkdir -p "$T30_REG_DIR/nestjs"
echo "ORIGINAL_NESTJS_CONTENT" > "$T30_REG_DIR/nestjs/ORIGINAL_MARKER"

# Without --replace flag, approve must fail
if SEMANTIC_REVIEW_JSON="$TEST_G_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve >/dev/null 2>&1; then
    log_fail "Test G: import --approve succeeded for SUPERSEDES without --replace flag"
fi
[ -f "$T30_REG_DIR/nestjs/ORIGINAL_MARKER" ] || log_fail "Test G: original marker deleted despite failed approve"

# With --approve --replace, replacement must succeed
TEST_G_APPROVE=$(SEMANTIC_REVIEW_JSON="$TEST_G_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve --replace 2>&1)
echo "$TEST_G_APPROVE" | grep -Fq "Successfully imported skill 'nestjs'" || log_fail "Test G: approve --replace failed: $TEST_G_APPROVE"

# Verify filesystem result:
# 1. Existing skill directory contains candidate content
[ -f "$T30_REG_DIR/nestjs/SKILL.md" ] || log_fail "Test G: missing nestjs/SKILL.md after replacement"
[ ! -f "$T30_REG_DIR/nestjs/ORIGINAL_MARKER" ] || log_fail "Test G: original marker still present after replacement"
grep -Fq "NestJS Database Transaction Best Practices" "$T30_REG_DIR/nestjs/SKILL.md" || log_fail "Test G: nestjs/SKILL.md does not contain candidate content"
# 2. No duplicate directory created under candidate name
[ ! -d "$T30_REG_DIR/nestjs-database-transaction-best-practices" ] || log_fail "Test G: duplicate candidate directory left in filesystem"

# Verify registry result:
# 1. Registry entry stays under existing skill name 'nestjs'
jq -e '.skills["nestjs"]' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test G: missing registry entry for 'nestjs'"
jq -e '.skills["nestjs"].name == "nestjs"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test G: registry name is not 'nestjs'"
jq -e '.skills["nestjs"].provenance.semantic_review.decision == "SUPERSEDES"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test G: registry decision is not SUPERSEDES"
jq -e '.skills["nestjs"].provenance.semantic_review.recommended_action == "REPLACE"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test G: registry action is not REPLACE"
# 2. No duplicate entry under candidate name
jq -e '.skills["nestjs-database-transaction-best-practices"]' "$T30_REG_DIR/_registry.json" >/dev/null 2>&1 && log_fail "Test G: duplicate candidate entry in registry"

# G3: SUPERSEDES + EXTEND blocks automatic import
TEST_G_EXTEND_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "SUPERSEDES",
  "recommended_action": "EXTEND",
  "reason": "Candidate extends existing scope"
}'
if SEMANTIC_REVIEW_JSON="$TEST_G_EXTEND_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve --replace >/dev/null 2>&1; then
    log_fail "Test G: import --approve succeeded for EXTEND action"
fi

# Reset registry and sandbox directory for subsequent tests
rm -rf "$T30_REG_DIR"
mkdir -p "$T30_REG_DIR"
cp "$REPO_ROOT/resources/skills/_registry.json" "$T30_REG_DIR/_registry.json"

# Test H — KEEP_BOTH decision allows import
TEST_H_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "KEEP_BOTH",
  "recommended_action": "CREATE",
  "reason": "Different workflow and scope"
}'
TEST_H_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_H_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_H_VAL" | jq -e '.valid == true' >/dev/null || log_fail "Test H: validate_semantic_review rejected valid KEEP_BOTH payload"
TEST_H_APPROVE=$(SEMANTIC_REVIEW_JSON="$TEST_H_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve 2>&1)
echo "$TEST_H_APPROVE" | grep -Fq "Successfully imported skill" || log_fail "Test H: approve failed for KEEP_BOTH: $TEST_H_APPROVE"
jq -e '.skills["nestjs-database-transaction-best-practices"].provenance.semantic_review.decision == "KEEP_BOTH"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test H: registry missing decision=KEEP_BOTH"
jq -e '.skills["nestjs-database-transaction-best-practices"].provenance.semantic_review.recommended_action == "CREATE"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test H: registry missing recommended_action=CREATE"
# Clean up imported fixture for next test
rm -rf "$T30_REG_DIR/nestjs-database-transaction-best-practices"
cp "$REPO_ROOT/resources/skills/_registry.json" "$T30_REG_DIR/_registry.json"

# Test I — PARTIAL_OVERLAP allows import
TEST_I_JSON='{
  "review_type": "semantic",
  "status": "completed",
  "existing": "nestjs",
  "decision": "PARTIAL_OVERLAP",
  "recommended_action": "COMPANION",
  "reason": "Specialized companion workflow"
}'
TEST_I_VAL=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && validate_semantic_review '$TEST_I_JSON' 'nestjs-database-transaction-best-practices' 'nestjs'")
echo "$TEST_I_VAL" | jq -e '.valid == true' >/dev/null || log_fail "Test I: validate_semantic_review rejected valid PARTIAL_OVERLAP payload"
TEST_I_APPROVE=$(SEMANTIC_REVIEW_JSON="$TEST_I_JSON" HOME="$MOCK_HOME" REPO_ROOT="$SANDBOX_DIR" SKILLS_SRC="$T30_REG_DIR" "$AI_SKILLS_BIN" import "$NEST_FIXTURE_PATH" --approve 2>&1)
echo "$TEST_I_APPROVE" | grep -Fq "Successfully imported skill" || log_fail "Test I: approve failed for PARTIAL_OVERLAP: $TEST_I_APPROVE"
jq -e '.skills["nestjs-database-transaction-best-practices"].provenance.semantic_review.decision == "PARTIAL_OVERLAP"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test I: registry missing decision=PARTIAL_OVERLAP"
jq -e '.skills["nestjs-database-transaction-best-practices"].provenance.semantic_review.recommended_action == "COMPANION"' "$T30_REG_DIR/_registry.json" >/dev/null || log_fail "Test I: registry missing recommended_action=COMPANION"

# Test J — Multi-Overlap Priority via production helper (aggregate_semantic_reviews)
# Subtest J1: KEEP_BOTH + DUPLICATE + PARTIAL_OVERLAP -> DUPLICATE
MOCK_MULTI_1='[
  { "existing": "skillA", "review": { "status": "completed", "decision": "KEEP_BOTH", "recommended_action": "CREATE", "reason": "r1" } },
  { "existing": "skillB", "review": { "status": "completed", "decision": "DUPLICATE", "recommended_action": "REUSE", "reason": "r2" } },
  { "existing": "skillC", "review": { "status": "completed", "decision": "PARTIAL_OVERLAP", "recommended_action": "COMPANION", "reason": "r3" } }
]'
RES_J1=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && aggregate_semantic_reviews '$MOCK_MULTI_1'")
DEC_J1=$(echo "$RES_J1" | jq -r '.decision')
[ "$DEC_J1" = "DUPLICATE" ] || log_fail "Test J1: Multi-overlap priority failed: expected DUPLICATE, got $DEC_J1"

# Subtest J2: DUPLICATE + CONFLICT -> CONFLICT
MOCK_MULTI_2='[
  { "existing": "skillA", "review": { "status": "completed", "decision": "DUPLICATE", "recommended_action": "REUSE", "reason": "r1" } },
  { "existing": "skillB", "review": { "status": "completed", "decision": "CONFLICT", "recommended_action": "REUSE", "reason": "r2" } }
]'
RES_J2=$(bash -c "source '$REPO_ROOT/scripts/lib/curate.sh' && aggregate_semantic_reviews '$MOCK_MULTI_2'")
DEC_J2=$(echo "$RES_J2" | jq -r '.decision')
[ "$DEC_J2" = "CONFLICT" ] || log_fail "Test J2: Multi-overlap priority failed: expected CONFLICT, got $DEC_J2"

rm -rf "$T30_REG_DIR"
log_ok "Semantic review strict schema validation and decision handling verified (Tests A - J)"

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
# Verify senior-global-specific baseline is linked by sync-editors.sh
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/project-context" ] || log_fail "sync-editors.sh missed project-context"
[ -L "$MOCK_SYNC_HOME/.codex/skills/agent-memory-bootstrap" ] || log_fail "sync-editors.sh missed agent-memory-bootstrap"
[ -L "$MOCK_SYNC_HOME/.claude/skills/repo-first-implementation" ] || log_fail "sync-editors.sh missed repo-first-implementation"
[ -L "$MOCK_SYNC_HOME/.codex/skills/project-source-quality" ] || log_fail "sync-editors.sh missed project-source-quality"
[ -L "$MOCK_SYNC_HOME/.claude/skills/detect-stack" ] || log_fail "sync-editors.sh missed detect-stack"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/junior-coding-agent" ] || log_fail "sync-editors.sh did not preserve requested junior-coding-agent"

# Verify Editor Export Integration (CLAUDE.md, Neovim AGENTS.md, Zed AGENTS.md, VSCode/Antigravity AGENTS.md)
[ -f "$MOCK_SYNC_HOME/.claude/CLAUDE.md" ] || log_fail "Missing .claude/CLAUDE.md"
[ -f "$MOCK_SYNC_HOME/.codex/AGENTS.md" ] || log_fail "Missing .codex/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.gemini/GEMINI.md" ] || log_fail "Missing .gemini/GEMINI.md"
[ -f "$MOCK_SYNC_HOME/.config/nvim/AGENTS.md" ] || log_fail "Missing .config/nvim/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.config/zed/prompts/AGENTS.md" ] || log_fail "Missing .config/zed/prompts/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.antigravity-ide/User/prompts/AGENTS.md" ] || log_fail "Missing .antigravity-ide/User/prompts/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.config/Code/User/prompts/AGENTS.md" ] || log_fail "Missing .config/Code/User/prompts/AGENTS.md"
grep -Fq "AI Agent Guidelines" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing header"
grep -Fq "ponytail" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing ponytail rule"
grep -Fq "agent-memory-bootstrap" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing memory bootstrap rule"
grep -Fq "Mandatory Agent Memory protocol" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing mandatory memory protocol"
grep -Fq "Mandatory Agent Memory protocol" "$MOCK_SYNC_HOME/.codex/AGENTS.md" || log_fail "AGENTS.md missing mandatory memory protocol"
grep -Fq "Mandatory Agent Memory protocol" "$MOCK_SYNC_HOME/.gemini/GEMINI.md" || log_fail "GEMINI.md missing mandatory memory protocol"
grep -Fq "repo-first-implementation" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing repo-first workflow rule"
grep -Fq "<!-- managed-by: Aethries/dotfiles ai-skills -->" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing ownership marker"

log_ok "sync-editors.sh links skills and exports editor rules automatically"

echo
log_ok "All AI Skills test assertions passed successfully!"
