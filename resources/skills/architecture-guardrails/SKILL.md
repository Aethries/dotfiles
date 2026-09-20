---
name: architecture-guardrails
description: "Internal guardrail: Enforces domain boundaries, clean layering, and unidirectional dependency graphs. Use when explicitly invoked by senior workflows."
---

# Architecture Guardrails

Enforces modular architecture, domain boundaries, and strict layer isolation across application components.

## Core Rules

1. **Unidirectional Dependency Flow**:
   - Dependencies must flow inward: `Presentation / API -> Domain / Service -> Persistence / Infrastructure`.
   - Outer layers depend on inner layers; inner core domain models never depend on outer transport or database frameworks.
2. **Layer Isolation**:
   - Presentation/controller layers must never directly query databases, execute SQL, or handle raw ORM transaction scopes.
   - Domain logic must remain free of transport-specific types (HTTP status codes, request bodies, gRPC metadata).
3. **Module & Domain Boundaries**:
   - Communicate across domain boundaries only through defined service interfaces or public module contracts.
   - Circular package or module imports are strictly prohibited.
4. **Side-Effect Containment**:
   - Keep business calculations pure and deterministic; isolate I/O, timers, and external network interactions to boundary adapters.
   - Avoid hidden or mutable global state.
