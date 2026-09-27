#!/usr/bin/env bash

set -euo pipefail

if ! command -v zellij >/dev/null 2>&1; then
	echo "Zellij is not installed. Falling back to plain zsh." >&2
	exec zsh
fi

# Query active/resurrectable Zellij sessions without starting a daemon
get_sessions() {
	local out
	set +e
	out="$(zellij list-sessions --short --no-formatting 2>&1)"
	local rc=$?
	set -e

	if [[ $rc -eq 0 ]]; then
		[[ -n "$out" ]] && printf '%s\n' "$out"
		return 0
	fi

	if echo "$out" | grep -qiE "(no active zellij sessions found|no sessions)"; then
		return 0
	fi

	echo "$out" >&2
	return 1
}

RAW_SESSIONS="$(get_sessions 2>/dev/null || true)"
mapfile -t SESSIONS < <(echo "$RAW_SESSIONS" | grep -v '^[[:space:]]*$' || true)

# If fzf is missing, fallback to attach latest or prompt for deliberate name
if ! command -v fzf >/dev/null 2>&1; then
	if [[ ${#SESSIONS[@]} -gt 0 ]]; then
		exec zellij attach "${SESSIONS[0]}"
	fi
	read -r -p "No Zellij sessions. Enter session name [main]: " name
	exec zellij --session "${name:-main}"
fi

HEADER="[Enter] Attach session | [Ctrl+N] New session | [Ctrl+Z] Plain shell | [Esc] Exit"

fzf_input=""
if [[ ${#SESSIONS[@]} -gt 0 ]]; then
	fzf_input="$(printf '%s\n' "${SESSIONS[@]}")"
fi

set +e
fzf_out="$(printf '%s' "$fzf_input" | fzf \
	--height=100% \
	--layout=reverse \
	--prompt="⚡ Zellij Session: " \
	--header="$HEADER" \
	--border=rounded \
	--print-query \
	--expect=ctrl-n,ctrl-z)"
fzf_rc=$?
set -e

# User cancelled with Esc / Ctrl+C
if [[ $fzf_rc -eq 130 ]]; then
	exit 0
fi

query="$(echo "$fzf_out" | sed -n '1p')"
key="$(echo "$fzf_out" | sed -n '2p')"
selection="$(echo "$fzf_out" | sed -n '3p')"

case "$key" in
	ctrl-z)
		exec zsh
		;;
	ctrl-n)
		new_name="$query"
		if [[ -z "$new_name" ]]; then
			read -r -p "Enter name for new session: " new_name
		fi
		if [[ -n "$new_name" ]]; then
			exec zellij --session "$new_name"
		fi
		exit 0
		;;
	*)
		if [[ -n "$selection" ]]; then
			exec zellij attach "$selection"
		elif [[ -n "$query" ]]; then
			# Check if query matches an existing session
			for s in "${SESSIONS[@]}"; do
				if [[ "$s" == "$query" ]]; then
					exec zellij attach "$s"
				fi
			done
			exec zellij --session "$query"
		else
			# No selection & no query:
			if [[ ${#SESSIONS[@]} -eq 0 ]]; then
				read -r -p "No Zellij sessions. Enter session name [main]: " name
				exec zellij --session "${name:-main}"
			fi
			exit 0
		fi
		;;
esac
