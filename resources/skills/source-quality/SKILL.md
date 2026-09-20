---
name: source-quality
description: "Internal guardrail: Enforces zero code duplication, strict package manager integrity, and AST awareness. Use when explicitly invoked by senior workflows."
---

# Source Quality Guardrail

Zero-tolerance for unnecessary code duplication, dead code, and package manager drift.

## Core Rules

1. **Zero Duplication (AST & Symbol Awareness)**:
   - Search for existing implementations before writing new code.
   - Maintain a single source of truth for constants, endpoints, domain models, and utility routines.
2. **Strict Tooling & Lockfile Adherence**:
   - Strictly follow the repository's established package manager. Never run `npm install` when `pnpm-lock.yaml` or `yarn.lock` is present.
   - Never add duplicate dependencies when current dependencies or standard libraries satisfy the requirement.
   - Follow repo formatting rules (tabs vs spaces, semicolons, import sorting).
3. **Dead Code Elimination**:
   - Disallow unused imports, variables, unreachable functions, and commented-out code.
   - Remove temporary debug statements and logs before completing tasks.
4. **Minimalistic Footprint**:
   - Shortest clean diff wins. Prefer boring, maintainable constructs over clever speculative abstractions.
