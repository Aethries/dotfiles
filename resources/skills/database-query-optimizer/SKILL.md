---
name: database-query-optimizer
description: "Database query optimization & planner analysis: EXPLAIN (ANALYZE, BUFFERS), sequential scan reduction, composite/partial/GIN indexing, lock contention triage, and connection starvation prevention. Use when optimizing SQL query performance."
---

# Database Query Optimization & Planner Analysis

Production standards for identifying slow queries, eliminating bottlenecks, and optimizing relational databases (PostgreSQL/MySQL).

## Core Rules

1. **Query Plan Dissection (`EXPLAIN ANALYZE`)**:
   - Always run `EXPLAIN (ANALYZE, BUFFERS, COSTS)` to observe actual execution times and buffer disk hits vs memory hits.
   - Look for high-cost plan nodes:
     - `Seq Scan`: Indicates missing or unusable indexes on filtered columns.
     - `Nested Loop` with high row counts: Replace with `Hash Join` or add inner index.
     - `External Sort Disk`: Indicates `work_mem` is too small, causing sorts to spill to disk.

2. **Targeted Indexing Strategies**:
   - **Composite Indexes**: Align column order to `(Equality Columns, Range/Sort Columns)`.
   - **Partial Indexes**: Index only active subsets to conserve memory and write I/O (`CREATE INDEX ... WHERE deleted_at IS NULL`).
   - **Covering Indexes (`INCLUDE`)**: Include frequently projected columns to achieve Index-Only scans without visiting heap table pages.
   - **GIN Indexes**: Use for JSONB containment (`@>`), arrays, and full-text search.

3. **Locking & Concurrency Hygiene**:
   - Never run unbounded multi-row `UPDATE` or `DELETE` statements inside long transactions; batch updates into small chunks (e.g. 1,000 rows) with small sleep pauses.
   - Avoid `SELECT ... FOR UPDATE` unless strictly necessary for pessimistic inventory locking; use optimistic locking (`version` column) where applicable.

4. **Connection Pool Sizing**:
   - Formula: `connections = ((core_count * 2) + effective_spindle_count)`. Over-allocating database connections degrades performance via CPU context switching and memory starvation.
