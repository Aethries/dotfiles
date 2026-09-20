# AI Skills Ecosystem Curation & Discovery Audit (Phase 25)

Comprehensive audit log of discovery runs, metadata overlap scoring, and AI semantic review decisions across 13 essential modern tech stacks.

---

## 1. Curation Philosophy & Evaluation Workflow

Every candidate skill evaluated from external sources (`official-vendor`, `anthropic-skills`, `skills-sh`, `agentic-awesome-skills`, `github-search`) undergoes the standardized triage process:

1. **Local Coverage Verification**: Query local canonical library first via registry. If covered, favor reuse over external bloat.
2. **External Discovery**: Query trusted providers in strict priority order. When unauthenticated or without local test fixtures, discovery outputs honest AI-assisted research guidance rather than fabricating synthetic repositories.
3. **Upstream Disambiguation & Verification**: Validate repository reachability, commit revision, skill subpath, and `SKILL.md` frontmatter before presenting candidates.
4. **Security & Sandbox Audit**: Zero-tolerance scanning for reverse shells, prompt injections, arbitrary pipe executions, and unvetted telemetry.
5. **Metadata Overlap Detection**: Symmetric weighted evaluation across capabilities (40%), triggers (30%), domain (10%), and word tokens (20%):
   - `< 0.40`: Disjoint capabilities (`KEEP_BOTH` / `CREATE`).
   - `0.40 - 0.69`: `review_candidate`.
   - `>= 0.70`: `strong_review_candidate`.
6. **Heuristic & Semantic Review**: Evaluate functional boundaries to establish concrete action:
   - `KEEP_BOTH` -> `CREATE` (orthogonal, distinct scope)
   - `PARTIAL_OVERLAP` -> `COMPANION` (specialized complementary workflow)
   - `DUPLICATE` -> `REUSE` (reject external duplicate, use canonical skill)
   - `SUPERSEDES` -> `REPLACE` (vendor-first advancement)

---

## 2. Tech Stack Curation Matrix

| Technology | Discovery Query | Discovered Candidate | Upstream URL | Local Overlap Match | Overlap Score | Decision | Action | Final Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Next.js** | `nextjs` | `nextjs-runtime-debugging` *(fixture)* | `https://github.com/vercel/next.js` (`skills/nextjs-runtime-debugging`) | `pixel-perfect-ui` | `0.10` | `PARTIAL_OVERLAP` | `COMPANION` | Adopt as companion for App Router SSR/hydration debugging |
| **React** | `react` | *No verified candidate found* | — | `pixel-perfect-ui` | `0.00` | `DUPLICATE` | `REUSE` | KEEP LOCAL `pixel-perfect-ui`; covers styling, components & UX |
| **NestJS** | `nestjs` | `nestjs-database-transaction-best-practices` *(fixture)* | `https://github.com/sickn33/agentic-awesome-skills` (`skills/backend/...`) | `nestjs` | `0.92` | `DUPLICATE` | `REUSE` | Reject candidate; canonical `nestjs` covers DI, modules & transactions |
| **PostgreSQL** | `postgresql` | *No verified candidate found* | — | `postgresql` | `0.00` | `DUPLICATE` | `REUSE` | KEEP LOCAL `postgresql`; covers indexing, queries & PgBouncer |
| **Docker** | `docker` | *No verified candidate found* | — | `docker` | `0.00` | `DUPLICATE` | `REUSE` | KEEP LOCAL `docker`; covers multi-stage builds, rootless & compose |
| **Kubernetes** | `kubernetes` | *No verified candidate found* | — | `cloud-infra` | `0.00` | `PARTIAL_OVERLAP` | `COMPANION` | KEEP LOCAL `cloud-infra`; author tailored skill if cluster orchestration needed |
| **GitHub Actions** | `github-actions` | `github-actions` *(verified)* | `https://github.com/anthropics/skills` (`skills/github-actions`) | None | `0.00` | `KEEP_BOTH` | `CREATE` | High-value candidate from Anthropic official; approved for CI/CD workflows |
| **Cloudflare** | `cloudflare` | *No verified candidate found* | — | `cloud-infra` | `0.00` | `PARTIAL_OVERLAP` | `COMPANION` | KEEP LOCAL `cloud-infra`; covers Workers & edge patterns |
| **AWS** | `aws` | *No verified candidate found* | — | `cloud-infra` | `0.00` | `PARTIAL_OVERLAP` | `COMPANION` | KEEP LOCAL `cloud-infra`; covers multi-cloud patterns |
| **GCP** | `gcp` | *No verified candidate found* | — | `cloud-infra` | `0.00` | `PARTIAL_OVERLAP` | `COMPANION` | KEEP LOCAL `cloud-infra`; covers GCP & serverless patterns |
| **Azure** | `azure` | *No verified candidate found* | — | `cloud-infra` | `0.00` | `PARTIAL_OVERLAP` | `COMPANION` | KEEP LOCAL `cloud-infra`; covers cloud infrastructure patterns |
| **OAuth / OIDC** | `oauth` | *No verified candidate found* | — | `security-guardrails` | `0.00` | `DUPLICATE` | `REUSE` | KEEP LOCAL `security-guardrails`; covers auth boundaries & tokens |
| **Prisma** | `prisma` | `prisma-transactions` *(fixture)* | `https://github.com/prisma/prisma` (`skills/prisma-transactions`) | `postgresql` | `0.05` | `KEEP_BOTH` | `CREATE` | ORM transaction skill; complementary to canonical `postgresql` |

---

## 3. Deep-Dive Evaluations

### 3.1 Next.js vs Local Frontend
- **Query**: `ai-skills discover nextjs` (fixture-enabled)
- **Discovered**: `nextjs-runtime-debugging` via `skills-sh` test fixture (`https://github.com/vercel/next.js`, path: `skills/nextjs-runtime-debugging`).
- **Overlap**: Heuristic similarity `0.10` with `pixel-perfect-ui`. Signals: `shared_name_tokens: debugging`.
- **Semantic Review**: `pixel-perfect-ui` focuses on visual fidelity, loading skeletons, responsive layouts, and CSS tokens. `nextjs-runtime-debugging` focuses exclusively on Next.js Server Components, hydration boundary mismatches, and App Router caching.
- **Decision**: `PARTIAL_OVERLAP` -> `COMPANION`.

### 3.2 NestJS External Transactions vs Canonical NestJS
- **Query**: `ai-skills discover nestjs` (fixture-enabled)
- **Discovered**: `nestjs-database-transaction-best-practices` via `agentic-awesome-skills` test fixture.
- **Overlap**: Heuristic similarity `0.92` with canonical `resources/skills/nestjs`. Signals: `shared_name_tokens: nestjs`, `high_token_overlap: 92%`.
- **Semantic Review**: Both skills address `@Injectable()` service layer transaction boundaries, rollback interceptors, and query runners.
- **Decision**: `DUPLICATE` -> `REUSE`.
- **Action**: Reject external bundle; use existing canonical `nestjs` skill.

### 3.3 Prisma Transactions vs Canonical PostgreSQL
- **Query**: `ai-skills discover prisma` (fixture-enabled)
- **Discovered**: `prisma-transactions` via `official-vendor` test fixture.
- **Overlap**: Heuristic similarity `0.05` with canonical `resources/skills/postgresql`. Signals: none.
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
