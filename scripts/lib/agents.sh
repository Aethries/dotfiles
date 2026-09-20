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

get_agent_global_primary() {
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
        raw_path="$(jq -r --arg id "$agent_id" '.agents[$id].global.primary // empty' "$AGENTS_JSON")"
        if [ -n "$raw_path" ]; then
            raw_path="${raw_path//\$HOME/$base_home}"
            raw_path="${raw_path/#\~/$base_home}"
            echo "$raw_path"
            return 0
        fi
    fi

    echo "Unknown or unconfigured agent ID: $agent_id" >&2
    return 1
}

get_agent_global_compatibility_paths() {
    local agent_id="$1"
    local base_home="${2:-${TARGET_HOME:-$HOME}}"

    if [ -f "$AGENTS_JSON" ]; then
        local compat_paths
        compat_paths="$(jq -r --arg id "$agent_id" '.agents[$id].global.compatibility[]? // empty' "$AGENTS_JSON")"
        if [ -n "$compat_paths" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                line="${line//\$HOME/$base_home}"
                line="${line/#\~/$base_home}"
                echo "$line"
            done <<< "$compat_paths"
        fi
    fi
}

get_agent_global_paths() {
    local agent_id="$1"
    local base_home="${2:-${TARGET_HOME:-$HOME}}"

    local primary
    primary="$(get_agent_global_primary "$agent_id" "$base_home")" || return 1
    local all_paths=("$primary")

    while IFS= read -r line; do
        [ -n "$line" ] && all_paths+=("$line")
    done < <(get_agent_global_compatibility_paths "$agent_id" "$base_home")

    printf '%s\n' "${all_paths[@]}" | LC_ALL=C sort -u
}

get_agent_project_primary() {
    local agent_id="$1"
    local proj_root="${2:-${PROJECT_ROOT:-$PWD}}"

    if [ -f "$AGENTS_JSON" ]; then
        local rel_path
        rel_path="$(jq -r --arg id "$agent_id" '.agents[$id].project.primary // empty' "$AGENTS_JSON")"
        if [ -n "$rel_path" ]; then
            echo "$proj_root/$rel_path"
            return 0
        fi
    fi

    echo "Unknown or unconfigured agent ID: $agent_id" >&2
    return 1
}

get_agent_project_compatibility_paths() {
    local agent_id="$1"
    local proj_root="${2:-${PROJECT_ROOT:-$PWD}}"

    if [ -f "$AGENTS_JSON" ]; then
        local compat_paths
        compat_paths="$(jq -r --arg id "$agent_id" '.agents[$id].project.compatibility[]? // empty' "$AGENTS_JSON")"
        if [ -n "$compat_paths" ]; then
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                echo "$proj_root/$line"
            done <<< "$compat_paths"
        fi
    fi
}

get_agent_project_paths() {
    local agent_id="$1"
    local proj_root="${2:-${PROJECT_ROOT:-$PWD}}"

    local primary
    primary="$(get_agent_project_primary "$agent_id" "$proj_root")" || return 1
    local all_paths=("$primary")

    while IFS= read -r line; do
        [ -n "$line" ] && all_paths+=("$line")
    done < <(get_agent_project_compatibility_paths "$agent_id" "$proj_root")

    printf '%s\n' "${all_paths[@]}" | LC_ALL=C sort -u
}

resolve_agent_global_path() {
    get_agent_global_primary "$@"
}

resolve_agent_project_path() {
    get_agent_project_primary "$@"
}

map_target_to_agent_ids() {
    local target="$1"
    case "$target" in
        all)
            get_all_agent_ids | tr '\n' ' '
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
        codex|codex-cli)
            echo "codex-cli"
            ;;
        claude|claude-code)
            echo "claude-code"
            ;;
        *)
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

resolve_target_paths() {
    local mode="$1" # "global" or "project"
    local base_dir="${2:-$PWD}"
    shift 2
    local targets=("$@")

    local resolved_paths=()
    for t in "${targets[@]}"; do
        [ -n "$t" ] || continue
        local agent_ids
        agent_ids="$(map_target_to_agent_ids "$t")"
        if [ -z "$agent_ids" ]; then
            echo "Unknown target agent or alias: $t" >&2
            return 1
        fi

        for aid in $agent_ids; do
            local paths=()
            if [ "$mode" = "project" ]; then
                mapfile -t paths < <(get_agent_project_paths "$aid" "$base_dir")
            else
                mapfile -t paths < <(get_agent_global_paths "$aid" "$base_dir")
            fi
            for p in "${paths[@]}"; do
                [ -n "$p" ] && resolved_paths+=("$p")
            done
        done
    done

    if [ "${#resolved_paths[@]}" -eq 0 ]; then
        return 0
    fi

    printf '%s\n' "${resolved_paths[@]}" | LC_ALL=C sort -u
}
