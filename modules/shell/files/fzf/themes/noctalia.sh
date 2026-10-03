fzf_theme_opts="\
--color=bg+:#3c3836
--color=bg:#282828
--color=spinner:#ebdbb2
--color=hl:#fb4934
--color=fg:#ebdbb2
--color=header:#fb4934
--color=info:#b8bb26
--color=pointer:#ebdbb2
--color=marker:#ebdbb2
--color=fg+:#fbf1c7
--color=prompt:#b8bb26
--color=hl+:#fb4934
--color=selected-bg:#282828
--color=border:#665c54
--color=label:#fbf1c7"

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS
}$fzf_theme_opts"
