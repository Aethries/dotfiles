# Resilience & Reliability Patterns

Standard architecture implementations for system resilience.

---

## 1. Retry with Exponential Backoff & Jitter
Prevent synchronized retry storms against struggling downstream services:
```
sleep = random_between(0, min(max_backoff, base * 2 ^ attempt))
```
- **Base Backoff**: 100ms
- **Max Backoff**: 5000ms
- **Max Retries**: 3 attempts
- **Retry Condition**: Retry only on transient errors (503 Service Unavailable, 504 Gateway Timeout, connection reset). Never retry 4xx errors (except 429 when `Retry-After` is present).

## 2. Circuit Breaker States
- **CLOSED**: Traffic flows normally. Error rate monitored over sliding window (e.g. 20 requests).
- **OPEN**: If error rate > 50%, all calls immediately return fallback or fail fast without hitting downstream.
- **HALF-OPEN**: After `cooldown_period` (e.g. 15s), allow trial requests through. If successful, reset to CLOSED; if failures persist, trip back to OPEN.

## 3. Bulkhead & Pool Isolation
- Dedicated database connection pool for web requests vs background batch processing.
- Thread pool isolation per upstream integration (e.g. payment gateway cannot exhaust email worker pool).

## 4. Dead Letter Queue (DLQ) Strategy
- Consumer tries processing up to 3 times with exponential backoff.
- On 4th failure, message acked from primary queue and forwarded to `service-dlq` with failure headers (`x-exception`, `x-retry-count`, `x-timestamp`).
- Alert fires if DLQ count > 0.
