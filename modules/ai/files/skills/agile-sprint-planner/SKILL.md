---
name: agile-sprint-planner
description: "Agile sprint planning & task decomposition: user story mapping, acceptance criteria (Definition of Done), story point sizing, dependency graphs, and critical path estimation. Use when breaking down epics into actionable developer tasks."
---

# Agile Sprint Planning & Task Decomposition

Standards for converting high-level product initiatives into tightly scoped, deliverable developer tasks.

## Core Rules

1. **User Story Structure & INVEST Principles**:
   - Write stories in user-centric format: `As a [persona], I want [capability] so that [business value]`.
   - Ensure stories satisfy INVEST criteria: Independent, Negotiable, Valuable, Estimable, Small, Testable.

2. **Unambiguous Acceptance Criteria (Definition of Done)**:
   - Every user story must provide verifiable acceptance criteria:
     - Functional behavior verified (happy path + error cases).
     - Automated unit/integration tests written and passing in CI.
     - Telemetry events / logs emitted for monitoring.
     - Documentation updated (API spec, README, or migration guide).

3. **Dependency & Critical Path Mapping**:
   - Identify blocking dependencies between backend, frontend, and infrastructure tasks before sprint commitment.
   - Sequence tasks to unblock parallel work (e.g. deliver mock API contract schemas on Day 1 to unblock frontend development).

4. **Task Sizing Discipline**:
   - Decompose tasks so that no individual engineering ticket exceeds 2–3 developer days.
   - If a task feels ambiguous or estimate variance is high, schedule a time-boxed spike ticket first.
