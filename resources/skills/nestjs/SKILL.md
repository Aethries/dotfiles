---
name: nestjs
description: "NestJS enterprise architecture, modular structure, dependency injection, and interceptor/pipe patterns. Use when developing or refactoring NestJS backend applications."
---

# NestJS Architecture & Best Practices

Enterprise architecture rules for building scalable, maintainable server-side applications with NestJS.

## Core Rules

1. **Stack & Ecosystem Reconnaissance First**:
   - Inspect `package.json` to detect the project's established validation and auth stack:
     - **Validation**: Detect whether the project uses `zod` (`nestjs-zod`), `valibot`, `typia`, or `class-validator`/`class-transformer`. Never introduce a secondary validation library if one is already installed.
     - **Authentication & Authorization**: Detect whether the project uses `@nestjs/passport`, `better-auth`, `lucia`, or custom session guards before writing auth logic.
     - **Platform**: Verify `@nestjs/platform-express` vs `@nestjs/platform-fastify` before writing platform-specific middleware or interceptors.
2. **Modular Architecture & Encapsulation**:
   - Organize by domain feature modules (`UsersModule`, `BillingModule`, `OrdersModule`).
   - Export ONLY services intended for public consumption outside the module. Keep internal repositories and helpers unexported.
   - Use `forRoot` / `forRootAsync` with `ConfigService` for dynamic configurable modules.
3. **Dependency Injection & Lifecycle Hygiene**:
   - Inject interfaces or service classes directly into constructors via private readonly members:
     ```typescript
     constructor(private readonly usersService: UsersService) {}
     ```
   - Avoid circular dependencies. Use `forwardRef()` strictly as an emergency migration escape hatch, not an architecture pattern.
4. **Pipes, Interceptors & Exception Filters**:
   - Configure global or route-level validation matching the project's validation library.
   - Use custom `ExceptionFilter` to map domain exceptions to standard HTTP error envelopes.
   - Use Interceptors for cross-cutting telemetry, logging, and response transformations.
5. **Layer 0 Core Guardrails**:
   - Must honor `architecture-guardrails` (domain logic decoupled from HTTP transport) and `security-guardrails`.
