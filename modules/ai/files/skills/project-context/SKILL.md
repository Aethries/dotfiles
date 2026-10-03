---
name: project-context
description: "Internal guardrail: Enforces codebase reconnaissance, dependency inspection, and priority of project conventions. Use when explicitly invoked by senior workflows."
---

# Project Context Guardrail

Mandatory pre-flight reconnaissance before proposing or executing non-trivial architectural or implementation decisions.

## Core Rules

1. **Reconnaissance First**:
   - Inspect build system, package manager, linter/formatter configs, and test frameworks before changing code.
   - Detect existing package managers via lockfiles (`pnpm-lock.yaml`, `package-lock.json`, `bun.lockb`, `yarn.lock`, `Cargo.lock`, `flake.nix`, `go.mod`, `pyproject.toml`). Never assume tools.
2. **Strict Precedence Hierarchy**:
   `project convention > generic best practice > agent personal preference`
3. **Reuse Existing Abstractions**:
   - Search the codebase for existing utilities, helpers, patterns, and type definitions before creating new ones.
   - Match existing naming conventions, directory structure, and module granularity.
4. **Target Runtime & Edition**:
   - Align with the project's configured language version, compiler flags, and target environment.
