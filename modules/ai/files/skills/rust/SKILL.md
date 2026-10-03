---
name: rust
description: "Rust systems programming: memory safety, ownership/borrowing, Tokio async runtime, error handling, and Clippy hygiene. Use when developing Rust applications, CLI tools, or async services."
---

# Rust Systems Engineering

Idiomatic Rust development standards for CLI tools, systems programming, and high-throughput async services.

## Core Rules

1. **Idiomatic Error Handling**:
   - Use `thiserror` for domain-specific library and service errors where callers need to match on variants.
   - Use `anyhow` for top-level application binaries and CLI tools where detailed context matters.
   - Ban `unwrap()` and `expect()` in production paths; propagate errors via `?` or handle via `match`/`if let`.
2. **Ownership & Borrowing**:
   - Pass references (`&str`, `&[T]`) rather than owned clones (`String`, `Vec<T>`) unless ownership is required.
   - Avoid excessive `.clone()` to appease the borrow checker; restructure types or lifetimes.
3. **Async Runtime & Tokio**:
   - Use Tokio for async I/O (`tokio::fs`, `tokio::net`).
   - Never run blocking CPU-bound computations or blocking standard library I/O on async worker threads; offload via `tokio::task::spawn_blocking`.
   - Always handle cancellation gracefully with `tokio::select!`.
4. **Clippy & Compiler Hygiene**:
   - Enable and strictly satisfy `#![deny(clippy::all)]` and `#![warn(clippy::pedantic)]`.
   - Document public structs, traits, and functions with doc-comments (`///`).
