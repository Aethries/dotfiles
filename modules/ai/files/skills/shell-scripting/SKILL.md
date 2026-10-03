---
name: shell-scripting
description: "Defensive Bash & POSIX shell scripting: strict error handling, shellcheck static analysis, dynamic path resolution, trap cleanups, and atomic file operations. Use when authoring or refactoring shell scripts."
---

# Defensive Shell Scripting Standards

Production standards for robust, portable Bash and POSIX automation scripts across developer environments.

## Core Rules

1. **Strict Execution Modes**:
   - Begin scripts with `set -euo pipefail` to abort on errors, undefined variables, and pipeline failures.
   - For POSIX `/bin/sh` scripts, use `set -eu`.

2. **No Hardcoded Absolute Paths**:
   - Resolve script directory dynamically:
     ```bash
     SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
     ```
   - Respect environment overrides (`${REPO_ROOT:-...}`). Never hardcode `/home/<user>` or `/loc/...`.

3. **Variable Hygiene & Quoting**:
   - Always double-quote variable expansions: `"$VAR"`, `"${FILES[@]}"`.
   - Use uppercase for environment variables (`PATH`, `USER_HOME`), lowercase for local script variables (`local target_dir`).
   - Use default parameter expansions for optional variables (`${1:-default}`).

4. **Resource Management & Traps**:
   - Clean up temporary files with `trap`:
     ```bash
     tmp_dir="$(mktemp -d)"
     trap 'rm -rf "$tmp_dir"' EXIT
     ```
   - Atomic file writes: write to temporary file, then `mv -f "$tmp_file" "$dest_file"`.

5. **Linting & Formatting**:
   - Run and pass `shellcheck` with zero warnings.
   - Format with `shfmt -i 2 -ci`.
