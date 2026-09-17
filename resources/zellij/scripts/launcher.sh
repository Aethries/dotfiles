#!/usr/bin/env bash
# ==============================================================================
# Zellij Pre-Session Picker & Launcher
# Prevents unwanted temporary sessions and provides deterministic workspace startup.
# ==============================================================================

set -euo pipefail

# Mode configuration
MODE="picker"
FALLBACK_ON_EMPTY_LATEST="picker" # "picker" or a stable name such as "main"

for arg in "$@"; do
    case "$arg" in
        --latest)
            MODE="latest"
            ;;
        --help|-h)
            cat << 'EOS'
Usage: launcher.sh [OPTIONS]

Options:
  --latest    Attach directly to the newest created session (or launch picker if none)
  -h, --help  Show this help message
EOS
            exit 0
            ;;
        *)
            echo "launcher: unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

# 1. Dependency check
if ! command -v zellij >/dev/null 2>&1; then
    echo "Error: zellij is not installed or not in PATH." >&2
    exit 127
fi

# 2. Session name validator
validate_session_name() {
    local name="$1"
    if [ -z "$name" ] || [ -z "${name//[[:space:]]/}" ]; then
        echo "Error: Session name cannot be empty." >&2
        return 1
    fi
    if [[ "$name" =~ ^- ]]; then
        echo "Error: Session name cannot begin with a dash ('-')." >&2
        return 1
    fi
    if [[ "$name" =~ [[:cntrl:]] ]]; then
        echo "Error: Session name contains invalid control characters." >&2
        return 1
    fi
    return 0
}

# 3. Obtain existing sessions without starting a Zellij server
# Uses zellij list-sessions --short --no-formatting
get_sessions() {
    local out rc
    out=""
    rc=0
    # Capture stdout and stderr
    set +e
    out="$(zellij list-sessions --short --no-formatting 2>&1)"
    rc=$?
    set -e

    if [ $rc -eq 0 ]; then
        # Sessions exist; return non-empty lines
        # zellij list-sessions lists the newest session first by creation order
        if [ -n "$out" ]; then
            printf '%s\n' "$out"
        fi
        return 0
    fi

    # Check for documented "no sessions" exit
    if echo "$out" | grep -qiE "(no active zellij sessions found|no sessions)"; then
        return 0
    fi

    # Unexpected error
    echo "Error querying Zellij sessions: $out" >&2
    return 1
}

# Collect sessions into an array
RAW_SESSIONS=""
if ! RAW_SESSIONS="$(get_sessions)"; then
    exit 1
fi

mapfile -t SESSIONS <<< "$RAW_SESSIONS"
CLEAN_SESSIONS=()
for s in "${SESSIONS[@]}"; do
    [ -n "$s" ] && CLEAN_SESSIONS+=("$s")
done
SESSIONS=("${CLEAN_SESSIONS[@]}")

# 4. Handle --latest mode
if [ "$MODE" = "latest" ]; then
    if [ ${#SESSIONS[@]} -gt 0 ]; then
        # Newest session is the first element
        exec zellij attach -- "${SESSIONS[0]}"
    fi
    if [ "$FALLBACK_ON_EMPTY_LATEST" = "picker" ]; then
        MODE="picker"
    else
        validate_session_name "$FALLBACK_ON_EMPTY_LATEST"
        exec zellij --session "$FALLBACK_ON_EMPTY_LATEST"
    fi
fi

# 5. Check fzf presence
if ! command -v fzf >/dev/null 2>&1; then
    echo "Notice: fzf is not installed. Using deterministic fallback." >&2
    if [ ${#SESSIONS[@]} -gt 0 ]; then
        echo "Attaching newest session: ${SESSIONS[0]}" >&2
        exec zellij attach -- "${SESSIONS[0]}"
    fi
    echo "No sessions exist. Starting plain shell." >&2
    exec zsh
fi

# 6. Interactive FZF picker flow
HEADER="[Enter] Attach/Resurrect | [Ctrl+N] New Session | [Ctrl+Z] Plain Shell | [Ctrl+L] Latest | [Esc] Cancel
(Note: Shared multi-client sessions use smallest window size. Ctrl+Shift+S then Ctrl+X disconnects other clients)"

run_picker() {
    local fzf_input=""
    if [ ${#SESSIONS[@]} -gt 0 ]; then
        fzf_input="$(printf '%s\n' "${SESSIONS[@]}")"
    fi

    local fzf_out
    set +e
    fzf_out="$(printf '%s' "$fzf_input" | fzf \
        --height=100% \
        --layout=reverse \
        --prompt="⚡ Zellij Session: " \
        --header="$HEADER" \
        --border=rounded \
        --print-query \
        --expect=ctrl-n,ctrl-z,ctrl-l \
        --exit-0)"
    local fzf_rc=$?
    set -e

    # Exit cleanly if cancelled (Esc / Ctrl+C / exit code 130 or 1 when empty)
    if [ $fzf_rc -eq 130 ]; then
        exit 0
    fi

    local query key selection
    query="$(echo "$fzf_out" | sed -n '1p')"
    key="$(echo "$fzf_out" | sed -n '2p')"
    selection="$(echo "$fzf_out" | sed -n '3p')"

    if [ $fzf_rc -ne 0 ] && [ -z "$key" ] && [ -z "$query" ]; then
        exit 0
    fi

    case "$key" in
        ctrl-z)
            # Plain shell requested
            exec zsh
            ;;
        ctrl-l)
            # Latest session
            if [ ${#SESSIONS[@]} -gt 0 ]; then
                exec zellij attach -- "${SESSIONS[0]}"
            fi
            echo "No active sessions exist." >&2
            exec zsh
            ;;
        ctrl-n)
            # Create named session
            local new_name="$query"
            if [ -z "$new_name" ]; then
                read -r -p "Enter name for new session: " new_name
            fi
            if validate_session_name "$new_name"; then
                exec zellij --session "$new_name"
            fi
            exit 1
            ;;
        *)
            # Enter key pressed
            if [ -n "$selection" ]; then
                # An existing session was selected
                exec zellij attach -- "$selection"
            elif [ -n "$query" ]; then
                # Query was entered and Enter pressed
                # Check if it matches an existing session
                for s in "${SESSIONS[@]}"; do
                    if [ "$s" = "$query" ]; then
                        exec zellij attach -- "$s"
                    fi
                done
                # Otherwise, treat as new session name
                if validate_session_name "$query"; then
                    exec zellij --session "$query"
                fi
                exit 1
            else
                # Empty enter on empty list -> exit cleanly
                exit 0
            fi
            ;;
    esac
}

run_picker
