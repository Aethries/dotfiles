# Editor theme and installation

## Palette and style ownership

Noctalia supplies semantic colors (`primary`, `on_primary`, `surface`, etc.).
The repository owns rounded borders, layout, opacity, animation, spacing,
highlight roles, and active/inactive states.

| Responsibility | Source |
| --- | --- |
| Palette mapping and highlight styling | `files/matugen-template.lua` |
| Generated colors and highlights | `files/lua/matugen.lua` |
| Neovide opacity, padding, animation and corner radius | `files/lua/config/neovide.lua` |
| Plugin layouts and rounded borders | `files/lua/plugins/ui.lua`, `navigation.lua`, `lsp.lua` |
| Template registration | `../noctalia/files/templates.toml` |

Edit the template when changing highlights. Editing only the generated Lua is
temporary: the next palette update regenerates it. Both Neovim and Neovide use
this same template. Accent backgrounds use their corresponding `on_*` text
colors; the exact numerical contrast still depends on the chosen palette and
the wallpaper behind transparent areas.

`modules/noctalia/setup.sh` installs the user template registration. The
community `neovim` template is disabled because it writes the same output and
would replace our styling. No community cache directory is needed. The post
hook reloads running Neovim processes through SIGUSR1.

After changing the template, apply the current palette with:

```sh
noctalia msg templates-apply
```

Ghostty's built-in template selects a separate theme file. Starship's built-in
integration updates its palette section. Zellij's community template writes
the theme file; the tab layout remains in the repository layout configuration.

## Installation

The root `install.sh` installs the package manifests and runs the module setup
scripts. Neovim setup links its configuration and invokes Lazy; dependencies
are declared in Lua and pinned in `files/lazy-lock.json`. Image preview needs
`imagemagick` and `chafa`, declared in `packages/pacman.txt`.

Command completion loads on `CmdlineEnter`: `:` suggests commands, arguments
and paths. Tab/Shift+Tab navigate suggestions, Ctrl+Y accepts a selected entry,
and Ctrl+E closes completion. No entry is automatically preselected.

## Verification boundaries (2026-10-06)

- Passed: Noctalia configuration validation; actual rendering with two palettes
  changes only color values; active template application preserves the same
  non-color Lua; Lua syntax checks.
- Passed: command completion source/config checks for `se` and `set nu`.
- Passed: eight UI setup modules run twice with an empty HOME under another
  username and twelve links resolve into an isolated repository copy. External
  downloads/package commands were mocked in this check.
- Not verified: a complete installation on a fresh operating system, Neovide
  appearance by GUI testing, and all real dependency downloads. `chafa` was not
  installed on the current machine during this audit.
- Remaining portability concerns outside the editor template: saved Noctalia
  wallpaper paths and Codex project-specific paths. Codex desktop colors are
  separate from its CLI theme integration.

## Vietnamese preedit in Ghostty

The supplied recording shows the caret staying at the start of composing text
and advancing only on commit. In Ghostty 1.3.1, GTK preedit handling discards
the IME caret offset, and the renderer skips the native cursor during preedit.
The shader consequently cannot animate the missing preedit caret position.
No documented Ghostty option fixes this behavior; the existing shader is kept.

References: [GTK preedit handling](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/apprt/gtk/class/surface.zig),
[renderer](https://github.com/ghostty-org/ghostty/blob/v1.3.1/src/renderer/generic.zig),
[Noctalia template configuration](https://docs.noctalia.dev/noctalia/theming/templates/).
