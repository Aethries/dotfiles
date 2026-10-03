---
name: system-design-guardrails
description: "Internal guardrail: Enforces distributed systems constraints, idempotency, retry safety, and transaction boundaries. Use when explicitly invoked by senior workflows."
---

# System Design Guardrails

Enforces reliability, fault tolerance, transaction hygiene, and distributed systems invariants.

## Core Rules

1. **Write Idempotency**:
   - Any state-mutating operation, background job, message handler, or webhook receiver must be safely retryable or keyed by an idempotency token.
2. **Failure Handling & Bounded Retries**:
   - All network calls and external service integrations must configure explicit timeouts.
   - Retries must be bounded and employ exponential backoff with jitter to avoid stampedes.
   - Implement backpressure and circuit breaking on asynchronous streams and queue consumers.
3. **Transaction Boundaries**:
   - No blind multi-service distributed two-phase commits. Use saga or transactional outbox patterns across distributed boundaries.
   - Keep database transactions as short and narrow as possible. Never hold an open database transaction across an external HTTP or RPC call.
4. **Resource Management**:
   - Explicitly release all connections, streams, file descriptors, and mutex locks using native deterministic constructs (`defer`, `finally`, `using`).
