---
name: nixos
description: "NixOS module design, Flakes configuration, Home Manager integrations, and reproducible devShells. Use when writing Nix expressions, packaging software, or configuring NixOS systems."
---

# NixOS & Flakes Architecture

Authoritative guide for writing idiomatic Nix expressions, modular NixOS configurations, and reproducible devShells.

## Core Rules

1. **Flakes & Hermeticity**:
   - Always pin inputs with `flake.lock`. Never rely on unpinned channels (`<nixpkgs>`).
   - Keep Nix expressions pure and hermetic. No arbitrary network access or impure filesystem dependencies during builds.
2. **Modular Composition & Option Contracts**:
   - Split configurations into domain modules (`modules/apps/`, `modules/system/`, `modules/desktop/`).
   - Expose explicit `options` with `types` and `default` values rather than dumping raw config into `configuration.nix`.
   - Prefer `lib.mkIf` and `lib.mkDefault` for clean conditional overrides.
3. **Reproducible Development Environments (`devShells`)**:
   - Provide standard `devShells.default = pkgs.mkShell { ... }` containing compilers, language servers, linters, and helper scripts.
   - Use `direnv` and `nix-direnv` for seamless environment activation.
4. **Nix Packaging Best Practices**:
   - Use native builders (`buildRustPackage`, `buildGoModule`, `mkDerivation`, `buildNpmPackage`).
   - Pin hashes properly (`vendorHash`, `cargoHash`) and avoid `hash = ""`.
   - Test builds with `nix flake check` and `nix build`.
