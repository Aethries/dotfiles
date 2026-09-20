# Migration Plan: <Feature / Schema Name>

- **Migration ID:** YYYYMMDD_<short_name>
- **Target Systems:** PostgreSQL / MongoDB / Redis / S3
- **Estimated Rows Affected:** XX,XXX
- **Target Release:** vX.Y.Z

---

## 1. Context & Motivation
- Why is this migration required?
- What is the current schema/data state and what is the target state?

## 2. Risk Assessment
- Table lock potential: Low / Medium / High
- Replication lag risk: Low / Medium / High
- Backfill duration estimate: XX minutes

## 3. Phased Execution Blueprint

### Phase 1: Expand (Deployable at any time)
- [ ] SQL DDL Script: Add new columns / tables with nullable / default properties.
- [ ] Index creation: `CREATE INDEX CONCURRENTLY ...`
- [ ] Application Release 1: Enable dual-writing to old and new models.

### Phase 2: Historic Data Backfill
- [ ] Backfill Script: Batched updates (`LIMIT 1000`) with delay between batches.
- [ ] Data Parity Validation Query: Verify zero discrepancy between old and new columns.

### Phase 3: Contract (Cutover & Cleanup)
- [ ] Application Release 2: Switch application read traffic exclusively to new model.
- [ ] Remove write traffic to deprecated old columns.
- [ ] Cleanup Release (N+1): Drop deprecated columns / tables.

## 4. Rollback & Contingency Plan
- **Abort Criteria:** Replication lag > 30s or error rate > 0.1%.
- **Rollback SQL Script:**
  ```sql
  -- Rollback commands to restore previous state safely
  ```
