---
name: caching-strategy-architect
description: "Multi-tier caching architecture & invalidation: CDN edge caching, reverse proxy cache, distributed Redis, in-memory local caches, Write-Through/Cache-Aside patterns, and cache penetration/stampede prevention. Use when designing high-concurrency caching tiers."
---

# Multi-Tier Caching Architecture & Strategy

Production standards for designing performant, coherent, multi-layer caching architectures across distributed systems.

## Core Rules

1. **Multi-Tier Caching Topology**:
   - Tier 1: **Browser / Edge CDN** (Cloudflare, Fastly): Static assets, public cacheable GET payloads (`Cache-Control: public, max-age=3600, stale-while-revalidate=60`).
   - Tier 2: **Gateway / Reverse Proxy** (Nginx, Envoy): Microsecond response for identical public API queries.
   - Tier 3: **Distributed Cache** (Redis, Memcached): Shared cluster state, sessions, rate limits, frequently accessed relational entities.
   - Tier 4: **Process Local Memory** (LRU / Caffeine / Go sync.Map): Ultra-hot immutable lookup tables (sub-millisecond latency).

2. **Caching Access Patterns**:
   - **Cache-Aside (Lazy Loading)**: Application reads cache; on miss, queries DB and populates cache. Best for read-heavy, unpredictable query patterns.
   - **Write-Through**: Application writes to cache; cache writes to DB synchronously. Ensures consistency but adds write latency.
   - **Write-Behind (Write-Back)**: Application writes to cache; worker asynchronously flushes to DB. Best for high write throughput (counters, analytics), with slight durability trade-off.

3. **Invalidation Strategies (Cache Eviction)**:
   - Always set an explicit TTL on every cache entry; never create immortal cache keys.
   - Invalidate by event: publish domain events (`ProductUpdated`) to trigger targeted cache deletion across nodes.
   - Use cache tag-based purging (surrogate keys) on edge CDNs.

4. **Failure Defense Protocols**:
   - **Cache Penetration (Non-existent keys)**: Cache null results with short TTL (60s) or use Bloom filters to avoid hammering DB with non-existent IDs.
   - **Cache Breakdown / Stampede**: Use mutex locks or probabilistic early expiration (XFetch) for hot keys near expiry.
   - **Cache Avalanche**: Add random jitter to key TTLs to distribute expiration events evenly over time.
