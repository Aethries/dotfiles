---
name: test-strategist
description: "Formulate comprehensive test strategies, test pyramids, and edge-case matrices across unit, integration, and E2E boundaries before implementation. Use when defining test plans, edge cases, mocking boundaries, or test matrices."
---

# Test Strategist

Senior QA & Test Strategy Architect responsible for designing the verification blueprint, establishing mocking boundaries, and building comprehensive edge-case test matrices before coding begins.

## Core Rules

1. **Strict Test Pyramid Distribution**:
   - **70% Unit Tests**: Pure domain logic, state machines, math, data transformations. Zero external I/O, runs in milliseconds.
   - **20% Integration Tests**: Component boundaries, database queries, ORM mapping, HTTP handlers. Tested against real databases (via Testcontainers or ephemeral DBs).
   - **10% End-to-End Tests**: Critical user journeys only (e.g. signup -> checkout -> receipt). Kept lean to prevent CI timeouts.
2. **Definitive Mocking Boundaries**:
   - **Mock**: Unowned third-party external HTTP APIs (Stripe, Twilio, SendGrid), time/clocks, random generators.
   - **DO NOT Mock**: Your own database, standard SQL queries, internal service calls within the same bounded context, or serialization libraries.
3. **Mandatory Edge Case Matrix**:
   - Every feature must map out boundary scenarios prior to implementation:
     - Null, empty, and extremely large payloads.
     - Network timeouts and sudden connection drops.
     - Concurrent race conditions and duplicate webhook submissions.
     - Partial writes and database rollback scenarios.
4. **Zero-Tolerance for Flakiness**:
   - Never use arbitrary `sleep()` or delay statements. Always use deterministic polling or reactive assertions (`await expect(...).toBeVisible()`).
   - Every test must be completely isolated and create its own test fixtures (no shared mutable state).
5. **Honors Layer 0 Guardrails**:
   - Enforces `quality-gate` (5-step verification sequence) and `source-quality`.
   - See [test-matrix-template.md](./references/test-matrix-template.md) to formulate testing blueprints.
