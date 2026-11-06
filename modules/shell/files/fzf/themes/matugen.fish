set -l fzf_theme_opts "\
--color=bg+:#282c34
--color=bg:#21252b
--color=spinner:#78c4ce
--color=hl:#e27881
--color=fg:#e6e6e6
--color=header:#e27881
--color=info:#62bac6
--color=pointer:#78c4ce
--color=marker:#78c4ce
--color=fg+:#c9ccd3
--color=prompt:#62bac6
--color=hl+:#e27881
--color=selected-bg:#21252b
--color=border:#393e47
--color=label:#c9ccd3"

if set -q FZF_DEFAULT_OPTS[1]; and test -n "$FZF_DEFAULT_OPTS"
    set -Ux FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS
$fzf_theme_opts"
else
    set -Ux FZF_DEFAULT_OPTS "$fzf_theme_opts"
end
