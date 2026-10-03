---
name: golang
description: "Idiomatic Go systems programming: concurrency patterns, goroutines, channels, error wrapping, table-driven tests, gopls, and golangci-lint hygiene. Use when developing Go applications, CLI tools, or microservices."
---

# Idiomatic Go Engineering

Standards for high-performance, maintainable Go code following official Go idioms and tooling conventions.

## Core Invariants

1. **Error Handling & Wrapping**:
   - Always return errors to callers; never drop errors with `_` unless explicitly justified.
   - Wrap errors with context using `fmt.Errorf("operation failed: %w", err)` to preserve `errors.Is` and `errors.As` chains.
   - Do not panic in library or service code. Restrict `panic()` strictly to non-recoverable bootstrap failures.

2. **Concurrency & Lifecycle**:
   - Always accept `context.Context` as the first argument in blocking, I/O, or network operations (`ctx context.Context`).
   - Every goroutine must have a deterministic lifecycle and exit condition. Prevent goroutine leaks by binding to context cancellation or close channels.
   - Use `sync.WaitGroup` or `errgroup.Group` for coordinated worker fan-out.
   - Prefer channel communication for data ownership transfer; use `sync.Mutex` / `sync.RWMutex` for state synchronization.

3. **Interface Design (Accept Interfaces, Return Structs)**:
   - Define interfaces where they are consumed, not where they are implemented.
   - Keep interfaces minimal (1–2 methods; e.g. `io.Reader`, `io.Closer`).
   - Avoid package-level exported interfaces with only a single implementation.

4. **Testing & Tooling**:
   - Structure tests as table-driven tests (`tests := []struct{ name string ... }`).
   - Satisfy `golangci-lint` without suppressions.
   - Format strictly with `gofumpt` and run `goimports`.
