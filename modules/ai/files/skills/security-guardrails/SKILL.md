---
name: security-guardrails
description: "Internal guardrail: Enforces zero hardcoded secrets, input validation, and strict authorization boundaries. Use when explicitly invoked by senior workflows."
---

# Security Guardrails

Zero-tolerance security guardrails protecting infrastructure, data integrity, and authentication boundaries.

## Core Rules

1. **Zero Hardcoded Secrets**:
   - Never commit API keys, passwords, bearer tokens, or private certificates.
   - Load secrets exclusively via environment variables, secret managers, or encrypted credential vaults.
   - Verify sensitive credential files match `.gitignore` rules before touching code.
2. **Untrusted Boundary Validation**:
   - Validate and constrain all inputs at system entrypoints (schema, types, maximum length, allowable ranges).
   - Parameterize all database queries (zero raw string concatenation for SQL, NoSQL, or shell invocations).
   - Sanitize against injection attacks (SQLi, command injection, XSS, SSRF, path traversal `../`).
3. **Authorization & Multi-Tenancy**:
   - Verify authentication and authorization permissions on every private endpoint and mutation.
   - Scope all entity lookups and modifications by tenant and user identity to prevent Insecure Direct Object Reference (IDOR).
4. **Principle of Least Privilege**:
   - Restrict execution permissions. Containers and service daemons must run as non-root unprivileged users.
   - Restrict filesystem read/write privileges to designated working directories.
