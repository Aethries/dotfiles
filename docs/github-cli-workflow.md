# GitHub CLI Workflow

This document describes the reproducible GitHub CLI (`gh`) aliases shipped by
the repository, how they are installed, and the safety rules for common issue
and pull-request operations.

## Source of truth

All aliases are defined in:

```text
resources/gh/config.yml
```

Bootstrap links that file to the active user's GitHub CLI configuration:

```text
~/.config/gh/config.yml -> <repository>/resources/gh/config.yml
```

The link is created by `scripts/lib/links.sh`, called by
`scripts/bootstrap.sh`. Editing the repository file and rerunning bootstrap is
the supported update path. Do not put authentication tokens, cookies, or
personal host credentials in the tracked file.

## Prerequisites

Install/authenticate the GitHub CLI before using the aliases:

```sh
command -v gh
gh auth status
gh auth login
```

The `d` alias also requires `gh-dash`, which is provided by the NixOS package
set in `modules/packages.nix`.

After bootstrap, open a new shell or verify the linked configuration directly:

```sh
gh alias list
readlink -f "$HOME/.config/gh/config.yml"
```

For a temporary, non-invasive verification without changing the active user
configuration:

```sh
GH_CONFIG_DIR="$(mktemp -d)" gh alias list
```

## Alias reference

### Issues

| Alias | Expansion | Intended use |
| --- | --- | --- |
| `gh il` | `issue list --state open` | List active issues |
| `gh ila` | `issue list --state all` | List open and closed issues |
| `gh iv NUMBER` | `issue view --comments NUMBER` | Read an issue and its comments |
| `gh ic` | `issue create` | Create an issue interactively |
| `gh icl NUMBER` | `issue close NUMBER` | Close a completed issue |
| `gh ire NUMBER` | `issue reopen NUMBER` | Reopen an issue |

Examples:

```sh
gh il
gh il --label priority:p1
gh iv 32
gh icl 32
```

The close and reopen aliases change GitHub state. Review the issue number
before using them.

### Pull requests

| Alias | Expansion | Intended use |
| --- | --- | --- |
| `gh prl` | `pr list` | List pull requests |
| `gh prv NUMBER` | `pr view --comments NUMBER` | Inspect a pull request and comments |
| `gh prd NUMBER` | `pr diff NUMBER` | Review a pull-request diff |
| `gh prc` | `pr create` | Create a pull request interactively |
| `gh co NUMBER` | `pr checkout NUMBER` | Check out a pull request locally |
| `gh prm NUMBER` | `pr merge --squash --delete-branch NUMBER` | Squash-merge and delete the head branch |

Examples:

```sh
gh prl
gh prv 119
gh prd 119
gh co 119
```

`gh prm` is intentionally a mutating shortcut. Confirm the target pull
request, required checks, review status, and branch policy before running it.
If the repository requires a review, the alias cannot bypass that policy.

### Milestones and dashboard

| Alias | Expansion | Intended use |
| --- | --- | --- |
| `gh ml` | API query for repository milestones | Show milestone counts and state |
| `gh mli TITLE` | `issue list --state all --milestone TITLE` | List issues in a milestone |
| `gh d` | `gh-dash` | Open the dashboard |
| `gh browse-here` | `browse` | Open the current repository in a browser |

`gh ml` calls the GitHub API and therefore requires authentication and network
access. It reports each milestone's number, title, open issue count, closed
issue count, and state.

Examples:

```sh
gh ml
gh mli "Ready"
gh d
gh browse-here
```

## Repository selection

The aliases operate on the current repository when run inside a checkout. Use
standard `gh` flags when you need an explicit target:

```sh
gh il --repo Aethries/dotfiles
gh prv 119 --repo Aethries/dotfiles
gh ml --repo Aethries/dotfiles
```

For API-backed aliases such as `gh ml`, the `:owner/:repo` placeholders are
resolved by `gh` from the current repository context.

## Shell complements

The Zsh configuration provides short grouping aliases:

```sh
ghi='gh issue'
ghpr='gh pr'
ghml='gh ml'
ghd='gh-dash'
```

These complement, rather than replace, the `gh` aliases. For example:

```sh
ghi list --state open
ghpr view 119 --comments
ghml
```

## Maintenance workflow

1. Edit `resources/gh/config.yml`.
2. Keep aliases declarative and free of secrets.
3. Add or update the expected mapping in `tests/gh/test-aliases.sh`.
4. Run the focused test.
5. Run the repository quality gate.
6. Bootstrap or relink the user configuration.

Focused validation:

```sh
bash tests/gh/test-aliases.sh
```

Full validation:

```sh
bash scripts/check.sh
nix flake check path:$PWD --no-build
```

The focused test copies the tracked config into an isolated `GH_CONFIG_DIR`,
loads it with `gh alias list`, and verifies both the alias names and their
command expansions. It does not modify the user's real GitHub CLI config.

## Troubleshooting

### Alias is not found

Check the active config path and link:

```sh
gh config get config-dir
readlink -f "${GH_CONFIG_DIR:-$HOME/.config/gh}/config.yml"
gh alias list
```

If the link is missing, rerun bootstrap or recreate the managed link through
the normal dotfiles linking flow.

### API alias fails with authentication error

Run:

```sh
gh auth status
gh auth refresh
```

Do not copy tokens into `resources/gh/config.yml`.

### `gh prm` refuses to merge

This is normally branch protection working as intended. Inspect the pull
request checks and review requirements:

```sh
gh prv NUMBER
gh pr checks NUMBER
```

Obtain the required approval or use the repository's documented merge process;
do not weaken branch protection to make the shortcut succeed.
