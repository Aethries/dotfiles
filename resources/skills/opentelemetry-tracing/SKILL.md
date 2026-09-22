---
name: opentelemetry-tracing
description: "OpenTelemetry (OTel) observability: distributed tracing, span context propagation, baggage, semantic attributes, metrics instrumentation, and collector exporting. Use when adding observability to microservices or web applications."
---

# OpenTelemetry (OTel) Observability Standards

Standards for instrumenting production microservices and applications with distributed traces and metrics using OpenTelemetry.

## Core Rules

1. **Context Propagation Across Service Boundaries**:
   - Always propagate W3C Trace Context (`traceparent` and `tracestate` headers) across HTTP, gRPC, and message brokers (RabbitMQ, Kafka, NATS).
   - In Go, pass `ctx` through all calls; in Node.js, ensure async context tracking (`AsyncLocalStorage`) is active to avoid losing trace parentage.

2. **Semantic Attributes & Cardinality Control**:
   - Adhere to OpenTelemetry Semantic Conventions for span names and attributes (`http.request.method`, `http.response.status_code`, `db.system`, `db.statement`).
   - Never inject high-cardinality attributes (UUIDs, email addresses, raw timestamps) into metric labels; attach them exclusively to span attributes.

3. **Span Granularity & Error Recording**:
   - Create child spans only for significant operations (external HTTP calls, database transactions, background jobs, heavy algorithms). Avoid micro-spans on trivial utility functions.
   - When an exception occurs, set span status to `ERROR` and record the exception object (`span.recordException(err)`).

4. **Exporter & Sampling Strategy**:
   - Export telemetry using OTLP protocol (gRPC or HTTP/protobuf) to an OpenTelemetry Collector or agent sidecar.
   - Apply head-based or tail-based sampling (e.g. 5–10% of successful requests, 100% of errors) to manage network throughput and backend storage costs.
