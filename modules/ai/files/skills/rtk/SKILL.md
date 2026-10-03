---
name: rtk
description: Rust Token Killer (RTK) terminal output filter and token optimization workflow. Filters command noise (git diff, test logs, linters, build traces) before ingestion into model context.
---

# RTK (Rust Token Killer) Shell Optimization Skill

Use this skill to minimize token consumption from terminal command outputs.

## Purpose
High-volume terminal outputs (`git diff`, `npm test`, linter logs, build stdout) consume excessive context tokens. RTK filters this noise natively before prompt ingestion.

## Guidelines
1. **Narrow Command Execution**:
   - Prefer targeted file status: `git status -s` instead of full `git status`.
   - Prefer diff stats first: `git diff --stat` before dumping entire diffs.
   - Limit command output using `head -n <N>`, `grep`, or tail when exploring large outputs.
2. **Shell Wrapper & Aliases**:
   - Use RTK-wrapped commands when exploring high-volume output: `rgit`, `rdiff`, `rtest`, `rlog`.
   - RTK automatically strips ANSI escapes, collapses repetitive test run lines, and prunes boilerplate headers.
3. **Preserve Error Traces**:
   - Never filter out root cause stack traces, type errors, compiler warnings, or security alerts.
