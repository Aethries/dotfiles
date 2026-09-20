---
name: api-contract-designer
description: "Standardize API interfaces across REST, GraphQL, gRPC, and WebSockets. Enforces uniform error envelopes, idempotency keys, and explicit pagination contracts. Use when designing API endpoints, schemas, payloads, or webhook specifications."
---

# API Contract Designer

Senior API Architect responsible for designing robust, consistent, and backward-compatible API contracts across REST, GraphQL, gRPC, and WebSockets.

## Core Rules

1. **Protocol & Interface Matching**:
   - **REST**: Primary public and CRUD interface; resource-oriented URLs (`/v1/workspaces/{id}/members`).
   - **GraphQL**: Complex aggregations and rich client dashboards requiring dynamic field selection.
   - **gRPC / Protobuf**: High-throughput internal service-to-service communication.
   - **WebSockets / SSE**: Push notifications, streaming status, and real-time collaboration.
2. **Uniform Error Envelope**:
   - Every API error response must use the canonical error envelope:
     ```json
     {
       "error": {
         "code": "RESOURCE_NOT_FOUND",
         "message": "Workspace with ID 42 was not found.",
         "details": [
           { "field": "workspace_id", "issue": "Does not exist or belongs to another tenant" }
         ]
       }
     }
     ```
   - Match HTTP status codes accurately (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict, 422 Unprocessable, 429 Too Many Requests, 500 Internal Error).
3. **Mutation Idempotency**:
   - All non-idempotent operations (POST/PATCH for payments, checkouts, or resource provisioning) must support the `Idempotency-Key` header.
   - Replayed requests with the same idempotency key must return the cached initial response without re-executing side effects.
4. **Explicit Pagination Contracts**:
   - High-volume and chronological feeds must use **Cursor-Based Pagination** (`limit`, `cursor`, `next_cursor`).
   - Admin search tables with low churn may use **Offset/Limit Pagination** (`page`, `per_page`, `total_count`).
5. **Strict Backward Compatibility**:
   - API modifications must be strictly additive (new fields are optional; existing fields and semantics are never deleted or modified in-place).
   - Versioning occurs via URL path (`/v1/...`).
6. **Honors Layer 0 Guardrails**:
   - Enforces `security-guardrails` (input validation, rate limiting headers, authentication scopes) and `system-design-guardrails`.
   - See [api-standards.md](./references/api-standards.md) for full interface standards.
