---
name: redis
description: "Redis caching patterns, eviction policies, data structures, atomic operations, and pub/sub. Use when designing cache layers, rate limiters, distributed locks, or key eviction strategies."
---

# Redis Caching & In-Memory Patterns

Architecture and engineering best practices for Redis caching, atomic synchronization, and data structures.

## Core Rules

1. **Key Naming & TTL Invariants**:
   - Format keys with structured prefixes: `{tenant}:{namespace}:{entity}:{id}` (e.g. `tenant_1:cache:user:42`).
   - Every cached object MUST have an explicit Time-To-Live (`TTL`). Indefinite keys without TTL lead to unconstrained memory growth.
   - Add random jitter to TTLs (`TTL + rand(-30, 30)`) to prevent cache stampede / simultaneous expiration.
2. **Data Structure Selection**:
   - **Strings**: Simple JSON/binary key-value caches and atomic counters (`INCR`, `DECR`).
   - **Hashes**: Structured entity objects with field-level reads and updates (`HGET`, `HSET`).
   - **Sorted Sets (ZSET)**: Leaderboards, rolling rate limiters, and time-delayed task queues.
   - **Bitmaps / HyperLogLog**: High-density analytics, unique daily active users (DAU).
3. **Atomic Mutations & Distributed Locking**:
   - Use Lua scripts or `MULTI`/`EXEC` for multi-key transactional updates to prevent race conditions.
   - For distributed locks, use Redlock or standard `SET key value NX PX 5000` with unique ownership verification on release.
4. **Memory Policy & Eviction**:
   - Configure `maxmemory` and select an eviction policy appropriate for workload:
     - `volatile-lru` / `allkeys-lru` for standard cache layers.
     - `noeviction` when Redis is utilized for persistent queues (e.g. BullMQ).
