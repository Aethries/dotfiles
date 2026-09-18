<div align="center">

# ❄️ NixOS Dotfiles

**Declarative, aesthetic, and reproducible workstation powered by Nix Flakes, Niri, Zellij, and Noctalia.**

[![NixOS](https://img.shields.io/badge/NixOS-Unstable-blue?logo=nixos&logoColor=white&style=for-the-badge)](https://nixos.org)
[![Wayland](https://img.shields.io/badge/Wayland-Niri-orange?logo=wayland&logoColor=white&style=for-the-badge)](https://github.com/YaLTeR/niri)
[![Terminal](https://img.shields.io/badge/Multiplexer-Zellij-green?logo=gnubash&logoColor=white&style=for-the-badge)](https://zellij.dev)
[![Editor](https://img.shields.io/badge/Editor-Neovim%20%26%20Godot-lightblue?logo=neovim&logoColor=white&style=for-the-badge)](https://neovim.io)
[![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)](LICENSE)

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#key-features">Key Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#quickstart">Quickstart</a> •
  <a href="#keybindings">Keybindings</a> •
  <a href="#secrets--security">Security</a> •
  <a href="#testing--qa">QA</a>
</p>

</div>

---

## Overview

Personal `x86_64` NixOS configuration for a workstation driving **Niri** (scrollable-tiling Wayland compositor) and **Noctalia** (integrated design system). Machine hardware configurations and private user secrets stay separated under `.machine/` and `secrets/`, keeping the core repository clean, modular, and fully reproducible.

---

## Key Features

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Compositor** | [Niri](https://github.com/YaLTeR/niri) | Dynamic infinite-horizontal scrollable tiling Wayland compositor. |
| **Theme & UI** | Noctalia + Matugen | Unified dynamic theme across GTK, Kitty, Zellij, and desktop widgets. |
| **Multiplexer** | [Zellij](https://zellij.dev) | Headless session persistence, custom `zjstatus` bar, cross-pane navigation. |
| **Terminal** | [Kitty](https://sw.kovidgoyal.net/kitty/) | GPU-accelerated terminal renderer linked directly to Zellij session launcher. |
| **Editor** | [Neovim](https://neovim.io) | Tailored Lua setup with LSP, DAP, and seamless split-to-pane navigation. |
| **Game Dev** | [Godot 4](https://godotengine.org) | Pinned engine, headless LSP daemon, DAP debugging, and Godot MCP server. |
| **Shell & CLI** | Zsh + Starship | Blazing fast prompt, fastfetch, and Yazi terminal file manager. |
| **Security** | Age & Vault | Local authenticated encrypted archives; zero plain-text leaks to git. |

---

## Architecture

The flake separates declarative Nix configurations from user-specific dotfiles and machine targets:

```text
.
├── configuration.nix       # Top-level NixOS system entry point
├── flake.nix               # Flake inputs, outputs, checks, and devShells
├── modules/                # Composable NixOS system modules
│   ├── base.nix            # Core boot, kernel, locale, nix settings
│   ├── desktop.nix         # Wayland, Niri, portals, audio, display
│   ├── godot.nix           # Godot 4 package, tooling, and editor sync
│   ├── packages.nix        # System-wide CLI & GUI package definitions
│   ├── services.nix        # Systemd user services, daemons, background tasks
│   └── zellij.nix          # Multiplexer configuration module
├── resources/              # User configuration files linked to $HOME
│   ├── kitty/              # Kitty terminal configuration & themes
│   ├── niri/               # Niri compositor config (config.kdl)
│   ├── noctalia/           # Noctalia theme definitions & palettes
│   ├── nvim/               # Neovim lua configuration & plugins
│   ├── starship/           # Starship prompt configuration
│   ├── systemd/            # Validated systemd user unit templates
│   └── zellij/             # Layouts, status bar, and launcher scripts
├── scripts/                # Bootstrapping, installer, checking & test scripts
└── tests/                  # Automated test suites (vault, zellij launcher)
```

---

## Quickstart

### 1. Existing NixOS Installation

Bootstrap configuration onto an existing NixOS system:

```sh
git clone https://github.com/Aethries/dotfiles.git ~/Workspaces/dotfiles
cd ~/Workspaces/dotfiles
./scripts/bootstrap.sh
```

### 2. Fresh Installation (Live ISO)

Review target storage disks carefully before running:

```sh
sudo ./scripts/nixos-installer.sh
```

### 3. Rebuild & Health Check

Rebuild system generations and run the doctor diagnostics suite:

```sh
./scripts/build.sh switch
./scripts/check.sh
./scripts/doctor.sh
```

> [!NOTE]
> `system.stateVersion` must remain the NixOS version used for the machine's initial installation. Do not bump it during regular updates.

---

## Godot Development

Godot 4, the graphical editor, export templates, `godotpcktool`, and the Godot MCP server are pinned in `flake.lock`.

```sh
./scripts/build.sh switch
```

- **Neovim GDScript integration**: Open the project in Godot first, then edit `.gd` files in Neovim. Neovim connects to Godot's LSP on port `6005`. Debug via `<leader>dc` on DAP port `6006`.
- **Editor settings sync**: `scripts/sync-editors.sh` links Neovim and Antigravity configs, locks extension checksums, and loads Godot MCP (`resources/gemini/mcp_config.json`).

---

## Keybindings

### Niri (Compositor)

| Binding | Action |
| :--- | :--- |
| `Super + h` / `l` | Focus left / right column |
| `Super + Ctrl + h` / `l` | Move column left / right |
| `Super + j` / `k` | Focus workspace below / above |
| `Super + Ctrl + j` / `k` | Move column to workspace below / above |
| `Super + Tab` | Toggle Overview mode |

### Zellij (Multiplexer)

| Binding | Action |
| :--- | :--- |
| `Ctrl + h` / `j` / `k` / `l` | Seamless navigation between Neovim splits & Zellij panes |
| `Ctrl + Shift + [` / `]` | Previous / Next tab (guaranteed native action) |
| `Ctrl + Shift + 1..9` | Switch directly to tab index |
| `Ctrl + Shift + s` | Open in-session session manager |
| `Ctrl + Shift + Esc` | Emergency recover to `NORMAL` mode |

---

## Secrets & Security

Plaintext credentials stay strictly isolated in the uncommitted `secrets/` directory.

- **Vault encryption**: Archives use authenticated `age` passphrase encryption:
  ```sh
  ./scripts/secrets.sh encrypt
  ./scripts/secrets.sh decrypt
  ```
- **Local-only Vault**: The `vault` utility maintains a local-only encrypted backup (`secrets.vault`). There is no automated cloud sync—users control their backup destinations safely.

---

## Testing & QA

Every commit must satisfy rigorous local QA before deployment:

```sh
./scripts/check.sh
```

The validation pipeline enforces:
- `shellcheck` across all bash scripts and launcher hooks.
- `nixfmt` check on all Nix expressions.
- `nix flake check` verifying full derivation evaluation.
- `systemd-analyze verify` on user service units.
- Dedicated unit tests for vault encryption and Zellij launcher idempotency.
