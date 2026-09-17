# NixOS dotfiles

Personal x86_64 NixOS configuration for an Intel-graphics workstation running
Niri and Noctalia. Machine hardware and user settings are generated under
`.machine/` and intentionally stay out of Git.

## Install

From an existing NixOS system:

```sh
./scripts/bootstrap.sh
```

From a NixOS live ISO, review the selected disk carefully before confirming:

```sh
sudo ./scripts/nixos-installer.sh
```

Rebuild and validate:

```sh
./scripts/build.sh switch
./scripts/check.sh
./scripts/doctor.sh
```

`system.stateVersion` must remain the NixOS version used for the machine's first
installation. Do not bump it during normal upgrades.

## Godot development

Godot 4, its editor UI, matching export templates, `godotpcktool` and the Godot
MCP server are pinned through `flake.lock`. Apply them and synchronize the
repo-owned editor settings with:

```sh
./scripts/build.sh switch
```

The build calls `scripts/sync-editors.sh` after a successful activation. It
links Neovim and Antigravity settings from `resources/`, links Godot export
templates from the active NixOS profile, and installs checksum-verified versions
of the Antigravity extensions declared in
`resources/antigravity/extensions.lock.json`. Existing regular files are moved
to timestamped `.pre-dotfiles.*` backups before a managed link replaces them.
Antigravity also receives the repo-owned Godot MCP configuration from
`resources/gemini/mcp_config.json`, allowing its agent to launch and inspect
Godot projects through the packaged `godot-mcp` command.

For GDScript in Neovim, open the project in Godot first and then edit a `.gd`
file; Neovim connects to Godot's LSP on port 6005. Start debugging with
`<leader>dc` while Godot's DAP server is available on port 6006. Antigravity's
Godot Tools integration starts a headless language server automatically and can
open the graphical editor with `Godot Tools: Open workspace with Godot editor`.

This setup targets GDScript. C#/.NET, Android and console export toolchains are
intentionally not installed because each adds a much larger, target-specific
SDK and should be enabled only when a project needs it.

## Desktop and terminal behavior

Niri uses workspaces, not vertical window stacks, for Vim-like vertical
navigation:

- `Super+j/k`: focus the workspace below/above;
- `Super+Ctrl+j/k`: move the current column to the workspace below/above;
- `Super+h/l`: focus the column to the left/right;
- `Super+Ctrl+h/l`: move the column to the left/right;
- `Super+Tab`: toggle Overview using Niri's native controls.

Do not add runtime-generated plain `h/j/k/l` Overview bindings. The previous IPC
listener could leave application keys captured outside Overview, so both the
listener and its dynamic include have been removed. `Super+u/i` and
`Super+Ctrl+u/i` are intentionally unbound.

Kitty is only the terminal renderer; Zellij owns tabs, panes and persistent
sessions. Kitty starts a repo-managed launcher (`~/.config/zellij/scripts/launcher.sh`),
which queries existing sessions before starting Zellij. Cancelling or closing the picker
creates zero temporary Zellij processes or randomly named sessions. Select a running
session to attach, an exited session to resurrect, or enter an explicit name to create a
new workspace. Pressing `Ctrl+Z` opens a plain Zsh shell without Zellij.

The zjstatus bar uses Noctalia's generated primary accent and
highlights the active tab as a rounded pill with a `●` marker. Its right side
shows hostname, CPU %, memory %, network receive/transmit rate and root-disk
usage %. System
metrics come from `resources/zellij/scripts/system-status.sh` and refresh every
three seconds.

### Multi-client geometry and shared sessions

In Zellij, when multiple clients attach to the same session, viewing the same tab
enforces the smallest connected client geometry across all attached windows.
Connecting a smaller terminal window constrains the larger terminal view.

- **Disconnecting another client**: Press `Ctrl+Shift+s` to open the in-session manager,
  then press `Ctrl+x` to disconnect other clients. After disconnecting the smaller client,
  resize the Kitty window or switch tabs once to restore full window dimensions.
- **Single-client recommendation**: For normal interactive work, attach only one
  terminal client per session. The `pj` project switcher warns before attaching to an
  already active session from outside Zellij.

### Navigation bindings

- **Tab navigation (Guaranteed native)**: `Ctrl+Shift+[` (previous tab) and `Ctrl+Shift+]`
  (next tab), plus `Ctrl+Shift+1..9` (direct tab index). These bindings execute client-local
  native Zellij actions and work reliably without WASM plugins.
- **Pane and Neovim split navigation**: `Ctrl+h/j/k/l` moves seamlessly between Neovim splits
  and Zellij panes. This chord is strictly pane-scoped and never crosses tabs, ensuring that
  one keypress produces exactly one navigation action even in multi-client sessions.

### Troubleshooting

- **Checking Zellij version**: Run `zellij --version` in any shell.
- **UI Name distinctions**:
  - `3:Tab #3` (rounded pill) is the **tab name** (`Ctrl+Shift+r` to rename).
  - Title on pane border is the **pane name** (`Ctrl+Shift+,` to rename).
  - An identifier like `project-api` is the **session name** (`zellij action rename-session <name>`).
- **Opening the session manager**: In an active session, press `Ctrl+Shift+s`.
- **Mode recovery**: If alphanumeric keys appear swallowed, check the left status pill.
  If it displays `PREFIX`, `MOVE`, `SCROLL`, `SEARCH`, or a rename mode, press
  `Ctrl+Shift+Esc` to return to `NORMAL`.

## Secrets

Plaintext belongs only in the ignored `secrets/` directory. New archives use
authenticated `age` passphrase encryption:

```sh
./scripts/secrets.sh decrypt
./scripts/secrets.sh encrypt
```

The committed `secrets.enc` may still use the legacy OpenSSL format. Decrypt it
once and encrypt it again to migrate; the scripts retain read-only compatibility.

`vault` creates a local-only encrypted archive (default: repository-local `secrets.vault`).
The `backup`, `restore`, `list`, and destructive `clean` commands operate purely locally.
There is no automatic remote copy or cloud synchronization; the user is responsible
for maintaining an off-machine copy if disaster recovery is required.
`vault restore` never fetches a missing file and fails immediately if the target archive is absent.
Pre-existing `$HOME/.config/rclone` files are not removed automatically, but new backups omit
rclone configuration and legacy archive restores block `.config/rclone`.

Run `vault` and `init-9router` as the desktop user, without prefixing the whole
command with `sudo`. Both scripts request `sudo` only for the ownership or
system files they need to change. During `vault restore`, applications that keep
credential databases open are closed, and GNOME Keyring plus 9router are
restarted after the restored files are in place.
