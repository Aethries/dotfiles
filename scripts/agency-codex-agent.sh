#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${AGENCY_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/agency-common.sh"

ROLE="${1:-}"
TASK="${AGENCY_TASK:-}"

if [ -z "$ROLE" ] || [ -z "$TASK" ]; then
    echo "Usage: $0 <agency-role>" >&2
    exit 2
fi

model=""
reasoning="medium"
sandbox="workspace-write"
role_instruction=""

case "$ROLE" in
    think-terra-high)
        model="$AGENCY_MODEL_THINK_TERRA"
        reasoning="high"
        sandbox="read-only"
        role_instruction="You are a planning-only analyst. Do not edit, create, delete, commit, push, or merge files. Inspect the worktree and return a concrete implementation plan, risks, validation matrix, and stop conditions."
        ;;
    think-terra-xhigh)
        model="$AGENCY_MODEL_THINK_TERRA"
        reasoning="xhigh"
        sandbox="read-only"
        role_instruction="You are a planning-only analyst. Do not edit, create, delete, commit, push, or merge files. Produce a rigorous implementation plan with explicit contracts, decision triggers, tests, rollback, and definition of done."
        ;;
    think-sol)
        model="$AGENCY_MODEL_THINK_SOL"
        reasoning="high"
        sandbox="read-only"
        role_instruction="You are a planning-only reviewer. Do not edit, create, delete, commit, push, or merge files. Analyze the request and return actionable decisions and a minimal safe plan."
        ;;
    implement-luna-xhigh)
        model="$AGENCY_MODEL_IMPLEMENT_LUNA"
        reasoning="xhigh"
        role_instruction="You are the primary implementation agent. Make the requested changes in this Agency worktree, preserve unrelated edits, run proportionate validation, and report remaining limitations. Do not commit, push, or merge unless the task explicitly asks."
        ;;
    implement-gemini-flash-high)
        model="$AGENCY_MODEL_IMPLEMENT_GEMINI_HIGH"
        reasoning="high"
        role_instruction="You are an implementation agent. Make the requested changes in this Agency worktree, keep the diff scoped, and run relevant checks. Do not commit, push, or merge unless explicitly requested."
        ;;
    implement-gemini-flash-medium)
        model="$AGENCY_MODEL_IMPLEMENT_GEMINI_MEDIUM"
        reasoning="medium"
        role_instruction="You are a focused implementation agent. Make only the requested changes in this Agency worktree, verify them, and stop when the definition of done is met. Do not commit, push, or merge unless explicitly requested."
        ;;
    *)
        echo "Unknown Agency role: $ROLE" >&2
        exit 2
        ;;
esac

require_ninerouter_key

WORKTREE_ROOT="$(pwd -P)"
PROMPT="$role_instruction

Repository root: $REPO_ROOT
Agency worktree: $WORKTREE_ROOT

Task:
$TASK"

exec codex exec \
    -C "$WORKTREE_ROOT" \
    --model "$model" \
    --sandbox "$sandbox" \
    --config 'model_provider="nine_router"' \
    --config 'model_providers.nine_router.name="9Router local gateway"' \
    --config "model_providers.nine_router.base_url=\"$(agency_router_base_url)\"" \
    --config 'model_providers.nine_router.wire_api="responses"' \
    --config 'model_providers.nine_router.auth.command="ninerouter-token"' \
    --config 'model_providers.nine_router.auth.timeout_ms=5000' \
    --config 'model_providers.nine_router.auth.refresh_interval_ms=0' \
    --config 'model_providers.nine_router.request_max_retries=2' \
    --config 'model_providers.nine_router.stream_max_retries=2' \
    --config 'approval_policy="never"' \
    --config "model_reasoning_effort=\"$reasoning\"" \
    "$PROMPT"
