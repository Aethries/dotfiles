---
name: transactional-outbox-pattern
description: "Transactional Outbox Pattern & reliable messaging: eliminating dual-write bugs, database outbox tables, Change Data Capture (CDC) via Debezium, polling publishers, and idempotent message consumption. Use when publishing events reliably from transactional systems."
---

# Transactional Outbox Pattern & Reliable Messaging

Standards for achieving guaranteed at-least-once message delivery without dual-write bugs in distributed systems.

## Core Rules

1. **Eliminate Dual-Write Anti-Patterns**:
   - Never write to a database and directly publish to a message broker in the same API handler. If the broker call fails or network drops, database state and event bus desynchronize permanently.
   - Insert business entity state and outbox event records within the same ACID database transaction:
     ```sql
     BEGIN;
     INSERT INTO orders (...) VALUES (...);
     INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload, created_at)
     VALUES (gen_random_uuid(), 'Order', order_id, 'OrderCreated', payload_json, NOW());
     COMMIT;
     ```

2. **Publishing Mechanisms**:
   - **CDC (Change Data Capture)**: Read outbox table changes directly from database WAL / binary logs (e.g. via Debezium) for zero polling overhead and instant event dispatch.
   - **Polling Publisher**: If CDC is unavailable, poll with `SELECT ... FOR UPDATE SKIP LOCKED` in small batches, publish to broker, then delete or mark as published.

3. **Idempotent Consumers**:
   - Message delivery is at-least-once. Every consumer must implement idempotency.
   - Maintain a processed events table (`processed_events (event_id, processed_at)`) or verify unique constraints before executing state transitions.

4. **Payload Minimization**:
   - Store serializable JSON/Protobuf in outbox payloads.
   - Include metadata: `id`, `correlation_id`, `trace_id`, `aggregate_type`, `aggregate_id`, `event_type`, and `timestamp`.
