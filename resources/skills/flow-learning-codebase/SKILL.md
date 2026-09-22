---
name: flow-learning-codebase
description: "Codebase flow learning & reverse engineering: execution path tracing, sequence reconstruction, dependency topology mapping, mental model synthesis, and legacy codebase exploration. Use when onboarding into unfamiliar codebases or tracing complex request flows."
---

# Codebase Flow Learning & Reverse Engineering

Methodology for rapidly mapping execution paths, data flows, and architectural mental models in unfamiliar codebases.

## Core Rules

1. **Entry Point Identification**:
   - Locate boundary entry points first: HTTP router, CLI command entry, queue listener, or scheduled cron.
   - Trace inbound request serialization, validation, and authentication middleware before inspecting business logic.

2. **Breadth-First Sequence Reconstruction**:
   - Trace the primary happy path end-to-end before exploring edge cases or secondary branches.
   - Construct concise sequence sketches:
     `Client Request -> Controller -> AuthGuard -> Service.execute() -> Repository.query() -> DB -> EventBus.publish() -> Response`
   - Document state mutations at each layer: identify which layer modifies the database, writes to cache, or invokes external APIs.

3. **Dependency Topology & Bounded Contexts**:
   - Identify module boundaries and dependency direction: verify if domain logic depends on infrastructure or vice versa.
   - Trace shared mutable state (singletons, global variables, in-memory caches) that may introduce hidden coupling.

4. **Telemetry & Log Anchoring**:
   - Look for structured logging statements and tracing spans (`tracer.startSpan`) to observe production runtime behavior.
   - Reconstruct error handling flows: identify where errors are caught, transformed, or suppressed.
