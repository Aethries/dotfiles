#!/usr/bin/env bash
# ============================================================================== 
# Isolated ai-skills add selector and install-flow tests
# ============================================================================== 

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AI_SKILLS_BIN="$REPO_ROOT/scripts/ai-skills.sh"
SKILLS_SOURCE="$REPO_ROOT/resources/skills"
ORIGINAL_PATH="$PATH"
SANDBOX_DIR="$(mktemp -d -t dotfiles-ai-skills-add-XXXXXX)"
MOCK_HOME="$SANDBOX_DIR/home"
MOCK_PROJECT="$SANDBOX_DIR/project"
MOCK_BIN="$SANDBOX_DIR/bin"
FAKE_FZF_LOG="$SANDBOX_DIR/fzf.log"
FAKE_FZF_INPUT="$SANDBOX_DIR/fzf.input"
NO_FZF_PATH=""
NO_FZF_BIN="$SANDBOX_DIR/no-fzf-bin"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

mkdir -p "$MOCK_HOME" "$MOCK_PROJECT/.git" "$MOCK_BIN" "$NO_FZF_BIN"

# Build a temporary PATH containing every original executable except fzf.
IFS=: read -r -a path_entries <<< "$ORIGINAL_PATH"
for path_entry in "${path_entries[@]}"; do
    [ -d "$path_entry" ] || continue
    for candidate in "$path_entry"/*; do
        [ -x "$candidate" ] || continue
        candidate_name="$(basename "$candidate")"
        [ "$candidate_name" = fzf ] && continue
        [ -e "$NO_FZF_BIN/$candidate_name" ] || ln -s "$candidate" "$NO_FZF_BIN/$candidate_name"
    done
done
NO_FZF_PATH="$NO_FZF_BIN"

cat > "$MOCK_BIN/fzf" <<'EOF'
#!/usr/bin/env bash
cat > "$FAKE_FZF_INPUT"
printf '%s\n' "${FAKE_FZF_OUTPUT:-}"
echo "$*" >> "$FAKE_FZF_LOG"
exit "${FAKE_FZF_EXIT:-0}"
EOF
chmod +x "$MOCK_BIN/fzf"

run_ai_skills() {
    HOME="$MOCK_HOME" \
        REPO_ROOT="$REPO_ROOT" \
        SKILLS_SRC="$SKILLS_SOURCE" \
        PATH="$MOCK_BIN:$ORIGINAL_PATH" \
        "$AI_SKILLS_BIN" "$@"
}

run_ai_skills_without_fzf() {
    HOME="$MOCK_HOME" \
        REPO_ROOT="$REPO_ROOT" \
        SKILLS_SRC="$SKILLS_SOURCE" \
        PATH="$NO_FZF_PATH" \
        "$AI_SKILLS_BIN" "$@"
}

echo "[1/7] Selector emits only selected canonical skill names"
: > "$FAKE_FZF_INPUT"
: > "$FAKE_FZF_LOG"
selected_output="$({
    HOME="$MOCK_HOME" \
        REPO_ROOT="$REPO_ROOT" \
        SKILLS_SRC="$SKILLS_SOURCE" \
        PATH="$MOCK_BIN:$ORIGINAL_PATH" \
        FAKE_FZF_OUTPUT="ponytail" \
        FAKE_FZF_LOG="$FAKE_FZF_LOG" \
        FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
        bash -c 'source "$1"; select_skill_names' _ "$AI_SKILLS_BIN"
})"
[ "$selected_output" = "ponytail" ] || {
    echo "selector returned unexpected stdout: $selected_output" >&2
    exit 1
}
grep -qx 'ponytail' "$FAKE_FZF_INPUT"
if grep -q '^_' "$FAKE_FZF_INPUT"; then
    echo "selector exposed metadata entries beginning with _" >&2
    exit 1
fi

echo "[2/7] Interactive global add preserves the parsed target agent"
: > "$FAKE_FZF_LOG"
FAKE_FZF_OUTPUT=$'ponytail\nsenior-implementer' \
    FAKE_FZF_LOG="$FAKE_FZF_LOG" \
    FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
    run_ai_skills add --global codex-cli >/dev/null
[ -L "$MOCK_HOME/.codex/skills/ponytail" ]
[ -L "$MOCK_HOME/.codex/skills/senior-implementer" ]
[ ! -e "$MOCK_HOME/.claude/skills/ponytail" ]

target_home="$SANDBOX_DIR/target-home"
mkdir -p "$target_home"
FAKE_FZF_OUTPUT="ponytail" \
    HOME="$target_home" \
    REPO_ROOT="$REPO_ROOT" \
    SKILLS_SRC="$SKILLS_SOURCE" \
    PATH="$MOCK_BIN:$ORIGINAL_PATH" \
    FAKE_FZF_LOG="$FAKE_FZF_LOG" \
    FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
    "$AI_SKILLS_BIN" add --global claude-code >/dev/null
[ -L "$target_home/.claude/skills/ponytail" ]
[ ! -e "$target_home/.codex/skills/ponytail" ]

FAKE_FZF_OUTPUT="ponytail" \
    HOME="$target_home" \
    REPO_ROOT="$REPO_ROOT" \
    SKILLS_SRC="$SKILLS_SOURCE" \
    PATH="$MOCK_BIN:$ORIGINAL_PATH" \
    FAKE_FZF_LOG="$FAKE_FZF_LOG" \
    FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
    "$AI_SKILLS_BIN" add --target antigravity-cli >/dev/null
[ -L "$target_home/.gemini/config/skills/ponytail" ]
[ ! -e "$target_home/.codex/skills/ponytail" ]

echo "[3/7] Interactive project add creates physical copies and lockfile entries"
FAKE_FZF_OUTPUT=$'ponytail\nsenior-implementer' \
    FAKE_FZF_LOG="$FAKE_FZF_LOG" \
    FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
    run_ai_skills add --project "$MOCK_PROJECT" >/dev/null
[ -d "$MOCK_PROJECT/.agents/skills/ponytail" ]
[ ! -L "$MOCK_PROJECT/.agents/skills/ponytail" ]
[ -f "$MOCK_PROJECT/.agents/skills/ponytail/SKILL.md" ]
[ -f "$MOCK_PROJECT/.agent-skills.lock.json" ]
jq -e '.skills.ponytail.targets | length >= 1' "$MOCK_PROJECT/.agent-skills.lock.json" >/dev/null

echo "[4/7] Explicit add remains non-interactive"
: > "$FAKE_FZF_LOG"
run_ai_skills add ponytail --global codex-cli >/dev/null
[ ! -s "$FAKE_FZF_LOG" ]

echo "[5/7] Existing interactive flow still presents the action menu"
interactive_home="$SANDBOX_DIR/interactive-home"
mkdir -p "$interactive_home"
printf '1\n' | HOME="$interactive_home" \
    REPO_ROOT="$REPO_ROOT" \
    SKILLS_SRC="$SKILLS_SOURCE" \
    PATH="$MOCK_BIN:$ORIGINAL_PATH" \
    FAKE_FZF_OUTPUT="ponytail" \
    FAKE_FZF_LOG="$FAKE_FZF_LOG" \
    FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
    "$AI_SKILLS_BIN" interactive >/dev/null
[ -L "$interactive_home/.gemini/config/skills/ponytail" ]
[ -L "$interactive_home/.codex/skills/ponytail" ]

echo "[6/7] Fzf cancel exits successfully without installation or Missing skill name"
cancel_home="$SANDBOX_DIR/cancel-home"
mkdir -p "$cancel_home"
cancel_output="$({
    HOME="$cancel_home" \
        REPO_ROOT="$REPO_ROOT" \
        SKILLS_SRC="$SKILLS_SOURCE" \
        PATH="$MOCK_BIN:$ORIGINAL_PATH" \
        FAKE_FZF_OUTPUT="" \
        FAKE_FZF_EXIT=130 \
        FAKE_FZF_LOG="$FAKE_FZF_LOG" \
        FAKE_FZF_INPUT="$FAKE_FZF_INPUT" \
        "$AI_SKILLS_BIN" add --global codex-cli
})"
if grep -Fq "Missing skill name" <<< "$cancel_output"; then
    echo "cancel path reported a missing skill name" >&2
    exit 1
fi
[ ! -e "$cancel_home/.codex/skills" ]

echo "[7/7] Numbered fallback ignores invalid choices without mutation"
fallback_home="$SANDBOX_DIR/fallback-home"
mkdir -p "$fallback_home"
invalid_output="$({
    printf '999\n' | HOME="$fallback_home" \
        REPO_ROOT="$REPO_ROOT" \
        SKILLS_SRC="$SKILLS_SOURCE" \
        PATH="$NO_FZF_PATH" \
        "$AI_SKILLS_BIN" add --global codex-cli
})"
if grep -Fq "Missing skill name" <<< "$invalid_output"; then
    echo "invalid fallback selection reported a missing skill name" >&2
    exit 1
fi
[ ! -e "$fallback_home/.codex/skills" ]

printf '1\n' | HOME="$fallback_home" \
    REPO_ROOT="$REPO_ROOT" \
    SKILLS_SRC="$SKILLS_SOURCE" \
    PATH="$NO_FZF_PATH" \
    "$AI_SKILLS_BIN" add --global codex-cli >/dev/null 2>&1
find "$fallback_home/.codex/skills" -mindepth 1 -maxdepth 1 -type l -print -quit | grep -q .

echo "[✓] ai-skills add selector, target preservation, explicit mode, project copy, cancel flow, and numbered fallback passed"
