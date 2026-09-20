---
name: nestjs
description: "NestJS enterprise architecture, modular structure, dependency injection, and interceptor/pipe patterns. Use when developing or refactoring NestJS backend applications."
---

# NestJS Architecture & Best Practices

Enterprise architecture rules for building scalable, maintainable server-side applications with NestJS.

## Core Rules

1. **Modular Architecture & Encapsulation**:
   - Organize by domain feature modules (`UsersModule`, `BillingModule`, `OrdersModule`).
   - Export ONLY services intended for public consumption outside the module. Keep internal repositories and helpers unexported.
   - Use `forRoot` / `forRootAsync` with `ConfigService` for dynamic configurable modules.
2. **Dependency Injection Hygiene**:
   - Inject interfaces or service classes directly into constructors via private readonly members:
     ```typescript
     constructor(private readonly usersService: UsersService) {}
     ```
   - Avoid circular dependencies. Use `forwardRef()` strictly as a temporary migration fix, not an architecture pattern.
3. **Pipes, Interceptors & Exception Filters**:
   - Use `ValidationPipe` with `class-validator` and `class-transformer` (`whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`).
   - Use custom `ExceptionFilter` to map domain exceptions to standard HTTP error envelopes.
   - Use Interceptors for cross-cutting logging, performance metrics, and response transformations.
4. **Layer 0 Core Guardrails**:
   - Must honor `architecture-guardrails` (domain logic separated from controller transport) and `security-guardrails` (JWT guard authentication, role decorators).
