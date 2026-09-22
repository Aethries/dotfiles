---
name: qa-test-flow-engineer
description: "QA test flow engineering: user journey test cases, regression test matrices, edge-case failure injection, Gherkin/BDD scenarios, and release readiness verification. Use when designing end-to-end test flows and test suites."
---

# QA Test Flow Engineering

Standards for designing comprehensive end-to-end user journeys, regression verification matrices, and system test flows.

## Core Rules

1. **User Journey & Flow Mapping**:
   - Map complete end-to-end user flows from entry point to terminal state (e.g., Guest Registration -> Email Verification -> Profile Setup -> Subscription Purchase -> Invoicing).
   - Format scenarios using BDD (Given-When-Then) syntax:
     ```gherkin
     Scenario: User cannot check out with expired card
       Given an authenticated user with items in their cart
       When the user submits payment with an expired credit card
       Then a user-friendly error "Card expired" is displayed
       And the cart contents remain intact
     ```

2. **Test Scenario Matrices**:
   - Structure regression matrices with explicit dimensions:
     - Pre-conditions & State requirements
     - Input vectors (valid, boundary, malicious/invalid)
     - Expected system state & database mutations
     - Expected telemetry, audit logs, and external webhooks

3. **Failure Injection & Negative Flows**:
   - Test unexpected user drop-off (closing tab mid-checkout, double-clicking submit).
   - Test network interruptions (offline state, 504 gateway timeout, partial response).
   - Test race conditions (simultaneous logins, concurrent inventory purchases).

4. **Release Gate Verification**:
   - Maintain a critical path Smoke Test checklist (P0 flows that must pass before any production deployment).
   - Flag non-deterministic or flaky tests immediately; quarantine flaky flows until stabilized.
