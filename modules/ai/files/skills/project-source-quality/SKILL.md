---
name: project-source-quality
description: "Internal guardrail: Enforces project-native conventions, dependency choices, and functional correctness before and after production code changes. Use for implementation, bug fixes, refactors, and code review; not for docs-only requests or simple explanations."
---

# Project Source Quality Guardrail

Apply this guardrail whenever source code may change.

## 1. Build evidence before editing

- Identify the repository root, package manager, runtime versions, build/test/lint commands, and relevant `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, or README guidance.
- Use CodeGraph/Codebase Memory for symbol, import, and dependency relationships before reading or changing unfamiliar code.
- Inspect at least two nearby implementations that solve a similar problem. Record the observed file location, naming, export, error-handling, testing, and module-boundary patterns.

## 2. Preserve the project’s language

- Follow `project convention > generic best practice > agent preference`.
- Prefer an existing abstraction or dependency. Then prefer the repository’s standard library/platform. Add a dependency only when necessary and explicitly approved.
- Derive names and placement from neighboring code. Do not invent a new naming scheme, folder, export style, or architectural layer.

## 3. Implement a coherent change

- State the input, output, error, and side-effect contract before editing.
- Keep the smallest complete diff. Do not mix cleanup, renaming, formatting, or unrelated refactors.
- Preserve public behavior unless the requirement explicitly changes it. Validate trust-boundary inputs and handle expected failures explicitly.

## 4. Verify and report honestly

- Review the final diff for wrong files, names, imports, dependencies, dead code, duplicated logic, and accidental behavior changes.
- Run the narrowest relevant checks first, then the repository’s applicable quality gates. Never hide failures with suppressions or weakened tests.
- After source changes, update CodeGraph/Codebase Memory and verify index status.
- If conventions conflict or evidence is insufficient, stop and report the conflict instead of guessing.
