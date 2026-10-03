export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
	git
	fzf-tab
	you-should-use
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# Default Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Path additions
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/go/bin:$PATH"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY

# Completion
autoload -Uz compinit
compinit

# Starship Prompt
if command -v starship >/dev/null 2>&1; then
	eval "$(starship init zsh)"
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
	eval "$(zoxide init zsh)"
fi

# Git Delta Pager
if command -v delta >/dev/null 2>&1; then
	export GIT_PAGER="delta --dark --line-numbers --paging=auto"
fi

# ------------------------------------------------------------------------------
# Navigation & Directory Ergonomics
# ------------------------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

function mkcd() {
	mkdir -p "$1" && cd "$1"
}

# ------------------------------------------------------------------------------
# Modern CLI Replacements
# ------------------------------------------------------------------------------
# Eza (modern ls)
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

# Bat (modern cat)
if command -v bat >/dev/null 2>&1; then
	alias cat='bat --paging=never --style=plain'
	alias catp='bat'
fi

# Lazygit, Lazydocker & Containers
alias lg="lazygit"
alias ld="lazydocker"
alias spf="superfile"
if command -v ctop >/dev/null 2>&1; then
	alias dtop="ctop"
fi
if command -v oxker >/dev/null 2>&1; then
	alias ox="oxker"
fi
if command -v dive >/dev/null 2>&1; then
	alias dlayers="dive"
fi

# System Monitoring & Resource Usage
alias bottom="btm"
alias df="duf"
alias du="dust"
alias docs="tldr"
alias fetch="fastfetch"
if command -v procs >/dev/null 2>&1; then
	alias ps="procs"
fi
if command -v onefetch >/dev/null 2>&1; then
	alias repo="onefetch"
fi
if command -v curlie >/dev/null 2>&1; then
	alias http="curlie"
fi
if command -v viddy >/dev/null 2>&1; then
	alias watch="viddy"
fi
if command -v difft >/dev/null 2>&1; then
	alias dft="difft"
fi
if command -v visidata >/dev/null 2>&1; then
	alias vd="visidata"
fi
if command -v hyperfine >/dev/null 2>&1; then
	alias bmark="hyperfine"
fi
if command -v trippy >/dev/null 2>&1; then
	alias trip="trippy"
fi
if command -v gh >/dev/null 2>&1; then
	alias ghd="gh dash"
fi

# Safe File Removal
if command -v trash >/dev/null 2>&1; then
	alias rm="trash"
	alias rmf="/bin/rm -rf"
fi

# Ping with graph
if command -v gping >/dev/null 2>&1; then
	alias ping="gping"
fi

# Clipboard Manager (Clipse)
alias clip="clip-picker"
alias clip-tui="clipse"
alias clip-clear="clipse -clear"

# ------------------------------------------------------------------------------
# Editor & IDE Quick Launchers
# ------------------------------------------------------------------------------
alias n='nvim'
alias v='nvim'
alias n.='nvim .'
alias code='antigravity-ide'
alias ide='antigravity-ide'
alias c.='antigravity-ide .'
alias code.='antigravity-ide .'
alias c='clear'

# Neovide GUI launcher (fully detached from terminal, immune to terminal closing)
function nv() {
	nohup neovide --fork "$@" >/dev/null 2>&1 &!
}
alias nv.="nv ."

# Zellij Multiplexer
alias zreset="zellij delete-all-sessions --yes --force"

# ------------------------------------------------------------------------------
# Input Method (Fcitx5 Wayland)
# ------------------------------------------------------------------------------
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export ELECTRON_OZONE_PLATFORM_HINT="auto"
export NODE_EXTRA_CA_CERTS="$HOME/.9router/mitm/rootCA.crt"

# ------------------------------------------------------------------------------
# Clipboard, Network & System
# ------------------------------------------------------------------------------
alias cpwd="pwd | tr -d '\n' | wl-copy"
alias copy="wl-copy"
alias paste="wl-paste"
alias ports="sudo ss -tulpn | grep LISTEN"
alias myip="curl -s https://ifconfig.me && echo"

# Cloudflare Tools
function tunnel() {
	if [[ -z "${1:-}" ]]; then
		echo "Usage: tunnel <port>"
		return 1
	fi
	cloudflared tunnel --url "http://localhost:$1"
}

function 1111() {
	if ! systemctl is-active --quiet warp-svc 2>/dev/null; then
		sudo systemctl start warp-svc
	fi
	warp-cli "$@"
}

# ------------------------------------------------------------------------------
# Integrations (Yazi, FZF, NVM)
# ------------------------------------------------------------------------------
# Yazi (cwd integration)
function y() {
	local tmp
	tmp="$(mktemp -t "yazi-cwd.XXXXX")"

	yazi "$@" --cwd-file="$tmp"

	if [[ -f "$tmp" ]]; then
		local cwd
		cwd="$(cat -- "$tmp")"

		if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
			builtin cd -- "$cwd"
		fi
	fi

	rm -f "$tmp"
}
alias yazi="y"

# FZF keybindings and completions
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
	source /usr/share/fzf/key-bindings.zsh
fi

if [[ -f /usr/share/fzf/completion.zsh ]]; then
	source /usr/share/fzf/completion.zsh
fi

# FZF Theme (Synced with Noctalia)
if [[ -f "$HOME/.config/fzf/themes/noctalia.sh" ]]; then
	source "$HOME/.config/fzf/themes/noctalia.sh"
fi

# Mise (Multi-Runtime Manager)
if command -v mise >/dev/null 2>&1; then
	eval "$(mise activate zsh)"
fi

# FZF-Tab options (Noctalia styled with eza preview)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'

# Atuin (Magical Shell History)
if command -v atuin >/dev/null 2>&1; then
	eval "$(atuin init zsh)"
fi

# Direnv (Per-directory environment loader)
if command -v direnv >/dev/null 2>&1; then
	eval "$(direnv hook zsh)"
fi

# TheFuck (CLI auto-corrector)
if command -v thefuck >/dev/null 2>&1; then
	eval "$(thefuck --alias)"
fi

# Carapace (Multi-shell contextual completion engine)
if command -v carapace >/dev/null 2>&1; then
	export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
	source <(carapace _carapace zsh)
fi

# ------------------------------------------------------------------------------
# Universal Smart Archive Extractor
# ------------------------------------------------------------------------------
function extract() {
	if [[ -f "$1" ]]; then
		case "$1" in
			*.tar.bz2)   tar xjf "$1"        ;;
			*.tar.gz)    tar xzf "$1"        ;;
			*.bz2)       bunzip2 "$1"        ;;
			*.rar)       unrar x "$1"        ;;
			*.gz)        gunzip "$1"         ;;
			*.tar)       tar xf "$1"         ;;
			*.tbz2)      tar xjf "$1"        ;;
			*.tgz)       tar xzf "$1"        ;;
			*.zip)       unzip "$1"          ;;
			*.Z)         uncompress "$1"     ;;
			*.7z)        7z x "$1"           ;;
			*.tar.xz)    tar xf "$1"         ;;
			*.tar.zst)   tar --zstd -xf "$1" ;;
			*.zst)       unzstd "$1"         ;;
			*)           echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}

# ------------------------------------------------------------------------------
# Local Overrides (untracked machine-specific secrets/configs)
# ------------------------------------------------------------------------------
if [[ -f "$HOME/.zshrc.local" ]]; then
	source "$HOME/.zshrc.local"
fi
