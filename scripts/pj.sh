#!/usr/bin/env bash
# ==============================================================================
# pj: High-Performance Project & Session Switcher
# Powered by fzf, Zellij, Neovim & Antigravity IDE
# ==============================================================================

set -euo pipefail

WORKSPACE_DIRS=(
    "$HOME/Workspaces"
    "$HOME/Projects"
    "$HOME/Repos"
    "$HOME/src"
)

# Collect list of project directories (Git repositories & top-level workspace folders)
get_projects() {
    for base in "${WORKSPACE_DIRS[@]}"; do
        if [ -d "$base" ]; then
            # Find git repositories or top-level project folders
            find "$base" -mindepth 1 -maxdepth 2 -type d \( -name ".git" -o -exec test -d "{}/.git" \; \) -prune -print 2>/dev/null | sed 's/\/\.git$//' | sort -u
            # Also include non-git folders directly under ~/Workspaces
            find "$base" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
        fi
    done | sort -u
}

PROJECTS=$(get_projects)

if [ -z "$PROJECTS" ]; then
    echo "No projects found in ${WORKSPACE_DIRS[*]}"
    exit 0
fi

# FZF Interactive Selector with instant previews and action keybindings
# shellcheck disable=SC2016
SELECTION=$(echo "$PROJECTS" | fzf \
    --height=100% \
    --layout=reverse \
    --prompt="🚀 Jump to Project: " \
    --border=rounded \
    --header="[Enter] Zellij Session (or Tab inside Zellij) | [Ctrl+O / Ctrl+A] Antigravity IDE | [Ctrl+N] Neovim | [Ctrl+W] Worktree | [Ctrl+G] Lazygit | [Ctrl+Y] Yazi" \
    --expect="ctrl-o,ctrl-a,ctrl-n,ctrl-g,ctrl-y,ctrl-w" \
    --preview='
        dir={}
        if [ -d "$dir/.git" ]; then
            echo -e "\033[1;34m==> Git Repository: \033[0m$dir"
            echo
            git -C "$dir" status -s
            echo
            echo -e "\033[1;33mRecent Commits:\033[0m"
            git -C "$dir" log -n 5 --color=always --format="%C(auto)%h %s %C(dim)(%cr)%Creset" 2>/dev/null
        else
            echo -e "\033[1;34m==> Directory: \033[0m$dir"
            echo
            eza -T -L 2 --icons=auto "$dir" 2>/dev/null || ls -la "$dir"
        fi
    ' \
    --preview-window="right:55%:wrap"
) || exit 0

KEY=$(head -n 1 <<< "$SELECTION")
TARGET_DIR=$(tail -n +2 <<< "$SELECTION" | head -n 1)

if [ -z "$TARGET_DIR" ]; then
    exit 0
fi

PROJECT_NAME=$(basename "$TARGET_DIR" | tr '.' '-' | tr ' ' '-')

case "$KEY" in
    ctrl-w)
        # Git Worktree switcher
        if [ -d "$TARGET_DIR/.git" ] || [ -f "$TARGET_DIR/.git" ]; then
            WORKTREES=$(git -C "$TARGET_DIR" worktree list --porcelain 2>/dev/null | grep "^worktree " | cut -d' ' -f2-)
            if [ -n "$WORKTREES" ]; then
                WT_SEL=$(echo "$WORKTREES" | fzf --prompt="🌳 Select Worktree: " --height=40% --layout=reverse --border=rounded) || exit 0
                if [ -n "$WT_SEL" ]; then
                    cd "$WT_SEL"
                    exec nvim .
                fi
            fi
        fi
        exit 0
        ;;
    ctrl-o|ctrl-a)
        # Open in Antigravity IDE (detached from transient terminal session)
        setsid -f antigravity-ide "$TARGET_DIR" >/dev/null 2>&1
        exit 0
        ;;
    ctrl-n)
        # Open directly in Neovim
        cd "$TARGET_DIR"
        exec nvim .
        ;;
    ctrl-g)
        # Open directly in Lazygit
        cd "$TARGET_DIR"
        exec lazygit
        ;;
    ctrl-y)
        # Open in Yazi
        cd "$TARGET_DIR"
        exec yazi
        ;;
    *)
        # Default (Enter): Open tab if inside Zellij; create or confirm-attach if outside
        cd "$TARGET_DIR"
        if [ -n "${ZELLIJ:-}" ]; then
            # Inside an existing Zellij session: open a project tab in the current session
            zellij action new-tab --name "$PROJECT_NAME" --cwd "$TARGET_DIR"
        else
            # Outside Zellij: check if session already exists to avoid accidental multi-client attach
            if zellij list-sessions --short --no-formatting 2>/dev/null | grep -Fxq -- "$PROJECT_NAME"; then
                echo "Notice: Session '$PROJECT_NAME' is already active or saved."
                echo "Connecting a second client enforces the smallest terminal geometry across clients."
                read -r -p "Attach to '$PROJECT_NAME'? [Y/n] " confirm
                if [[ "${confirm:-y}" =~ ^[Yy]$ ]]; then
                    exec zellij attach "$PROJECT_NAME"
                else
                    echo "Attach aborted."
                    exit 0
                fi
            else
                # A repository can own its workspace declaratively. Fall back to
                # the generic work layout for projects without .zellij.kdl.
                if [ -f "$TARGET_DIR/.zellij.kdl" ]; then
                    LAYOUT_PATH="$TARGET_DIR/.zellij.kdl"
                else
                    LAYOUT_PATH="$HOME/.config/zellij/layouts/work.kdl"
                fi
                if [ -f "$LAYOUT_PATH" ]; then
                    exec zellij --session "$PROJECT_NAME" --layout "$LAYOUT_PATH"
                else
                    exec zellij --session "$PROJECT_NAME"
                fi
            fi
        fi
        ;;
esac
