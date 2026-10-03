---
name: prisma
description: "Prisma ORM data modeling & transactions: schema design, relations, migration drift handling, interactive $transaction isolation, batching, and query performance tuning. Use when writing Prisma schemas or queries."
---

# Prisma ORM Standards

Standards for type-safe database access, schema authoring, migration management, and transaction safety with Prisma.

## Core Rules

1. **Schema Design & Relations**:
   - Explicitly define indexes for frequently queried or filtered fields (`@@index([userId, createdAt])`).
   - Use explicit relation names on ambiguous relations.
   - Define cascading behavior explicitly (`onDelete: Cascade` or `onDelete: Restrict`).
   - Enforce enum types at the schema level rather than using free-form strings.

2. **Query Performance & Selection**:
   - Always use `select` to retrieve only required fields; avoid `include` with unbounded nested relations that cause N+1 query amplification.
   - For pagination, prefer cursor-based pagination (`cursor: { id: lastId }, take: pageSize, skip: 1`) over offset-based pagination (`skip: 10000`).

3. **Transaction Safety**:
   - Wrap multi-operation mutations in `prisma.$transaction()`:
     ```typescript
     await prisma.$transaction(async (tx) => {
       const user = await tx.user.update(...);
       await tx.auditLog.create(...);
     });
     ```
   - Keep interactive transactions brief to avoid database connection pool starvation and timeout errors.

4. **Migration & Deployment**:
   - In development, generate migrations via `prisma migrate dev --name <migration_name>`.
   - In CI/CD and production environments, apply migrations strictly using `prisma migrate deploy`.
