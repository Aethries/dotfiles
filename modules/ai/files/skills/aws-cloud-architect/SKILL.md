---
name: aws-cloud-architect
description: "AWS cloud architecture & serverless patterns: IAM least privilege, ECS/Fargate, Lambda, S3 security & lifecycle, EventBridge, DynamoDB single-table design, and AWS CDK/Terraform infrastructure. Use when designing or deploying on AWS."
---

# AWS Cloud Architecture Standards

Engineering standards for secure, scalable, and cost-effective cloud infrastructures on Amazon Web Services.

## Core Rules

1. **IAM & Security Isolation**:
   - Enforce least-privilege permissions: explicitly define actions and resources; never grant wildcards (`*`) on production roles.
   - Use IAM Roles and temporary STS credentials for application workloads; ban long-lived access keys.
   - Secure S3 buckets by default: enable Block Public Access, SSE-S3/KMS encryption, versioning, and SSL-only bucket policies (`aws:SecureTransport`).

2. **Compute & Serverless**:
   - For containerized workloads, prefer AWS ECS with Fargate for zero-management container execution.
   - For event-driven compute, use AWS Lambda with arm64 (Graviton) architecture for cost/performance optimization.
   - Configure Lambda provisioned concurrency or keep initialization handlers outside the main invocation handler to minimize cold starts.

3. **Event-Driven & Async Pipelines**:
   - Use Amazon EventBridge as the central event bus for cross-account or cross-service domain events.
   - Place Amazon SQS queues before compute consumers to buffer bursts and prevent downstream throttling.
   - Always attach Dead Letter Queues (DLQ) with alarm metrics to all asynchronous SNS/SQS/Lambda pipelines.

4. **Storage & DynamoDB**:
   - For NoSQL requirements, apply DynamoDB single-table design using partition keys (PK) and sort keys (SK) aligned strictly to access patterns.
