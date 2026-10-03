# Senior Implementation Checklist

Execute this checklist for every implementation task before declaring work complete.

---

## 1. Preflight & Reconnaissance
- [ ] Requirements read from `docs/specs/<feature>.md` or `docs/plans/<feature>.md`.
- [ ] Codebase searched via Codebase Memory / CodeGraph AST tools (`cg symbol`, `get_code_snippet`) rather than brute-force file scanning.
- [ ] Existing project conventions, directory layouts, and dependency managers identified.

## 2. Implementation & Code Quality
- [ ] Scoped strictly to current phase/requirement; no unauthorized scope expansion.
- [ ] Ponytail YAGNI ladder applied: Standard library or existing helpers used over new dependencies.
- [ ] Deliberate simplifications annotated with `// ponytail:` comment naming ceiling and upgrade path.
- [ ] No duplicated logic across modules (`source-quality`).

## 3. Terminal & Token Efficiency
- [ ] High-volume CLI output wrapped with RTK (`rtk git diff`, `rtk test`).
- [ ] Unnecessary command output filtered before entering conversation context.

## 4. Quality Gate Verification (Mandatory 5-Step)
- [ ] 1. Linter executed (`npm run lint`, `cargo clippy`, `golangci-lint`, etc.) with zero errors.
- [ ] 2. Formatter checked (`prettier --check`, `nixfmt`, etc.).
- [ ] 3. Typechecker executed (`tsc --noEmit`, `mypy`, `cargo check`).
- [ ] 4. Unit and integration tests passed.
- [ ] 5. Project build succeeds cleanly.

## 5. Clean Wrap-up
- [ ] No temporary debug logs (`console.log`, `print`, `dbg!`) left behind.
- [ ] `git status` inspected; only intended files modified.
