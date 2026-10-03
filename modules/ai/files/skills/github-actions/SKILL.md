---
name: github-actions
description: "GitHub Actions CI/CD automation: workflow syntax, matrix builds, dependency caching, composite actions, secret hygiene, and artifact retention. Use when creating or debugging GitHub Actions workflows."
---

# GitHub Actions CI/CD Standards

Standards for authoring deterministic, secure, and performant CI/CD workflows with GitHub Actions.

## Core Rules

1. **Security & Permissions**:
   - Explicitly specify `permissions` at top-level or job-level (`permissions: { contents: read }`).
   - Pin third-party actions to full commit SHA (e.g. `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1`) rather than mutable tags to guard against supply-chain tampering.
   - Mask and protect sensitive tokens with repository secrets (`${{ secrets.GITHUB_TOKEN }}`). Never echo credentials into workflow logs.

2. **Caching & Speed**:
   - Cache package manager stores (pnpm, npm, cargo, go) using native setup actions (`actions/setup-node` with `cache: 'pnpm'`, `actions/setup-go` with `cache: true`).
   - Run linter and type-checker steps before running heavy end-to-end or build steps to fail fast.

3. **Matrix & Concurrency**:
   - Use concurrency groups with `cancel-in-progress: true` on PR branches to cancel redundant runs:
     ```yaml
     concurrency:
       group: ${{ github.workflow }}-${{ github.ref }}
       cancel-in-progress: true
     ```
   - Use matrix builds for multi-platform or multi-version compatibility checks (`matrix: { os: [ubuntu-latest], node: [20, 22] }`).
