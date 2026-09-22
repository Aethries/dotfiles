---
name: api-security-auditor
description: "API security auditing & OWASP API Top 10 defense: Broken Object Level Authorization (BOLA), mass assignment, JWT token safety, rate limiting, CORS configuration, and SSRF prevention. Use when reviewing or securing API endpoints."
---

# API Security Auditing & OWASP Defense

Defensive engineering standards for eliminating vulnerabilities across REST, GraphQL, and RPC endpoints.

## Core Rules

1. **Broken Object Level Authorization (BOLA / IDOR)**:
   - Never rely on client-supplied IDs alone (`GET /orders/:id`). Always verify that the authenticated user owns or has explicit permission to access the target object (`WHERE id = :id AND user_id = :auth_user_id`).
   - Use non-sequential UUIDs (v4 or v7) for external IDs to prevent enumeration attacks.

2. **Broken Object Property Level Auth (Mass Assignment)**:
   - Never pass raw `request.body` into database update or creation methods.
   - Use strict DTOs / Pydantic models with whitelist-only field definitions. Strip sensitive fields (`role`, `is_admin`, `verified`).

3. **Authentication & Token Hygiene**:
   - Verify JWT signatures strictly using asymmetric keys (RS256 / EdDSA). Ban `alg: none`.
   - Store access tokens in memory or short-lived memory; store refresh tokens exclusively in HTTP-only, Secure, SameSite cookies.
   - Enforce token rotation and blacklisting on logout.

4. **Resource Limiting & SSRF Defenses**:
   - Enforce rate limiting per IP and per authenticated user (`express-rate-limit`, Redis token bucket).
   - If the API fetches user-supplied URLs, block loopback and private IP ranges (`127.0.0.1`, `10.0.0.0/8`, `192.168.0.0/16`, `169.254.169.254`) to prevent Server-Side Request Forgery (SSRF).
