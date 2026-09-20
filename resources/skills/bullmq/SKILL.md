---
name: bullmq
description: "Distributed job queues, background workers, scheduled jobs, and retry policies using BullMQ and Redis. Use when implementing async task processing, queue concurrency, or background workers."
---

# BullMQ Distributed Job Queues

Best practices for designing background job queues, worker concurrency, and resilient task scheduling using BullMQ and Redis.

## Core Rules

1. **Job Idempotency & Unique Keys**:
   - Provide a deterministic `jobId` for critical business jobs (e.g. `order-confirmation-${orderId}`) to prevent duplicate queuing.
   - Job workers MUST be idempotent; executing the same job twice must produce no adverse side-effects.
2. **Backoff & Failure Resilience**:
   - Configure retry backoff with exponential strategy:
     ```typescript
     {
       attempts: 5,
       backoff: { type: 'exponential', delay: 2000 },
       removeOnComplete: 1000,
       removeOnFail: 5000,
     }
     ```
   - Unhandled failures after max attempts must route to dead-letter alerting or a quarantine queue.
3. **Worker Concurrency & Connection Hygiene**:
   - Tune `concurrency` based on job I/O profile (high concurrency for external HTTP calls; low concurrency for CPU-bound tasks).
   - Use dedicated Redis connection instances for Queues, Workers, and QueueEvents (`maxRetriesPerRequest: null`).
4. **Clean Graceful Shutdown**:
   - Listen to `SIGTERM` / `SIGINT` signals and call `worker.close()` to allow in-flight jobs to finish before process termination.
