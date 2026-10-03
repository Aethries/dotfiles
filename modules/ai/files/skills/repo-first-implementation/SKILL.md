---
name: repo-first-implementation
description: "Run a structured, repository-first workflow for implementing features, bug fixes, refactors, or production code. Use before source changes; not for docs-only requests, explanations, or trivial one-line edits."
---

# Repo-First Implementation

Use this workflow whenever a task can change production source code.

## 1. Establish scope and evidence

- Confirm the requested outcome, acceptance criteria, and authorized files or systems.
- Find the repository root. Read applicable `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, README, contributing guidance, manifests, lockfiles, and CI configuration.
- Run `detect-stack` when stack context is missing or stale. Load project memory when an Agent Memory MCP is configured; otherwise use repository-owned memory files.
- Use CodeGraph/Codebase Memory before tracing unfamiliar symbols, callers, imports, or dependencies.

## 2. Reconstruct the local design

- Inspect at least two neighboring implementations with the same responsibility.
- Record observed conventions for file placement, names, exports, dependency direction, errors, side effects, and tests.
- Treat `project convention > generic best practice > agent preference` as the precedence order.
- Apply SOLID as a diagnostic, not a reason to invent layers: preserve existing boundaries and reuse existing abstractions.

## 3. Define the change

- State the input, output, error, side-effect, and compatibility contract.
- Identify the affected module boundary, dependency direction, and smallest complete file set.
- For non-trivial work, write or update a plan/spec with milestones and validation commands before editing.
- If evidence conflicts or a new dependency, layer, naming scheme, or public contract is needed, stop and ask instead of guessing.

## 4. Implement narrowly

- Make the smallest coherent diff that satisfies the contract.
- Reuse project-native utilities and dependencies. Do not mix cleanup, renaming, formatting, or unrelated refactors.
- Validate trust-boundary inputs and expected failure paths. Preserve public behavior unless the requirement explicitly changes it.

## 5. Verify before handoff

- Immediately update CodeGraph/Codebase Memory after source mutations and verify index status.
- Run focused checks first, then the repository's applicable lint, format, typecheck, test, and build gates. Use RTK when available.
- Review the final diff for wrong paths, names, imports, dependencies, dead code, duplication, accidental API changes, and missing tests.
- Report passed, failed, blocked, and not-run checks separately. Never claim completion from inspection alone.

Skip the full workflow only for a genuinely trivial edit whose location, naming, behavior, and validation are already unambiguous; still inspect the final diff.
