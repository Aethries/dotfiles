---
name: postgresql
description: "PostgreSQL database performance tuning, indexing, connection pooling with PgBouncer, and query optimization. Use when optimizing Postgres queries, tuning vacuum/memory parameters, or configuring connection pools."
---

# PostgreSQL Optimization & Performance

Senior database administrator and performance tuning guide for PostgreSQL and PgBouncer.

## Core Rules

1. **Workload & Cost Model Analysis First**:
   - Always profile queries using `EXPLAIN (ANALYZE, BUFFERS)`.
   - Evaluate access paths realistically: sequential scans are often optimal for small tables, low cardinality predicates, or bulk reads. Focus optimization on buffer reads, I/O wait times, and high filter discard rates rather than blindly eliminating sequential scans.
   - Avoid `SELECT *`; project explicit column lists to enable index-only scans.
2. **Workload-Aligned Indexing Strategy**:
   - Select index types based on column cardinality and query access patterns:
     - **B-tree**: Default for high-cardinality equality and range searches.
     - **BRIN**: Ideal for massive append-only tables physically clustered by time/sequence.
     - **GIN**: Optimal for JSONB containment (`jsonb_path_ops`), array operations, and full-text search.
     - **Partial Indexes**: Highly effective for small, high-churn active subsets (`WHERE processed = false`).
   - Create production indexes with `CONCURRENTLY` to prevent blocking concurrent reads and writes.
3. **Connection Topology & Pooling**:
   - Match connection strategies to deployment topology (serverless ephemeral functions vs persistent microservices).
   - Size active database connections against physical CPU cores and I/O saturation limits rather than arbitrary multiplier rules.
   - When deploying connection poolers (PgBouncer, Supavisor, or application pools), evaluate pooling mode constraints (transaction vs session pooling, named prepared statement limitations).
4. **Resource Sizing & Maintenance Hygiene**:
   - Size `work_mem` conservatively based on peak concurrent queries to prevent out-of-memory errors during complex sort/hash operations.
   - Adjust `shared_buffers` and cache parameters based on dedicated database memory vs shared host constraints.
   - Tune autovacuum scale factors, cost limits, and freeze thresholds on high-write tables to prevent bloat and transaction ID wraparound.
