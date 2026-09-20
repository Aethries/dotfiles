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

GEMINI_SKILLS_DIR="$(resolve_agent_global_path antigravity-cli "$TARGET_HOME")"
GEMINI_IDE_SKILLS_DIR="$(resolve_agent_global_path antigravity-ide "$TARGET_HOME")"
CODEX_SKILLS_DIR="$(resolve_agent_global_path codex-cli "$TARGET_HOME")"
CLAUDE_SKILLS_DIR="$(resolve_agent_global_path claude-code "$TARGET_HOME")"
PROJECT_SKILLS_DIR="$PWD/.agents/skills"

safe_link() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local backup
        backup="${dest}.pre-skill.$(date +%Y%m%d%H%M%S)"
        mv -- "$dest" "$backup"
        log_warn "Moved existing non-symlink $dest to $backup"
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

        if [ -L "$GEMINI_SKILLS_DIR/$name" ] && [ -e "$GEMINI_SKILLS_DIR/$name" ]; then
            status_gemini="${GREEN}●${RESET}"
        fi
        if [ -L "$CODEX_SKILLS_DIR/$name" ] && [ -e "$CODEX_SKILLS_DIR/$name" ]; then
            status_codex="${GREEN}●${RESET}"
        fi
        if [ -L "$CLAUDE_SKILLS_DIR/$name" ] && [ -e "$CLAUDE_SKILLS_DIR/$name" ]; then
            status_claude="${GREEN}●${RESET}"
        fi
        if [ -L "$PROJECT_SKILLS_DIR/$name" ] && [ -e "$PROJECT_SKILLS_DIR/$name" ]; then
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
  "version": 1,
  "generated_at": "",
  "skills": {}
}
EOF
    fi

    local iso_timestamp
    iso_timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    local tmp_lock
    tmp_lock="$(mktemp "$proj_root/.agent-skills.lock.tmp.XXXXXX")"

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
           --arg time "$iso_timestamp" \
           '
           .generated_at = $time |
           .skills[$skill] = {
               version: $ver,
               source: $src,
               content_hash: $hash,
               target_path: $path
           }
           ' "$lock_file" > "$tmp_lock"
        mv -f "$tmp_lock" "$lock_file"
        log_ok "Updated lockfile: $lock_file (recorded $skill_name@$ver)"
    elif [ "$action" = "remove" ]; then
        jq --arg skill "$skill_name" \
           --arg time "$iso_timestamp" \
           '
           .generated_at = $time |
           del(.skills[$skill])
           ' "$lock_file" > "$tmp_lock"
        mv -f "$tmp_lock" "$lock_file"
        log_ok "Updated lockfile: $lock_file (removed $skill_name)"
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

    case "$target" in
        all)
            safe_link "$skill_dir" "$GEMINI_SKILLS_DIR/$name"
            log_ok "Linked globally to Gemini/Antigravity CLI: $GEMINI_SKILLS_DIR/$name"
            safe_link "$skill_dir" "$CODEX_SKILLS_DIR/$name"
            log_ok "Linked globally to Codex CLI: $CODEX_SKILLS_DIR/$name"
            safe_link "$skill_dir" "$CLAUDE_SKILLS_DIR/$name"
            log_ok "Linked globally to Claude Code: $CLAUDE_SKILLS_DIR/$name"
            ;;
        gemini|antigravity)
            safe_link "$skill_dir" "$GEMINI_SKILLS_DIR/$name"
            log_ok "Linked globally to Gemini/Antigravity CLI: $GEMINI_SKILLS_DIR/$name"
            ;;
        antigravity-ide)
            safe_link "$skill_dir" "$GEMINI_IDE_SKILLS_DIR/$name"
            log_ok "Linked globally to Antigravity IDE: $GEMINI_IDE_SKILLS_DIR/$name"
            ;;
        codex|codex-cli)
            safe_link "$skill_dir" "$CODEX_SKILLS_DIR/$name"
            log_ok "Linked globally to Codex CLI: $CODEX_SKILLS_DIR/$name"
            ;;
        claude|claude-code)
            safe_link "$skill_dir" "$CLAUDE_SKILLS_DIR/$name"
            log_ok "Linked globally to Claude Code: $CLAUDE_SKILLS_DIR/$name"
            ;;
        *)
            local custom_path
            custom_path="$(resolve_agent_global_path "$target" "$TARGET_HOME")"
            if [ -n "$custom_path" ] && [ "$custom_path" != "$TARGET_HOME/.$target/skills" ]; then
                safe_link "$skill_dir" "$custom_path/$name"
                log_ok "Linked globally to $(get_agent_name "$target"): $custom_path/$name"
            else
                log_fail "Unknown global target: $target (choose: all, gemini, codex, claude, or agent id)"
                return 1
            fi
            ;;
    esac
}

install_project() {
    local name="$1"
    local dest_base="${2:-$PROJECT_SKILLS_DIR}"
    [ "$dest_base" = "project" ] && dest_base="$PROJECT_SKILLS_DIR"
    local skill_src="$SKILLS_SRC/$name"

    if [ ! -d "$skill_src" ] || [ ! -f "$skill_src/SKILL.md" ]; then
        log_fail "Skill '$name' does not exist in $SKILLS_SRC"
        return 1
    fi

    log_info "Installing skill '$name' into project (path: $dest_base)..."

    local dest="$dest_base/$name"

    # Strict invariant: Project = physical copy, NOT symlink
    if [ -L "$dest" ]; then
        log_warn "Replacing existing symlink $dest with true directory copy"
        rm -f "$dest"
    elif [ -d "$dest" ]; then
        rm -rf "$dest"
    fi

    mkdir -p "$dest"
    cp -f "$skill_src/SKILL.md" "$dest/"

    for subdir in references scripts assets; do
        if [ -d "$skill_src/$subdir" ]; then
            cp -a "$skill_src/$subdir" "$dest/"
        fi
    done

    # Verify storage invariant
    if [ -L "$dest" ] || [ ! -d "$dest" ] || [ ! -f "$dest/SKILL.md" ]; then
        log_fail "Physical copy assertion failed for project skill: $dest"
        return 1
    fi

    local proj_root
    proj_root="$(find_project_root "$dest_base")"
    local rel_path
    if [[ "$dest" == "$proj_root/"* ]]; then
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

    case "$target" in
        all)
            safe_unlink "$GEMINI_SKILLS_DIR/$name"
            safe_unlink "$CODEX_SKILLS_DIR/$name"
            safe_unlink "$CLAUDE_SKILLS_DIR/$name"
            ;;
        gemini|antigravity)
            safe_unlink "$GEMINI_SKILLS_DIR/$name"
            ;;
        antigravity-ide)
            safe_unlink "$GEMINI_IDE_SKILLS_DIR/$name"
            ;;
        codex|codex-cli)
            safe_unlink "$CODEX_SKILLS_DIR/$name"
            ;;
        claude|claude-code)
            safe_unlink "$CLAUDE_SKILLS_DIR/$name"
            ;;
        *)
            local custom_path
            custom_path="$(resolve_agent_global_path "$target" "$TARGET_HOME")"
            if [ -n "$custom_path" ]; then
                safe_unlink "$custom_path/$name"
            else
                log_fail "Unknown global target: $target"
                return 1
            fi
            ;;
    esac
}

remove_project() {
    local name="$1"
    local dest_base="${2:-$PROJECT_SKILLS_DIR}"
    [ "$dest_base" = "project" ] && dest_base="$PROJECT_SKILLS_DIR"
    local dest="$dest_base/$name"

    log_info "Removing project skill '$name' from $dest_base..."

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -rf "$dest"
        log_ok "Removed project skill directory: $dest"
    else
        log_warn "Project skill $dest does not exist"
    fi

    local proj_root
    proj_root="$(find_project_root "$dest_base")"
    update_project_lockfile "$proj_root" "$name" "remove" ""
}

add_skill() {
    local name="$1"
    local mode_or_target="${2:-all}"
    local path_or_agent="${3:-}"

    case "$mode_or_target" in
        project)
            install_project "$name" "${path_or_agent:-$PROJECT_SKILLS_DIR}"
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
            remove_project "$name" "${path_or_agent:-$PROJECT_SKILLS_DIR}"
            ;;
        global)
            remove_global "$name" "${path_or_agent:-all}"
            ;;
        all)
            remove_global "$name" "all"
            if [ -e "${path_or_agent:-$PROJECT_SKILLS_DIR}/$name" ]; then
                remove_project "$name" "${path_or_agent:-$PROJECT_SKILLS_DIR}"
            fi
            ;;
        *)
            remove_global "$name" "$mode_or_target"
            ;;
    esac
}

sync_skills() {
    log_info "Synchronizing canonical skills from _registry.json to user agents..."
    if [ ! -d "$SKILLS_SRC" ]; then
        log_warn "No skills directory at $SKILLS_SRC"
        return 0
    fi

    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    local skill_names=()
    if [ -f "$reg_file" ]; then
        mapfile -t skill_names < <(jq -r '.skills | keys[]' "$reg_file" | LC_ALL=C sort)
    else
        mapfile -t skill_names < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -exec test -f '{}/SKILL.md' ';' -exec basename {} \; | LC_ALL=C sort)
    fi

    for name in "${skill_names[@]}"; do
        [ -d "$SKILLS_SRC/$name" ] || continue
        [ -f "$SKILLS_SRC/$name/SKILL.md" ] || continue
        install_global "$name" "all"
    done

    # Reconcile and clean up broken symlinks across agent global directories
    local agent_ids
    agent_ids="$(get_all_agent_ids)"
    for agent in $agent_ids; do
        local gpath
        gpath="$(resolve_agent_global_path "$agent" "$TARGET_HOME")"
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

    log_ok "All skills synchronized successfully against _registry.json"
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

export_all_rules() {
    echo "<!-- Consolidated AI Rules & Instructions -->"
    echo "# AI Agent Guidelines & Engineering Standards"
    echo
    echo "> Generated automatically from canonical AI skills registry."
    echo
    local reg_file="$REPO_ROOT/resources/skills/_registry.json"
    local skill_names=()
    if [ -f "$reg_file" ]; then
        mapfile -t skill_names < <(jq -r '.skills | keys[]' "$reg_file" | LC_ALL=C sort)
    else
        mapfile -t skill_names < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -exec test -f '{}/SKILL.md' ';' -exec basename {} \; | LC_ALL=C sort)
    fi

    for s in "${skill_names[@]}"; do
        local skill_file="$SKILLS_SRC/$s/SKILL.md"
        [ -f "$skill_file" ] || continue
        echo "## $s"
        echo
        sed -e '1{/^---$/!q;};1,/^---$/d' "$skill_file"
        echo
        echo "---"
        echo
    done
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

        local local_dir=""
        if [ -f "$lock_file" ]; then
            local rel_path
            rel_path="$(jq -r --arg s "$s" '.skills[$s].target_path // empty' "$lock_file" 2>/dev/null || true)"
            if [ -n "$rel_path" ] && [ -d "$proj_root/$rel_path" ]; then
                local_dir="$proj_root/$rel_path"
            fi
        fi

        if [ -z "$local_dir" ]; then
            if [ -d "$proj_root/.agents/skills/$s" ]; then
                local_dir="$proj_root/.agents/skills/$s"
            elif [ -d "$proj_root/.codex/skills/$s" ]; then
                local_dir="$proj_root/.codex/skills/$s"
            elif [ -d "$proj_root/.claude/skills/$s" ]; then
                local_dir="$proj_root/.claude/skills/$s"
            fi
        fi

        if [ -z "$local_dir" ] || [ ! -d "$local_dir" ]; then
            log_fail "Project skill '$s' not found on disk in $proj_root"
            has_diff=1
            continue
        fi

        echo -e "${BOLD}${CYAN}Diffing skill '$s': canonical ($canonical_dir) <-> local ($local_dir)${RESET}"
        if ! diff -u -r "$canonical_dir" "$local_dir"; then
            has_diff=1
        else
            log_ok "Skill '$s' matches canonical version"
        fi
        echo
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

        local local_dir=""
        local rel_path=""
        if [ -f "$lock_file" ]; then
            rel_path="$(jq -r --arg s "$s" '.skills[$s].target_path // empty' "$lock_file" 2>/dev/null || true)"
            if [ -n "$rel_path" ] && [ -d "$proj_root/$rel_path" ]; then
                local_dir="$proj_root/$rel_path"
            fi
        fi

        if [ -z "$local_dir" ]; then
            if [ -d "$proj_root/.agents/skills/$s" ]; then
                rel_path=".agents/skills/$s"
                local_dir="$proj_root/$rel_path"
            elif [ -d "$proj_root/.codex/skills/$s" ]; then
                rel_path=".codex/skills/$s"
                local_dir="$proj_root/$rel_path"
            elif [ -d "$proj_root/.claude/skills/$s" ]; then
                rel_path=".claude/skills/$s"
                local_dir="$proj_root/$rel_path"
            fi
        fi

        if [ -z "$local_dir" ] || [ ! -d "$local_dir" ]; then
            log_fail "Project skill '$s' not found on disk to update"
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
                    read -r -p "Skill '$s' has local modifications. Overwrite with canonical? [y/N]: " confirm
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

        # Safely copy canonical bundle
        rm -rf "$local_dir"
        mkdir -p "$local_dir"
        cp -f "$canonical_dir/SKILL.md" "$local_dir/"
        for subdir in references scripts assets; do
            if [ -d "$canonical_dir/$subdir" ]; then
                cp -a "$canonical_dir/$subdir" "$local_dir/"
            fi
        done

        update_project_lockfile "$proj_root" "$s" "add" "$rel_path"
        log_ok "Updated skill '$s' in project: $local_dir (content hash: $canonical_hash)"
        update_count=$((update_count + 1))
    done

    log_ok "Updated $update_count skill(s) in $proj_root"
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
        local gpath
        gpath="$(resolve_agent_global_path "$agent" "$TARGET_HOME")"
        if [ -d "$gpath" ]; then
            for link in "$gpath"/*; do
                [ -e "$link" ] || [ -L "$link" ] || continue
                local link_name
                link_name="$(basename "$link")"
                [[ "$link_name" == _* ]] && continue
                if [ -L "$link" ]; then
                    if [ -e "$link" ]; then
                        echo -e "  [${GREEN}✓${RESET}] $agent: $link_name -> $(readlink "$link")"
                        doctor_ok=$((doctor_ok + 1))
                    else
                        echo -e "  [${RED}✗${RESET}] $agent: BROKEN symlink: $link -> $(readlink "$link")"
                        doctor_errors=$((doctor_errors + 1))
                    fi
                elif [ -d "$link" ]; then
                    echo -e "  [${YELLOW}!${RESET}] $agent: $link_name is a directory, not a symlink"
                    doctor_warns=$((doctor_warns + 1))
                fi
            done
        fi
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
            local rel_path
            rel_path="$(jq -r --arg s "$s" '.skills[$s].target_path // empty' "$lock_file")"
            [ -z "$rel_path" ] && rel_path=".agents/skills/$s"
            local full_path="$proj_root/$rel_path"

            if [ ! -d "$full_path" ]; then
                echo -e "  [${RED}✗${RESET}] Skill '$s': missing on disk at $full_path"
                doctor_errors=$((doctor_errors + 1))
            else
                local actual_hash
                actual_hash="$(compute_skill_hash "$full_path")"
                if [ "$actual_hash" = "$expected_hash" ]; then
                    echo -e "  [${GREEN}✓${RESET}] Skill '$s': hash verified ($actual_hash)"
                    doctor_ok=$((doctor_ok + 1))
                else
                    echo -e "  [${YELLOW}!${RESET}] Skill '$s': modified/drifted (lock: $expected_hash, local: $actual_hash)"
                    doctor_warns=$((doctor_warns + 1))
                fi
            fi
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
            for s in "${selected_skills[@]}"; do
                install_project "$s" "$proj_root/.agents/skills"
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

show_usage() {
    echo "Usage: $(basename "$0") <command> [arguments]"
    echo
    echo "Commands:"
    echo "  list                                  List all available skills and their link status"
    echo "  add <skill...> [--global <agent>]     Link skill canonically to agent config (default: all)"
    echo "  add <skill...> --project [path]       Physically copy skill bundle into project and update lockfile"
    echo "  remove <skill...> [--global <agent>]  Unlink skill from global agent config"
    echo "  remove <skill...> --project [path]    Remove physical skill from project and lockfile"
    echo "  sync                                  Synchronize all canonical skills globally against _registry.json"
    echo "  diff [skill...]                       Show unified diff between project skill and canonical version"
    echo "  update [skill...] [--force]           Safely update project skill and refresh lockfile hash"
    echo "  doctor                                Run diagnostic health audit on symlinks, locks, and binaries"
    echo "  preview <skill>                       Display full skill contents with rich metadata"
    echo "  export [<skill>|--all]                Export ruleset snippet for project rules or all instructions"
    echo "  interactive                           Interactive fzf / menu selector (default if no args)"
    echo "  help                                  Show this help message"
    echo
    echo "Examples:"
    echo "  ai-skills list"
    echo "  ai-skills add ponytail caveman --global claude"
    echo "  ai-skills add ponytail caveman --project"
    echo "  ai-skills diff ponytail"
    echo "  ai-skills update ponytail"
    echo "  ai-skills doctor"
    echo "  ai-skills sync"
}

# Main command dispatch
CMD="${1:-interactive}"
shift || true

case "$CMD" in
    list|--list|-l)
        list_skills
        ;;
    preview|show)
        if [ "$#" -lt 1 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") preview <skill>"
            exit 1
        fi
        preview_skill "$1"
        ;;
    add|install)
        skills=()
        MODE="global"
        TARGET_OPT="all"
        TARGET_SPECIFIED=false
        PROJECT_OPT=""
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --global|-g)
                    MODE="global"
                    TARGET_SPECIFIED=true
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
                    TARGET_SPECIFIED=true
                    if [ "${2:-}" = "project" ]; then
                        MODE="project"
                    else
                        TARGET_OPT="${2:-all}"
                    fi
                    shift 2 || shift 1
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
                    TARGET_SPECIFIED=true
                    shift
                    ;;
                *)
                    skills+=("$1")
                    shift
                    ;;
            esac
        done

        if [ "${#skills[@]}" -eq 0 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") add <skill...> [--global <agent>] [--project [path]]"
            exit 1
        fi

        if [ "$MODE" = "project" ]; then
            target_paths=()
            if [ -n "$PROJECT_OPT" ]; then
                target_paths=("$PROJECT_OPT")
            elif [ "$TARGET_SPECIFIED" = true ]; then
                proj_root="$(find_project_root "$PWD")"
                mapfile -t target_paths < <(resolve_target_paths "project" "$proj_root" "$TARGET_OPT")
            else
                proj_root="$(find_project_root "$PWD")"
                target_paths=("$proj_root/.agents/skills")
            fi
            for sk in "${skills[@]}"; do
                for dest_p in "${target_paths[@]}"; do
                    install_project "$sk" "$dest_p"
                done
            done
        else
            for sk in "${skills[@]}"; do
                install_global "$sk" "$TARGET_OPT"
            done
        fi
        ;;
    remove|rm|uninstall)
        skills=()
        MODE="all"
        TARGET_OPT="all"
        TARGET_SPECIFIED=false
        PROJECT_OPT=""
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --global|-g)
                    MODE="global"
                    TARGET_SPECIFIED=true
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
                    TARGET_SPECIFIED=true
                    if [ "${2:-}" = "project" ]; then
                        MODE="project"
                    else
                        TARGET_OPT="${2:-all}"
                    fi
                    shift 2 || shift 1
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
                    TARGET_SPECIFIED=true
                    shift
                    ;;
                *)
                    skills+=("$1")
                    shift
                    ;;
            esac
        done

        if [ "${#skills[@]}" -eq 0 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") remove <skill...> [--global <agent>] [--project [path]]"
            exit 1
        fi

        for sk in "${skills[@]}"; do
            if [ "$MODE" = "project" ]; then
                target_paths=()
                if [ -n "$PROJECT_OPT" ]; then
                    target_paths=("$PROJECT_OPT")
                elif [ "$TARGET_SPECIFIED" = true ]; then
                    proj_root="$(find_project_root "$PWD")"
                    mapfile -t target_paths < <(resolve_target_paths "project" "$proj_root" "$TARGET_OPT")
                else
                    proj_root="$(find_project_root "$PWD")"
                    target_paths=("$proj_root/.agents/skills")
                fi
                for dest_p in "${target_paths[@]}"; do
                    remove_project "$sk" "$dest_p"
                done
            elif [ "$MODE" = "all" ] && [ "$TARGET_OPT" = "all" ]; then
                remove_global "$sk" "all"
                proj_root="$(find_project_root "$PWD")"
                if [ -e "$proj_root/.agents/skills/$sk" ]; then
                    remove_project "$sk" "$proj_root/.agents/skills"
                fi
            else
                remove_global "$sk" "$TARGET_OPT"
            fi
        done
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
        sync_skills
        ;;
    export)
        if [ "${1:-}" = "--all" ] || [ "$#" -eq 0 ]; then
            export_all_rules
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

