---
name: azure-cloud-architect
description: "Microsoft Azure architecture: Azure Container Apps, AKS, Azure Functions, Entra ID (Azure AD) Managed Identities, Key Vault, Service Bus, and Bicep/Terraform IaC. Use when designing or deploying on Microsoft Azure."
---

# Azure Cloud Architecture Standards

Engineering standards for cloud-native workloads, identity governance, and enterprise architectures on Microsoft Azure.

## Core Rules

1. **Identity & Managed Identities**:
   - Enforce Azure Entra ID (Azure AD) Managed Identities (System-Assigned or User-Assigned) for all compute resources (Container Apps, AKS, VMs, Functions).
   - Zero hardcoded connection strings: access Azure SQL, Storage, and Service Bus via Managed Identity tokens.

2. **Container & Application Hosting**:
   - Prefer Azure Container Apps (ACA) for serverless microservices with built-in KEDA scaling, Dapr integration, and ingress routing.
   - For complex multi-tenant orchestration or low-level network topologies, deploy on Azure Kubernetes Service (AKS).

3. **Secrets & Configuration**:
   - Store all credentials, certificates, and encryption keys in Azure Key Vault.
   - Protect Key Vault access via Azure RBAC rather than legacy access policies.
   - Inject Key Vault secrets into Container Apps using secret references mapped to Managed Identities.

4. **Messaging & Reliable Integration**:
   - Use Azure Service Bus (Standard/Premium) for reliable message queuing, duplicate detection, and FIFO ordering.
   - Configure dead-letter sub-queues on all subscription topics.
