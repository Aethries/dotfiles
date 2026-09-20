---
name: docker
description: "Docker containerization, multi-stage builds, rootless containers, layer caching, and compose architectures. Use when creating Dockerfiles, optimizing image sizes, or configuring Docker Compose."
---

# Docker Containerization & Multi-Stage Builds

Production standards for authoring secure, compact, and highly cacheable Dockerfiles and compose setups.

## Core Rules

1. **Multi-Stage Builds**:
   - Separate build-time tooling (compilers, devDependencies, header files) from runtime environments.
   - Use lightweight runtime base images (e.g. `alpine`, `distroless`, or slim variants).
   - Only copy compiled artifacts and production dependencies into the final stage.
2. **Layer Caching Optimization**:
   - Order Dockerfile instructions from least-frequently changed to most-frequently changed.
   - Copy dependency manifests (`package.json`, `pnpm-lock.yaml`, `Cargo.toml`, `go.mod`) and install dependencies BEFORE copying application source code.
3. **Non-Root User Enforcement**:
   - Never run container processes as root in production.
   - Create a dedicated non-root user and group (`USER appuser:appgroup`).
4. **Secrets & Cache Hygiene**:
   - Never burn secrets, `.env` files, private keys, or API tokens into image layers.
   - Use BuildKit secret mounts (`--mount=type=secret,id=npmrc`) for build-time credentials.
   - Use `.dockerignore` to exclude `.git`, `node_modules`, build caches, and test artifacts.
5. **Health Checks & Signals**:
   - Define lightweight `HEALTHCHECK` instructions.
   - Use `STOPSIGNAL SIGTERM` and ensure your PID 1 process properly reaps zombies and forwards signals.
