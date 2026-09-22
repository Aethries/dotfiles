# Zellij Session Workflow

This document describes the repository's Zellij session startup flow, the
keyboard controls used by the launcher, and the rules for opting into a
layout.

## Scope

The session flow has two separate entry points:

| Entry point | Use | Implementation |
| --- | --- | --- |
| Kitty startup | Choose, attach, or create a session before Zellij starts | `resources/zellij/scripts/launcher.sh` |
| In-session manager | Manage sessions after Zellij is already running | `Ctrl + Shift + s` in `resources/zellij/config.kdl` |

Kitty starts the repository launcher from `resources/kitty/kitty.conf`. The
launcher queries existing sessions before starting a Zellij server. This keeps
cancel, plain-shell, and unexpected picker failures from creating an unnamed
or temporary session.

## Default new-session behavior

Creating a session does not ask the user to choose a layout. A named session
created without `--layout` uses:

```sh
zellij --session "project-name"
```

The repository's canonical Zellij configuration remains authoritative. Its
`default_layout "default"` setting is used by Zellij as the normal config
fallback; the launcher does not force an interactive template choice or add a
layout override.

Layout selection is explicit. The following command opts into the `work`
layout:

```sh
resources/zellij/scripts/launcher.sh --layout work
```

The same option applies only to the new-session path. Attaching to or
resurrecting an existing session never changes that session's layout.

## Startup picker flow

Run the launcher directly when testing or when Kitty is not the entry point:

```sh
resources/zellij/scripts/launcher.sh
```

The picker receives the current sessions in newest-first order. Its controls
are:

| Input | Behavior |
| --- | --- |
| `Enter` on an existing session | Attach to that session with `--` argument protection |
| Type a new name, then `Enter` | Create that name without an explicit layout |
| `Ctrl + N` | Create the query as a new named session; prompt for a name if the query is empty |
| `Ctrl + Z` | Leave the picker and start a plain Zsh shell |
| `Ctrl + L` | Attach to the newest existing session |
| `Esc` / `Ctrl + C` | Cancel without creating or attaching a session |
| `--latest` | Attach newest session directly; fall back to the picker when none exists |
| `--layout NAME` | Apply `NAME` only when creating a new session |

When no session exists, `Ctrl + N` followed by a name is the fastest explicit
creation path. The launcher never creates an unnamed session from an empty
query. The fallback from an empty picker query uses the stable name `main` and
still delegates layout behavior to the canonical Zellij config.

## Session name rules

Names are passed as one quoted argument. The launcher rejects:

- empty or whitespace-only names;
- names beginning with `-`, which could be interpreted as an option;
- names containing control characters.

Spaces and punctuation are allowed. For example, `my project` remains one
session-name argument and is not split by the shell.

## Existing-session and restore behavior

`zellij list-sessions --short --no-formatting` is queried before the picker is
shown. Existing sessions are attached with:

```sh
zellij attach "session-name"
```

The launcher does not recreate, rename, or apply a layout to an existing session.
Zellij's own serialization and resurrection settings remain in `resources/zellij/config.kdl`.

If `fzf` is unavailable, the launcher uses a deterministic fallback:

1. attach the newest existing session;
2. otherwise start a plain Zsh shell.

It does not silently create a temporary session in this mode.

## Layouts

Repository layouts live in `resources/zellij/layouts/`. To make a layout the
explicit choice for a new session:

```sh
resources/zellij/scripts/launcher.sh --layout work
```

The layout argument can be a Zellij layout name or a path accepted by the
installed Zellij version. Layouts are not selected by default in the startup
picker. Existing project-specific behavior in `scripts/pj.sh` remains separate:
that script can pass a project layout when opening a project intentionally.

## Keybindings inside a session

The repository reserves `Ctrl + Shift` for Zellij management:

| Binding | Action |
| --- | --- |
| `Ctrl + Shift + s` | Open the in-session session manager |
| `Ctrl + Shift + [` / `]` | Previous / next tab |
| `Ctrl + Shift + 1..9` | Jump to a tab |
| `Ctrl + Shift + Esc` | Return to `NORMAL` mode from an accidental input mode |

The in-session manager is for managing an already-running server. The Kitty
launcher is the path that guarantees a new session starts without an explicit
layout selection.

## Verification

Run the isolated launcher suite:

```sh
bash tests/zellij/launcher_test.sh
```

The suite verifies:

- named creation has no `--layout` by default;
- `--layout work` is passed only when explicitly requested;
- existing sessions attach correctly;
- newest-session and no-session fallbacks are deterministic;
- names with spaces remain one argument;
- dash-prefixed names are protected;
- invalid input, missing dependencies, cancellation, and unexpected Zellij
  errors fail safely.

The complete repository gate also checks the launcher:

```sh
bash scripts/check.sh
```

## Troubleshooting

### The launcher says Zellij is missing

Verify the NixOS package is active and that `zellij` is on `PATH`:

```sh
command -v zellij
zellij --version
```

### The picker immediately opens a shell

This is the documented fallback when `fzf` is unavailable. Verify:

```sh
command -v fzf
```

### A layout was applied unexpectedly

Check the invocation source. The generic launcher applies a layout only when
`--layout` is supplied. Project-specific layout selection may come from
`scripts/pj.sh` or a direct `zellij --layout ...` command.

### A session cannot be attached

List sessions directly and inspect the exact name:

```sh
zellij list-sessions --short --no-formatting
```

Then retry with the launcher or `zellij attach "exact-name"`.
