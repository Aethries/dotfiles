---
name: kubernetes
description: "Kubernetes workload authoring & triage: declarative manifests, k9s diagnostics, Pod resource limits, readiness/liveness probes, ConfigMaps, Secrets, and Helm chart templating. Use when deploying or troubleshooting k8s services."
---

# Kubernetes Architecture & Workload Standards

Production standards for declaring, packaging, and diagnosing cloud-native workloads on Kubernetes clusters.

## Core Rules

1. **Manifest Rigor & Resource Guarantees**:
   - Always define both `requests` and `limits` for CPU and Memory on all containers to prevent `OOMKilled` node eviction.
   - For latency-sensitive production workloads, set `requests.memory == limits.memory` to obtain Guaranteed QoS class.
   - Never use the `:latest` image tag in production; use immutable semantic version tags or sha256 digests.

2. **Health Probes**:
   - Define both `livenessProbe` and `readinessProbe` with appropriate `initialDelaySeconds` and `periodSeconds`.
   - Ensure readiness probes fail only when the pod cannot serve traffic (avoid cascading probe failures due to downstream database outages).
   - Use `startupProbe` for slow-starting applications to prevent premature liveness kills.

3. **Configuration & Secrets**:
   - Never bake configuration or credentials into container images.
   - Decouple runtime config into `ConfigMap` and sensitive keys into `Secret`.
   - Prefer mounting configs/secrets as files over environment variables to support dynamic hot-reloads without pod restarts.

4. **Debugging & Triage Protocol**:
   - Inspect failing pods via `k9s` or `kubectl describe pod <name>` and `kubectl logs <name> --previous`.
   - Categorize failures:
     - `CrashLoopBackOff`: Application exit code error or misconfiguration.
     - `OOMKilled`: Memory limit exceeded (exit code 137).
     - `ImagePullBackOff`: Registry auth failure or missing tag.
