# Dotfiles AI stack

Use `http://127.0.0.1:20128/v1` as the only local model gateway. Do not point
clients directly at Bifrost or at provider endpoints when OmniRoute is active.

Use CodeGraph before broad repository scans when a workspace is indexed. Never
index `$HOME`, `/`, Downloads, Documents, credentials, or environment files.

Use RTK explicitly for terminal output compression when it helps. OmniRoute's
own compression pipeline remains independent from standalone RTK.
