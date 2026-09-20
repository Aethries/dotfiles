#!/usr/bin/env bash
# ==============================================================================
# scripts/lib/agents.sh: Multi-Agent Adapter Query & Path Resolution Subsystem
# ==============================================================================

# Determine repo root if not already defined
if [ -z "${REPO_ROOT:-}" ]; then
    _LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$_LIB_DIR/../.." && pwd)"
fi

AGENTS_JSON="${AGENTS_JSON:-$REPO_ROOT/resources/skills/_agents.json}"

get_agents_config_path() {
    echo "$AGENTS_JSON"
}

get_all_agent_ids() {
    if [ ! -f "$AGENTS_JSON" ]; then
        echo "antigravity-cli antigravity-ide codex-cli claude-code"
        return 0
    fi
    jq -r '.agents | keys[]' "$AGENTS_JSON"
}

get_agent_name() {
    local agent_id="$1"
    if [ -f "$AGENTS_JSON" ]; then
        jq -r --arg id "$agent_id" '.agents[$id].name // $id' "$AGENTS_JSON"
    else
        echo "$agent_id"
    fi
}

get_agent_binary() {
    local agent_id="$1"
    if [ -f "$AGENTS_JSON" ]; then
        jq -r --arg id "$agent_id" '.agents[$id].binary // ""' "$AGENTS_JSON"
    fi
}

get_agent_rule_file() {
    local agent_id="$1"
    if [ -f "$AGENTS_JSON" ]; then
        jq -r --arg id "$agent_id" '.agents[$id].rule_file // "RULES.md"' "$AGENTS_JSON"
    else
        echo "RULES.md"
    fi
}

resolve_agent_global_path() {
    local agent_id="$1"
    local base_home="${2:-${TARGET_HOME:-$HOME}}"

    # 1. Environment variable override check
    case "$agent_id" in
        antigravity-cli)
            if [ -n "${GEMINI_CONFIG_DIR:-}" ]; then
                echo "$GEMINI_CONFIG_DIR/skills"
                return 0
            fi
            ;;
        antigravity-ide)
            if [ -n "${ANTIGRAVITY_CONFIG_DIR:-}" ]; then
                echo "$ANTIGRAVITY_CONFIG_DIR/skills"
                return 0
            fi
            ;;
        codex-cli)
            if [ -n "${CODEX_HOME:-}" ]; then
                echo "$CODEX_HOME/skills"
                return 0
            fi
            ;;
        codex-gui)
            if [ -n "${CODEX_HOME:-}" ]; then
                echo "$CODEX_HOME/gui/skills"
                return 0
            fi
            ;;
        claude-code)
            if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
                echo "$CLAUDE_CONFIG_DIR/skills"
                return 0
            fi
            ;;
    esac

    # 2. Configured template resolution from _agents.json
    if [ -f "$AGENTS_JSON" ]; then
        local raw_path
        raw_path="$(jq -r --arg id "$agent_id" '.agents[$id].global_path // ""' "$AGENTS_JSON")"
        if [ -n "$raw_path" ] && [ "$raw_path" != "null" ]; then
            # Replace literal $HOME or ~ with base_home
            raw_path="${raw_path//\$HOME/$base_home}"
            raw_path="${raw_path/#\~/$base_home}"
            echo "$raw_path"
            return 0
        fi
    fi

    # 3. Fallback defaults
    case "$agent_id" in
        antigravity-cli) echo "$base_home/.gemini/config/skills" ;;
        antigravity-ide) echo "$base_home/.gemini/antigravity-cli/skills" ;;
        antigravity-desktop) echo "$base_home/.gemini/skills" ;;
        codex-cli) echo "$base_home/.codex/skills" ;;
        codex-gui) echo "$base_home/.codex/gui/skills" ;;
        claude-code) echo "$base_home/.claude/skills" ;;
        *) echo "$base_home/.$agent_id/skills" ;;
    esac
}

resolve_agent_project_path() {
    local agent_id="$1"
    local proj_root="${2:-${PROJECT_ROOT:-$PWD}}"

    if [ -f "$AGENTS_JSON" ]; then
        local rel_path
        rel_path="$(jq -r --arg id "$agent_id" '.agents[$id].project_path // ""' "$AGENTS_JSON")"
        if [ -n "$rel_path" ] && [ "$rel_path" != "null" ]; then
            echo "$proj_root/$rel_path"
            return 0
        fi
    fi

    echo "$proj_root/.agents/skills"
}

map_target_to_agent_ids() {
    local target="$1"
    case "$target" in
        all)
            # Default active ecosystem targets
            echo "antigravity-cli antigravity-ide codex-cli claude-code"
            ;;
        gemini|antigravity)
            echo "antigravity-cli antigravity-ide"
            ;;
        gemini-cli|antigravity-cli)
            echo "antigravity-cli"
            ;;
        antigravity-ide)
            echo "antigravity-ide"
            ;;
        antigravity-desktop)
            echo "antigravity-desktop"
            ;;
        codex|codex-cli)
            echo "codex-cli"
            ;;
        codex-gui)
            echo "codex-gui"
            ;;
        claude|claude-code)
            echo "claude-code"
            ;;
        *)
            # Check if target is a known agent ID
            local known_ids
            known_ids="$(get_all_agent_ids)"
            if echo "$known_ids" | grep -qw "$target"; then
                echo "$target"
            else
                echo ""
            fi
            ;;
    esac
}
