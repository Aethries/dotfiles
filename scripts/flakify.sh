#!/usr/bin/env bash
# ==============================================================================
# flakify: Instant Zero-Pollution Dev Environment Generator
# Generates reproducible Nix devShell flakes + .envrc in 1 second
# ==============================================================================

set -euo pipefail

TEMPLATE="${1:-}"

if [ -z "$TEMPLATE" ]; then
    if command -v fzf >/dev/null 2>&1; then
        TEMPLATE=$(printf "node\ngo\nrust\npython\nfullstack" | fzf \
            --height=40% \
            --layout=reverse \
            --border=rounded \
            --prompt="⚡ Select Dev Environment: ")
    else
        echo "Usage: flakify <node|go|rust|python|fullstack>"
        exit 1
    fi
fi

if [ -z "$TEMPLATE" ]; then
    exit 0
fi

if [ -f "flake.nix" ]; then
    echo "⚠️  flake.nix already exists in current directory ($(pwd)). Aborting to avoid overwrite."
    exit 1
fi

case "$TEMPLATE" in
    node)
        cat << 'EOF' > flake.nix
{
  description = "Node.js Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
            corepack
            pnpm
            yarn
            typescript
            typescript-language-server
          ];

          shellHook = ''
            export COREPACK_ENABLE_STRICT=0
            echo "🚀 Node.js dev environment loaded ($(node --version))"
          '';
        };
      });
}
EOF
        ;;

    go)
        cat << 'EOF' > flake.nix
{
  description = "Go Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            golangci-lint
            delve
          ];

          shellHook = ''
            echo "🚀 Go dev environment loaded ($(go version))"
          '';
        };
      });
}
EOF
        ;;

    rust)
        cat << 'EOF' > flake.nix
{
  description = "Rust Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            cargo
            rust-analyzer
            clippy
            rustfmt
            pkg-config
          ];

          shellHook = ''
            echo "🚀 Rust dev environment loaded ($(rustc --version))"
          '';
        };
      });
}
EOF
        ;;

    python)
        cat << 'EOF' > flake.nix
{
  description = "Python Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python311
            uv
            ruff
            pyright
          ];

          shellHook = ''
            echo "🚀 Python dev environment loaded ($(python3 --version))"
          '';
        };
      });
}
EOF
        ;;

    fullstack)
        cat << 'EOF' > flake.nix
{
  description = "Fullstack Web & Go Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
            pnpm
            go
            gopls
            tailwindcss-language-server
            docker-compose
          ];

          shellHook = ''
            echo "🚀 Fullstack dev environment loaded"
          '';
        };
      });
}
EOF
        ;;

    *)
        echo "Unknown template '$TEMPLATE'. Available: node, go, rust, python, fullstack"
        exit 1
        ;;
esac

# Create .envrc for direnv integration
if [ ! -f ".envrc" ]; then
    echo "use flake" > .envrc
fi

if command -v direnv >/dev/null 2>&1; then
    direnv allow
fi

echo "✨ Successfully initialized '$TEMPLATE' environment in $(pwd)!"
echo "   - Created flake.nix"
echo "   - Created .envrc (direnv enabled)"
