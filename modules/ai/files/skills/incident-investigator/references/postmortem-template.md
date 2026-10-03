# Post-Mortem: <Incident Title>

- **Date:** YYYY-MM-DD
- **Severity:** Sev-1 (Critical) | Sev-2 (Major) | Sev-3 (Minor)
- **Incident Lead:** <Commander / Agent>
- **Impact Duration:** XX minutes (HH:MM to HH:MM UTC)

---

## 1. Executive Summary
- Brief 2-3 sentence overview of what broke, customer impact, and how it was mitigated.

## 2. Customer Impact
- Total users / requests impacted.
- Financial or operational impact.
- Affected components and services.

## 3. Incident Timeline (UTC)
- **HH:MM** - Culprit deployment / trigger event occurred.
- **HH:MM** - First alert triggered or user report received.
- **HH:MM** - Incident response initiated.
- **HH:MM** - Mitigation deployed (e.g. rollback, traffic redirected).
- **HH:MM** - System recovery verified and metrics stabilized.

## 4. Root Cause Analysis (5 Whys)
1. **Why did the checkout fail?** Database connections were exhausted.
2. **Why were connections exhausted?** A new reporting query was missing an index and ran table scans.
3. **Why did the query run table scans?** The index was not added to the migration script.
4. **Why was the index omitted?** The query was tested only against small local test fixtures.
5. **Why wasn't production-scale query planning checked?** Query EXPLAIN verification was not automated in CI.

## 5. Lessons Learned
- **What went well:** Fast rollback mechanism; monitoring alerts fired promptly.
- **What went poorly:** Log aggregation delayed triage; missing circuit breaker.
- **Where we got lucky:** Off-peak traffic window kept impact low.

## 6. Action Items & Remediation
| Action Item | Type | Owner | Due Date | Status |
| :--- | :--- | :--- | :--- | :--- |
| Add index on `orders.created_at` | Fix | DB Team | YYYY-MM-DD | Open |
| Add automated `EXPLAIN ANALYZE` check in CI | Prevention | DevOps | YYYY-MM-DD | Open |
| Implement connection pool timeout & circuit breaker | Mitigation | Backend | YYYY-MM-DD | Open |
