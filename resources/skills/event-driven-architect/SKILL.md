---
name: event-driven-architect
description: "Event-Driven Architecture (EDA) & Event Sourcing: broker selection (Kafka, RabbitMQ, NATS), schema registries (Avro/Protobuf), idempotency keys, dead-letter exchanges, and consumer backpressure. Use when designing asynchronous distributed systems."
---

# Event-Driven Architecture (EDA) & System Design

Engineering standards for decoupled, fault-tolerant, and high-throughput event-driven distributed architectures.

## Core Rules

1. **Event Types & Payload Design**:
   - Differentiate clearly:
     - **Domain Events**: Facts that happened in the business domain (`OrderPlaced`, `InvoicePaid`).
     - **Event-Carried State Transfer (ECST)**: Full state snapshots enabling consumers to update internal caches without querying the producer.
   - Enforce schema contracts via Schema Registries (Protobuf / Avro / JSON Schema). Never publish schema-less raw JSON across bounded contexts.

2. **Idempotency & Ordering Semantics**:
   - Producers must generate deterministic idempotency keys (`Idempotency-Key` header or event ID).
   - Assume distributed messaging provides at-least-once delivery; consumers must be strictly idempotent.
   - For strict FIFO ordering requirements, partition events by business entity ID (e.g. `partition_key = customer_id`).

3. **Dead-Letter Exchanges & Poison Pills**:
   - Attach a Dead-Letter Queue (DLQ) to all topic subscriptions.
   - Configure retry policies with exponential backoff and jitter (e.g. 3 retries over 5 minutes before routing to DLQ).
   - Set up alerting on DLQ message count to notify on-call engineers of unparseable poison pills.

4. **Backpressure & Concurrency Control**:
   - Consumers must pull work based on processing capacity (prefetch limit / batch size) rather than having brokers push unbounded workloads that exhaust memory.
