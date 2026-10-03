---
name: cloud-infra
description: "Cloud infrastructure design, Terraform/OpenTofu, serverless architectures, and multi-cloud patterns across AWS, GCP, and Cloudflare. Use when designing cloud infrastructure, edge workers, or IaC modules."
---

# Cloud Infrastructure & Infrastructure-as-Code

Engineering patterns for declarative cloud provisioning, edge computing, and serverless architectures across AWS, GCP, and Cloudflare.

## Core Rules

1. **Infrastructure as Code (IaC) First**:
   - Every production cloud resource must be provisioned declaratively via Terraform / OpenTofu or Nix.
   - Prohibit manual console clicks ("ClickOps") for stateful or production resources.
   - Use remote state with state locking (e.g. S3 + DynamoDB or GCS).
2. **Principle of Least Privilege (IAM)**:
   - Grant minimal required permissions to service accounts and IAM roles.
   - Avoid wildcard permissions (`*`). Scope policies down to specific resource ARNs.
   - Use short-lived credentials (OIDC federation for CI/CD like GitHub Actions) instead of long-lived static API keys.
3. **Edge & Serverless Optimization**:
   - Utilize Cloudflare Workers / Pages for edge routing, caching, and low-latency API proxying.
   - Keep cold starts low: minimize bundled dependency footprint; prefer native Web standard APIs (`fetch`, `Request`, `Response`).
4. **Networking & VPC Topology**:
   - Database and internal storage resources must reside strictly within private subnets with zero public IP exposure.
   - Direct inbound traffic through API Gateways or load balancers with WAF rules enabled.
