{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ----------------------------------------------------------
    # Nix LSP & Formatters
    # ----------------------------------------------------------
    nil # Language server for Nix
    nixd # Nix language server with rich diagnostics
    nixfmt # Official RFC-style Nix formatter

    # ----------------------------------------------------------
    # Go LSP & Tools
    # ----------------------------------------------------------
    gopls # Official Go language server
    golangci-lint # Fast Go linters runner

    # ----------------------------------------------------------
    # Web Development (JavaScript / TypeScript / CSS / HTML / JSON)
    # ----------------------------------------------------------
    typescript-language-server # Language server for TypeScript & JavaScript
    vscode-langservers-extracted # HTML/CSS/JSON/ESLint language servers
    tailwindcss-language-server # Tailwind CSS language server

    # ----------------------------------------------------------
    # Lua LSP
    # ----------------------------------------------------------
    lua-language-server # Language server for Lua

    # ----------------------------------------------------------
    # Shell Scripting (Bash / POSIX)
    # ----------------------------------------------------------
    bash-language-server # Language server for Bash
    shellcheck # Static analysis tool for shell scripts
    shfmt # Shell script formatter

    # ----------------------------------------------------------
    # C / C++
    # ----------------------------------------------------------
    clang-tools # Clangd language server and clang tools

    # ----------------------------------------------------------
    # Documentation & Data Formats (Markdown, YAML, KDL)
    # ----------------------------------------------------------
    marksman # Language server for Markdown
    yaml-language-server # Language server for YAML
    kdlfmt # Formatter for KDL documents

    # ----------------------------------------------------------
    # Formatters missing from conform.nvim config
    # ----------------------------------------------------------
    stylua # Lua formatter (conform: lua)
    gotools # Provides goimports (conform: go)
    gofumpt # Strict Go formatter (conform: go)
    ruff # Python linter & formatter (conform: python)
    prettier # JS/TS/YAML/Markdown formatter (conform: fallback)
  ];
}
