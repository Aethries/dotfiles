---
name: redis-distributed-patterns
description: "Advanced Redis distributed patterns: Redlock distributed locking, sliding-window rate limiting, Redis Streams consumer groups, cache stampede prevention, and atomic Lua scripting. Use when implementing distributed coordination or caching."
---

# Redis Distributed Patterns & High-Performance Caching

Production standards for distributed concurrency, stream processing, and caching primitives using Redis.

## Core Rules

1. **Distributed Locking (Redlock & Safe Unlock)**:
   - Always acquire locks with a deterministic TTL and random token value (`SET resource_name my_random_token NX PX 30000`).
   - Never release locks with simple `DEL`. Use atomic Lua script verification to guarantee that a process only releases locks it currently owns:
     ```lua
     if redis.call("get", KEYS[1]) == ARGV[1] then
         return redis.call("del", KEYS[1])
     else
         return 0
     end
     ```

2. **Sliding-Window Rate Limiting**:
   - Implement rate limiters via Redis Sorted Sets (`ZSET`):
     - Score and member set to microsecond timestamps.
     - Prune timestamps outside window via `ZREMRANGEBYSCORE`.
     - Count remaining elements via `ZCARD`.
     - Reject if count exceeds limit; otherwise add current timestamp via `ZADD`.

3. **Redis Streams & Consumer Groups**:
   - Use Redis Streams (`XADD`) for persistent event queues.
   - Use Consumer Groups (`XREADGROUP`) to fan out message processing across multiple worker instances.
   - Acknowledge processed messages explicitly (`XACK`) and reclaim stuck messages via `XAUTOCLAIM`.

4. **Cache Stampede (Thundering Herd) Defense**:
   - Apply probabilistic early expiration (XFetch algorithm) or distributed mutexes before querying the database on cache miss.
   - Add random TTL jitter (`TTL = base_ttl + rand(0, 300)`) to prevent simultaneous key expiration across clusters.
