---
name: grpc-protobuf-engineer
description: "gRPC & Protocol Buffers engineering: binary serialization, service definitions (.proto), unary and streaming RPCs, backwards compatibility rules, and interceptor chains across Go and TypeScript. Use when designing or implementing gRPC services."
---

# gRPC & Protocol Buffers Engineering

Standards for high-throughput, low-latency inter-service communication using gRPC and Protocol Buffers (Proto3).

## Core Rules

1. **Protobuf Schema Evolution**:
   - Never change existing tag numbers or data types of published fields.
   - If a field is deprecated, mark it `[deprecated = true]` or use `reserved` tag numbers and field names to prevent accidental reuse.
   - Treat all Proto3 fields as optional; handle zero/default values safely without assuming presence unless using field presence wrappers.

2. **Streaming & RPC Patterns**:
   - **Unary RPC**: Default for request-response APIs.
   - **Server Streaming**: Use for real-time event feeds, large file downloads, or query result pagination.
   - **Client Streaming**: Use for bulk telemetry ingestion or file uploads.
   - **Bidirectional Streaming**: Use for full-duplex conversational channels (chat, live synchronization).

3. **Context & Deadline Propagation**:
   - Every outbound client call must set an explicit deadline/timeout (`context.WithTimeout`). Never make unbounded gRPC calls.
   - Propagate cancellation tokens down through the entire call graph to release downstream server resources.

4. **Error Handling & Status Codes**:
   - Use standard gRPC status codes (`codes.NotFound`, `codes.InvalidArgument`, `codes.Unauthenticated`, `codes.DeadlineExceeded`).
   - Attach rich error details using `google.rpc.Status` with error details (`BadRequest`, `PreconditionFailure`, `LocalizedMessage`).
