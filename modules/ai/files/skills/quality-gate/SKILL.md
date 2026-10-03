---
name: quality-gate
description: "Internal guardrail: Enforces non-negotiable verification sequence before declaring work complete. Use when explicitly invoked by senior workflows."
---

# Quality Gate Guardrail

Non-negotiable verification sequence and test integrity standards required before marking any task complete.

## Core Rules

1. **Mandatory 5-Step Verification Sequence**:
   Tasks are ONLY considered complete when all applicable verification rungs pass locally:
   1. **Lint**: Run project linters (`eslint`, `shellcheck`, `golangci-lint`, `ruff`, `cargo clippy`).
   2. **Format**: Check formatting compliance (`prettier`, `nixfmt`, `gofmt`, `black`, `rustfmt`).
   3. **Typecheck**: Verify static types (`tsc`, `mypy`, `pyright`).
   4. **Test**: Execute unit, integration, and regression test suites.
   5. **Build**: Execute local build / compilation step.
2. **Zero Weakening of Guardrails**:
   - Never insert `@ts-ignore`, `@ts-expect-error`, `eslint-disable`, `# noqa`, or compiler suppression flags to bypass failures without explicit approval.
   - Never weaken assertions, skip existing tests, or delete failing test cases to make a test suite pass.
3. **Regression Evidence**:
   - Bug fixes must include an automated regression test reproducing the original issue.
   - Non-trivial logic must leave at least one runnable automated verification check behind.
