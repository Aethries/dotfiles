# Test Strategy & Edge Case Matrix

Feature verification matrix defining test levels, mocking boundaries, and edge case coverage.

---

## 1. Test Pyramid Distribution
- **Unit Target**: ~70% (Domain entities, calculation services, parsers)
- **Integration Target**: ~20% (Database repositories, API endpoints, queue workers)
- **E2E Target**: ~10% (Core user journeys: onboarding, purchasing, admin approval)

## 2. Mocking Strategy
| Boundary | Strategy | Tooling / Approach |
| :--- | :--- | :--- |
| External APIs (e.g. Stripe, AWS S3) | Mock / Stub | WireMock / MSW / nock |
| Primary Database (PostgreSQL) | Real Instance | Testcontainers / Ephemeral Test DB |
| System Clock / Timers | Controlled Fake | FakeClock / Vi.useFakeTimers |
| File System | In-Memory / Temp Dir | Ephemeral tmpdir with cleanup |

## 3. Edge Case Matrix
| ID | Scenario | Level | Preconditions / Input | Expected Result | Failure Mode Tested |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-01 | Happy Path | Unit | Valid credentials and input | 200 OK + payload | None |
| TC-02 | Missing Mandatory Field | Unit | Payload with missing required key | 400 Bad Request + field error | Validation |
| TC-03 | Concurrent Duplicate Request | Integration | 2 identical requests with same idempotency key | 1 processed, 1 cached reply | Race Condition |
| TC-04 | DB Deadlock / Timeout | Integration | Simulated DB lock contention | Retries 3x with backoff -> 503 | Resilience |
| TC-05 | Upstream Outage | Integration | Third-party payment gateway 500 | Circuit breaker opens -> graceful error | Dependency Failure |
| TC-06 | Boundary Values | Unit | Max integer, 10MB payload, empty string | Graceful rejection without crash | Resource Exhaustion |

## 4. Flakiness Prevention Checklist
- [ ] No hardcoded `sleep()` or timeout delays.
- [ ] Database state reset between tests via transaction rollback or table truncate.
- [ ] Random seed fixed or parameterized.
- [ ] Ports dynamically assigned to avoid conflicts in parallel execution.
