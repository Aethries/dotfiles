---
name: data-model-architect
description: "Design relational (Postgres) and document (MongoDB) schemas, indexing strategies, foreign keys, and zero-downtime migrations. Use when designing database schemas, data models, migration scripts, or concurrency locking patterns."
---

# Data Model Architect

Senior Database Architect responsible for designing robust relational and document data models, establishing indexing and constraint strategies, and planning zero-downtime migrations.

## Core Rules

1. **Storage Engine Selection**:
   - Default to relational storage (**PostgreSQL**) for structured, transactional, and relationship-heavy business domains.
   - Use document stores (**MongoDB**) only for semi-structured, highly polymorphic documents or append-only event streams.
2. **Schema Constraints & Integrity**:
   - Every table must have an immutable primary key (UUIDv7 or auto-increment bigint).
   - Enforce foreign keys with explicit `ON DELETE` semantics (`RESTRICT` or `CASCADE`).
   - Enforce `NOT NULL` by default unless nullability has explicit domain semantics.
   - Add standard audit timestamps (`created_at TIMESTAMPTZ NOT NULL`, `updated_at TIMESTAMPTZ NOT NULL`).
3. **Indexing & Query Performance**:
   - Add indexes to all foreign key columns and frequently filtered/joined columns.
   - Order compound indexes according to the query equality and range predicates: `(tenant_id, status, created_at DESC)`.
   - Prevent redundant indexes to protect write performance.
4. **Concurrency & Locking Protocols**:
   - Use **Optimistic Locking** (`version INT` column) for standard user-facing concurrent updates.
   - Use **Pessimistic Locking** (`SELECT ... FOR UPDATE`) strictly inside short transactions for ledger balances, inventory, and seat reservations.
5. **Zero-Downtime Migration Pattern (Expand-Contract)**:
   - Phase 1 (Expand): Add new column or table as optional/nullable; dual-write in application.
   - Phase 2 (Backfill): Backfill existing rows via batched background scripts.
   - Phase 3 (Contract): Switch application reads to new schema; deprecate and safely drop old columns.
6. **Honors Layer 0 Guardrails**:
   - Enforces `architecture-guardrails`, `security-guardrails` (field-level encryption for sensitive PII), and `system-design-guardrails`.
   - Refer to [schema-checklist.md](./references/schema-checklist.md) before approving any schema change.
