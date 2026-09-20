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
    local skill_file="$SKILLS_SRC/$name/SKILL.md"
    if [ ! -f "$skill_file" ]; then
        log_fail "Skill '$name' not found at $SKILLS_SRC/$name"
        return 1
    fi

    echo -e "${BOLD}${CYAN}=== Skill: $name ===${RESET}"
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
    log_info "Synchronizing all canonical skills to user agents..."
    if [ ! -d "$SKILLS_SRC" ]; then
        log_warn "No skills directory at $SKILLS_SRC"
        return 0
    fi

    for skill_dir in "$SKILLS_SRC"/*; do
        [ -d "$skill_dir" ] || continue
        [ -f "$skill_dir/SKILL.md" ] || continue
        local name
        name="$(basename "$skill_dir")"
        [[ "$name" == _* ]] && continue
        add_skill "$name" "all"
    done
    log_ok "All skills synchronized successfully"
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

interactive_mode() {
    if [ ! -d "$SKILLS_SRC" ]; then
        log_fail "No skills repository found at $SKILLS_SRC"
        return 1
    fi

    mapfile -t skills < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d ! -name '_*' -exec test -f '{}/SKILL.md' ';' -exec basename {} \; | sort)
    if [ "${#skills[@]}" -eq 0 ]; then
        echo "No skills available in $SKILLS_SRC."
        return 0
    fi

    local selected_skill=""
    if command -v fzf >/dev/null 2>&1; then
        # shellcheck disable=SC2016
        selected_skill=$(printf '%s\n' "${skills[@]}" | fzf \
            --prompt="Select AI Skill: " \
            --header="[Enter] Select | [ESC] Exit" \
            --preview "cat $SKILLS_SRC/{}/SKILL.md 2>/dev/null || echo 'No preview'" \
            --preview-window="right:60%:wrap")
    else
        echo -e "${BOLD}${CYAN}Select an AI Skill:${RESET}"
        local i=1
        for s in "${skills[@]}"; do
            echo "  $i) $s"
            i=$((i + 1))
        done
        read -r -p "Enter number (1-${#skills[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#skills[@]}" ]; then
            selected_skill="${skills[$((choice - 1))]}"
        fi
    fi

    if [ -z "$selected_skill" ]; then
        return 0
    fi

    echo
    echo -e "Selected Skill: ${BOLD}${selected_skill}${RESET}"
    echo "1) Link to All (Gemini, Codex & Claude)"
    echo "2) Link to Gemini / Antigravity CLI only"
    echo "3) Link to Codex CLI only"
    echo "4) Link to Claude Code only"
    echo "5) Link to current project (.agents/skills)"
    echo "6) Export ruleset snippet for .cursorrules / CLAUDE.md"
    echo "7) Unlink / Remove skill"
    echo "q) Quit"
    read -r -p "Choose action [1-7/q]: " action

    case "$action" in
        1) add_skill "$selected_skill" "all" ;;
        2) add_skill "$selected_skill" "gemini" ;;
        3) add_skill "$selected_skill" "codex" ;;
        4) add_skill "$selected_skill" "claude" ;;
        5) add_skill "$selected_skill" "project" ;;
        6) export_skill "$selected_skill" ;;
        7) remove_skill "$selected_skill" "all" ;;
        *) echo "Cancelled." ;;
    esac
}

show_usage() {
    echo "Usage: $(basename "$0") <command> [arguments]"
    echo
    echo "Commands:"
    echo "  list                                  List all available skills and their link status"
    echo "  add <skill> [--global <agent>]        Link skill canonically to agent config (default: all)"
    echo "  add <skill> --project [path]          Physically copy skill bundle into project and update lockfile"
    echo "  remove <skill> [--global <agent>]     Unlink skill from global agent config"
    echo "  remove <skill> --project [path]       Remove physical skill from project and lockfile"
    echo "  sync                                  Synchronize all repository skills globally"
    echo "  preview <skill>                       Display full skill contents"
    echo "  export <skill>                        Export markdown snippet for project rules"
    echo "  interactive                           Interactive fzf / menu selector (default if no args)"
    echo "  help                                  Show this help message"
    echo
    echo "Examples:"
    echo "  add-skills list"
    echo "  add-skills add ponytail --global claude"
    echo "  add-skills add ponytail --project"
    echo "  add-skills add ponytail --project .agents/skills"
    echo "  add-skills sync"
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
        if [ "$#" -lt 1 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") add <skill> [--global <agent>] [--project [path]]"
            exit 1
        fi
        SKILL_NAME="$1"
        MODE="global"
        TARGET_OPT="all"
        PROJECT_OPT="$PROJECT_SKILLS_DIR"
        shift
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --global|-g)
                    MODE="global"
                    TARGET_OPT="${2:-all}"
                    shift 2 || shift 1
                    ;;
                --project|-p)
                    MODE="project"
                    if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                        PROJECT_OPT="$2"
                        shift 2
                    else
                        PROJECT_OPT="$PROJECT_SKILLS_DIR"
                        shift 1
                    fi
                    ;;
                --target|-t)
                    if [ "${2:-}" = "project" ]; then
                        MODE="project"
                        PROJECT_OPT="$PROJECT_SKILLS_DIR"
                    else
                        MODE="global"
                        TARGET_OPT="${2:-all}"
                    fi
                    shift 2 || shift 1
                    ;;
                project)
                    MODE="project"
                    PROJECT_OPT="$PROJECT_SKILLS_DIR"
                    shift
                    ;;
                *)
                    TARGET_OPT="$1"
                    shift
                    ;;
            esac
        done
        if [ "$MODE" = "project" ]; then
            install_project "$SKILL_NAME" "$PROJECT_OPT"
        else
            install_global "$SKILL_NAME" "$TARGET_OPT"
        fi
        ;;
    remove|rm|uninstall)
        if [ "$#" -lt 1 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") remove <skill> [--global <agent>] [--project [path]]"
            exit 1
        fi
        SKILL_NAME="$1"
        MODE="global"
        TARGET_OPT="all"
        PROJECT_OPT="$PROJECT_SKILLS_DIR"
        shift
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --global|-g)
                    MODE="global"
                    TARGET_OPT="${2:-all}"
                    shift 2 || shift 1
                    ;;
                --project|-p)
                    MODE="project"
                    if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
                        PROJECT_OPT="$2"
                        shift 2
                    else
                        PROJECT_OPT="$PROJECT_SKILLS_DIR"
                        shift 1
                    fi
                    ;;
                --target|-t)
                    if [ "${2:-}" = "project" ]; then
                        MODE="project"
                        PROJECT_OPT="$PROJECT_SKILLS_DIR"
                    else
                        MODE="global"
                        TARGET_OPT="${2:-all}"
                    fi
                    shift 2 || shift 1
                    ;;
                project)
                    MODE="project"
                    PROJECT_OPT="$PROJECT_SKILLS_DIR"
                    shift
                    ;;
                *)
                    TARGET_OPT="$1"
                    shift
                    ;;
            esac
        done
        if [ "$MODE" = "project" ]; then
            remove_project "$SKILL_NAME" "$PROJECT_OPT"
        elif [ "$TARGET_OPT" = "all" ]; then
            remove_global "$SKILL_NAME" "all"
            remove_project "$SKILL_NAME" "$PROJECT_OPT"
        else
            remove_global "$SKILL_NAME" "$TARGET_OPT"
        fi
        ;;
    sync)
        sync_skills
        ;;
    export)
        if [ "$#" -lt 1 ]; then
            log_fail "Missing skill name. Usage: $(basename "$0") export <skill>"
            exit 1
        fi
        export_skill "$1"
        ;;
    interactive)
        interactive_mode
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
