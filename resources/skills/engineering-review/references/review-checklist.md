# Code Review & PR Verification Checklist

Use this checklist when conducting formal engineering reviews under `docs/reviews/`.

---

## 1. Specification & Scope Compliance
- [ ] PR solves the explicit problem described in the issue / spec.
- [ ] No unapproved scope expansion or architectural rewrites.
- [ ] Acceptance criteria from `docs/specs/<feature>.md` are demonstrably satisfied.

## 2. Correctness & Edge Cases
- [ ] Null, undefined, empty collections, and extreme boundary values tested.
- [ ] Concurrency and race conditions evaluated (e.g. double-clicks, duplicate API calls).
- [ ] Transaction boundaries and rollback hygiene respected on database writes.

## 3. Security & Privacy
- [ ] Zero hardcoded credentials, tokens, or sensitive URLs.
- [ ] Input validation applied at every external API and user input boundary.
- [ ] Multi-tenant isolation verified (tenant ID explicitly checked on queries).
- [ ] Error messages do not leak internal stack traces or database errors to users.

## 4. Performance & Scalability
- [ ] No N+1 queries in loops; batch loading used where appropriate.
- [ ] New database queries covered by indexes.
- [ ] High-volume endpoints support pagination (cursor or offset).

## 5. Test Coverage & Quality Gate
- [ ] Unit tests cover domain logic and failure branches.
- [ ] Quality gate verification passed cleanly (lint, format, typecheck, tests, build).
- [ ] PR review findings documented with clear recommendation (Approve / Request Changes).
