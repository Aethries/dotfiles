# AI Skills Ecosystem Curation & Discovery Audit

Comprehensive audit log of external discovery runs, candidate verification, and curation triage across 13 essential modern tech stacks.

---

## 1. Curation Philosophy & Evaluation Workflow

Every candidate evaluated from external sources (`official-vendor`, `anthropic-skills`, `skills-sh`, `agentic-awesome-skills`, `github-search`) undergoes the standardized triage process:

1. **Local Coverage Verification**: Query local canonical library first via registry. If covered, favor reuse over external bloat.
2. **External Discovery**: Query trusted providers in strict priority order. When unauthenticated or without local test fixtures, discovery outputs honest AI-assisted research guidance rather than fabricating synthetic repositories.
3. **Upstream Disambiguation & Verification**: Validate repository reachability, commit revision, skill subpath, and `SKILL.md` frontmatter before presenting candidates.
4. **Security & Sandbox Audit**: Zero-tolerance scanning for reverse shells, prompt injections, arbitrary pipe executions, and unvetted telemetry.
5. **Metadata Overlap Detection**: Symmetric weighted evaluation across capabilities (40%), triggers (30%), domain (10%), and word tokens (20%):
   - `< 0.40`: Disjoint capabilities (`KEEP_BOTH` / `CREATE`).
   - `0.40 - 0.69`: `review_candidate`.
   - `>= 0.70`: `strong_review_candidate`.
6. **Heuristic & Semantic Review Separation**:
   - **Heuristic Review**: Non-authoritative token and trigger comparison. Emits `heuristic_decision`, `heuristic_action`, `similarity_score`, `signals`, and `reason`. Never emits binding decisions.
   - **Semantic Review**: Model-level functional boundary comparison. Required for approving overlapping external candidates into the canonical library. Emits `decision` (`KEEP_BOTH`, `PARTIAL_OVERLAP`, `DUPLICATE`, `SUPERSEDES`, `CONFLICT`), `recommended_action` (`REUSE`, `COMPANION`, `CREATE`, `REPLACE`), `reason`, and `evidence`.

---

## Section A: Verified Real-World Curation Audit

> [!NOTE]
> All entries in Section A represent actual real-world upstream verification performed against live git sources. Where upstream vendors do not publish structured `SKILL.md` bundles, this is factually recorded as *No verified candidate found*, and existing local dotfiles skills are retained.

| Technology | Discovery Query | Discovered Candidate | Upstream URL | Local Canonical Match | Heuristic / Overlap | Recommended Action | Final Determination |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Next.js** | `nextjs` | *No verified candidate found* | — | `pixel-perfect-ui` | None | `REUSE` | KEEP LOCAL `pixel-perfect-ui`; covers styling, components & UX. Author specialized runtime debugging skill when needed. |
| **React** | `react` | *No verified candidate found* | — | `pixel-perfect-ui` | None | `REUSE` | KEEP LOCAL `pixel-perfect-ui`; covers design systems, responsive layouts & component state. |
| **NestJS** | `nestjs` | *No verified candidate found* | — | `nestjs` | None | `REUSE` | KEEP LOCAL `nestjs`; comprehensive canonical skill covers DI, controllers, modules, transactions & interceptors. |
| **PostgreSQL** | `postgresql` | *No verified candidate found* | — | `postgresql` | None | `REUSE` | KEEP LOCAL `postgresql`; covers indexing, queries, connection pooling & PgBouncer. |
| **Docker** | `docker` | *No verified candidate found* | — | `docker` | None | `REUSE` | KEEP LOCAL `docker`; covers multi-stage builds, rootless containers & docker-compose architectures. |
| **Kubernetes** | `kubernetes` | *No verified candidate found* | — | `cloud-infra` | None | `COMPANION` | KEEP LOCAL `cloud-infra`; covers container orchestration, cloud services & Terraform modules. |
| **GitHub Actions** | `github-actions` | *No verified candidate found* | — | `engineering-review` / `cloud-infra` | None | `REUSE` | KEEP LOCAL `engineering-review` & `cloud-infra`; Anthropic official repository (`anthropics/skills`) does not host a GitHub Actions skill bundle. |
| **Cloudflare** | `cloudflare` | *No verified candidate found* | — | `cloud-infra` | None | `COMPANION` | KEEP LOCAL `cloud-infra`; covers Cloudflare Workers, DNS & edge infrastructure. |
| **AWS** | `aws` | *No verified candidate found* | — | `cloud-infra` | None | `COMPANION` | KEEP LOCAL `cloud-infra`; covers AWS serverless, IAM & multi-cloud architecture. |
| **GCP** | `gcp` | *No verified candidate found* | — | `cloud-infra` | None | `COMPANION` | KEEP LOCAL `cloud-infra`; covers GCP services, Cloud Run & IAM patterns. |
| **Azure** | `azure` | *No verified candidate found* | — | `cloud-infra` | None | `COMPANION` | KEEP LOCAL `cloud-infra`; covers Azure infrastructure & deployment patterns. |
| **OAuth / OIDC** | `oauth` | *No verified candidate found* | — | `security-guardrails` | None | `REUSE` | KEEP LOCAL `security-guardrails`; covers authorization boundaries, secret safety & token validation. |
| **Prisma** | `prisma` | *No verified candidate found* | — | `postgresql` / `data-model-architect` | None | `COMPANION` | KEEP LOCAL canonical database skills; author dedicated Prisma ORM companion skill if client transactions required. |

---

## Section B: Test Fixture Validation (FOR TESTING ONLY)

> [!IMPORTANT]
> **NOT REAL UPSTREAM EVIDENCE — FOR CLI PIPELINE TEST COVERAGE ONLY.**
> The candidates, paths, and scores below are synthetic fixtures stored under `tests/ai/fixtures/` and are used exclusively to exercise the candidate verification filter, multi-overlap detection, heuristic scoring, security audit, and semantic review import gate.

### B.1 Fixture Evaluation Matrix

| Tech Scenario | Fixture Query | Fixture Candidate | Mock Upstream URL | Colliding Canonical Skill | Heuristic Similarity | Heuristic Action | Mock Semantic Review Decision |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Next.js Debugging** | `nextjs` | `nextjs-runtime-debugging` | `tests/ai/fixtures/semantic/nextjs-runtime-debugging` | `pixel-perfect-ui` | `0.10` | `COMPANION` | `PARTIAL_OVERLAP` -> `COMPANION` |
| **NestJS Transactions** | `nestjs` | `nestjs-database-transaction-best-practices` | `tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices` | `nestjs` | `0.92` | `REUSE` | `DUPLICATE` -> `REUSE` (blocks approve without `--replace`) |
| **Prisma Transactions** | `prisma` | `prisma-transactions` | `tests/ai/fixtures/semantic/prisma-transactions` | `postgresql` | `0.05` | `CREATE` | `KEEP_BOTH` -> `CREATE` |
| **Browser Automation** | `browser` | `browser-debugging` | `tests/ai/fixtures/semantic/browser-debugging` | `pixel-perfect-ui` | `0.12` | `COMPANION` | `PARTIAL_OVERLAP` -> `COMPANION` |

### B.2 Fixture Deep-Dives

#### 1. Next.js Runtime Debugging vs Canonical Frontend
- **Fixture Path**: `tests/ai/fixtures/semantic/nextjs-runtime-debugging/SKILL.md`
- **Heuristic Overlap**: Similarity `0.10` with `pixel-perfect-ui`. Signals: `shared_name_tokens: debugging`.
- **Semantic Review**: `pixel-perfect-ui` addresses visual styling, loading skeletons, and responsive components. `nextjs-runtime-debugging` specifically targets React Server Components (RSC) payload streaming, hydration boundaries, and App Router caching.
- **Outcome**: `PARTIAL_OVERLAP` -> `COMPANION`.

#### 2. NestJS Database Transactions vs Canonical NestJS
- **Fixture Path**: `tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices/SKILL.md`
- **Heuristic Overlap**: Similarity `0.92` with canonical `resources/skills/nestjs`. Signals: `shared_name_tokens: nestjs`, `high_token_overlap: 92%`.
- **Semantic Review**: Candidate duplicates the existing `@Injectable()` service layer transaction boundaries, rollback interceptors, and query runners already established in `nestjs`.
- **Outcome**: `DUPLICATE` -> `REUSE`. Reject external bundle; use existing canonical `nestjs` skill.

#### 3. Prisma Transactions vs Canonical PostgreSQL
- **Fixture Path**: `tests/ai/fixtures/semantic/prisma-transactions/SKILL.md`
- **Heuristic Overlap**: Similarity `0.05` with canonical `resources/skills/postgresql`. Signals: none.
- **Semantic Review**: `postgresql` governs relational schema design, connection pooling, and raw SQL optimization. `prisma-transactions` addresses Prisma client interactive transactions (`$transaction`), optimistic locking, and model concurrency.
- **Outcome**: `KEEP_BOTH` -> `CREATE`.

---

## 3. Operational Safety & Import Invariants

```bash
# 1. Preview mode evaluates heuristic overlap without modifying registry or disk
ai-skills import tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices --preview
# Output: Flags semantic review as REQUIRED for every overlapping canonical skill

# 2. Approve mode enforces the semantic review gate
ai-skills import tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices --approve
# Output: Aborts with exit code 1:
# "Import cannot be approved. Semantic review is required because this candidate overlaps existing skills."

# 3. Supplying completed semantic reviews for every overlap target permits approval
SEMANTIC_REVIEW_JSON='[
  {"review_type":"semantic","status":"completed","candidate":"nestjs-database-transaction-best-practices","existing":"nestjs","decision":"DUPLICATE","recommended_action":"REUSE","reason":"Duplicates canonical nestjs"},
  {"review_type":"semantic","status":"completed","candidate":"nestjs-database-transaction-best-practices","existing":"nestjs-cqrs-microservices","decision":"KEEP_BOTH","recommended_action":"CREATE","reason":"Distinct companion workflow"},
  {"review_type":"semantic","status":"completed","candidate":"nestjs-database-transaction-best-practices","existing":"database-query-optimizer","decision":"KEEP_BOTH","recommended_action":"CREATE","reason":"Distinct companion workflow"}
]' \
ai-skills import tests/ai/fixtures/semantic/nestjs-database-transaction-best-practices --approve --replace
```
