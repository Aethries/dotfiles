---
name: gcp-cloud-architect
description: "Google Cloud Platform architecture: Cloud Run serverless containers, Workload Identity federation, Cloud Pub/Sub, Cloud Storage, BigQuery, VPC Service Controls, and IAM least privilege. Use when designing or deploying on GCP."
---

# Google Cloud Platform Architecture Standards

Standards for building secure, scalable, and idiomatic applications on Google Cloud Platform.

## Core Rules

1. **Identity & Authentication**:
   - Strictly use Workload Identity Federation for GKE, Cloud Run, and GitHub Actions; eliminate service account key downloads (`.json` keys).
   - Assign granular predefined IAM roles or custom roles rather than primitive roles (`Owner`, `Editor`, `Viewer`).

2. **Serverless & Microservices**:
   - Prefer Cloud Run for containerized web services, APIs, and background queue workers.
   - Configure CPU allocation: use "CPU always allocated" for background processing/WebSockets; use "CPU allocated during request processing" for stateless REST APIs.
   - Enforce execution under a dedicated, low-privilege service account per Cloud Run service.

3. **Messaging & Asynchronous Streams**:
   - Use Cloud Pub/Sub for high-throughput messaging. Configure pull subscriptions with exponential backoff and dead-letter topics.
   - Separate telemetry streams from business domain events.

4. **Storage & Data Management**:
   - Enforce Uniform Bucket-Level Access and Public Access Prevention on all Google Cloud Storage (GCS) buckets.
   - Store application secrets exclusively in Google Secret Manager; access via IAM roles at container initialization.
