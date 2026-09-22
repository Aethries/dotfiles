---
name: cicd-security-hardening
description: "CI/CD pipeline security & supply-chain defense: OpenID Connect (OIDC) cloud authentication, action commit SHA pinning, SLSA provenance generation, secret scanning, and runner hardening. Use when securing automated deployment pipelines."
---

# CI/CD Security Hardening & Supply Chain Defense

Standards for eliminating vulnerabilities, credential leakage, and supply-chain tampering across automated CI/CD pipelines.

## Core Rules

1. **OIDC Federation (Zero Long-Lived Cloud Credentials)**:
   - Eliminate hardcoded cloud credentials (`AWS_ACCESS_KEY_ID`, GCP `.json` service account keys) from CI secrets.
   - Authenticate runners directly to AWS, GCP, or Azure using OpenID Connect (OIDC) federated trust with temporary JWT tokens:
     ```yaml
     permissions:
       id-token: write
       contents: read
     ```

2. **Immutable Action Commit Pinning**:
   - Pin third-party CI actions to full 40-character commit SHAs rather than mutable version tags (`v3`, `v4`):
     ```yaml
     uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
     ```
   - Automated dependabot / renovate updates should upgrade the pinned SHA while updating the trailing version comment.

3. **Artifact Integrity & SLSA Provenance**:
   - Sign container images and binary release artifacts using Sigstore/Cosign.
   - Generate cryptographic software bills of materials (SBOM) via Syft or Trivy during the build step.

4. **Secret Scanning & PR Isolation**:
   - Run automated secret scanning tools (TruffleHog, Gitleaks) on every pull request to catch hardcoded tokens before merge.
   - Never run untrusted fork PRs with elevated repository secret permissions (`pull_request_target` anti-pattern).
