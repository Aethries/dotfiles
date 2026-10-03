---
name: helm-chart-architect
description: "Production Helm v3 chart engineering: template authoring, values.schema.json validation, umbrella chart composition, subchart dependency overrides, lifecycle hooks, and chart release versioning. Use when packaging cloud-native applications for Kubernetes."
---

# Production Helm v3 Chart Engineering

Standards for creating robust, reusable, and validated Helm packages for Kubernetes infrastructure and workloads.

## Core Rules

1. **Schema Validation (`values.schema.json`)**:
   - Every production chart must include a `values.schema.json` to enforce strict type checking and required parameters at install/upgrade time:
     ```bash
     helm lint ./my-chart
     ```
   - Prevent deployment crashes caused by missing keys or malformed configurations.

2. **Template Hygiene & Helpers**:
   - Centralize resource naming, labels, and selector logic inside `templates/_helpers.tpl`.
   - Adhere to standard Kubernetes recommended labels (`app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by: Helm`).
   - Use `{{- with .Values.resources }} resources: {{- toYaml . | nindent 10 }} {{- end }}` to pass standard resource specifications cleanly.

3. **Umbrella & Subchart Composition**:
   - Structure complex distributed applications as an umbrella chart with subcharts declared in `Chart.yaml` dependencies.
   - Override subchart configurations cleanly from root `values.yaml` using the subchart name as key.

4. **Lifecycle Hooks & Migrations**:
   - Execute pre-deployment database migrations or schema adjustments via Helm hooks (`helm.sh/hook: pre-install,pre-upgrade`).
   - Configure hook deletion policies (`helm.sh/hook-delete-policy: hook-succeeded,before-hook-creation`) to clean up completed batch jobs.
