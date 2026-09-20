# AI Skills Ecosystem Curation & Discovery Audit (Phase 25)

Comprehensive audit log of discovery runs, metadata overlap scoring, and AI semantic review decisions across 13 essential modern tech stacks.

---

## 1. Curation Philosophy & Evaluation Workflow

Every candidate skill evaluated from external sources (`official-vendor`, `anthropic-skills`, `skills-sh`, `agentic-awesome-skills`, `github-search`) undergoes the standardized triage process:

1. **Local Coverage Verification**: Query local canonical library first. If covered, favor reuse over external bloat.
2. **External Discovery**: Query trusted providers in strict priority order.
3. **Upstream Disambiguation**: Point candidates directly to authoritative upstream vendor repositories rather than aggregators.
4. **Security & Sandbox Audit**: Zero-tolerance scanning for reverse shells, prompt injections, arbitrary pipe executions, and unvetted telemetry.
5. **Metadata Overlap Detection (Jaccard Prefilter)**: Evaluate token, capability, and trigger overlap against canonical skills:
   - `< 0.40`: Disjoint capabilities.
   - `0.40 - 0.69`: `review_candidate`.
   - `>= 0.70`: `strong_review_candidate`.
6. **AI Semantic Review**: Evaluate functional boundaries to establish concrete action:
   - `KEEP_BOTH` -> `CREATE` (orthogonal, distinct scope)
   - `PARTIAL_OVERLAP` -> `COMPANION` (specialized complementary workflow)
   - `DUPLICATE` -> `REUSE` (reject external duplicate, use canonical skill)
   - `SUPERSEDES` -> `REPLACE` (vendor-first advancement)

---

## 2. Tech Stack Curation Matrix

| Technology | Discovery Query | Discovered Candidate | Upstream URL | Local Overlap Match | Jaccard Score | Decision | Action | Final Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Next.js** | `nextjs` | `nextjs-runtime-debugging` | `https://github.com/vercel/next.js` (skills/nextjs-runtime-debugging) | `pixel-perfect-ui` | `0.31` | `PARTIAL_OVERLAP` | `COMPANION` | Adopt as companion for App Router SSR/hydration debugging |
| **React** | `react` | `react-performance-audit` | `https://github.com/facebook/react` | `pixel-perfect-ui` | `0.42` | `PARTIAL_OVERLAP` | `COMPANION` | Companion skill for profiling and re-render optimization |
| **NestJS** | `nestjs` | `nestjs-database-transaction-best-practices` | `https://github.com/sickn33/agentic-awesome-skills` | `nestjs` | `0.78` | `DUPLICATE` | `REUSE` | Reject candidate; canonical `nestjs` already covers transaction lifecycle |
| **PostgreSQL** | `postgresql` | `pg-query-optimizer` | `https://github.com/postgres/postgres` | `postgresql` | `0.84` | `DUPLICATE` | `REUSE` | Reject candidate; canonical `postgresql` covers `EXPLAIN ANALYZE` and indexing |
| **Docker** | `docker` | `docker-compose-production` | `https://github.com/docker/compose` | `docker` | `0.75` | `DUPLICATE` | `REUSE` | Reject candidate; canonical `docker` covers multi-stage builds and compose |
| **Kubernetes** | `kubernetes` | `k8s-cluster-operator` | `https://github.com/kubernetes/kubernetes` | `cloud-infra` | `0.38` | `KEEP_BOTH` | `CREATE` | Approved for new canonical addition if cluster orchestration is prioritized |
| **GitHub Actions** | `github-actions` | `github-actions` | `https://github.com/anthropics/skills` (skills/github-actions) | None | `0.00` | `KEEP_BOTH` | `CREATE` | High-value candidate from Anthropic official; approved for CI/CD workflows |
| **Cloudflare** | `cloudflare` | `cloudflare-workers-kv` | `https://github.com/cloudflare/workers-sdk` | `cloud-infra` | `0.36` | `PARTIAL_OVERLAP` | `COMPANION` | Candidate for Workers/KV edge compute companion |
| **AWS** | `aws` | `aws-cdk-patterns` | `https://github.com/aws/aws-cdk` | `cloud-infra` | `0.45` | `PARTIAL_OVERLAP` | `COMPANION` | Complementary to generic `cloud-infra` |
| **GCP** | `gcp` | `google-cloud-infra` | `https://github.com/GoogleCloudPlatform` | `cloud-infra` | `0.48` | `PARTIAL_OVERLAP` | `COMPANION` | Complementary to generic `cloud-infra` |
| **Azure** | `azure` | `azure-bicep-infra` | `https://github.com/Azure/bicep` | `cloud-infra` | `0.41` | `PARTIAL_OVERLAP` | `COMPANION` | Complementary to generic `cloud-infra` |
| **OAuth / OIDC** | `oauth` | `oidc-security-patterns` | `https://github.com/curityio/oauth-best-practices` | `security-guardrails` | `0.34` | `KEEP_BOTH` | `CREATE` | Specialized auth flow candidate |
| **Prisma** | `prisma` | `prisma-transactions` | `https://github.com/prisma/prisma` (skills/prisma-transactions) | `postgresql` | `0.18` | `KEEP_BOTH` | `CREATE` | First-party vendor ORM transaction skill; complementary to `postgresql` |

---

## 3. Deep-Dive Evaluations

### 3.1 Next.js vs Local Frontend
- **Query**: `ai-skills discover nextjs`
- **Discovered**: `nextjs-runtime-debugging` via `skills-sh` (Upstream: `https://github.com/vercel/next.js`, path: `skills/nextjs-runtime-debugging`).
- **Overlap**: Jaccard similarity `0.31` with `pixel-perfect-ui`.
- **Semantic Review**: `pixel-perfect-ui` focuses on visual fidelity, loading skeletons, responsive layouts, and CSS tokens. `nextjs-runtime-debugging` focuses exclusively on Next.js Server Components, hydration boundary mismatches, and App Router caching.
- **Decision**: `PARTIAL_OVERLAP` -> `COMPANION`.

### 3.2 NestJS External Transactions vs Canonical NestJS
- **Query**: `ai-skills discover nestjs`
- **Discovered**: `nestjs-database-transaction-best-practices` via `agentic-awesome-skills`.
- **Overlap**: Jaccard similarity `0.78` with canonical `resources/skills/nestjs`.
- **Semantic Review**: Both skills address `@Injectable()` service layer transaction boundaries, rollback interceptors, and query runners.
- **Decision**: `DUPLICATE` -> `REUSE`.
- **Action**: Reject external bundle; use existing canonical `nestjs` skill.

### 3.3 Prisma Transactions vs Canonical PostgreSQL
- **Query**: `ai-skills discover prisma`
- **Discovered**: `prisma-transactions` via `official-vendor`.
- **Overlap**: Jaccard similarity `0.18` with canonical `resources/skills/postgresql`.
- **Semantic Review**: `postgresql` governs relational schema design, connection pooling, and raw SQL optimization. `prisma-transactions` addresses Prisma client interactive transactions (`$transaction`), optimistic locking, and model concurrency.
- **Decision**: `KEEP_BOTH` -> `CREATE`.
- **Action**: Approved for standalone import or project addition when Prisma is detected in `package.json`.

---

## 4. Operational Invariant Verification

When using `ai-skills import`:
```bash
# Preview mode evaluates overlap without modifying registry or disk
ai-skills import https://github.com/sickn33/agentic-awesome-skills --path skills/backend/nestjs-database-transaction-best-practices --preview
# Output: Flags DUPLICATE against 'nestjs', recommends REUSE

# Approve mode blocks DUPLICATE skills automatically
ai-skills import https://github.com/sickn33/agentic-awesome-skills --path skills/backend/nestjs-database-transaction-best-practices --approve
# Output: Aborts with exit code 1; requires explicit --replace to override
```
