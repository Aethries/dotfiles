export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY

# Completion
autoload -Uz compinit
compinit

# zoxide
eval "$(zoxide init zsh)"

# Starship
eval "$(starship init zsh)"

# Yazi
function y() {
	local tmp
	tmp="$(mktemp -t "yazi-cwd.XXXXX")"

	yazi "$@" --cwd-file="$tmp"

	if [[ -f "$tmp"  ]]; then
		local cwd
		cwd="$(cat -- "$tmp")"

		if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
			builtin cd -- "$cwd"
		fi
	fi

	rm -f "$tmp"
}

alias c="clear"

if [[ -f /usr/share/fzf/key-bindings.zsh  ]]; then
	source /usr/share/fzf/key-bindings.zsh
fi

if [[ -f /usr/share/fzf/completion.zsh  ]]; then
	source /usr/share/fzf/completion.zsh
fi

if [[ -r /usr/share/nvm/init-nvm.sh  ]]; then
	source /usr/share/nvm/init-nvm.sh
fi
