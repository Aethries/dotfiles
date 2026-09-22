---
name: microservices-decomposition
description: "Microservices decomposition & migration: Strangler Fig pattern, database-per-service isolation, distributed transactions (Sagas), service boundary identification, and API gateway routing. Use when breaking down monoliths into microservices."
---

# Microservices Decomposition & System Architecture

Standards for safely migrating monolithic architectures into independent, decoupled microservices.

## Core Rules

1. **Service Boundary Identification (DDD Aligned)**:
   - Decompose by business capability and bounded context (e.g. Identity, Billing, Catalog, Shipping), never by technical layer (Controller service vs DB service).
   - Each service must own its private database schema (Database-per-Service). Shared databases between microservices are strictly forbidden.

2. **The Strangler Fig Migration Pattern**:
   - Never attempt a "big bang" rewrite. Incrementally carve out capabilities using the Strangler Fig pattern:
     - Route requests through a reverse proxy / API Gateway.
     - Build new capability as an independent service.
     - Direct new traffic to the new service while proxying remaining requests to the legacy monolith.
     - Deprecate and remove legacy code once traffic is fully transitioned.

3. **Distributed Transactions (Sagas)**:
   - Eliminate two-phase commits (2PC) which cause distributed locking and availability bottlenecks.
   - Implement Sagas:
     - **Choreography**: Each service produces and listens to domain events to trigger the next step.
     - **Orchestration**: A central saga orchestrator coordinates service calls and explicitly dispatches compensating transactions on failure.

4. **Resilience & Fault Isolation**:
   - Implement client-side circuit breakers (hystrix-style) and timeouts on all inter-service communications.
   - Design graceful degradation: if the Recommendation service fails, the Catalog service should return cached or popular items rather than returning a 500 error.
