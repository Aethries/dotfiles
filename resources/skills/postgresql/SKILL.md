---
name: postgresql
description: "PostgreSQL database performance tuning, indexing, connection pooling with PgBouncer, and query optimization. Use when optimizing Postgres queries, tuning vacuum/memory parameters, or configuring connection pools."
---

# PostgreSQL Optimization & Performance

Senior database administrator and performance tuning guide for PostgreSQL and PgBouncer.

## Core Rules

1. **Query Optimization & EXPLAIN ANALYZE**:
   - Inspect query plans using `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`.
   - Eliminate `Seq Scan` on multi-million row tables; replace with selective B-tree or BRIN indexes.
   - Avoid `SELECT *`; specify explicit column lists to leverage index-only scans.
2. **Indexing Strategy**:
   - Create indexes on all foreign key references and high-cardinality search predicates.
   - Use **Partial Indexes** (`WHERE status = 'unprocessed'`) for small, high-churn subsets.
   - Use **GIN Indexes** for JSONB search (`jsonb_path_ops`) and full-text search (`to_tsvector`).
   - Create production indexes with `CONCURRENTLY` to eliminate read/write table locks.
3. **Connection Pooling & PgBouncer**:
   - Never allow application containers to open unpooled direct connections to Postgres.
   - Deploy **PgBouncer** in `transaction` pooling mode for web workloads.
   - In transaction pooling mode, avoid session-level features (prepared statements without named protocol, `SET`, `LISTEN/NOTIFY`).
4. **Memory & Vacuum Tuning**:
   - Set `shared_buffers` to ~25% of system RAM.
   - Configure `work_mem` conservatively per query (e.g. 16MB-64MB) to prevent OOM under concurrent complex sorts.
   - Ensure `autovacuum` is aggressively tuned on append-heavy tables to prevent transaction ID wraparound and table bloat.
