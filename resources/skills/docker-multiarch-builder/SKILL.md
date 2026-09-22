---
name: docker-multiarch-builder
description: "Docker Buildx & multi-architecture image engineering: cross-platform compilation (linux/amd64, linux/arm64), BuildKit cache mounts (--mount=type=cache), rootless containers, and minimal distroless base images. Use when building production container images."
---

# Docker Multi-Architecture & BuildKit Standards

Standards for building secure, ultra-compact, multi-architecture container images using Docker Buildx and BuildKit.

## Core Rules

1. **Multi-Arch Compilation (Buildx)**:
   - Build for cross-platform target platforms using BuildKit:
     ```bash
     docker buildx create --use --name multi-builder
     docker buildx build --platform linux/amd64,linux/arm64 -t myrepo/app:1.0.0 --push .
     ```
   - Avoid slow QEMU emulation for compiled languages (Go, Rust, C); use native multi-stage cross-compilation with target architecture arguments (`TARGETARCH`, `TARGETOS`).

2. **BuildKit Cache Mounts**:
   - Cache package manager stores between builds to achieve near-instant rebuilds:
     ```dockerfile
     # Node/pnpm cache
     RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile
     # Go module cache
     RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build go build -o /bin/app .
     ```

3. **Minimal Distroless & Scratch Images**:
   - Run production binaries on minimal bases (`gcr.io/distroless/static-debian12`, `alpine`, or `scratch`).
   - Eliminate package managers, shells, and build dependencies from the final image stage to minimize CVE attack surface.

4. **Rootless & Security Context**:
   - Explicitly declare a non-root user (`USER nonroot:nonroot` or `USER 10001:10001`).
   - Never run application processes as root (`UID 0`) inside containers.
