set -l fzf_theme_opts "\
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

if set -q FZF_DEFAULT_OPTS[1]; and test -n "$FZF_DEFAULT_OPTS"
    set -Ux FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS
$fzf_theme_opts"
else
    set -Ux FZF_DEFAULT_OPTS "$fzf_theme_opts"
end
