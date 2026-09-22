---
name: domain-driven-design
description: "Strategic and tactical Domain-Driven Design (DDD): Bounded Contexts, Ubiquitous Language, Aggregate Roots, Entities, Value Objects, Domain Events, and Anti-Corruption Layers (ACL). Use when designing complex business domains or decomposing monoliths."
---

# Domain-Driven Design (DDD) Standards

Strategic and tactical architecture patterns for modeling complex domains with clear system boundaries.

## Core Rules

1. **Ubiquitous Language & Bounded Contexts**:
   - Align all code symbols (classes, methods, variables) with domain terminology agreed upon with domain experts.
   - Establish explicit Bounded Contexts. Model concepts independently within each context (e.g., `Customer` in Billing context differs from `Customer` in Support context).
   - Use Anti-Corruption Layers (ACL) to translate data across context boundaries or when integrating external legacy systems.

2. **Tactical Building Blocks**:
   - **Entities**: Objects defined by identity that persists across state changes (`id: UUID`).
   - **Value Objects**: Immutable objects defined solely by their attributes (e.g., `Money { amount, currency }`). Replace primitives with value objects to encapsulate validation.
   - **Aggregate Roots**: Clusters of entities and value objects treated as a single transactional consistency boundary. External objects may only hold references to the Aggregate Root.

3. **Invariants & Domain Events**:
   - All business invariant checks must execute inside Aggregate Roots before state transitions occur.
   - Emit Domain Events (`OrderPlaced`, `PaymentFailed`) when an aggregate transitions state.
   - Use repositories strictly at the Aggregate Root level (`OrderRepository`, not `OrderItemRepository`).
