---
name: tech-debt-strategist
description: "Technical debt assessment & remediation planning: categorizing debt (architectural, code, dependency, testing), interest calculation, risk-vs-reward prioritization, and boy-scout refactoring roadmaps. Use when planning refactoring or legacy system modernization."
---

# Technical Debt Strategy & Refactoring Roadmaps

Standards for auditing, sizing, and incrementally eliminating technical debt without stopping product velocity.

## Core Rules

1. **Categorization & Quantification**:
   - Categorize technical debt into four quadrants:
     - **Architectural Debt**: Monolithic coupling, violation of boundaries, poor database schemas.
     - **Code Hygiene Debt**: Duplicated logic, dead code, missing error handling.
     - **Dependency Debt**: Outdated runtimes, deprecated libraries, unmaintained packages.
     - **Test Debt**: Slow test suites, flaky tests, missing edge-case coverage.
   - Quantify the "interest rate" (e.g. developer hours lost per sprint, customer incident frequency, deployment friction).

2. **The 20% Boy Scout Rule**:
   - Reserve 15–20% of engineering bandwidth in every sprint for incremental debt paydown.
   - Practice opportunist refactoring: clean up and test code touched during active feature work rather than waiting for giant, unapprovable rewrite projects.

3. **Risk-Reward Prioritization**:
   - Prioritize remediation with high interest savings and low blast radius:
     - High Interest / Low Risk: Eliminate immediately.
     - High Interest / High Risk: Design expand-and-contract migration with feature flags.
     - Low Interest: Defer or leave untouched.

4. **Safety Net Verification**:
   - Never begin a refactoring initiative without an existing automated regression test suite covering the target component's observable behavior.
