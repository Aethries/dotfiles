---
name: ponytail
description: Anti-overengineering ruleset biasing agents toward minimal, standard-library-first code.
---

# Ponytail / Lazy Senior Developer Skill

Lazy means efficient, not careless. The best code is the code never written.

## Core Rules

1. **Ultra: YAGNI Extremist**: Deletion before addition. Ship the one-liner and challenge the rest of the requirement in the same response.
2. **6-Step Code Filter**: Stop at the first rung that holds:
   - Does this need to exist at all? (YAGNI)
   - Does stdlib do it? Use it.
   - Does native platform feature cover it? Use it (CSS over JS, DB constraint over app code).
   - Does an already-installed dependency solve it? Use it; never add a new one for what a few lines can do.
   - Can it be one line? One line.
   - Only then: minimum code that works.
   - For detailed filter breakdowns and edge cases, see [code-filter.md](./references/code-filter.md).
3. **No Unrequested Abstractions**: No interface with one implementation, no factory for one product, no config for a value that never changes, no scaffolding "for later".
4. **Boring over Clever**: Fewest files possible; shortest working diff wins. Two stdlib options the same size: take the edge-case-correct one.
5. **Deliberate Simplifications**: Mark with a `// ponytail:` comment naming the ceiling and upgrade path.
   - Pattern: `[code] → skipped: [X], add when [Y].`
6. **Non-Negotiables**: Never simplify away input validation at trust boundaries, error handling that prevents data loss, security, accessibility, or anything explicitly requested.
7. **Verification**: Non-trivial logic leaves ONE runnable check behind (an assert-based self-check or one small test file; no frameworks). Trivial one-liners need no test.

## Granular Laziness Tiers

- **Lite**: Mild pruning of boilerplate, keeps standard comments and error handling.
- **Full**: Strict YAGNI, standard library first, zero unrequested abstraction.
- **Ultra** (Default): Radical minimalism, extreme conciseness, ship the one-liner, delete before adding, strip all speculative boilerplate and filler. Active by default.

## Safety & Quality Guardrails

- **Zero Semantic Degradation**: Ponytail must never compromise code correctness, type safety, or security.
- **Diff & Syntax Integrity**: Never prune code indentation, patch context, compiler errors, or test assertion logic.
- **Domain Exceptions**: Architecture documentation, security reviews, and root-cause analysis (RCA) remain thorough and detailed.
