---
name: prd-author
description: "Product Requirements Document (PRD) authoring: problem formulation, user personas, measurable success metrics (KPIs/OKRs), feature prioritization (MoSCoW/RICE), and out-of-scope boundaries. Use when defining new products or major initiatives."
---

# Product Requirements Document (PRD) Standards

Standards for authoring unambiguous, value-driven PRDs aligning product goals, engineering constraints, and business outcomes.

## Core Rules

1. **Problem Statement First**:
   - Begin with the core user problem and evidence: who experiences this pain, how severe is it, and what are the current workarounds?
   - Resist prescribing technical solutions in the problem formulation section.

2. **Measurable Success Metrics (KPIs & OKRs)**:
   - Every feature must define measurable leading and lagging indicators:
     - Leading: User engagement rate, workflow completion speed, adoption percentage.
     - Lagging: Churn reduction, ARR impact, support ticket volume decrease.
   - Specify guardrail metrics that must NOT regress (e.g. page latency, error rate).

3. **Strict Scoping & Non-Goals**:
   - Explicitly enumerate **Non-Goals / Out of Scope** items to prevent scope creep.
   - Categorize features using MoSCoW prioritization:
     - **Must-Have (P0)**: System cannot release without this.
     - **Should-Have (P1)**: Important but temporary workarounds exist.
     - **Could-Have (P2)**: High-value polish if time permits.
     - **Won't-Have (P3)**: Explicitly deferred to future iterations.

4. **Edge Cases & Failure Modes**:
   - Define expected user experiences for empty states, permission denials, offline states, and data migration edge cases.
