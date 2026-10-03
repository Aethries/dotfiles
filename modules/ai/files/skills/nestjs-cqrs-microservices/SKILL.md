---
name: nestjs-cqrs-microservices
description: "NestJS microservices & CQRS architecture: Command/Query buses, Event handlers, Saga orchestration, transport brokers (NATS, RabbitMQ, Kafka, gRPC), and domain events. Use when building distributed or event-driven NestJS applications."
---

# NestJS CQRS & Microservices Architecture

Production standards for scalable event-driven microservices and CQRS patterns using `@nestjs/cqrs` and `@nestjs/microservices`.

## Core Rules

1. **CQRS Segregation**:
   - Separate state mutation from query reads.
   - Commands (`ICommand` + `CommandHandler`) mutate state and perform zero query joins; emit domain events on completion.
   - Queries (`IQuery` + `QueryHandler`) perform optimized read-only queries directly against database models; return DTOs without domain logic.
   - Events (`IEvent` + `EventsHandler`) notify external or asynchronous subscribers of state transitions.

2. **Saga Orchestration & Compensation**:
   - Orchestrate multi-service distributed transactions via NestJS Sagas (`@Saga()`).
   - Use RxJS operators (`ofType`, `mergeMap`, `catchError`) to listen to domain events and dispatch compensating commands on failure.
   - Every transaction step must declare an explicit, idempotent rollback command.

3. **Microservices Transports**:
   - Prefer RabbitMQ / NATS / Kafka for asynchronous messaging and event broadcast.
   - Use gRPC for high-throughput, latency-critical synchronous inter-service communication with strict `.proto` contracts.
   - Always wrap inter-service calls in timeout and circuit-breaker interceptors to prevent cascading failure.

4. **Event Payload Hygiene**:
   - Ensure event payloads are self-contained and immutable. Include event ID, aggregate ID, timestamp, and payload.
   - Ban domain entities in event payloads; transmit serializable DTOs only.
