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
grep -Fq "Safety & Quality Guardrails" "$SKILL_FILE" || log_fail "SKILL.md missing 'Safety & Quality Guardrails'"

REF_FILE="$REPO_ROOT/resources/skills/ponytail/references/code-filter.md"
[ -f "$REF_FILE" ] || log_fail "Missing $REF_FILE"
grep -Fq "Rung 1: YAGNI Check" "$REF_FILE" || log_fail "Missing Rung 1 in code-filter.md"
grep -Fq "Rung 6: Minimum Working Code" "$REF_FILE" || log_fail "Missing Rung 6 in code-filter.md"
grep -Fq "ponytail:" "$REF_FILE" || log_fail "Missing comment convention in code-filter.md"

log_ok "Ponytail SKILL.md and reference schemas are valid"

# ------------------------------------------------------------------------------
# 2. Test ai-skills.sh CLI in Sandbox
# ------------------------------------------------------------------------------
log_info "Testing ai-skills.sh CLI in isolated sandbox..."

AI_SKILLS_BIN="$REPO_ROOT/scripts/ai-skills.sh"
[ -x "$AI_SKILLS_BIN" ] || log_fail "ai-skills.sh is not executable"

# Test 2.1: list command
LIST_OUTPUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" list)
echo "$LIST_OUTPUT" | grep -Fq "ponytail" || log_fail "list command did not include 'ponytail'"
log_ok "ai-skills.sh list outputs available skills"

# Test 2.2: preview command
PREVIEW_OUTPUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" preview ponytail)
echo "$PREVIEW_OUTPUT" | grep -Fq "name: ponytail" || log_fail "preview command did not display skill content"
log_ok "ai-skills.sh preview works"

# Test 2.3: add command (gemini and codex)
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target gemini >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "Failed to link ponytail to gemini"
[ -f "$MOCK_HOME/.gemini/config/skills/ponytail/SKILL.md" ] || log_fail "Linked skill file not accessible"

HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target codex >/dev/null
[ -L "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "Failed to link ponytail to codex"

# Test 2.4: add command (project target)
(cd "$MOCK_PROJECT" && HOME="$MOCK_HOME" "$AI_SKILLS_BIN" add ponytail --target project >/dev/null)
[ -L "$MOCK_PROJECT/.agents/skills/ponytail" ] || log_fail "Failed to link ponytail to project .agents/skills"
log_ok "ai-skills.sh add links correctly across gemini, codex, and project"

# Test 2.5: export command
EXPORT_OUTPUT=$(HOME="$MOCK_HOME" "$AI_SKILLS_BIN" export ponytail)
echo "$EXPORT_OUTPUT" | grep -Fq "Ponytail Anti-Overengineering Rule Snippet" || log_fail "export failed"
log_ok "ai-skills.sh export produces markdown snippet"

# Test 2.6: remove command
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove ponytail --target gemini >/dev/null
[ ! -e "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "remove command failed to unlink gemini target"

HOME="$MOCK_HOME" "$AI_SKILLS_BIN" remove ponytail --target all >/dev/null
[ ! -e "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "remove command failed to unlink codex target"
log_ok "ai-skills.sh remove unlinks targets cleanly"

# Test 2.7: sync command
HOME="$MOCK_HOME" "$AI_SKILLS_BIN" sync >/dev/null
[ -L "$MOCK_HOME/.gemini/config/skills/ponytail" ] || log_fail "sync command failed to link gemini target"
[ -L "$MOCK_HOME/.codex/skills/ponytail" ] || log_fail "sync command failed to link codex target"
log_ok "ai-skills.sh sync synchronizes canonical skills"

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
log_ok "sync-editors.sh links skills automatically"

echo
log_ok "All AI Skills test assertions passed successfully!"
