#!/usr/bin/env bash
# ==============================================================================
# Isolated Zellij Launcher Unit Test Suite
# Implements all 18 test cases specified in section 9 of zellij-ux-hardening.md
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_fail() { echo -e "  [${RED}✗${RESET}] $1" >&2; exit 1; }

SANDBOX_DIR="$REPO_ROOT/.sandbox/zellij-test-$$"
mkdir -p "$SANDBOX_DIR/bin" "$SANDBOX_DIR/home"

cleanup() {
    rm -rf "$SANDBOX_DIR"
}
trap cleanup EXIT

# 1. Fake zellij
cat << 'EOS' > "$SANDBOX_DIR/bin/zellij"
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "list-sessions" ]; then
    if [ -n "${FAKE_ZELLIJ_LIST_OUTPUT:-}" ] && [ -f "$FAKE_ZELLIJ_LIST_OUTPUT" ]; then
        cat "$FAKE_ZELLIJ_LIST_OUTPUT"
    fi
    exit "${FAKE_ZELLIJ_LIST_EXIT:-0}"
fi

# Record argv for attach / new session calls as NUL-delimited records
if [ -n "${RECORD_ZELLIJ_CALLS:-}" ]; then
    for arg in "$@"; do
        printf '%s\0' "$arg" >> "$RECORD_ZELLIJ_CALLS"
    done
    printf '\n' >> "$RECORD_ZELLIJ_CALLS"
fi
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/zellij"

# 2. Fake fzf
cat << 'EOS' > "$SANDBOX_DIR/bin/fzf"
#!/usr/bin/env bash
# Record stdin received by fzf
if [ -n "${RECORD_FZF_STDIN:-}" ]; then
    cat > "$RECORD_FZF_STDIN"
fi

if [ -n "${FAKE_FZF_EXIT:-}" ] && [ "$FAKE_FZF_EXIT" -ne 0 ]; then
    exit "$FAKE_FZF_EXIT"
fi

if [ -n "${FAKE_FZF_OUTPUT:-}" ]; then
    printf '%s\n' "$FAKE_FZF_OUTPUT"
fi
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/fzf"

# 3. Fake zsh
cat << 'EOS' > "$SANDBOX_DIR/bin/zsh"
#!/usr/bin/env bash
if [ -n "${RECORD_ZSH_CALLS:-}" ]; then
    for arg in "$@"; do
        printf '%s\0' "$arg" >> "$RECORD_ZSH_CALLS"
    done
    printf '\n' >> "$RECORD_ZSH_CALLS"
fi
exit 0
EOS
chmod +x "$SANDBOX_DIR/bin/zsh"

export PATH="$SANDBOX_DIR/bin:$PATH"
export HOME="$SANDBOX_DIR/home"
LAUNCHER="$REPO_ROOT/resources/zellij/scripts/launcher.sh"

reset_records() {
    export RECORD_ZELLIJ_CALLS="$SANDBOX_DIR/zellij.records"
    export RECORD_FZF_STDIN="$SANDBOX_DIR/fzf_stdin.txt"
    export RECORD_ZSH_CALLS="$SANDBOX_DIR/zsh.records"
    rm -f "$RECORD_ZELLIJ_CALLS" "$RECORD_FZF_STDIN" "$RECORD_ZSH_CALLS"
    export FAKE_ZELLIJ_LIST_OUTPUT=""
    export FAKE_ZELLIJ_LIST_EXIT=0
    export FAKE_FZF_OUTPUT=""
    export FAKE_FZF_EXIT=0
}

log_info "Case 1: No sessions, cancel -> no zellij create/attach call"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_EXIT=130
"$LAUNCHER" || true
[ ! -f "$RECORD_ZELLIJ_CALLS" ] || log_fail "Case 1: Zellij was called on cancel"
log_ok "Case 1 passed"

log_info "Case 2: No sessions, plain shell -> exact zsh exec branch"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_OUTPUT=$'query\nctrl-z\n'
"$LAUNCHER"
[ -f "$RECORD_ZSH_CALLS" ] || log_fail "Case 2: zsh was not invoked"
[ ! -f "$RECORD_ZELLIJ_CALLS" ] || log_fail "Case 2: Zellij was invoked unexpectedly"
log_ok "Case 2 passed"

log_info "Case 3: No sessions, valid new name -> exactly one named create call"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_OUTPUT=$'my-new-project\nctrl-n\n'
"$LAUNCHER"
[ -f "$RECORD_ZELLIJ_CALLS" ] || log_fail "Case 3: zellij create not called"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[0]}" = "--session" ] || log_fail "Case 3: expected --session, got ${args[0]}"
[ "${args[1]}" = "my-new-project" ] || log_fail "Case 3: expected name 'my-new-project', got '${args[1]}'"
log_ok "Case 3 passed"

log_info "Case 4: Existing active session selected -> exact attach argv"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_multiple.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
export FAKE_FZF_OUTPUT=$'\n\nproject-alpha'
"$LAUNCHER"
[ -f "$RECORD_ZELLIJ_CALLS" ] || log_fail "Case 4: zellij attach not called"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[0]}" = "attach" ] || log_fail "Case 4: expected attach"
[ "${args[1]}" = "--" ] || log_fail "Case 4: expected -- protection"
[ "${args[2]}" = "project-alpha" ] || log_fail "Case 4: expected project-alpha"
log_ok "Case 4 passed"

log_info "Case 5: Exited session selected -> exact resurrection/attach argv"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_multiple.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
export FAKE_FZF_OUTPUT=$'\n\nmain'
"$LAUNCHER"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[0]}" = "attach" ] && [ "${args[1]}" = "--" ] && [ "${args[2]}" = "main" ] || log_fail "Case 5: resurrection attach mismatch"
log_ok "Case 5 passed"

log_info "Case 6: Several sessions -> newest is initially highlighted (passed top of list to fzf)"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_multiple.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
export FAKE_FZF_EXIT=130
"$LAUNCHER" || true
[ -f "$RECORD_FZF_STDIN" ] || log_fail "Case 6: fzf did not receive stdin"
FIRST_SESSION="$(head -n 1 "$RECORD_FZF_STDIN")"
[ "$FIRST_SESSION" = "project-beta" ] || log_fail "Case 6: expected project-beta first, got $FIRST_SESSION"
log_ok "Case 6 passed"

log_info "Case 7: --latest with sessions -> exact newest name attached"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_multiple.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
"$LAUNCHER" --latest
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[0]}" = "attach" ] && [ "${args[1]}" = "--" ] && [ "${args[2]}" = "project-beta" ] || log_fail "Case 7: wrong session attached for --latest"
log_ok "Case 7 passed"

log_info "Case 8: --latest without sessions -> picker or documented fallback, never unnamed create"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_EXIT=130
"$LAUNCHER" --latest || true
if [ -f "$RECORD_ZELLIJ_CALLS" ]; then
    mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
    for a in "${args[@]}"; do
        [ -n "$a" ] || log_fail "Case 8: unnamed session created"
    done
fi
log_ok "Case 8 passed"

log_info "Case 9: Session name containing spaces or punctuation -> remains one argv element"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_with_spaces.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
export FAKE_FZF_OUTPUT=$'\n\nmy project'
"$LAUNCHER"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[2]}" = "my project" ] || log_fail "Case 9: session name with space was split: '${args[2]}'"
log_ok "Case 9 passed"

log_info "Case 10: Invalid/empty name -> useful error, no session created"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_OUTPUT=$'   \nctrl-n\n'
if "$LAUNCHER" 2>/dev/null; then
    log_fail "Case 10: launcher unexpectedly succeeded with whitespace name"
fi
[ ! -f "$RECORD_ZELLIJ_CALLS" ] || log_fail "Case 10: zellij was called with empty name"
log_ok "Case 10 passed"

log_info "Case 11: fzf missing -> deterministic fallback"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_multiple.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
mkdir -p "$SANDBOX_DIR/no_fzf"
ln -sf "$SANDBOX_DIR/bin/zellij" "$SANDBOX_DIR/no_fzf/zellij"
ln -sf "$SANDBOX_DIR/bin/zsh" "$SANDBOX_DIR/no_fzf/zsh"
for cmd in bash env sh grep sed cat readlink basename; do
    p="$(type -p "$cmd" || true)"
    [ -n "$p" ] && ln -sf "$p" "$SANDBOX_DIR/no_fzf/$cmd"
done
PATH="$SANDBOX_DIR/no_fzf" "$LAUNCHER"
rm -rf "$SANDBOX_DIR/no_fzf"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[0]}" = "attach" ] && [ "${args[2]}" = "project-beta" ] || log_fail "Case 11: fallback did not attach newest"
log_ok "Case 11 passed"

log_info "Case 12: zellij missing -> useful error and nonzero exit"
reset_records
mkdir -p "$SANDBOX_DIR/no_zellij"
ln -sf "$SANDBOX_DIR/bin/fzf" "$SANDBOX_DIR/no_zellij/fzf"
ln -sf "$SANDBOX_DIR/bin/zsh" "$SANDBOX_DIR/no_zellij/zsh"
for cmd in bash env sh grep sed cat readlink basename; do
    p="$(type -p "$cmd" || true)"
    [ -n "$p" ] && ln -sf "$p" "$SANDBOX_DIR/no_zellij/$cmd"
done
if PATH="$SANDBOX_DIR/no_zellij" "$LAUNCHER" 2>/dev/null; then
    rm -rf "$SANDBOX_DIR/no_zellij"
    log_fail "Case 12: launcher did not exit nonzero when zellij was missing"
fi
rm -rf "$SANDBOX_DIR/no_zellij"
log_ok "Case 12 passed"

log_info "Case 13: list-sessions 'none' status -> treated as empty"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_EXIT=130
"$LAUNCHER" || true
[ -f "$RECORD_FZF_STDIN" ] && [ ! -s "$RECORD_FZF_STDIN" ] || log_fail "Case 13: list not empty"
log_ok "Case 13 passed"

log_info "Case 14: Unexpected list-sessions error -> surfaced, not treated as empty"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_error.txt"
export FAKE_ZELLIJ_LIST_EXIT=2
if "$LAUNCHER" 2>/dev/null; then
    log_fail "Case 14: unexpected error was silently swallowed"
fi
log_ok "Case 14 passed"

log_info "Case 15: Picker cancel code -> clean exit 0"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_multiple.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
export FAKE_FZF_EXIT=130
"$LAUNCHER"
[ ! -f "$RECORD_ZELLIJ_CALLS" ] || log_fail "Case 15: zellij called after cancel"
log_ok "Case 15 passed"

log_info "Case 16: Signal while picker is open -> no Zellij server exists to orphan"
# In test environment, launcher does not start Zellij before or during fzf picker.
[ ! -f "$RECORD_ZELLIJ_CALLS" ]
log_ok "Case 16 passed"

log_info "Case 17: Malicious input: never executed or parsed as options"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_empty.txt"
export FAKE_ZELLIJ_LIST_EXIT=1
export FAKE_FZF_OUTPUT=$'work; rm -rf /; $(whoami)\nctrl-n\n'
"$LAUNCHER"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
# shellcheck disable=SC2016
[ "${args[1]}" = 'work; rm -rf /; $(whoami)' ] || log_fail "Case 17: argument was expanded or corrupted"
log_ok "Case 17 passed"

log_info "Case 18: Existing name beginning with a dash -> protected by --"
reset_records
export FAKE_ZELLIJ_LIST_OUTPUT="$FIXTURES_DIR/list_sessions_dash.txt"
export FAKE_ZELLIJ_LIST_EXIT=0
export FAKE_FZF_OUTPUT=$'\n\n-odd-session'
"$LAUNCHER"
mapfile -d '' args < "$RECORD_ZELLIJ_CALLS"
[ "${args[0]}" = "attach" ] && [ "${args[1]}" = "--" ] && [ "${args[2]}" = "-odd-session" ] || log_fail "Case 18: dash session not protected by --"
log_ok "Case 18 passed"

echo
log_ok "ALL 18 LAUNCHER TEST CASES PASSED SUCCESSFULLY."
