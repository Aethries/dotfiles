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
[ -L "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "Failed to link ponytail to codex"

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

# Test 2.7: sync command
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" sync >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "sync command failed to link gemini ponytail"
[ -L "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "sync command failed to link codex ponytail"
[ -L "$MOCK_HOME/.claude/skills/ponytail" ] || log_fail "sync command failed to link claude ponytail"
[ -L "$MOCK_HOME/.gemini/config/skills/junior-coding-agent" ] || log_fail "sync command failed to link gemini junior-coding-agent"
[ -L "$MOCK_HOME/.codex/skills/junior-coding-agent" ] || log_fail "sync command failed to link codex junior-coding-agent"
[ -L "$MOCK_HOME/.claude/skills/junior-coding-agent" ] || log_fail "sync command failed to link claude junior-coding-agent"
[ -L "$MOCK_HOME/.gemini/config/skills/release-notes" ] || log_fail "sync command failed to link gemini release-notes"
[ -L "$MOCK_HOME/.codex/skills/release-notes" ] || log_fail "sync command failed to link codex release-notes"
[ -L "$MOCK_HOME/.claude/skills/release-notes" ] || log_fail "sync command failed to link claude release-notes"
[ -L "$MOCK_HOME/.gemini/config/skills/caveman" ] || log_fail "sync command failed to link gemini caveman"
[ -L "$MOCK_HOME/.codex/skills/caveman" ] || log_fail "sync command failed to link codex caveman"
[ -L "$MOCK_HOME/.claude/skills/caveman" ] || log_fail "sync command failed to link claude caveman"
[ -L "$MOCK_HOME/.gemini/config/skills/rtk" ] || log_fail "sync command failed to link gemini rtk"
[ -L "$MOCK_HOME/.codex/skills/rtk" ] || log_fail "sync command failed to link codex rtk"
[ -L "$MOCK_HOME/.claude/skills/rtk" ] || log_fail "sync command failed to link claude rtk"
log_ok "ai-skills.sh sync synchronizes canonical skills across all agents"

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
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/junior-coding-agent" ] || log_fail "sync-editors.sh did not link junior-coding-agent skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/junior-coding-agent" ] || log_fail "sync-editors.sh did not link codex junior-coding-agent skill"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/release-notes" ] || log_fail "sync-editors.sh did not link release-notes skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/release-notes" ] || log_fail "sync-editors.sh did not link codex release-notes skill"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/caveman" ] || log_fail "sync-editors.sh did not link caveman skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/caveman" ] || log_fail "sync-editors.sh did not link codex caveman skill"
[ -L "$MOCK_SYNC_HOME/.gemini/config/skills/rtk" ] || log_fail "sync-editors.sh did not link rtk skill"
[ -L "$MOCK_SYNC_HOME/.codex/skills/rtk" ] || log_fail "sync-editors.sh did not link codex rtk skill"
[ -L "$MOCK_SYNC_HOME/.claude/skills/rtk" ] || log_fail "sync-editors.sh did not link claude rtk skill"

# Verify Editor Export Integration (CLAUDE.md, Neovim AGENTS.md, Zed AGENTS.md, VSCode/Antigravity AGENTS.md)
[ -f "$MOCK_SYNC_HOME/.claude/CLAUDE.md" ] || log_fail "Missing .claude/CLAUDE.md"
[ -f "$MOCK_SYNC_HOME/.config/nvim/AGENTS.md" ] || log_fail "Missing .config/nvim/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.config/zed/prompts/AGENTS.md" ] || log_fail "Missing .config/zed/prompts/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.antigravity-ide/User/prompts/AGENTS.md" ] || log_fail "Missing .antigravity-ide/User/prompts/AGENTS.md"
[ -f "$MOCK_SYNC_HOME/.config/Code/User/prompts/AGENTS.md" ] || log_fail "Missing .config/Code/User/prompts/AGENTS.md"
grep -Fq "AI Agent Guidelines" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing header"
grep -Fq "ponytail" "$MOCK_SYNC_HOME/.claude/CLAUDE.md" || log_fail "CLAUDE.md missing ponytail rule"

log_ok "sync-editors.sh links skills and exports editor rules automatically"

echo
log_ok "All AI Skills test assertions passed successfully!"

