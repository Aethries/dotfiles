# Schema Design & Migration Checklist

Review every schema, table definition, and migration script against this checklist.

---

## 1. Primary Keys & Types
- [ ] Primary key defined using standard type (UUIDv7 or BigInt).
- [ ] Data types chosen to match domain precision (e.g. `DECIMAL(18,4)` or integer cents for monetary values, never floating-point).
- [ ] Timestamps stored with timezone (`TIMESTAMPTZ` in Postgres, ISO-8601 UTC).

## 2. Integrity & Constraints
- [ ] Mandatory `NOT NULL` constraints applied across non-optional attributes.
- [ ] Foreign keys explicitly declared with appropriate `ON DELETE` behavior (`CASCADE`, `RESTRICT`, or `SET NULL`).
- [ ] Unique constraints declared for natural business keys (e.g. `(tenant_id, email)`).
- [ ] Check constraints (`CHECK`) enforced for range boundaries, positive integers, and enum state sets.

## 3. Indexing Strategy
- [ ] Foreign key columns have an index.
- [ ] Compound indexes ordered by: Equality columns first -> Range/Sort columns last.
- [ ] High-volume partial indexes used for status filters (e.g. `WHERE status = 'pending'`).
- [ ] No duplicate or overlapping indexes.

## 4. Concurrency & Locking
- [ ] Concurrency pattern documented (Optimistic via `version` column vs Pessimistic via `SELECT FOR UPDATE`).
- [ ] Transaction isolation level considered (Read Committed default; Serializable for complex financial reconciliations).
- [ ] Transactions kept strictly under 100ms; external network calls (HTTP/RPC) strictly forbidden inside database transactions.

## 5. Zero-Downtime Migration Safety (Expand-Contract)
- [ ] Adding new column: Created as `NULL` or with default that does not trigger table lock.
- [ ] Renaming column: Forbidden in single step. Uses alias or new column + dual-write.
- [ ] Dropping column: Column is ignored in application code for at least one release cycle before `DROP COLUMN`.
- [ ] Large backfill: Script executes in batches of 1,000-5,000 rows with pauses to avoid replication lag and table locking.
