---
name: trpc-fullstack
description: "tRPC end-to-end type safety: router architecture, procedure middlewares, input validation (Zod), context injection, batching, and error formatter patterns across Next.js / Express / Fastify. Use when authoring type-safe fullstack RPC APIs."
---

# tRPC Fullstack Engineering Standards

Standards for end-to-end type-safe APIs connecting TypeScript frontends and backends without schemas or code generation.

## Core Rules

1. **Router & Procedure Hierarchy**:
   - Organize routers modularly by business domain (`userRouter`, `postRouter`, `billingRouter`) and merge via `appRouter`.
   - Separate procedures into:
     - `publicProcedure`: Unauthenticated access.
     - `protectedProcedure`: Enforces valid session/token via middleware; injects authenticated `ctx.user`.
     - `adminProcedure`: Enforces role-based access checks before invoking business logic.

2. **Input & Output Validation (Zod)**:
   - Validate every procedure input using Zod schemas (`.input(z.object({ id: z.string().uuid() }))`).
   - For sensitive procedures, define explicit `.output(...)` schemas to prevent leaking internal database columns or secrets to the client.

3. **Context Injection**:
   - Keep `createTRPCContext` lightweight. Inject database connection pools, auth tokens, and session handlers.
   - Avoid executing blocking database queries inside context initialization; query on demand inside procedure middlewares or handlers.

4. **Batching & Error Formatting**:
   - Enable HTTP batching (`httpBatchLink`) on client connections to combine concurrent procedure calls into a single network payload.
   - Format server errors with `TRPCError` using standard codes (`UNAUTHORIZED`, `NOT_FOUND`, `BAD_REQUEST`, `INTERNAL_SERVER_ERROR`).
   - Mask internal stack traces and database errors in production client responses.
