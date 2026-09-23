# Stack Context

Generated: 2026-09-23

## Stack

- **Language**: Nix and Bash; Lua, Python, JSON, TOML, and KDL are secondary
- **Framework**: NixOS modules and flakes; no application framework
- **Build**: `nixos-rebuild` through `flake.nix`, with `nixfmt`
- **Test**: `bash tests/ai/skills_test.sh` and `bash scripts/check.sh`
- **Lint**: `shellcheck` for shell scripts; `nixfmt --check` for Nix
- **Format**: `nixfmt --check` is a CI gate

## Secondary Languages

- **Lua**: Neovim configuration and keymap generation
- **Python**: small desktop/system helper scripts
- **JSON/TOML/KDL**: agent, editor, desktop, and compositor configuration

## Conventions

- Repository-owned configuration lives under `resources/`; Nix modules live
  under `modules/` and custom derivations under `pkgs/`.
- Global agent skills are canonical under `resources/skills/` and linked by
  `scripts/ai-skills.sh`; editor sync is handled by `scripts/sync-editors.sh`.
- Keep credentials out of tracked files; use the repository's secret tooling.
- Preserve unrelated worktree changes and verify with focused gates before
  declaring a system change complete.

## CI Gates

- `.github/workflows/ci.yml`: `nix develop --command bash scripts/check.sh`
- `.github/workflows/skills-ci.yml`: Bash syntax, ShellCheck, metadata checks,
  and `tests/ai/skills_test.sh`
