---
name: deep-debugger
description: "Senior debugging & root-cause isolation: binary git bisecting, memory leak diagnosis, heap snapshot profiling, CPU flamegraphs, race condition reproduction, and distributed trace analysis. Use when diagnosing elusive, intermittent, or high-severity production bugs."
---

# Senior Debugging & Root Cause Isolation

Rigorous diagnostic standards for isolating, reproducing, and eliminating complex software regressions.

## Core Rules

1. **Deterministic Reproduction First**:
   - Never write patch code until the bug is deterministically reproduced in a minimal, isolated test script or unit test.
   - If intermittent, increase concurrency, inject artificial network latency, or randomize execution ordering until failure rate is measurable.

2. **Binary Search & Bisecting**:
   - For historical regressions, use automated `git bisect run <test_script>` to find the exact offending commit SHA.
   - For runtime logic, use binary chop hypothesis testing: halve the suspect code path at each diagnostic step.

3. **Memory & Performance Profiling**:
   - For memory leaks, capture two heap snapshots (before and after workload cycle) and inspect the retained objects diff.
   - For high CPU usage, capture CPU profiles/flamegraphs; optimize only the hot path identified by profiling, never guess.
   - Inspect event loop blockage (Node.js/Go) using performance hooks or runtime metrics.

4. **Race Conditions & Concurrency**:
   - Detect data races using native toolchain flags (`go test -race`, Node.js `--trace-warnings`, Rust Loom/ThreadSanitizer).
   - Verify lock acquisition ordering across all threads to prevent deadlocks.
