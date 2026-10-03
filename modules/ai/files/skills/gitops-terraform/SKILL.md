---
name: gitops-terraform
description: "GitOps & Terraform / OpenTofu infrastructure as code: state locking, remote S3/GCS backends, module composition, drift detection, and ArgoCD declarative synchronization. Use when provisioning infrastructure or implementing GitOps pipelines."
---

# GitOps & Terraform Infrastructure Standards

Standards for declarative, drift-free Infrastructure as Code (IaC) using Terraform / OpenTofu and GitOps workflows.

## Core Rules

1. **Remote State & Locking Invariants**:
   - Never store state locally or commit `.tfstate` files to version control.
   - Use encrypted remote backends (S3 with DynamoDB state locking, or GCS with object locking).
   - Isolate environments via dedicated state files or separate workspaces (`env/prod`, `env/staging`).

2. **Module Composition & Interface Design**:
   - Adhere to the standard module structure: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.
   - Explicitly define type constraints and descriptions on all input variables.
   - Pin required provider versions strictly in `versions.tf`.

3. **Drift Detection & Plan Hygiene**:
   - Always run and inspect `terraform plan -out=tfplan` before applying changes.
   - Ban interactive `terraform apply` in production; apply exclusively via automated CI/CD pipelines against approved plan artifacts.
   - Schedule recurring drift detection plans to detect manual console modifications.

4. **GitOps & ArgoCD Synchronization**:
   - For Kubernetes clusters, maintain Git as the single source of truth for desired state.
   - Use automated sync with automated pruning and self-healing in ArgoCD to immediately revert out-of-band cluster drift.
