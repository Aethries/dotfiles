# Stack Context

Generated: 2026-10-06

## Stack
- Language: Bash for workstation installation and module setup.
- Runtime: Arch Linux, pacman/yay, systemd, greetd, Umbriel/Wayland.
- Build: no application build for the shell provisioning scripts.
- Checks: bash -n and git diff --check.
- Lint/format: shellcheck and shfmt when installed; no root CI workflow found.

## Secondary Languages
- TOML/conf: desktop and application configuration.
- Lua: Neovim configuration.
- Python/JavaScript: bundled AI skill tooling, separate from workstation setup.

## Conventions
- Module entrypoint: modules/<name>/setup.sh with set -euo pipefail.
- Shared helpers: scripts/common.sh and scripts/links.sh.
- Configuration: modules/<name>/files, symlinked into the user home.
- Failure: error exits nonzero; warn marks work requiring manual follow-up.
- Package manifests: packages/pacman.txt, packages/aur.txt, packages/node.txt.
- No existing Sunshine provisioning test suite found.

## CI Gates
- No repository CI gates found for remote.sh or the Sunshine module.
