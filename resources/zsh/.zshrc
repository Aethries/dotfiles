# ==============================================================================
# Zsh Configuration (.zshrc)
# High performance Zsh powered by Zimfw & Starship
# ==============================================================================

# Default Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Path additions
export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

# History Configuration
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# ------------------------------------------------------------------------------
# Zimfw Framework Initialization
# ------------------------------------------------------------------------------
ZIM_HOME="${ZDOTDIR:-${HOME}}/.zim"

# Auto-download zimfw if missing
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# ------------------------------------------------------------------------------
# Zsh Vi Mode (jeffreytse/zsh-vi-mode) Settings
# ------------------------------------------------------------------------------
ZVM_INIT_MODE=sourcing
ZVM_VI_EDITOR="nvim"
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

# Caret style: Thin caret (beam) cho Insert, Block cho Normal & Visual
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE

# Chống conflict với Neovim:
# 1. Tắt đổi cursor khi chạy bên trong Neovim (:terminal)
if [[ -n "$NVIM" ]]; then
  ZVM_CURSOR_STYLE_ENABLED=false
fi

# Build & initialize Zim modules
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
(( $+functions[compdef] )) || compdef() { :; }
source ${ZIM_HOME}/init.zsh

# ------------------------------------------------------------------------------
# Zsh Autosuggestions Settings
# ------------------------------------------------------------------------------
# Chỉ hoàn thành autocomplete khi bấm Shift+Tab (loại bỏ mũi tên phải để tránh accept ngoài ý muốn)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line vi-end-of-line vi-add-eol)

# Keybindings callback for zsh-vi-mode
function zvm_after_init() {
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down

  # Shift+Tab: Accept autosuggestion completion
  bindkey '^[[Z' autosuggest-accept
  bindkey -M viins '^[[Z' autosuggest-accept
}

# Fallback binding cho standard zle
bindkey '^[[Z' autosuggest-accept

# ------------------------------------------------------------------------------
# Starship Prompt
# ------------------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Node.js, Corepack & NVM Environment (Fast Node Manager)
# ------------------------------------------------------------------------------
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
  function nvm() {
    fnm "$@"
  }
  alias nvm="fnm"
fi
export COREPACK_ENABLE_STRICT=0

# ------------------------------------------------------------------------------
# Modern Terminal Tools Integration
# ------------------------------------------------------------------------------

# Zoxide (Smarter cd with interactive fuzzy IDE integration)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"

  # Fuzzy project jump & open with Antigravity IDE
  function ide() {
    local target
    if [ $# -eq 0 ]; then
      target=$(zoxide query -i) && [ -n "$target" ] && antigravity-ide "$target"
    else
      target=$(zoxide query "$@") && [ -n "$target" ] && antigravity-ide "$target"
    fi
  }

  # Fuzzy project jump & open with Neovim
  function nide() {
    local target
    if [ $# -eq 0 ]; then
      target=$(zoxide query -i) && [ -n "$target" ] && (cd "$target" && nvim .)
    else
      target=$(zoxide query "$@") && [ -n "$target" ] && (cd "$target" && nvim .)
    fi
  }
fi

# FZF: Fuzzy finder integration (Ctrl+R history, Ctrl+T files, Alt+C directory)
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
  [ -f "$HOME/.config/fzf/themes/noctalia.sh" ] && source "$HOME/.config/fzf/themes/noctalia.sh"
fi

# Yazi: Modern terminal file manager with shell wrapper to change CWD on exit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
alias yazi="y"

# Broot interactive directory tree
alias br="broot -d -p"

# Git Delta: Beautiful syntax-highlighted side-by-side diff view
export GIT_PAGER="delta --dark --line-numbers --paging=auto"

# Lazygit & Lazydocker (Essential DevOps TUI)
alias lg="lazygit"
alias ld="lazydocker"

# RTK (Rust Token Killer) Shell Integration for AI Token Optimization
if command -v rtk >/dev/null 2>&1; then
  eval "$(rtk init - --shell zsh 2>/dev/null)" 2>/dev/null || true
  alias rgit="rtk git"
  alias rdiff="rtk diff"
  alias rtest="rtk test"
  alias rlog="rtk log"
fi

# CodeGraph & Codebase Memory MCP CLI Workflow
function cg() {
  local cmd="${1:-status}"
  shift 2>/dev/null || true

  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || repo_root="$PWD"

  local bin="codebase-memory-mcp"
  if ! command -v "$bin" >/dev/null 2>&1; then
    if [ -x "$HOME/.local/bin/codebase-memory-mcp" ]; then
      bin="$HOME/.local/bin/codebase-memory-mcp"
    elif [ -x "/run/current-system/sw/bin/codebase-memory-mcp" ]; then
      bin="/run/current-system/sw/bin/codebase-memory-mcp"
    else
      echo "codebase-memory-mcp binary not found. Please run ./scripts/build.sh or bootstrap." >&2
      return 1
    fi
  fi

  local project_name
  project_name="$(echo "$repo_root" | sed 's|^/||; s|/|-|g')"

  case "$cmd" in
    init)
      echo "==> Indexing repository AST into Codebase Memory..."
      echo "  Repo root : $repo_root"
      mkdir -p "$repo_root/.codegraph"
      "$bin" cli --quiet index_repository "{\"repo_path\":\"$repo_root\"}"
      echo "✓ AST knowledge graph indexed successfully!"
      ;;
    status)
      echo "==> CodeGraph AST Status ($repo_root):"
      "$bin" cli --quiet index_status "{\"project\":\"$project_name\"}" 2>/dev/null || \
        echo "No index found for $repo_root. Run 'cg init' to build knowledge graph."
      ;;
    clean)
      echo "==> Cleaning CodeGraph cache for $repo_root..."
      rm -rf "$repo_root/.codegraph"
      rm -f "$HOME/.cache/codebase-memory-mcp/${project_name}"*.db 2>/dev/null || true
      echo "✓ CodeGraph cache cleared. Run 'cg init' to re-index."
      ;;
    search)
      if [ $# -eq 0 ]; then
        echo "Usage: cg search <symbol>" >&2
        return 1
      fi
      "$bin" cli --quiet search_graph "{\"project\":\"$project_name\",\"query\":\"$1\"}"
      ;;
    ui)
      echo "Opening Codebase Memory Graph UI on port 9749..."
      xdg-open "http://localhost:9749" 2>/dev/null || echo "Navigate to http://localhost:9749"
      ;;
    help|--help|-h)
      echo "CodeGraph & Codebase Memory CLI"
      echo "Usage: cg <command> [args]"
      echo ""
      echo "Commands:"
      echo "  init    - Index or refresh AST knowledge graph for current Git repository"
      echo "  status  - Show index status, node/edge counts, and graph freshness"
      echo "  clean   - Remove local .codegraph/ and database cache"
      echo "  search  - Search symbols across codebase AST graph"
      echo "  ui      - Open visual graph explorer in browser"
      ;;
    *)
      "$bin" cli "$cmd" "$@"
      ;;
  esac
}

# Eza: Modern replacement for ls
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto'
  alias ll='eza -lh --icons=auto --git'
  alias la='eza -lha --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lha --color=auto'
fi

# Bat: Modern replacement for cat with syntax highlighting
if command -v bat >/dev/null 2>&1; then
  export BAT_THEME="noctalia"
  alias cat='bat --paging=never --style=plain'
  alias catp='bat'
fi

# System Monitoring & Fastfetch
alias fetch="fastfetch"
alias fashfetch="fastfetch"
alias bottom="btm"
alias df="duf"
alias du="dust"
alias codecount="tokei"

# Quick documentation / cheat-sheet
alias docs="tldr"

# GitHub CLI & Kubernetes TUI
alias ghd="gh-dash"
alias ghi="gh issue"
alias ghpr="gh pr"
alias ghml="gh ml"
alias k="kubectl"
alias kns="k9s"

# Phone Connect CLI
alias phone="kdeconnect-cli"

# SSH
alias ssh="TERM=xterm-256color ssh"

# ------------------------------------------------------------------------------
# Dotfiles & System Management (Thao tác ở bất cứ đâu)
# ------------------------------------------------------------------------------
# Dynamically resolve dotfiles repository root (follows ~/.zshrc symlink)
if [ -z "${DOTFILES_DIR:-}" ]; then
  if [ -L "${ZDOTDIR:-$HOME}/.zshrc" ]; then
    DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${ZDOTDIR:-$HOME}/.zshrc")")/../.." && pwd)"
  elif [ -d "$HOME/Workspaces/dotfiles" ]; then
    DOTFILES_DIR="$HOME/Workspaces/dotfiles"
  elif [ -d "$HOME/dotfiles" ]; then
    DOTFILES_DIR="$HOME/dotfiles"
  else
    DOTFILES_DIR="$HOME/.config/dotfiles"
  fi
fi
export DOTFILES_DIR

if [ -f "$DOTFILES_DIR/resources/ai/gateway.env" ]; then
  source "$DOTFILES_DIR/resources/ai/gateway.env"
fi

alias dots="cd \"$DOTFILES_DIR\""
alias rebuild="\"$DOTFILES_DIR/scripts/build.sh\""
alias sync-theme="\"$DOTFILES_DIR/scripts/sync-noctalia.sh\""
alias vault-save="\"$DOTFILES_DIR/scripts/vault.sh\" backup"
alias vault-load="\"$DOTFILES_DIR/scripts/vault.sh\" restore"
alias clean-nix="nix-collect-garbage -d && sudo nix-collect-garbage -d"

# High-Performance Workflow Tools
function pj() {
  if [ -f "${DOTFILES_DIR:-}/scripts/pj.sh" ]; then
    "${DOTFILES_DIR}/scripts/pj.sh" "$@"
  else
    command pj "$@"
  fi
}
alias work="pj"

function flakify() {
  if [ -f "${DOTFILES_DIR:-}/scripts/flakify.sh" ]; then
    "${DOTFILES_DIR}/scripts/flakify.sh" "$@"
  else
    command flakify "$@"
  fi
}

function screenshot() {
  if [ -f "${DOTFILES_DIR:-}/scripts/screenshot.sh" ]; then
    "${DOTFILES_DIR}/scripts/screenshot.sh" "$@"
  else
    command screenshot "$@"
  fi
}
alias shot="screenshot"

function doctor() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -f "${DOTFILES_DIR}/scripts/doctor.sh" ]; then
    "${DOTFILES_DIR}/scripts/doctor.sh" "$@"
  elif command -v doctor >/dev/null 2>&1; then
    command doctor "$@"
  else
    echo "doctor not found in dotfiles or PATH" >&2
    return 1
  fi
}

function ai-skills() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -f "${DOTFILES_DIR}/scripts/ai-skills.sh" ]; then
    "${DOTFILES_DIR}/scripts/ai-skills.sh" "$@"
  elif command -v ai-skills >/dev/null 2>&1; then
    command ai-skills "$@"
  else
    echo "ai-skills not found in dotfiles or PATH" >&2
    return 1
  fi
}
alias add-skills="ai-skills"


# 9router MITM Root CA SSL Trust for Node.js / CLI tools
if [ -f "$HOME/.9router/mitm/rootCA.crt" ]; then
  export NODE_EXTRA_CA_CERTS="$HOME/.9router/mitm/rootCA.crt"
fi

function init-9router() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -f "${DOTFILES_DIR}/scripts/init-9router.sh" ]; then
    "${DOTFILES_DIR}/scripts/init-9router.sh" "$@"
  elif command -v init-9router >/dev/null 2>&1; then
    command init-9router "$@"
  else
    echo "init-9router not found in dotfiles or PATH" >&2
    return 1
  fi
}

function 9router() {
  case "${1:-}" in
    status)
      systemctl --user status 9router
      ;;
    restart)
      systemctl --user restart 9router && echo "✓ 9router restarted"
      ;;
    stop)
      systemctl --user stop 9router && echo "✓ 9router stopped"
      ;;
    start)
      systemctl --user start 9router && echo "✓ 9router started"
      ;;
    logs)
      journalctl --user -u 9router -f
      ;;
    update)
      echo "==> Updating 9router via init-9router script..."
      if [ -f "${DOTFILES_DIR:-}/scripts/init-9router.sh" ]; then
        "${DOTFILES_DIR}/scripts/init-9router.sh"
      else
        npm i -g "9router@${ROUTER_9_PINNED_VERSION:?ROUTER_9_PINNED_VERSION is not configured}"
        systemctl --user restart 9router
        echo "✓ 9router updated to pinned version $ROUTER_9_PINNED_VERSION and service restarted"
      fi
      ;;
    "")
      if systemctl --user is-active --quiet 9router.service; then
        echo "✓ 9router service is running in background (http://localhost:20128)"
        echo "  - View status: 9router status"
        echo "  - Follow logs: 9router logs"
        echo "  - Update:      9router update"
        echo "  - Restart:     9router restart"
        echo "  - Stop:        9router stop"
        return 0
      fi
      command 9router
      ;;
    *)
      command 9router "$@"
      ;;
  esac
}

function init-omniroute() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -f "${DOTFILES_DIR}/scripts/init-omniroute.sh" ]; then
    "${DOTFILES_DIR}/scripts/init-omniroute.sh" "$@"
  elif command -v init-omniroute >/dev/null 2>&1; then
    command init-omniroute "$@"
  else
    echo "init-omniroute not found in dotfiles or PATH" >&2
    return 1
  fi
}

function sync-omniroute() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -f "${DOTFILES_DIR}/scripts/sync-omniroute.sh" ]; then
    "${DOTFILES_DIR}/scripts/sync-omniroute.sh" "$@"
  elif command -v sync-omniroute >/dev/null 2>&1; then
    command sync-omniroute "$@"
  else
    echo "sync-omniroute not found in dotfiles or PATH" >&2
    return 1
  fi
}

function omni() {
  case "${1:-}" in
    status)
      systemctl --user status omniroute
      ;;
    restart)
      systemctl --user restart omniroute && echo "✓ omniroute restarted (port 20129)"
      ;;
    stop)
      systemctl --user stop omniroute && echo "✓ omniroute stopped"
      ;;
    start)
      systemctl --user start omniroute && echo "✓ omniroute started (port 20129)"
      ;;
    logs)
      journalctl --user -u omniroute -f
      ;;
    sync)
      sync-omniroute "${2:-status}"
      ;;
    *)
      if command -v omniroute >/dev/null 2>&1; then
        command omniroute "$@"
      else
        echo "omniroute CLI not found. Run init-omniroute first."
      fi
      ;;
  esac
}

# ------------------------------------------------------------------------------
# Cloudflare WARP (1.1.1.1) Aliases & Functions
# ------------------------------------------------------------------------------
alias warpcli="warp-cli --accept-tos"

function 1111() {
  if ! command -v warp-cli >/dev/null 2>&1; then
    echo "Error: warp-cli is not installed." >&2
    return 1
  fi

  local action="${1:-status}"
  case "$action" in
    on|connect|c|up)
      warp-cli --accept-tos connect
      ;;
    off|disconnect|d|down)
      warp-cli --accept-tos disconnect
      ;;
    toggle|t)
      if warp-cli --accept-tos status 2>/dev/null | grep -qi "Connected"; then
        echo "Disconnecting WARP (1.1.1.1)..."
        warp-cli --accept-tos disconnect
      else
        echo "Connecting to WARP (1.1.1.1)..."
        warp-cli --accept-tos connect
      fi
      ;;
    status|st|s)
      warp-cli --accept-tos status
      ;;
    register|reg)
      warp-cli --accept-tos registration new
      ;;
    settings)
      warp-cli --accept-tos settings
      ;;
    mode)
      shift
      warp-cli --accept-tos mode "$@"
      ;;
    *)
      warp-cli --accept-tos "$@"
      ;;
  esac
}

alias warp="1111"
alias warpon="warp-cli --accept-tos connect"
alias warpoff="warp-cli --accept-tos disconnect"
alias warpst="warp-cli --accept-tos status"
alias warptoggle="1111 toggle"

# ------------------------------------------------------------------------------
# Navigation & Directory Ergonomics
# ------------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Create directory and jump into it immediately
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ------------------------------------------------------------------------------
# Clipboard, Network & Safe Operations
# ------------------------------------------------------------------------------
alias cpwd="pwd | tr -d '\n' | wl-copy"
alias copy="wl-copy"
alias paste="wl-paste"
alias ports="sudo ss -tulpn | grep LISTEN"
alias myip="curl -s https://ifconfig.me && echo"

# Cloudflare Quick Tunnel (Public temporary local port)
function tunnel() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: tunnel [port] [protocol]"
    echo "Example: tunnel 3000"
    return 0
  fi
  local port="${1:-3000}"
  local proto="${2:-http}"
  echo "Exposing ${proto}://localhost:${port} via Cloudflare Tunnel..."
  cloudflared tunnel --url "${proto}://localhost:${port}"
}

if command -v gping >/dev/null 2>&1; then
  alias ping="gping"
fi

if command -v trash >/dev/null 2>&1; then
  alias rm="trash"
  alias rmf="/bin/rm -rf"
fi

# ------------------------------------------------------------------------------
# Editor & IDE Quick Launchers
# ------------------------------------------------------------------------------
alias n='nvim'
alias v='nvim'
alias n.='nvim .'
function nv() {
  setsid -f neovide --frame none "$@" >/dev/null 2>&1
}
function nv.() {
  setsid -f neovide --frame none . "$@" >/dev/null 2>&1
}
alias code='antigravity-ide'
alias ide='antigravity-ide'
alias c.='antigravity-ide .'
alias code.='antigravity-ide .'
alias c='clear'
alias grep='grep --color=auto'
alias zreset="$HOME/Workspaces/dotfiles/scripts/reset-zellij.sh"
alias zj-reset="$HOME/Workspaces/dotfiles/scripts/reset-zellij.sh"

# ------------------------------------------------------------------------------
# Universal Smart Archive Extractor
# ------------------------------------------------------------------------------
function extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *.tar.xz)    tar xf "$1"      ;;
      *.tar.zst)   tar --zstd -xf "$1" ;;
      *.zst)       unzstd "$1"      ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ------------------------------------------------------------------------------
# Google Cloud Pub/Sub Local Emulator Initializer
# ------------------------------------------------------------------------------
create_pubsub() {
  local base_url="http://localhost:8085/v1/projects/local-project"

  # 1. create-metadata-json-file-into-cs
  curl -X PUT "${base_url}/topics/create-metadata-json-file-into-cs"
  curl -X PUT "${base_url}/subscriptions/create-metadata-json-file-into-cs-sub" \
    -H "Content-Type: application/json" \
    -d '{"topic": "projects/local-project/topics/create-metadata-json-file-into-cs"}'

  # 2. create-metadata-for-event
  curl -X PUT "${base_url}/topics/create-metadata-for-event"
  curl -X PUT "${base_url}/subscriptions/create-metadata-for-event-sub" \
    -H "Content-Type: application/json" \
    -d '{"topic": "projects/local-project/topics/create-metadata-for-event"}'

  # 3. create-stamp-rally-metadata-json-into-cs
  curl -X PUT "${base_url}/topics/create-stamp-rally-metadata-json-into-cs"
  curl -X PUT "${base_url}/subscriptions/create-stamp-rally-metadata-json-into-cs-sub" \
    -H "Content-Type: application/json" \
    -d '{"topic": "projects/local-project/topics/create-stamp-rally-metadata-json-into-cs"}'

  # 4. peer-nomination-mint
  curl -X PUT "${base_url}/topics/peer-nomination-mint"
  curl -X PUT "${base_url}/subscriptions/peer-nomination-mint-sub" \
    -H "Content-Type: application/json" \
    -d '{"topic": "projects/local-project/topics/peer-nomination-mint"}'

  # 5. self-nom-mint
  curl -X PUT "${base_url}/topics/self-nom-mint"
  curl -X PUT "${base_url}/subscriptions/self-nom-mint-sub" \
    -H "Content-Type: application/json" \
    -d '{"topic": "projects/local-project/topics/self-nom-mint"}'
    
  echo "\n✨ Hoàn tất tạo tất cả topics và subscriptions!"
}

# ------------------------------------------------------------------------------
# Auto-run Fastfetch on new terminal session
# ------------------------------------------------------------------------------
if [[ -o interactive ]] && [ -z "${FASTFETCH_RAN:-}" ] && command -v fastfetch >/dev/null 2>&1; then
  export FASTFETCH_RAN=1
  fastfetch
fi
