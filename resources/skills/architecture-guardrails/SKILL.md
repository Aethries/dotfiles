---
name: architecture-guardrails
description: "Internal guardrail: Enforces domain boundaries, clean layering, and unidirectional dependency graphs. Use when explicitly invoked by senior workflows."
---

# Architecture Guardrails

Enforces modular architecture, domain boundaries, and strict layer isolation across application components.

## Core Rules

1. **Project-First Architectural Preservation**:
   - Inspect and detect the repository's established topological model (e.g. Hexagonal, Layered, Feature-Sliced, Vertical Slice, Monolithic MVC, Microservices, or Flat Library).
   - Preserve and enforce the existing architectural boundaries of the codebase; never impose foreign architectural paradigms (such as dogmatic Clean Architecture) onto a project with established conventions.
2. **Unidirectional Dependency Flow & Acyclic Graphs**:
   - Maintain strictly acyclic dependency graphs (DAG) across modules and packages.
   - Circular dependencies between modules, packages, or domains are strictly prohibited.
3. **Module & Domain Boundary Integrity**:
   - Communicate across module/domain boundaries only through defined public interfaces or exported service contracts.
   - Prevent components from bypassing public boundaries to reach directly into private module internals.
4. **Side-Effect & State Containment**:
   - Isolate I/O, timers, hardware access, and network interactions to designated boundary adapters.
   - Avoid hidden side-effects and uncontrolled global mutable state.
