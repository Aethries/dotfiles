#!/usr/bin/env bash
# ==============================================================================
# ai-skills.sh / add-skills: Central AI Agent Skills Manager & Synchronizer
# Manages and links canonical AI skills across Antigravity/Gemini, Codex, and projects.
# ==============================================================================

set -euo pipefail

# Visual styling
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

log_info() { echo -e "${BOLD}${BLUE}==>${RESET} $1"; }
log_ok() { echo -e "  [${GREEN}✓${RESET}] $1"; }
log_warn() { echo -e "  [${YELLOW}!${RESET}] ${YELLOW}$1${RESET}"; }
log_fail() { echo -e "  [${RED}✗${RESET}] ${RED}$1${RESET}" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$REPO_ROOT/resources/skills"

# Load agent adapter library
if [ -f "$REPO_ROOT/scripts/lib/agents.sh" ]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/scripts/lib/agents.sh"
fi

# Dynamic user and home detection (never hardcode user paths)
TARGET_USER="$(id -un)"
TARGET_HOME="$HOME"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

safe_link() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        if [ "${FORCE_REPLACE:-false}" != true ] && [ "${ALLOW_BACKUP:-false}" != true ]; then
            log_fail "Unmanaged file or directory exists at '$dest'. Aborting to prevent silent overwrite. Pass --replace or --backup to proceed."
            return 1
        fi
        if [ "${ALLOW_BACKUP:-false}" = true ]; then
            local backup
            backup="${dest}.pre-skill.$(date +%Y%m%d%H%M%S)"
            mv -- "$dest" "$backup"
            log_warn "Moved existing non-symlink $dest to $backup"
        else
            rm -rf -- "$dest"
            log_warn "Replaced unmanaged existing $dest (--replace/--force specified)"
        fi
    fi
    ln -sfn "$src" "$dest"
    if [ "$TARGET_USER" != "$(id -un)" ]; then
        chown -h "$TARGET_USER:" "$dest" 2>/dev/null || true
    fi
}

safe_unlink() {
    local dest="$1"
    if [ -L "$dest" ]; then
        rm -f "$dest"
        log_ok "Removed link: $dest"
    elif [ -e "$dest" ]; then
        log_warn "Target $dest is not a symlink; skipping removal for safety"
    fi
}

get_skill_desc() {
    local skill_dir="$1"
    local skill_file="$skill_dir/SKILL.md"
    if [ -f "$skill_file" ]; then
        local raw
        raw="$(sed -n -e '/^description:[[:space:]]*/{ s///; p; q; }' "$skill_file")"
        if [ "$raw" = ">-" ] || [ "$raw" = ">" ] || [ "$raw" = "|" ] || [ -z "$raw" ]; then
            sed -n -e '/^description:[[:space:]]*[>|]/,/^[^ ]/{ /^[[:space:]]\+/{ s/^[[:space:]]\+//; p; q; } }' "$skill_file"
        else
            echo "$raw"
        fi
    else
        echo "No description available"
    fi
}

list_skills() {
    echo -e "${BOLD}${CYAN}Available AI Skills in Repository:${RESET}"
    if [ ! -d "$SKILLS_SRC" ]; then
        log_warn "Skills directory not found at $SKILLS_SRC"
        return 0
    fi

    local proj_root
    proj_root="$(find_project_root "$PWD")"

    local g_gemini
    g_gemini="$(get_agent_global_primary antigravity-cli "$TARGET_HOME" 2>/dev/null || true)"
    local g_codex
    g_codex="$(get_agent_global_primary codex-cli "$TARGET_HOME" 2>/dev/null || true)"
    local g_claude
    g_claude="$(get_agent_global_primary claude-code "$TARGET_HOME" 2>/dev/null || true)"

    local found=0
    for skill_dir in "$SKILLS_SRC"/*; do
        [ -d "$skill_dir" ] || continue
        [ -f "$skill_dir/SKILL.md" ] || continue
        local name
        name="$(basename "$skill_dir")"
        [[ "$name" == _* ]] && continue
        found=1
        local desc
        desc="$(get_skill_desc "$skill_dir")"

        local status_gemini="${RED}○${RESET}"
        local status_codex="${RED}○${RESET}"
        local status_claude="${RED}○${RESET}"
        local status_project="${RED}○${RESET}"

        if [ -n "$g_gemini" ] && [ -L "$g_gemini/$name" ] && [ -e "$g_gemini/$name" ]; then
            status_gemini="${GREEN}●${RESET}"
        fi
        if [ -n "$g_codex" ] && [ -L "$g_codex/$name" ] && [ -e "$g_codex/$name" ]; then
            status_codex="${GREEN}●${RESET}"
        fi
        if [ -n "$g_claude" ] && [ -L "$g_claude/$name" ] && [ -e "$g_claude/$name" ]; then
            status_claude="${GREEN}●${RESET}"
        fi
        if [ -d "$proj_root/.agents/skills/$name" ] && [ ! -L "$proj_root/.agents/skills/$name" ]; then
            status_project="${GREEN}●${RESET}"
        fi

        echo
        echo -e "  ${BOLD}${name}${RESET}  [Gemini: $status_gemini | Codex: $status_codex | Claude: $status_claude | Project: $status_project]"
        echo -e "    ${desc}"
    done

    if [ "$found" -eq 0 ]; then
        echo "  No skills currently installed in $SKILLS_SRC."
    fi
    echo
}

preview_skill() {
    local name="$1"
    local skill_dir="$SKILLS_SRC/$name"
    local skill_file="$skill_dir/SKILL.md"
    if [ ! -f "$skill_file" ]; then
        log_fail "Skill '$name' not found at $SKILLS_SRC/$name"
        return 1
    fi

    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    local ver="1.0.0"
    local src="canonical"
    local tags="[]"
    local deps="none"
    if [ -f "$reg_file" ]; then
        ver="$(jq -r --arg s "$name" '.skills[$s].version // "1.0.0"' "$reg_file")"
        src="$(jq -r --arg s "$name" '.skills[$s].source // "canonical"' "$reg_file")"
        tags="$(jq -r --arg s "$name" '.skills[$s].tags // [] | join(", ")' "$reg_file")"
        deps="$(jq -r --arg s "$name" '.skills[$s].dependencies // [] | join(", ")' "$reg_file")"
        [ -z "$deps" ] && deps="none"
    fi

    local desc
    desc="$(get_skill_desc "$skill_dir")"

    echo -e "${BOLD}${CYAN}=== AI Skill: $name (v${ver}) ===${RESET}"
    echo -e "  ${BOLD}Source:${RESET}       $src"
    echo -e "  ${BOLD}Tags:${RESET}         $tags"
    echo -e "  ${BOLD}Dependencies:${RESET} $deps"
    echo -e "  ${BOLD}Description:${RESET}  $desc"
    echo -e "${BOLD}${BLUE}--- SKILL.md ---${RESET}"
    cat "$skill_file"
    echo
}

compute_skill_hash() {
    local skill_dir="$1"
    if [ ! -d "$skill_dir" ]; then
        echo "sha256:0000000000000000000000000000000000000000000000000000000000000000"
        return 0
    fi
    (cd "$skill_dir" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do sha256sum "$f"; done | sha256sum | awk '{print "sha256:" $1}')
}

get_skill_version() {
    local skill_name="$1"
    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    if [ -f "$reg_file" ]; then
        jq -r --arg s "$skill_name" '.skills[$s].version // "1.0.0"' "$reg_file"
    else
        echo "1.0.0"
    fi
}

get_skill_source() {
    local skill_name="$1"
    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    if [ -f "$reg_file" ]; then
        jq -r --arg s "$skill_name" '.skills[$s].source // "canonical"' "$reg_file"
    else
        echo "canonical"
    fi
}

find_project_root() {
    local dir="${1:-$PWD}"
    dir="$(cd "$dir" 2>/dev/null && pwd || echo "$dir")"
    while [ "$dir" != "/" ] && [ "$dir" != "." ] && [ -n "$dir" ]; do
        if [ -d "$dir/.git" ] || [ -f "$dir/flake.nix" ] || [ -f "$dir/.agent-skills.lock.json" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

assert_path_inside_project() {
    local target_path="$1"
    local proj_root="$2"

    local real_root
    real_root="$(cd "$proj_root" 2>/dev/null && pwd -P || echo "$proj_root")"

    local check_dir="$target_path"
    while [ ! -d "$check_dir" ] && [ "$check_dir" != "/" ] && [ "$check_dir" != "." ]; do
        check_dir="$(dirname "$check_dir")"
    done

    local real_target_dir
    real_target_dir="$(cd "$check_dir" 2>/dev/null && pwd -P || echo "$check_dir")"

    if [[ "$real_target_dir" != "$real_root" && "$real_target_dir" != "$real_root/"* ]]; then
        log_fail "Path escape violation: '$target_path' resolves outside project root '$real_root'"
        return 1
    fi
    return 0
}

update_project_lockfile() {
    local proj_root="$1"
    local skill_name="$2"
    local action="$3"
    local target_rel_path="${4:-.agents/skills/$skill_name}"
    local lock_file="$proj_root/.agent-skills.lock.json"

    if [ ! -f "$lock_file" ]; then
        if [ "$action" = "remove" ]; then
            return 0
        fi
        cat << 'EOF' > "$lock_file"
{
  "$schema": "https://raw.githubusercontent.com/Aethries/dotfiles/main/resources/skills/_lock.schema.json",
  "version": 2,
  "generated_at": "",
  "skills": {}
}
EOF
    fi

    local iso_timestamp
    iso_timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    local tmp_lock
    tmp_lock="$(mktemp "$proj_root/.agent-skills.lock.tmp.XXXXXX")"

    # Match which agents share this target_rel_path
    local matched_agents=()
    for aid in $(get_all_agent_ids); do
        local p
        p="$(jq -r --arg id "$aid" '.agents[$id].project.primary // empty' "$AGENTS_JSON" 2>/dev/null || true)"
        if [ -n "$p" ] && [[ "$target_rel_path" == "$p"* ]]; then
            matched_agents+=("$aid")
        fi
    done
    local agents_json
    if [ "${#matched_agents[@]}" -gt 0 ]; then
        agents_json="$(printf '%s\n' "${matched_agents[@]}" | jq -R . | jq -s .)"
    else
        agents_json="[]"
    fi

    if [ "$action" = "add" ]; then
        local ver
        ver="$(get_skill_version "$skill_name")"
        local src
        src="$(get_skill_source "$skill_name")"
        local hash
        hash="$(compute_skill_hash "$SKILLS_SRC/$skill_name")"

        jq --arg skill "$skill_name" \
           --arg ver "$ver" \
           --arg src "$src" \
           --arg hash "$hash" \
           --arg path "$target_rel_path" \
           --argjson agents "$agents_json" \
           --arg time "$iso_timestamp" \
           '
           .version = 2 |
           .generated_at = $time |
           .skills[$skill] as $existing |
           (
               if $existing and ($existing.targets | type == "array") then
                   [ $existing.targets[] | select(.path != $path) ] + [ { path: $path, agents: $agents } ]
               else
                   [ { path: $path, agents: $agents } ]
               end
           ) as $new_targets |
           .skills[$skill] = {
               version: $ver,
               source: $src,
               content_hash: $hash,
               target_path: $path,
               targets: $new_targets
           }
           ' "$lock_file" > "$tmp_lock"
        mv -f "$tmp_lock" "$lock_file"
        log_ok "Updated lockfile: $lock_file (recorded $skill_name@$ver in $target_rel_path)"
    elif [ "$action" = "remove" ]; then
        jq --arg skill "$skill_name" \
           --arg path "$target_rel_path" \
           --arg time "$iso_timestamp" \
           '
           .generated_at = $time |
           if .skills[$skill] then
               if (.skills[$skill].targets | type == "array") and ($path != "") then
                   .skills[$skill].targets |= [ .[] | select(.path != $path) ] |
                   if (.skills[$skill].targets | length == 0) then
                       del(.skills[$skill])
                   else
                       .skills[$skill].target_path = .skills[$skill].targets[0].path
                   end
               else
                   del(.skills[$skill])
               end
           else
               .
           end
           ' "$lock_file" > "$tmp_lock"
        mv -f "$tmp_lock" "$lock_file"
        log_ok "Updated lockfile: $lock_file (updated $skill_name)"
    else
        rm -f "$tmp_lock"
    fi
}

install_global() {
    local name="$1"
    local target="${2:-all}"
    local skill_dir="$SKILLS_SRC/$name"

    if [ ! -d "$skill_dir" ] || [ ! -f "$skill_dir/SKILL.md" ]; then
        log_fail "Skill '$name' does not exist in $SKILLS_SRC"
        return 1
    fi

    log_info "Installing skill '$name' globally (target: $target)..."

    local target_paths=()
    mapfile -t target_paths < <(resolve_target_paths "global" "$TARGET_HOME" "$target")
    if [ "${#target_paths[@]}" -eq 0 ]; then
        log_fail "No valid global target paths resolved for target: $target"
        return 1
    fi

    for tpath in "${target_paths[@]}"; do
        safe_link "$skill_dir" "$tpath/$name"
        log_ok "Linked globally: $tpath/$name"
    done
}

install_project() {
    local name="$1"
    local dest_target="${2:-}"
    local proj_root_arg="${3:-}"
    local skill_src="$SKILLS_SRC/$name"

    local proj_root
    local dest_base
    if [ -n "$proj_root_arg" ]; then
        proj_root="$(find_project_root "$proj_root_arg")"
        if [ -n "$dest_target" ] && [[ "$dest_target" == "$proj_root"* ]]; then
            dest_base="$dest_target"
        else
            dest_base="$proj_root/.agents/skills"
        fi
    elif [ -n "$dest_target" ]; then
        if [[ "$dest_target" == *"/skills" ]] || [[ "$dest_target" == *"/skills/" ]]; then
            proj_root="$(find_project_root "$dest_target")"
            dest_base="$dest_target"
        else
            proj_root="$(find_project_root "$dest_target")"
            dest_base="$proj_root/.agents/skills"
        fi
    else
        proj_root="$(find_project_root "$PWD")"
        dest_base="$proj_root/.agents/skills"
    fi

    if [ ! -d "$skill_src" ] || [ ! -f "$skill_src/SKILL.md" ]; then
        log_fail "Skill '$name' does not exist in $SKILLS_SRC"
        return 1
    fi

    local dest="$dest_base/$name"

    # Confinement assertion
    assert_path_inside_project "$dest" "$proj_root" || return 1

    # Check unmanaged existing destination (BLOCKER 4)
    local lock_file="$proj_root/.agent-skills.lock.json"
    local is_managed=false
    if [ -f "$lock_file" ]; then
        if jq -e --arg s "$name" '.skills[$s]' "$lock_file" >/dev/null 2>&1; then
            is_managed=true
        fi
    fi

    if [ -e "$dest" ] && [ "$is_managed" != true ]; then
        if [ "${FORCE_REPLACE:-false}" != true ] && [ "${ALLOW_BACKUP:-false}" != true ]; then
            log_fail "Destination '$dest' already exists and is NOT managed by $lock_file. Aborting to prevent accidental data loss. Pass --force or --backup to proceed."
            return 1
        fi
        if [ "${ALLOW_BACKUP:-false}" = true ]; then
            local backup
            backup="${dest}.pre-skill.$(date +%Y%m%d%H%M%S)"
            mv "$dest" "$backup"
            log_warn "Backed up unmanaged existing destination $dest to $backup"
        else
            rm -rf "$dest"
            log_warn "Removed unmanaged existing destination $dest (--force/--replace specified)"
        fi
    fi

    log_info "Installing skill '$name' into project (path: $dest)..."

    # Staging directory on same filesystem
    mkdir -p "$dest_base"
    local staging
    staging="$(mktemp -d "$dest_base/.staging.${name}.XXXXXX")"

    cleanup_staging() {
        [ -d "$staging" ] && rm -rf "$staging"
    }
    trap cleanup_staging EXIT ERR

    # Full copy (never whitelist)
    cp -a "$skill_src/." "$staging/"

    # Verify staging copy
    if [ ! -f "$staging/SKILL.md" ]; then
        rm -rf "$staging"
        log_fail "Physical staging copy assertion failed for skill: $name"
        return 1
    fi

    # Replace destination cleanly
    if [ -L "$dest" ]; then
        log_warn "Replacing existing symlink $dest with true directory copy"
        rm -f "$dest"
    elif [ -d "$dest" ]; then
        rm -rf "$dest"
    fi

    mv "$staging" "$dest"
    trap - EXIT ERR

    # Strict invariant: Project = physical directory, NOT symlink
    if [ -L "$dest" ] || [ ! -d "$dest" ] || [ ! -f "$dest/SKILL.md" ]; then
        log_fail "Physical copy assertion failed for project skill: $dest"
        return 1
    fi

    local rel_path
    local real_root
    real_root="$(cd "$proj_root" 2>/dev/null && pwd -P || echo "$proj_root")"
    local real_dest
    real_dest="$(cd "$dest" 2>/dev/null && pwd -P || echo "$dest")"
    if [[ "$real_dest" == "$real_root/"* ]]; then
        rel_path="${real_dest#"$real_root"/}"
    elif [[ "$dest" == "$proj_root/"* ]]; then
        rel_path="${dest#"$proj_root"/}"
    else
        rel_path=".agents/skills/$name"
    fi

    update_project_lockfile "$proj_root" "$name" "add" "$rel_path"
    log_ok "Physically installed skill '$name' in project: $dest"
}

remove_global() {
    local name="$1"
    local target="${2:-all}"

    log_info "Removing skill '$name' globally (target: $target)..."

    local target_paths=()
    mapfile -t target_paths < <(resolve_target_paths "global" "$TARGET_HOME" "$target")
    if [ "${#target_paths[@]}" -eq 0 ]; then
        log_fail "No valid global target paths resolved for target: $target"
        return 1
    fi

    for tpath in "${target_paths[@]}"; do
        safe_unlink "$tpath/$name"
    done
}

remove_project() {
    local name="$1"
    local dest_target="${2:-}"
    local proj_root_arg="${3:-}"
    local proj_root
    local dest_base

    if [ -n "$proj_root_arg" ]; then
        proj_root="$(find_project_root "$proj_root_arg")"
        if [ -n "$dest_target" ] && [[ "$dest_target" == "$proj_root"* ]]; then
            dest_base="$dest_target"
        else
            dest_base="$proj_root/.agents/skills"
        fi
    elif [ -n "$dest_target" ]; then
        if [[ "$dest_target" == *"/skills" ]] || [[ "$dest_target" == *"/skills/" ]]; then
            proj_root="$(find_project_root "$dest_target")"
            dest_base="$dest_target"
        else
            proj_root="$(find_project_root "$dest_target")"
            dest_base="$proj_root/.agents/skills"
        fi
    else
        proj_root="$(find_project_root "$PWD")"
        dest_base="$proj_root/.agents/skills"
    fi

    local dest="$dest_base/$name"

    # Confinement assertion
    assert_path_inside_project "$dest" "$proj_root" || return 1

    log_info "Removing project skill '$name' from $dest_base..."

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -rf "$dest"
        log_ok "Removed project skill directory: $dest"
    else
        log_warn "Project skill $dest does not exist"
    fi

    local rel_path
    local real_root
    real_root="$(cd "$proj_root" 2>/dev/null && pwd -P || echo "$proj_root")"
    if [[ "$dest" == "$real_root/"* ]]; then
        rel_path="${dest#"$real_root"/}"
    elif [[ "$dest" == "$proj_root/"* ]]; then
        rel_path="${dest#"$proj_root"/}"
    else
        rel_path=".agents/skills/$name"
    fi

    update_project_lockfile "$proj_root" "$name" "remove" "$rel_path"
}

add_skill() {
    local name="$1"
    local mode_or_target="${2:-all}"
    local path_or_agent="${3:-}"

    case "$mode_or_target" in
        project)
            install_project "$name" "${path_or_agent:-}"
            ;;
        global)
            install_global "$name" "${path_or_agent:-all}"
            ;;
        *)
            install_global "$name" "$mode_or_target"
            ;;
    esac
}

remove_skill() {
    local name="$1"
    local mode_or_target="${2:-all}"
    local path_or_agent="${3:-}"

    case "$mode_or_target" in
        project)
            remove_project "$name" "${path_or_agent:-}"
            ;;
        global)
            remove_global "$name" "${path_or_agent:-all}"
            ;;
        all)
            remove_global "$name" "all"
            local proj_root
            proj_root="$(find_project_root "$PWD")"
            if [ -e "${path_or_agent:-$proj_root/.agents/skills}/$name" ]; then
                remove_project "$name" "${path_or_agent:-$proj_root/.agents/skills}"
            fi
            ;;
        *)
            remove_global "$name" "$mode_or_target"
            ;;
    esac
}

sync_skills() {
    local profile="global-core"
    local all_canonical=false

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --profile|-p)
                profile="$2"
                shift 2
                ;;
            --all-canonical)
                all_canonical=true
                shift 1
                ;;
            *)
                shift 1
                ;;
        esac
    done

    if [ "$all_canonical" = true ]; then
        log_info "Synchronizing ALL canonical skills to user agents..."
    else
        log_info "Synchronizing profile '$profile' skills to user agents..."
    fi

    if [ ! -d "$SKILLS_SRC" ]; then
        log_warn "No skills directory at $SKILLS_SRC"
        return 0
    fi

    local skill_names=()
    if [ "$all_canonical" = true ]; then
        local reg_file="$REPO_ROOT/resources/skills/_registry.json"
        if [ -f "$reg_file" ]; then
            mapfile -t skill_names < <(jq -r '.skills | keys[]' "$reg_file" | LC_ALL=C sort)
        else
            mapfile -t skill_names < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -exec test -f '{}/SKILL.md' ';' -exec basename {} \; | LC_ALL=C sort)
        fi
    else
        local prof_file="$REPO_ROOT/resources/skills/_profiles.json"
        if [ -f "$prof_file" ]; then
            mapfile -t skill_names < <(jq -r --arg p "$profile" '.profiles[$p].skills[]? // empty' "$prof_file" | LC_ALL=C sort -u)
        fi
        if [ "${#skill_names[@]}" -eq 0 ]; then
            log_fail "Profile '$profile' not found or contains no skills in $prof_file"
            return 1
        fi
    fi

    for name in "${skill_names[@]}"; do
        [ -d "$SKILLS_SRC/$name" ] || continue
        [ -f "$SKILLS_SRC/$name/SKILL.md" ] || continue
        install_global "$name" "all"
    done

    # Reconcile and clean up broken symlinks across agent global directories (both primary and compatibility)
    local agent_ids
    agent_ids="$(get_all_agent_ids)"
    for agent in $agent_ids; do
        local gpaths=()
        mapfile -t gpaths < <(get_agent_global_paths "$agent" "$TARGET_HOME")
        for gpath in "${gpaths[@]}"; do
            if [ -d "$gpath" ]; then
                for link in "$gpath"/*; do
                    [ -L "$link" ] || continue
                    if [ ! -e "$link" ]; then
                        log_warn "Removing broken global symlink: $link"
                        rm -f "$link"
                    fi
                done
            fi
        done
    done

    log_ok "Skills synchronized successfully (profile: ${profile})"
}

export_skill() {
    local name="$1"
    local skill_file="$SKILLS_SRC/$name/SKILL.md"
    if [ ! -f "$skill_file" ]; then
        log_fail "Skill '$name' not found at $SKILLS_SRC/$name"
        return 1
    fi

    echo "<!-- Ponytail Anti-Overengineering Rule Snippet -->"
    echo "# Ponytail Ruleset ($name)"
    sed -e '1{/^---$/!q;};1,/^---$/d' "$skill_file"
}

export_rules() {
    cat << 'EOF'
<!-- managed-by: Aethries/dotfiles ai-skills -->
# AI Agent Guidelines & Senior Engineering Standards

> System-level orchestration rules generated by Aethries/dotfiles ai-skills.
> Progressive loading policy: Specialized domain skills are loaded on-demand from your skills directory. Do NOT preload all skills into context.

## 1. Core Operating Philosophy
- **Anti-Overengineering (ponytail)**: YAGNI extremist. Deletion over addition. Smallest working diff wins.
- **Ultra-Terse Communication (Caveman)**: Maximum compression, telegraphic tone, zero fluff.
- **AST Navigation (CodeGraph & Codebase Memory)**: Never do brute-force whole-repo scans when AST indexing can pinpoint symbols and hierarchies.
- **Token Efficiency (RTK)**: Filter noisy build, diff, and test output through RTK filters before context ingestion.

## 2. Senior Engineering Workflow Sequence
1. **Guardrails (Layer 0)**:
   - `architecture-guardrails`: Module boundaries, clean layering, acyclic dependency graph.
   - `security-guardrails`: Zero hardcoded credentials, input validation, strict auth boundaries.
   - `system-design-guardrails`: Distributed safety, idempotency, retry safety, transactional integrity.
   - `source-quality`: Zero duplication, package manager integrity, AST hygiene.
   - `project-context`: Reconnaissance first, adhere to existing patterns.
2. **Analysis & Specification (Layer 1 - Senior Leadership)**:
   - `feature-spec-writer`: Author exhaustive WHAT/WHY product specifications (`docs/specs/<feature>.md`). No code.
   - `technical-planner`: Formulate concrete phased execution plans (`docs/plans/<feature>.md`). Strictly analytical.
   - `architecture-designer`: Evaluate topology, bounded contexts, synchronous vs asynchronous models. Authors ADRs (`docs/architecture/adr/`).
   - `api-contract-designer`: Standardize REST/gRPC/WebSocket payloads, error envelopes, idempotency contracts.
   - `data-model-architect`: Design relational (PostgreSQL) / document schemas, zero-downtime migrations.
   - `test-strategist`: Define test pyramid and edge-case matrices before implementation.
3. **Execution & Implementation (Layer 2)**:
   - `senior-implementer`: Disciplined execution of approved specs/plans with 5-step quality verification.
   - `pixel-perfect-ui`: Frontend implementation with 100% fidelity to design systems and mockups.
4. **Operations & Verification (Layer 3 & 4)**:
   - `engineering-review`: Rigorous PR review (Blocker, Warning, Suggestion). Never merge without approval.
   - `incident-investigator`: Triage live failures, telemetry inspection, 5 Whys analysis under `docs/incidents/`.
   - `quality-gate`: Enforces verification sequence before declaring work complete.

## 3. Dynamic Skill On-Demand Triggers
When encountering specialized tasks, inspect the corresponding `SKILL.md` from your agent skills directory:
- **Rust Systems Programming**: `rust` (Tokio, borrow checker, Clippy, memory safety)
- **Containerization**: `docker` (Multi-stage builds, rootless, compose architectures)
- **Nix & System Config**: `nixos` (Flakes, devShells, modules)
- **Editor Tooling**: `neovim-lua` (Treesitter, LSP, keymaps, Lua plugins)
- **PostgreSQL Optimization**: `postgresql` (Query plans, indexing, vacuum, connection pooling)
- **Redis Patterns**: `redis` (Cache eviction, atomic primitives, Pub/Sub)
- **Job Queues**: `bullmq` (Concurrency, retries, delayed jobs)
- **Realtime WebSockets**: `centrifugo` (Channels, permissions, presence)
- **Chrome Extensions**: `chrome-extension` (Manifest V3, service workers, content scripts)
- **Cloud Infrastructure**: `cloud-infra` (Terraform/OpenTofu, multi-cloud, serverless)
- **Server Hardening**: `vps-hardening` (SSH, UFW, fail2ban, systemd sandboxing)
- **Skill Authoring**: `skill-author` (Creating standardized agent skills packages)
EOF
}

export_all_rules() {
    log_warn "'export --all' is deprecated to prevent startup context bloat. Outputting compact baseline rules."
    export_rules
}

cmd_diff() {
    local proj_root
    proj_root="$(find_project_root "$PWD")"
    local lock_file="$proj_root/.agent-skills.lock.json"

    local skills_to_diff=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --project|-p)
                if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                    proj_root="$(find_project_root "$2")"
                    lock_file="$proj_root/.agent-skills.lock.json"
                    shift 2
                else
                    shift 1
                fi
                ;;
            *)
                skills_to_diff+=("$1")
                shift
                ;;
        esac
    done

    if [ "${#skills_to_diff[@]}" -eq 0 ]; then
        if [ -f "$lock_file" ]; then
            mapfile -t skills_to_diff < <(jq -r '.skills | keys[]' "$lock_file" 2>/dev/null || true)
        elif [ -d "$proj_root/.agents/skills" ]; then
            mapfile -t skills_to_diff < <(find "$proj_root/.agents/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || true)
        fi
    fi

    if [ "${#skills_to_diff[@]}" -eq 0 ]; then
        log_warn "No project skills found to diff in $proj_root"
        return 0
    fi

    local has_diff=0
    for s in "${skills_to_diff[@]}"; do
        local canonical_dir="$SKILLS_SRC/$s"
        if [ ! -d "$canonical_dir" ]; then
            log_fail "Canonical skill '$s' not found at $canonical_dir"
            has_diff=1
            continue
        fi

        local target_rel_paths=()
        if [ -f "$lock_file" ]; then
            mapfile -t target_rel_paths < <(jq -r --arg s "$s" '(.skills[$s].targets[]?.path // empty), (.skills[$s].target_path // empty)' "$lock_file" 2>/dev/null | LC_ALL=C sort -u)
        fi

        if [ "${#target_rel_paths[@]}" -eq 0 ]; then
            for candidate in ".agents/skills/$s" ".codex/skills/$s" ".claude/skills/$s"; do
                if [ -d "$proj_root/$candidate" ]; then
                    target_rel_paths+=("$candidate")
                fi
            done
        fi

        if [ "${#target_rel_paths[@]}" -eq 0 ]; then
            log_fail "Project skill '$s' not found on disk in $proj_root"
            has_diff=1
            continue
        fi

        for rel_p in "${target_rel_paths[@]}"; do
            local local_dir="$proj_root/$rel_p"
            if [ ! -d "$local_dir" ]; then
                log_fail "Project skill target '$local_dir' missing on disk"
                has_diff=1
                continue
            fi

            echo -e "${BOLD}${CYAN}Diffing skill '$s': canonical ($canonical_dir) <-> local ($local_dir)${RESET}"
            if ! diff -u -r "$canonical_dir" "$local_dir"; then
                has_diff=1
            else
                log_ok "Skill '$s' at $rel_p matches canonical version"
            fi
            echo
        done
    done

    return "$has_diff"
}

cmd_update() {
    local force=false
    local skills_to_update=()
    local proj_dir="$PWD"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --force|-f)
                force=true
                shift
                ;;
            --project|-p)
                if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                    proj_dir="$2"
                    shift 2
                else
                    shift 1
                fi
                ;;
            *)
                skills_to_update+=("$1")
                shift
                ;;
        esac
    done

    local proj_root
    proj_root="$(find_project_root "$proj_dir")"
    local lock_file="$proj_root/.agent-skills.lock.json"

    if [ "${#skills_to_update[@]}" -eq 0 ]; then
        if [ -f "$lock_file" ]; then
            mapfile -t skills_to_update < <(jq -r '.skills | keys[]' "$lock_file" 2>/dev/null || true)
        elif [ -d "$proj_root/.agents/skills" ]; then
            mapfile -t skills_to_update < <(find "$proj_root/.agents/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || true)
        fi
    fi

    if [ "${#skills_to_update[@]}" -eq 0 ]; then
        log_warn "No project skills found to update in $proj_root"
        return 0
    fi

    local update_count=0
    for s in "${skills_to_update[@]}"; do
        local canonical_dir="$SKILLS_SRC/$s"
        if [ ! -d "$canonical_dir" ]; then
            log_fail "Canonical skill '$s' not found at $canonical_dir"
            continue
        fi

        local target_rel_paths=()
        if [ -f "$lock_file" ]; then
            mapfile -t target_rel_paths < <(jq -r --arg s "$s" '(.skills[$s].targets[]?.path // empty), (.skills[$s].target_path // empty)' "$lock_file" 2>/dev/null | LC_ALL=C sort -u)
        fi

        if [ "${#target_rel_paths[@]}" -eq 0 ]; then
            for candidate in ".agents/skills/$s" ".codex/skills/$s" ".claude/skills/$s"; do
                if [ -d "$proj_root/$candidate" ]; then
                    target_rel_paths+=("$candidate")
                fi
            done
        fi

        if [ "${#target_rel_paths[@]}" -eq 0 ]; then
            log_fail "Project skill '$s' not found on disk to update"
            continue
        fi

        for rel_p in "${target_rel_paths[@]}"; do
            local local_dir="$proj_root/$rel_p"
            if [ ! -d "$local_dir" ]; then
                log_fail "Project skill path '$local_dir' not found"
                continue
            fi

            local local_hash
            local_hash="$(compute_skill_hash "$local_dir")"
            local recorded_hash=""
            if [ -f "$lock_file" ]; then
                recorded_hash="$(jq -r --arg s "$s" '.skills[$s].content_hash // empty' "$lock_file" 2>/dev/null || true)"
            fi
            local canonical_hash
            canonical_hash="$(compute_skill_hash "$canonical_dir")"

            # Check for local modifications
            if [ -n "$recorded_hash" ] && [ "$local_hash" != "$recorded_hash" ] && [ "$local_hash" != "$canonical_hash" ]; then
                if [ "$force" != true ]; then
                    if [ -t 0 ]; then
                        read -r -p "Skill '$s' at $rel_p has local modifications. Overwrite with canonical? [y/N]: " confirm
                        if [[ ! "$confirm" =~ ^[yY] ]]; then
                            log_warn "Skipped '$s' (local modifications preserved)"
                            continue
                        fi
                    else
                        log_warn "Skill '$s' has local modifications. Skipping (use --force to overwrite)."
                        continue
                    fi
                fi
            fi

            install_project "$s" "$(dirname "$local_dir")"
            log_ok "Updated skill '$s' in project: $local_dir (content hash: $canonical_hash)"
            update_count=$((update_count + 1))
        done
    done

    log_ok "Updated $update_count target(s) across project skills in $proj_root"
}

cmd_doctor() {
    local doctor_errors=0
    local doctor_warns=0
    local doctor_ok=0

    echo -e "${BOLD}${CYAN}AI Skills Health Doctor${RESET}"
    echo "Auditing global symlinks, project locks, and AI binaries..."
    echo

    # 1. Global symlinks
    echo -e "${BOLD}${BLUE}==> Global Agent Symlinks${RESET}"
    local agent_ids
    agent_ids="$(get_all_agent_ids)"
    for agent in $agent_ids; do
        local gpaths=()
        mapfile -t gpaths < <(get_agent_global_paths "$agent" "$TARGET_HOME")
        for gpath in "${gpaths[@]}"; do
            if [ -d "$gpath" ]; then
                for link in "$gpath"/*; do
                    [ -e "$link" ] || [ -L "$link" ] || continue
                    local link_name
                    link_name="$(basename "$link")"
                    [[ "$link_name" == _* ]] && continue
                    if [ -L "$link" ]; then
                        if [ -e "$link" ]; then
                            echo -e "  [${GREEN}✓${RESET}] $agent ($gpath): $link_name -> $(readlink "$link")"
                            doctor_ok=$((doctor_ok + 1))
                        else
                            echo -e "  [${RED}✗${RESET}] $agent ($gpath): BROKEN symlink: $link -> $(readlink "$link")"
                            doctor_errors=$((doctor_errors + 1))
                        fi
                    elif [ -d "$link" ]; then
                        echo -e "  [${YELLOW}!${RESET}] $agent ($gpath): $link_name is a physical directory, not a symlink"
                        doctor_warns=$((doctor_warns + 1))
                    fi
                done
            fi
        done
    done

    # 2. Project locks & integrity
    echo
    echo -e "${BOLD}${BLUE}==> Project Skills & Lockfile Integrity${RESET}"
    local proj_root
    proj_root="$(find_project_root "$PWD")"
    local lock_file="$proj_root/.agent-skills.lock.json"
    if [ -f "$lock_file" ]; then
        echo -e "  Lockfile: $lock_file"
        local locked_skills
        locked_skills="$(jq -r '.skills | keys[]' "$lock_file" 2>/dev/null || true)"
        for s in $locked_skills; do
            local expected_hash
            expected_hash="$(jq -r --arg s "$s" '.skills[$s].content_hash // empty' "$lock_file")"
            local rel_paths=()
            mapfile -t rel_paths < <(jq -r --arg s "$s" '(.skills[$s].targets[]?.path // empty), (.skills[$s].target_path // empty)' "$lock_file" 2>/dev/null | LC_ALL=C sort -u)
            [ "${#rel_paths[@]}" -eq 0 ] && rel_paths=(".agents/skills/$s")

            for rel_path in "${rel_paths[@]}"; do
                local full_path="$proj_root/$rel_path"

                if [ -L "$full_path" ]; then
                    echo -e "  [${RED}✗${RESET}] Skill '$s' at $full_path is a SYMLINK (violates project physical copy invariant)"
                    doctor_errors=$((doctor_errors + 1))
                elif [ ! -d "$full_path" ]; then
                    echo -e "  [${RED}✗${RESET}] Skill '$s': missing on disk at $full_path"
                    doctor_errors=$((doctor_errors + 1))
                else
                    local actual_hash
                    actual_hash="$(compute_skill_hash "$full_path")"
                    if [ "$actual_hash" = "$expected_hash" ]; then
                        echo -e "  [${GREEN}✓${RESET}] Skill '$s' ($rel_path): hash verified ($actual_hash)"
                        doctor_ok=$((doctor_ok + 1))
                    else
                        echo -e "  [${YELLOW}!${RESET}] Skill '$s' ($rel_path): modified/drifted (lock: $expected_hash, local: $actual_hash)"
                        doctor_warns=$((doctor_warns + 1))
                    fi
                fi
            done
        done
    else
        echo -e "  No project lockfile found in $proj_root"
    fi

    # 3. Installed AI binaries
    echo
    echo -e "${BOLD}${BLUE}==> Installed AI Binaries${RESET}"
    local binaries=("gemini" "codex" "claude" "rtk")
    for bin in "${binaries[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
            local bin_path
            bin_path="$(command -v "$bin")"
            echo -e "  [${GREEN}✓${RESET}] $bin: installed ($bin_path)"
            doctor_ok=$((doctor_ok + 1))
        elif [ "$bin" = "gemini" ] && command -v agy >/dev/null 2>&1; then
            local bin_path
            bin_path="$(command -v agy)"
            echo -e "  [${GREEN}✓${RESET}] gemini (agy): installed ($bin_path)"
            doctor_ok=$((doctor_ok + 1))
        elif [ "$bin" = "claude" ] && command -v claude-code >/dev/null 2>&1; then
            local bin_path
            bin_path="$(command -v claude-code)"
            echo -e "  [${GREEN}✓${RESET}] claude (claude-code): installed ($bin_path)"
            doctor_ok=$((doctor_ok + 1))
        else
            echo -e "  [${YELLOW}!${RESET}] $bin: not found in PATH"
            doctor_warns=$((doctor_warns + 1))
        fi
    done

    echo
    echo -e "${BOLD}Summary:${RESET} ${GREEN}${doctor_ok} OK${RESET}, ${YELLOW}${doctor_warns} Warnings${RESET}, ${RED}${doctor_errors} Errors${RESET}"
    if [ "$doctor_errors" -gt 0 ]; then
        return 1
    fi
    return 0
}

search_skills() {
    local query="${1:-}"
    if [ -z "$query" ]; then
        log_fail "Usage: $(basename "$0") search <keyword>"
        return 1
    fi

    echo -e "${BOLD}${CYAN}Searching AI Skills for '${query}'...${RESET}"
    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    if [ ! -f "$reg_file" ]; then
        log_fail "Registry file not found at $reg_file"
        return 1
    fi

    local matched=0
    local skill_names=()
    mapfile -t skill_names < <(jq -r '.skills | keys[]' "$reg_file")

    for name in "${skill_names[@]}"; do
        local desc
        desc="$(jq -r --arg s "$name" '.skills[$s].description // ""' "$reg_file")"
        local tags
        tags="$(jq -r --arg s "$name" '.skills[$s].tags // [] | join(" ")' "$reg_file")"
        local triggers
        triggers="$(jq -r --arg s "$name" '.skills[$s].triggers // [] | join(" ")' "$reg_file")"
        local caps
        caps="$(jq -r --arg s "$name" '.skills[$s].capabilities // [] | join(" ")' "$reg_file")"
        local domain
        domain="$(jq -r --arg s "$name" '.skills[$s].domain // ""' "$reg_file")"

        local haystack="$name $desc $tags $triggers $caps $domain"
        if echo "$haystack" | grep -qi "$query"; then
            matched=$((matched + 1))
            echo
            echo -e "  ${BOLD}${GREEN}${name}${RESET} [domain: ${domain:-general}]"
            echo -e "    ${desc}"
            [ -n "$triggers" ] && echo -e "    ${BOLD}Triggers:${RESET} ${triggers}"
        fi
    done

    if [ "$matched" -eq 0 ]; then
        echo "  No local skills matched '${query}'."
        echo "  Use 'ai-skills discover' to inspect external trusted sources."
    else
        echo
        echo -e "Found ${matched} matching skill(s)."
    fi
}

inspect_skill() {
    local name="${1:-}"
    if [ -z "$name" ]; then
        log_fail "Usage: $(basename "$0") inspect <skill>"
        return 1
    fi

    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    local skill_dir="$SKILLS_SRC/$name"
    if [ ! -d "$skill_dir" ]; then
        log_fail "Skill '$name' not found at $skill_dir"
        return 1
    fi

    local ver="1.0.0"
    local src="canonical"
    local domain="general"
    local status="active"
    local tags="none"
    local deps="none"
    local triggers="none"
    local caps="none"
    local provenance="Dotfiles Internal Canonical"

    if [ -f "$reg_file" ]; then
        ver="$(jq -r --arg s "$name" '.skills[$s].version // "1.0.0"' "$reg_file")"
        src="$(jq -r --arg s "$name" '.skills[$s].source // "canonical"' "$reg_file")"
        domain="$(jq -r --arg s "$name" '.skills[$s].domain // "general"' "$reg_file")"
        status="$(jq -r --arg s "$name" '.skills[$s].status // "active"' "$reg_file")"
        tags="$(jq -r --arg s "$name" '.skills[$s].tags // [] | join(", ")' "$reg_file")"
        deps="$(jq -r --arg s "$name" '.skills[$s].dependencies // [] | join(", ")' "$reg_file")"
        triggers="$(jq -r --arg s "$name" '.skills[$s].triggers // [] | join(", ")' "$reg_file")"
        caps="$(jq -r --arg s "$name" '.skills[$s].capabilities // [] | join(", ")' "$reg_file")"
        local prov_json
        prov_json="$(jq -r --arg s "$name" '.skills[$s].provenance // empty' "$reg_file")"
        if [ -n "$prov_json" ] && [ "$prov_json" != "null" ]; then
            provenance="$(jq -r --arg s "$name" '.skills[$s].provenance.upstream_url // "local"' "$reg_file")"
        fi
    fi

    echo -e "${BOLD}${CYAN}=== Skill Inspection: $name (v${ver}) ===${RESET}"
    echo -e "  ${BOLD}Status:${RESET}       $status"
    echo -e "  ${BOLD}Domain:${RESET}       $domain"
    echo -e "  ${BOLD}Source:${RESET}       $src"
    echo -e "  ${BOLD}Provenance:${RESET}   $provenance"
    echo -e "  ${BOLD}Tags:${RESET}         $tags"
    echo -e "  ${BOLD}Triggers:${RESET}     $triggers"
    echo -e "  ${BOLD}Capabilities:${RESET} $caps"
    echo -e "  ${BOLD}Dependencies:${RESET} ${deps:-none}"
    echo -e "  ${BOLD}Location:${RESET}     $skill_dir"
    echo
    echo -e "${BOLD}${BLUE}--- SKILL.md Preview ---${RESET}"
    head -n 25 "$skill_dir/SKILL.md"
    echo
}

discover_sources() {
    local src_file="$REPO_ROOT/resources/skills/_sources.json"
    if [ ! -f "$src_file" ]; then
        log_fail "Sources registry not found at $src_file"
        return 1
    fi

    echo -e "${BOLD}${CYAN}Trusted AI Skills Sources & Registries:${RESET}"
    echo

    local source_keys=()
    mapfile -t source_keys < <(jq -r '.sources | keys[]' "$src_file")
    for k in "${source_keys[@]}"; do
        local name
        name="$(jq -r --arg k "$k" '.sources[$k].name' "$src_file")"
        local type
        type="$(jq -r --arg k "$k" '.sources[$k].type' "$src_file")"
        local url
        url="$(jq -r --arg k "$k" '.sources[$k].url' "$src_file")"
        local desc
        desc="$(jq -r --arg k "$k" '.sources[$k].description // ""' "$src_file")"
        local trust
        trust="$(jq -r --arg k "$k" '.sources[$k].trust_level // "unknown"' "$src_file")"
        local policy
        policy="$(jq -r --arg k "$k" '.sources[$k].curation_policy // "standard"' "$src_file")"

        echo -e "  ${BOLD}${GREEN}$k${RESET} (${name})"
        echo -e "    Type: ${type} | Trust: ${trust} | Policy: ${policy}"
        echo -e "    URL:  ${url}"
        [ -n "$desc" ] && echo -e "    ${desc}"
        echo
    done

    echo -e "${BOLD}How to import external skills:${RESET}"
    echo "  ai-skills import <git-url-or-dir> [skill-name]"
    echo
}

import_skill() {
    local src_location=""
    local skill_name=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --force|-f|--replace)
                FORCE_REPLACE=true
                shift
                ;;
            *)
                if [ -z "$src_location" ]; then
                    src_location="$1"
                elif [ -z "$skill_name" ]; then
                    skill_name="$1"
                fi
                shift
                ;;
        esac
    done

    if [ -z "$src_location" ]; then
        log_fail "Usage: $(basename "$0") import <git-repo-or-dir> [skill-name] [--force]"
        return 1
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d "/tmp/ai-skills-import.XXXXXX")"
    cleanup_import() {
        [ -d "$tmp_dir" ] && rm -rf "$tmp_dir"
    }
    trap cleanup_import EXIT

    log_info "Fetching external skill bundle from: $src_location..."
    if [ -d "$src_location" ]; then
        cp -a "$src_location/." "$tmp_dir/"
    elif [[ "$src_location" =~ ^https?:// ]] || [[ "$src_location" =~ ^git@ ]]; then
        git clone --depth 1 "$src_location" "$tmp_dir" >/dev/null 2>&1 || {
            log_fail "Failed to clone git repository: $src_location"
            return 1
        }
    else
        log_fail "Invalid source location: $src_location (must be local directory or git URL)"
        return 1
    fi

    if [ ! -f "$tmp_dir/SKILL.md" ]; then
        log_fail "Import failed: No SKILL.md found in source bundle"
        return 1
    fi

    if [ -z "$skill_name" ]; then
        skill_name="$(sed -n -e '/^name:[[:space:]]*/{ s///; p; q; }' "$tmp_dir/SKILL.md" | tr -d '\r"' || true)"
        [ -z "$skill_name" ] && skill_name="$(basename "$src_location" .git)"
    fi

    log_info "Running curation and security audit on '$skill_name'..."
    source "$REPO_ROOT/scripts/lib/curate.sh"
    if ! audit_skill_security "$tmp_dir"; then
        log_fail "Import rejected: Security audit violations found in '$skill_name'"
        return 1
    fi

    local target_dir="$SKILLS_SRC/$skill_name"
    local reg_file="$REPO_ROOT/resources/skills/_registry.json"

    # BLOCKER 6: Prevent silent overwrite of existing canonical skills
    if [ -d "$target_dir" ] || ([ -f "$reg_file" ] && jq -e --arg s "$skill_name" '.skills[$s]' "$reg_file" >/dev/null 2>&1); then
        if [ "${FORCE_REPLACE:-false}" != true ]; then
            log_fail "Import rejected: Skill '$skill_name' already exists in canonical library. Use --force or --replace to overwrite."
            return 1
        fi
        log_warn "Target skill '$skill_name' exists. Overwriting (--force/--replace specified)..."
        rm -rf "$target_dir"
    fi

    # BLOCKER 7: Record reproducible commit SHA and license metadata
    local commit_sha="null"
    if [ -d "$tmp_dir/.git" ]; then
        commit_sha="$(cd "$tmp_dir" && git rev-parse HEAD 2>/dev/null || echo "null")"
    fi

    local license="unspecified"
    if [ -f "$tmp_dir/LICENSE" ]; then
        license="$(head -n 1 "$tmp_dir/LICENSE" | tr -d '\r\n')"
    elif [ -f "$tmp_dir/LICENSE.md" ]; then
        license="$(head -n 1 "$tmp_dir/LICENSE.md" | tr -d '\r\n')"
    fi

    mkdir -p "$target_dir"
    cp -a "$tmp_dir/." "$target_dir/"

    local hash
    hash="$(compute_skill_hash "$target_dir")"
    if [ -f "$reg_file" ]; then
        local desc
        desc="$(get_skill_desc "$target_dir")"
        local tmp_reg
        tmp_reg="$(mktemp "$reg_file.tmp.XXXXXX")"
        local now
        now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        jq --arg s "$skill_name" \
           --arg hash "$hash" \
           --arg desc "$desc" \
           --arg url "$src_location" \
           --arg commit "$commit_sha" \
           --arg license "$license" \
           --arg now "$now" \
           '
           .skills[$s] = {
               name: $s,
               version: "1.0.0",
               source: "external",
               domain: "imported",
               description: $desc,
               tags: ["imported", "community"],
               dependencies: [],
               capabilities: [],
               triggers: [$s],
               provenance: {
                   upstream_url: $url,
                   commit: (if $commit == "null" then null else $commit end),
                   license: $license,
                   verified_by: "curate.sh-security-audit",
                   imported_at: $now
               },
               content_hash: $hash
           }
           ' "$reg_file" > "$tmp_reg"
        mv -f "$tmp_reg" "$reg_file"
    fi

    log_ok "Successfully imported skill '$skill_name' into $target_dir (hash: $hash)"
}

select_skills_interactive() {
    if [ ! -d "$SKILLS_SRC" ]; then
        log_fail "No skills repository found at $SKILLS_SRC"
        return 1
    fi

    mapfile -t skills < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -exec test -f '{}/SKILL.md' ';' -exec basename {} \; | LC_ALL=C sort)
    if [ "${#skills[@]}" -eq 0 ]; then
        echo "No skills available in $SKILLS_SRC."
        return 0
    fi

    local selected_skills=()
    if command -v fzf >/dev/null 2>&1; then
        # shellcheck disable=SC2016
        mapfile -t selected_skills < <(printf '%s\n' "${skills[@]}" | fzf \
            --multi \
            --prompt="Select AI Skill(s) [TAB=Multi-select, ENTER=Confirm]: " \
            --header="[TAB] Toggle Selection | [Enter] Confirm | [ESC] Exit" \
            --preview "$REPO_ROOT/scripts/ai-skills.sh preview {}" \
            --preview-window="right:65%:wrap")
    else
        echo -e "${BOLD}${CYAN}Available AI Skills:${RESET}"
        local i=1
        for s in "${skills[@]}"; do
            echo "  $i) $s"
            i=$((i + 1))
        done
        read -r -p "Enter number(s) (e.g. 1,3 or 'all'): " choices
        if [ "$choices" = "all" ] || [ "$choices" = "*" ]; then
            selected_skills=("${skills[@]}")
        else
            IFS=', ' read -r -a nums <<< "$choices"
            for n in "${nums[@]}"; do
                if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#skills[@]}" ]; then
                    selected_skills+=("${skills[$((n - 1))]}")
                fi
            done
        fi
    fi

    if [ "${#selected_skills[@]}" -eq 0 ]; then
        return 0
    fi

    echo
    echo -e "${BOLD}Selected Skill(s):${RESET} ${GREEN}${selected_skills[*]}${RESET}"
    echo "1) Link to All Global Agents (Gemini, Antigravity IDE, Codex, Claude)"
    echo "2) Select Specific Global Agents via Multi-Select"
    echo "3) Install to Project (.agents/skills - physical copy + lockfile)"
    echo "4) Diff against Project copy"
    echo "5) Update in Project (refresh lockfile)"
    echo "6) Export ruleset snippet"
    echo "7) Remove / Unlink"
    echo "q) Quit"
    read -r -p "Choose action [1-7/q]: " action

    case "$action" in
        1)
            for s in "${selected_skills[@]}"; do
                install_global "$s" "all"
            done
            ;;
        2)
            local chosen_agents=()
            local agent_candidates=("antigravity-cli" "antigravity-ide" "codex-cli" "claude-code")
            if command -v fzf >/dev/null 2>&1; then
                mapfile -t chosen_agents < <(printf '%s\n' "${agent_candidates[@]}" | fzf \
                    --multi \
                    --prompt="Select Target Agent(s) [TAB=Multi-select, ENTER=Confirm]: " \
                    --header="[TAB] Toggle Selection | [Enter] Confirm")
            else
                chosen_agents=("antigravity-cli" "antigravity-ide" "codex-cli" "claude-code")
            fi
            for s in "${selected_skills[@]}"; do
                for a in "${chosen_agents[@]}"; do
                    install_global "$s" "$a"
                done
            done
            ;;
        3)
            local proj_root
            proj_root="$(find_project_root "$PWD")"
            local chosen_agents=()
            local agent_candidates=("antigravity-cli" "antigravity-ide" "codex-cli" "claude-code")
            if command -v fzf >/dev/null 2>&1; then
                mapfile -t chosen_agents < <(printf '%s\n' "${agent_candidates[@]}" | fzf \
                    --multi \
                    --prompt="Select Project Target Agent(s) [TAB=Multi-select, ENTER=Confirm]: " \
                    --header="[TAB] Toggle Selection | [Enter] Confirm")
            else
                chosen_agents=("antigravity-cli" "antigravity-ide" "codex-cli" "claude-code")
            fi
            if [ "${#chosen_agents[@]}" -eq 0 ]; then
                chosen_agents=("antigravity-cli" "antigravity-ide" "codex-cli" "claude-code")
            fi
            local target_paths=()
            mapfile -t target_paths < <(resolve_target_paths "project" "$proj_root" "${chosen_agents[@]}")
            for s in "${selected_skills[@]}"; do
                for dest_p in "${target_paths[@]}"; do
                    install_project "$s" "$dest_p" "$proj_root"
                done
            done
            ;;
        4)
            cmd_diff "${selected_skills[@]}"
            ;;
        5)
            cmd_update "${selected_skills[@]}"
            ;;
        6)
            for s in "${selected_skills[@]}"; do
                export_skill "$s"
            done
            ;;
        7)
            for s in "${selected_skills[@]}"; do
                remove_skill "$s" "all"
            done
            ;;
        *)
            echo "Cancelled."
            ;;
    esac
}

cmd_add() {
    local skills=()
    local MODE="global"
    local TARGET_OPT="all"
    local PROJECT_OPT=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --global|-g)
                MODE="global"
                if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                    TARGET_OPT="$2"
                    shift 2
                else
                    TARGET_OPT="all"
                    shift 1
                fi
                ;;
            --project|-p)
                MODE="project"
                if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                    PROJECT_OPT="$2"
                    shift 2
                else
                    shift 1
                fi
                ;;
            --target|-t)
                if [ "${2:-}" = "project" ]; then
                    MODE="project"
                else
                    TARGET_OPT="${2:-all}"
                fi
                shift 2 || shift 1
                ;;
            --force|-f)
                FORCE_REPLACE=true
                shift
                ;;
            --replace)
                FORCE_REPLACE=true
                shift
                ;;
            --backup|-b)
                ALLOW_BACKUP=true
                shift
                ;;
            project)
                MODE="project"
                shift
                ;;
            global)
                MODE="global"
                shift
                ;;
            all)
                TARGET_OPT="all"
                shift
                ;;
            *)
                skills+=("$1")
                shift
                ;;
        esac
    done

    if [ "${#skills[@]}" -eq 0 ]; then
        log_fail "Missing skill name. Usage: $(basename "$0") add <skill...> [--global <agent>] [--project [path]] [--target <agent>] [--force|--replace|--backup]"
        return 1
    fi

    if [ "$MODE" = "project" ]; then
        local proj_root
        if [ -n "$PROJECT_OPT" ]; then
            proj_root="$(find_project_root "$PROJECT_OPT")"
        else
            proj_root="$(find_project_root "$PWD")"
        fi
        local target_spec="${TARGET_OPT:-all}"
        local target_paths=()
        mapfile -t target_paths < <(resolve_target_paths "project" "$proj_root" "$target_spec")
        if [ "${#target_paths[@]}" -eq 0 ]; then
            target_paths=("$proj_root/.agents/skills")
        fi
        for sk in "${skills[@]}"; do
            for dest_p in "${target_paths[@]}"; do
                install_project "$sk" "$dest_p" "$proj_root"
            done
        done
    else
        for sk in "${skills[@]}"; do
            install_global "$sk" "$TARGET_OPT"
        done
    fi
}

cmd_remove() {
    local skills=()
    local MODE="all"
    local TARGET_OPT="all"
    local PROJECT_OPT=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --global|-g)
                MODE="global"
                if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                    TARGET_OPT="$2"
                    shift 2
                else
                    TARGET_OPT="all"
                    shift 1
                fi
                ;;
            --project|-p)
                MODE="project"
                if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                    PROJECT_OPT="$2"
                    shift 2
                else
                    shift 1
                fi
                ;;
            --target|-t)
                if [ "${2:-}" = "project" ]; then
                    MODE="project"
                else
                    TARGET_OPT="${2:-all}"
                fi
                shift 2 || shift 1
                ;;
            --force|-f|--replace)
                FORCE_REPLACE=true
                shift
                ;;
            --backup|-b)
                ALLOW_BACKUP=true
                shift
                ;;
            project)
                MODE="project"
                shift
                ;;
            global)
                MODE="global"
                shift
                ;;
            all)
                MODE="all"
                TARGET_OPT="all"
                shift
                ;;
            *)
                skills+=("$1")
                shift
                ;;
        esac
    done

    if [ "${#skills[@]}" -eq 0 ]; then
        log_fail "Missing skill name. Usage: $(basename "$0") remove <skill...> [--global <agent>] [--project [path]] [--target <agent>]"
        return 1
    fi

    for sk in "${skills[@]}"; do
        if [ "$MODE" = "project" ]; then
            local proj_root
            if [ -n "$PROJECT_OPT" ]; then
                proj_root="$(find_project_root "$PROJECT_OPT")"
            else
                proj_root="$(find_project_root "$PWD")"
            fi
            local target_spec="${TARGET_OPT:-all}"
            local target_paths=()
            mapfile -t target_paths < <(resolve_target_paths "project" "$proj_root" "$target_spec")
            if [ "${#target_paths[@]}" -eq 0 ]; then
                target_paths=("$proj_root/.agents/skills")
            fi
            for dest_p in "${target_paths[@]}"; do
                remove_project "$sk" "$dest_p" "$proj_root"
            done
        elif [ "$MODE" = "all" ] && [ "$TARGET_OPT" = "all" ]; then
            remove_global "$sk" "all"
            local proj_root
            proj_root="$(find_project_root "$PWD")"
            local target_paths=()
            mapfile -t target_paths < <(resolve_target_paths "project" "$proj_root" "all")
            for dest_p in "${target_paths[@]}"; do
                remove_project "$sk" "$dest_p" "$proj_root"
            done
        else
            remove_global "$sk" "$TARGET_OPT"
        fi
    done
}

show_usage() {
    echo "Usage: $(basename "$0") <command> [arguments]"
    echo
    echo "Commands:"
    echo "  list                                  List all available skills and their link status"
    echo "  search <keyword>                      Search skills by keyword across names, tags, capabilities"
    echo "  inspect <skill>                       Display detailed skill metadata, triggers, and provenance"
    echo "  discover                              List trusted external skill sources and registries"
    echo "  import <url|dir> [name]               Import external skill bundle into repository"
    echo "  add <skill...> [--global <agent>]     Link skill canonically to agent config (default: all)"
    echo "  add <skill...> --project [path]       Physically copy skill bundle into project and update lockfile"
    echo "  remove <skill...> [--global <agent>]  Unlink skill from global agent config"
    echo "  remove <skill...> --project [path]    Remove physical skill from project and lockfile"
    echo "  sync [--profile <name>]               Synchronize skills globally (default: global-core)"
    echo "  diff [skill...]                       Show unified diff between project skill and canonical version"
    echo "  update [skill...] [--force]           Safely update project skill and refresh lockfile hash"
    echo "  doctor                                Run diagnostic health audit on symlinks, locks, and binaries"
    echo "  preview <skill>                       Display full skill contents with rich metadata"
    echo "  export-rules                          Export compact baseline orchestration rules for editors"
    echo "  export [<skill>]                      Export ruleset snippet for a specific skill"
    echo "  interactive                           Interactive fzf / menu selector (default if no args)"
    echo "  help                                  Show this help message"
    echo
    echo "Examples:"
    echo "  ai-skills list"
    echo "  ai-skills search redis"
    echo "  ai-skills inspect architecture-designer"
    echo "  ai-skills discover"
    echo "  ai-skills sync --profile global-core"
    echo "  ai-skills add ponytail caveman --global claude"
    echo "  ai-skills add ponytail caveman --project"
    echo "  ai-skills diff ponytail"
    echo "  ai-skills update ponytail"
    echo "  ai-skills doctor"
}

# Main command dispatch
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    CMD="${1:-interactive}"
    shift || true

    case "$CMD" in
    list|--list|-l)
        list_skills
        ;;
    search)
        search_skills "$@"
        ;;
    inspect)
        inspect_skill "$@"
        ;;
    discover)
        discover_sources "$@"
        ;;
    import)
        import_skill "$@"
        ;;
    preview|show)
        if [ "$#" -lt 1 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") preview <skill>"
            exit 1
        fi
        preview_skill "$1"
        ;;
    add|install)
        cmd_add "$@"
        ;;
    remove|rm|uninstall)
        cmd_remove "$@"
        ;;
    diff)
        cmd_diff "$@"
        exit $?
        ;;
    update)
        cmd_update "$@"
        exit $?
        ;;
    doctor)
        cmd_doctor "$@"
        exit $?
        ;;
    sync)
        sync_skills "$@"
        ;;
    export-rules)
        export_rules "$@"
        ;;
    export)
        if [ "${1:-}" = "--all" ] || [ "$#" -eq 0 ]; then
            export_rules
        else
            export_skill "$1"
        fi
        ;;
    interactive)
        select_skills_interactive
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        # If user passed skill name directly (e.g. `add-skills ponytail`)
        if [ -d "$SKILLS_SRC/$CMD" ]; then
            add_skill "$CMD" "${1:-all}"
        else
            log_fail "Unknown command or skill: '$CMD'"
            show_usage
            exit 1
        fi
        ;;
    esac
fi

