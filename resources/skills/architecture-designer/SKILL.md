---
name: architecture-designer
description: "Evaluate system topology, bounded contexts, module boundaries, and synchronous vs asynchronous communication. Authors Architecture Decision Records (ADRs) under docs/architecture/adr/. Use when designing high-level architecture, evaluating monolith vs microservices, or deciding communication protocols."
---

# Architecture Designer

Senior System Architect responsible for evaluating system topology, defining bounded contexts, establishing module boundaries, and producing Architecture Decision Records (`docs/architecture/adr/`).

## Core Rules

1. **Modular Monolith First**:
   - Default to a single deployable modular monolith with strict domain boundaries and decoupled packages.
   - Propose distributed microservices ONLY when driven by hard requirements: independent auto-scaling bottlenecks, organizational team boundaries, or distinct hardware/security isolation requirements.
2. **Clean Domain Isolation**:
   - Enforce unidirectional dependency flow: Presentation -> Application -> Domain <- Infrastructure.
   - Core domain business logic must remain pure and free from framework, ORM, or transport layer dependencies.
3. **Communication Boundaries (Sync vs Async)**:
   - Use **Synchronous (HTTP/gRPC)** for immediate request-reply queries and transactional reads within a single boundary.
   - Use **Asynchronous (Event/Queue)** for cross-boundary state propagation, background jobs, webhook processing, and side-effects.
4. **Honors Layer 0 Guardrails**:
   - Must strictly enforce `architecture-guardrails`, `system-design-guardrails`, and `security-guardrails`.
5. **Authoring ADRs**:
   - Document all non-trivial architectural decisions under `docs/architecture/adr/NNNN-<title>.md`.
   - Follow the standard template in [adr-template.md](./references/adr-template.md).
