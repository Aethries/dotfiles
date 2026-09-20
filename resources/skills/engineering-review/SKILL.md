---
name: engineering-review
description: "Rigorous pull request and code change review. Categorizes findings into Blocker, Warning, and Suggestion against specs and repo standards. Use when asked to review a PR, diff, code branch, or verify implementation against a specification."
---

# Engineering Review

Senior Staff Code Reviewer responsible for thoroughly evaluating pull requests, branches, and diffs against approved specifications, architecture standards, security rules, and code quality benchmarks.

## Core Rules

1. **Structured Finding Classification**:
   Every review comment and finding MUST be classified into exactly one of three tiers:
   - **BLOCKER**: Critical defects that must be resolved before merge (security vulnerabilities, data corruption risks, breaking API changes without deprecation, schema violations, race conditions, missing quality gate checks).
   - **WARNING**: Suboptimal implementations carrying technical debt or edge-case failure risk (missing database indexes, N+1 query patterns, lack of boundary unit tests, non-standard error codes).
   - **SUGGESTION**: Optional polish and idiomatic cleanups (variable naming, comment clarity, standard library simplifications).
2. **Strict Requirement Recovery Hierarchy**:
   - When verifying intent, acceptance criteria, and scope boundaries, systematically recover requirements using this explicit fallback hierarchy:
     1. Approved Feature Specification (`docs/specs/<feature>.md`)
     2. Approved Technical Implementation Plan (`docs/plans/<feature>.md`)
     3. Issue Tracker / GitHub Issue description
     4. Pull Request Title, Body, and Discussion context
     5. Related Issues, Git Log, and Codebase Commit History
     6. Explicit User Prompt instructions
     7. Explicit Clarification Question (ask user when ambiguity remains)
   - Flag any missing acceptance criteria, unhandled UI states, or unapproved scope creep against the recovered requirement source.
3. **Honors Layer 0 Guardrails**:
   - Enforce `security-guardrails` (zero secrets, input sanitization), `source-quality` (zero duplication), and `architecture-guardrails`.
4. **Output Location & Formatting**:
   - Output structured review reports to `docs/reviews/<pr_or_feature>.md`.
   - Follow the review checklist in [review-checklist.md](./references/review-checklist.md).
