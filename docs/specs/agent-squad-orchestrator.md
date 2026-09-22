# Feature Specification: Agent Squad Orchestrator

**Status:** Draft  
**Author:** Codex  
**Target Path:** `docs/specs/agent-squad-orchestrator.md`  
**Canonical Skill:** `resources/skills/agent-squad-orchestrator/SKILL.md`

---

## 1. Context & Problem Statement

Current AI CLI/IDE clients across dotfiles utilize disparate agent invocation mechanisms and gateways. When a task requires planning, code modification, testing, and review, users must manually select models, assign roles, and aggregate evidence. This introduces significant risks: leaders burn context on raw command execution, coders self-certify instead of relying on QA, or previews are delivered without verified test evidence.

`agent-squad-orchestrator` is an Agent Skill that standardizes a multi-role squad across **Codex CLI**, **Antigravity CLI/IDE**, and **Claude Code CLI**. The skill establishes an evidence-based handoff workflow, clear model tiering, and cross-provider agent invocation via subprocesses or local gateways.

The skill must serve as a canonical skill in dotfiles and belong to the `global-core` profile, allowing `scripts/ai-skills.sh sync --profile global-core` to automatically create and update global symlinks for all supported clients, without requiring users to manually add the skill to individual consumer repositories.

## 2. Goals & Non-Goals

### Goals

- Provide a skill named exactly `agent-squad-orchestrator`, consistently discoverable across the three target CLI/IDE clients.
- Standardize five distinct roles: PM/Leader, BA/Architect, Coder/Dev, Tester/QA, and Reviewer/Gatekeeper.
- Enforce strict separation of duties: leadership roles handle planning, orchestration, and communication exclusively; file editing, command execution, and log collection are reserved for worker roles.
- Standardize a five-step lifecycle: BA specification, Coder diff, Tester evidence, Reviewer verification, and Leader preview to the user.
- Define supported cross-provider invocation routes: `codex exec`, `invoke_subagent`, OmniRoute, and 9Router.
- Enable reviewers to issue auditable decisions grounded in acceptance criteria, git diffs, and test evidence.
- Package and register the skill so that the `global-core` profile syncs it without repository-level configuration.

### Non-Goals

- Do not implement a new background daemon, job queue, dashboard, or orchestration service.
- Do not replace native client mechanisms for spawning agents; the skill only standardizes role allocation decisions and handoff contracts.
- Do not auto-grant destructive execution permissions, publishing, deployment, merging, or secret access to any agent.
- Do not guarantee unconditional model or provider availability; route selection must support graceful fallback or clear blocker reporting.
- Do not permit the Leader to modify files directly or substitute unverified conversational assertions for QA/Reviewer certification.

## 3. Actors & Permissions

| Actor / Role | Purpose | Allowed | Prohibited |
| :--- | :--- | :--- | :--- |
| User | Defines goals and approves changes when required | Provide requirements, scope, permissions, and feedback on previews | Being assumed to have approved out-of-scope actions |
| PM / Leader (Conductor) | Coordinates the squad and interfaces with the user | Select roles/models, decompose work items, aggregate evidence, deliver previews | Running raw code, editing files directly, fabricating test evidence |
| BA / Architect | Clarifies verifiable requirements | Author specifications, acceptance criteria, risk/edge cases, test matrices | Modifying product code, certifying build/test outcomes |
| Coder / Dev | Implements in-scope changes | Reading/editing files, executing necessary development commands, producing git diffs, reporting handoffs | Self-approving changes or declaring QA Pass |
| Tester / QA | Performs independent verification | Running test/lint/build commands, recording commands, exit codes, logs/evidence, and criterion coverage | Editing code to make tests pass without handing off back to Coder |
| Reviewer / Gatekeeper | Enforces final quality gates | Reviewing diffs/evidence, evaluating against BA criteria, issuing Pass/Reject/Blocked decisions | Bypassing missing evidence, modifying reviewed diffs, sending previews as Leader |
| Provider adapter | Executes calls to selected models/providers | Invoking configured subprocesses/gateways; returning responses and errors | Exposing credentials, unilaterally expanding permissions, or bypassing policies |

## 4. Model Tiering Matrix

Each work item must be assigned to a tier based on responsibilities, not solely on provider. Specific models serve as examples and may adapt based on available configurations; roles and permission boundaries remain immutable.

| Tier | Required Roles | Preferred Model Families | Responsibilities | Context and Operational Constraints |
| :--- | :--- | :--- | :--- | :--- |
| Leadership / High Reasoning | Leader, PM, Supervisor; BA/Architect; Reviewer/Gatekeeper | Terra across reasoning levels, Sol/Astra, Gemini Pro, DeepSeek Pro | Planning, decomposition, risk assessment, authoring AC/test matrices, coordination, review, and user communication | No raw code execution, no direct file edits, no fabrication of execution evidence |
| Execution / Speed | Coder/Dev; Tester/QA | Luna, Gemini Flash, DeepSeek-V non-Pro, or equivalent execution models | Editing code, running commands, collecting logs, generating diffs, running test/lint/build suites | Confined to assigned work items; no final Pass authority or scope expansion |

### Assignment Rules

- The Leader must prioritize the leadership tier for scope, acceptance, review, and preview decisions, even when an execution provider possesses reasoning capabilities.
- Coder and Tester must prioritize the execution tier; different providers may be used to minimize correlated errors when available.
- An agent/turn must never simultaneously serve as both Coder and Reviewer for the same diff.
- If no execution tier is available, the Leader must report `Blocked` or request user authorization for a fallback route; the Leader must not execute changes under the guise of leadership tier.
- When a requested model is unavailable, the adapter must report the actual provider/model used within handoff evidence.

## 5. User Journeys & Flows

### 5.1 Primary happy path: five-step evidence-based workflow

1. Leader receives the user request, verifies scope/permissions, creates work items, and assigns the BA/Architect.
2. BA delivers a `BA Specification Package`: objectives, scope, assumptions, Given/When/Then acceptance criteria, test matrix, risks, and stop conditions.
3. Leader assigns a work item containing the BA package to Coder. Coder implements strictly within the approved scope, then hands off the modified file list, git diff, and executed commands.
4. Leader hands off a copy of the work item, BA package, and Coder handoff to Tester. Tester executes the appropriate test suite/linter/build, documenting exact commands, timestamps, exit codes, and evidence. Exit code `0` is valid only for explicitly recorded commands.
5. Reviewer receives the BA package, Coder diff, and Tester evidence. Reviewer maps every acceptance criterion against evidence and issues `Pass`, `Reject`, or `Blocked`. Only upon `Pass` does the Leader deliver a concise preview for user review/approval of the next step.

### 5.2 Alternative flows

- **Analysis-only tasks:** Leader assigns BA and, if necessary, Reviewer; no Coder/Tester handoff is created. Previews must explicitly state that no file changes or execution evidence exist.
- **Documentation-only tasks:** Coder still delivers a diff; Tester runs applicable validation (e.g., Markdown/link/schema checks) if present in the repository; Reviewer continues to verify against AC.
- **Trivial tasks:** BA may not require a standalone agent, but the Leader must formulate a minimal BA Specification Package prior to execution handoff. Reviewer remains independent from Coder.
- **Multiple independent work items:** Leader may branch across multiple Coders/Testers, but each branch requires distinct evidence and review; integration diffs must be re-verified by QA/Reviewer.

### 5.3 Error and recovery flows

| Scenario | Required Behavior |
| :--- | :--- |
| Subprocess/gateway error or timeout | Record invoked provider, endpoint/command, and redacted error code; attempt authorized fallback or report `Blocked`. Never fabricate agent results. |
| Coder encounters ambiguous scope | Halt modifications on the ambiguous portion, return questions/assumptions to Leader; Leader resolves or queries user if the resolution alters scope. |
| Test/lint/build non-zero exit | Tester reports `Fail` with exact command, exit code, filtered logs, and reproduction steps; Leader reassigns to Coder or informs user. |
| Evidence missing, stale, or mismatched with diff | Reviewer reports `Reject`/`Blocked`; must not be promoted to Pass via Leader summaries. |
| Diff contains out-of-scope changes or secrets | Reviewer reports `Reject`; Leader instructs Coder to isolate/revert out-of-scope portions per user permissions and re-initiate review. |
| No suitable provider available | Leader publicly declares `Blocked` state, attempted providers, and missing permissions/configurations; must not unilaterally relax role constraints. |

## 6. Functional Requirements & Business Rules

### 6.1 Skill identity and availability

- **REQ-1:** The canonical skill directory must be `resources/skills/agent-squad-orchestrator/` with `SKILL.md` as its entrypoint.
- **REQ-2:** Skill metadata must describe its purpose of multi-provider squad orchestration, triggers related to delegation/orchestration, and scope encompassing the three clients: Codex, Antigravity, and Claude Code.
- **REQ-3:** `resources/skills/_registry.json` must contain an entry for `agent-squad-orchestrator` with metadata consistent with the canonical skill.
- **REQ-4:** `resources/skills/_profiles.json` must list `agent-squad-orchestrator` under `profiles.global-core.skills` exactly once.
- **REQ-5:** Upon valid registration, `scripts/ai-skills.sh sync --profile global-core` must process the skill via existing global symlink mechanisms, requiring no manual addition in consumer repositories.

### 6.2 Role contracts and handoffs

- **REQ-6:** Every work item must include an owner role, objective, scope, inputs, expected output, selected provider/model, and status.
- **REQ-7:** Leader must only perform orchestration, planning, aggregation, and communication. Execution commands or filesystem modifications must be delegated to Coder or Tester.
- **REQ-8:** The BA Specification Package must minimally contain: problem/scope, non-goals, assumptions, acceptance criteria, test matrix, and risks/stop conditions.
- **REQ-9:** The Coder handoff must minimally contain: work item ID, modified files, git diff or diff reference, executed commands, outcomes, and limitations/open questions.
- **REQ-10:** The Tester Evidence Package must minimally contain: tested revision/diff, individual commands, working directory (when relevant), exit codes, outcomes, relevant logs/evidence, criterion coverage, and validation limitations.
- **REQ-11:** The Reviewer Decision Package must map each acceptance criterion to specific evidence and conclude with `Pass`, `Reject`, or `Blocked`, including rationale for any non-passing criteria.
- **REQ-12:** The Leader preview must not represent changes as complete or production-ready until Reviewer issues `Pass`. Previews must clearly detail the decision, primary evidence, unexecuted items (if any), and pending user decisions.

### 6.3 Cross-provider invocation

- **REQ-13:** The skill must recognize two invocation route categories: CLI subprocesses and OpenAI-compatible local gateways.
- **REQ-14:** Supported subprocess routes include `codex exec` for OpenAI/Codex and `invoke_subagent` for Google Antigravity/Gemini. Adapters must record commands/methods alongside redacted results or failure telemetry.
- **REQ-15:** The canonical OmniRoute endpoint is `http://127.0.0.1:20129/v1/chat/completions` adhering to the OpenAI Chat Completions API, dedicated to gateway-exposed providers/models such as DeepSeek or Claude.
- **REQ-16:** The canonical 9Router base endpoint is `http://127.0.0.1:20128`, dedicated to the Antigravity multi-OAuth pool. The skill must not assume fixed paths, auth headers, or model catalogs beyond current gateway configuration.
- **REQ-17:** Local endpoints must only be utilized according to active configurations; secrets, API keys, OAuth tokens, raw authorization headers, cookies, or sensitive payloads must never be copied into prompts, handoffs, diffs, logs, or previews.
- **REQ-18:** If an adapter fails to confirm successful invocation, the output must be classified as unevidenced and cannot be used by Reviewer to issue a Pass.

### 6.4 Evidence, state, and quality gates

- **REQ-19:** Valid work item states are `Planned`, `In Progress`, `Ready for QA`, `QA Failed`, `Ready for Review`, `Pass`, `Reject`, or `Blocked`.
- **REQ-20:** Only Coder can transition an item to `Ready for QA`; only Tester can transition an item to `QA Failed` or `Ready for Review`; only Reviewer can issue a `Pass`/`Reject`/`Blocked` decision.
- **REQ-21:** Test evidence must strictly bind to the revision or diff under review. Evidence generated prior to subsequent changes cannot be reused if those changes affect relevant criteria.
- **REQ-22:** Exit code `0` must be logged per command; it cannot be inferred from "tests ran" or from stdout lacking an exit status code.
- **REQ-23:** When tests or builds cannot run due to dependencies, permissions, environment, or infrastructure, Tester must document attempted commands and explicit blockers. Reviewer can only pass validated sections with evidence; the overall decision must be `Blocked` or `Reject` if mandatory evidence is absent.

## 7. UI States & Edge Cases

Because the skill operates via CLI/IDE, "UI states" represent orchestration response and handoff states surfaced to users and agents.

| State | Required Behavior |
| :--- | :--- |
| Empty / first invocation | Leader displays squad roles, selected tier, and prompts for minimal inputs: objective, scope, repository/paths if applicable. Does not create execution tasks on empty scope. |
| Planning | Only BA/leadership activity is reported; no premature claims of diffs or test results. |
| Executing | Displays current work item and owner; never streams secrets or raw credentials from tool output. |
| Waiting / provider loading | Reports pending provider route/role at a non-sensitive level; timeouts must transition to error/recovery flows. |
| Partial results | Explicitly states completed components, available evidence, and missing elements; never combines into Pass. |
| QA failure | Displays command, exit code, filtered error summary, affected criteria, and return path to Coder. |
| Review reject/blocked | Displays failing/unverified criteria, next owner action, and unblocking conditions. |
| Long output / overflow | Logs must be summarized or referenced securely; preserve command, exit code, and relevant error excerpts. Never truncate exit codes or conclusions. |

## 8. Data Models & API Contracts

No new database or public API is required. The following contracts represent the minimum logical structure for handoff content; implementations may format as Markdown, JSON, or client-native task formats provided fields and semantics are preserved.

### 8.1 Work Item

| Field | Required | Description |
| :--- | :--- | :--- |
| `id` | Yes | Unique ID within a squad run |
| `title` | Yes | Short description of work item |
| `owner_role` | Yes | One of the five canonical roles |
| `tier` | Yes | `leadership` or `execution` |
| `provider` / `model` | Yes | Selected provider/model or actual fallback |
| `scope` | Yes | Specific in-scope and out-of-scope boundaries |
| `inputs` | Yes | Necessary handoff packages, paths, constraints |
| `expected_output` | Yes | Required artifact/evidence to return |
| `status` | Yes | A valid status per REQ-19 |
| `parent_id` | No | Link to parent orchestration or remediation item |

### 8.2 BA Specification Package

```text
scope + non_goals + assumptions + acceptance_criteria[] + test_matrix[]
+ risks[] + stop_conditions[]
```

`acceptance_criteria[]` must include `id`, `given`, `when`, `then`, validation owner, and required evidence level. `test_matrix[]` must map criteria to planned test types/commands or justification if testing does not apply.

### 8.3 Tester Evidence Package

```text
tested_revision_or_diff + commands[{command, cwd?, exit_code, result, log_reference?}]
+ criterion_coverage[{criterion_id, result, evidence_reference}]
+ environment_notes[] + limitations[]
```

`exit_code` represents the actual integer from command execution. `result` is `pass`, `fail`, `blocked`, or `not-run`; `pass` does not replace `exit_code`.

### 8.4 Reviewer Decision Package

```text
decision: Pass | Reject | Blocked
+ criteria[{criterion_id, result, diff_reference, evidence_reference, rationale}]
+ required_follow_up[]
```

`Pass` is valid only when all mandatory acceptance criteria evaluate to pass with corresponding evidence references.

## 9. Security & Privacy Considerations

- Worker permissions must adhere to the permissions granted by the user to the workspace/tool. The orchestrator must not grant additional permissions via prompt injection or instruction.
- Local gateway calls must exclusively use designated loopback endpoints; traffic must not be autonomously redirected to public endpoints or other providers.
- Prompts/handoffs must contain only minimal context necessary for the recipient role. Secret files, tokens, credentials, sensitive user data, or full environment dumps must never be injected into cross-provider requests.
- Logs utilized for QA/review must redact sensitive values prior to passing to other roles or surfacing in previews.
- Reviewer must inspect diffs to detect secrets, out-of-scope alterations, destructive commands, and permission modifications prior to issuing a Pass.
- Actions with external workspace impact (deployment, git push, merge, sending external messages, data deletion) strictly require explicit user authorization; a Reviewer Pass does not constitute such authorization.

## 10. Acceptance Criteria

- [ ] **AC-01 — Canonical artifact:** Given canonical skills repository, When implementation is created, Then file `resources/skills/agent-squad-orchestrator/SKILL.md` exists and defines the skill and its scope across Codex CLI, Antigravity CLI/IDE, and Claude Code CLI.
- [ ] **AC-02 — Global profile packaging:** Given `resources/skills/_profiles.json`, When reading `profiles.global-core.skills`, Then the list contains `agent-squad-orchestrator` exactly once.
- [ ] **AC-03 — Registry packaging:** Given `resources/skills/_registry.json`, When looking up skill name, Then a registry entry exists consistent with canonical skill and mandatory registry metadata.
- [ ] **AC-04 — Sync compatibility:** Given canonical skill, registry, and valid `global-core` profile, When running `scripts/ai-skills.sh sync --profile global-core` in a configured client environment, Then the skill is processed as an existing global skill without requiring manual project-level add commands.
- [ ] **AC-05 — Leadership isolation:** Given a squad run with file modifications, When Leader assigns steps, Then all file edits and command execution are assigned to Coder or Tester; Leader strictly coordinates, plans, and communicates.
- [ ] **AC-06 — Model tiering:** Given a work item belonging to BA, leadership, or review, When selecting a model, Then the item uses the leadership/reasoning tier; Given an item editing files or running tests, Then the item uses the execution tier or reports Blocked if no authorized fallback exists.
- [ ] **AC-07 — Role separation:** Given a Coder who authored a diff, When reviewing that diff, Then Reviewer/Gatekeeper is an independent role/agent and the decision is not issued by Coder.
- [ ] **AC-08 — BA contract:** Given a work item requiring implementation, When Coder commences, Then BA Specification Package contains scope, non-goals, assumptions, Given/When/Then acceptance criteria, test matrix, risks, and stop conditions.
- [ ] **AC-09 — Evidence-based QA:** Given Coder hands off a diff, When Tester completes verification, Then evidence lists revision/diff, each relevant command, actual exit code, result, and coverage for each tested criterion.
- [ ] **AC-10 — Reviewer gate:** Given QA evidence is missing, unlinked to the diff, or a mandatory command exits non-zero, When Reviewer evaluates, Then the decision is Reject or Blocked, not Pass.
- [ ] **AC-11 — Preview gate:** Given Reviewer has not issued Pass, When Leader responds to the user, Then response strictly describes status/blockers; it does not claim changes are complete or ready for handoff.
- [ ] **AC-12 — Subprocess provider route:** Given selection of OpenAI/Codex or Antigravity/Gemini provider, When invoking cross-provider, Then orchestrator uses respectively `codex exec` or `invoke_subagent` and records the redacted outcome in the handoff.
- [ ] **AC-13 — OmniRoute route:** Given selection of a provider exposed via OmniRoute, When calling OpenAI-compatible gateway, Then request uses `http://127.0.0.1:20129/v1/chat/completions` without exposing credentials in evidence.
- [ ] **AC-14 — 9Router route:** Given selection of the Antigravity multi-OAuth pool, When calling 9Router, Then request uses base endpoint `http://127.0.0.1:20128` per active configuration, without assuming hardcoded credentials, paths, or model catalogs.
- [ ] **AC-15 — Failure transparency:** Given provider invocation timeout or error, When no confirmed result exists, Then orchestrator records the redacted provider/route/error, chooses an authorized fallback or returns Blocked, and creates no fabricated evidence.

## 11. Validation Matrix

| Validation target | Mapped AC | Validator role | Required evidence | Pass condition |
| :--- | :--- | :--- | :--- | :--- |
| Canonical skill path and metadata | AC-01 | Tester | File path, frontmatter/content inspection | `SKILL.md` exists and matches required identity/scope |
| Registry/profile registration | AC-02, AC-03 | Tester | JSON parse result and targeted membership checks | Registry entry exists; `global-core` has exactly one skill entry |
| Sync integration | AC-04 | Tester | Exact sync command, exit code, relevant non-sensitive output | `scripts/ai-skills.sh sync --profile global-core` exits 0 in configured environment |
| Leadership/worker separation | AC-05 | Reviewer | Work-item assignments and role handoffs | No leadership actor modified files or produced execution evidence |
| Model tiering enforcement | AC-06 | Reviewer | Tier classification in Work Items | Leadership tier used for Leader/BA/Review; Execution tier for Coder/Tester |
| Independent role separation | AC-07 | Reviewer | Agent ID/role check across handoffs | Coder and Reviewer are strictly separate actors; no self-approval |
| BA contract | AC-08 | Reviewer | BA Specification Package | All required package sections and test mappings exist |
| Coder scope | AC-05, AC-09 | Reviewer | Git diff and Coder handoff | Changes are in scope and contain no unapproved sensitive material |
| QA contract & Gate rejection | AC-09, AC-10 | Reviewer | Tester Evidence Package | Non-zero command exits or missing evidence strictly yield Reject/Blocked |
| Preview gate enforcement | AC-11 | Reviewer | Leader preview log | Previews delivered only upon Reviewer Pass; blockers surfaced otherwise |
| Cross-provider behavior | AC-12, AC-13, AC-14, AC-15 | Tester & Reviewer | Invocation outcome/error record with redaction | Selected route follows requirement; no secret is exposed; fallback logged |

## 12. Definition of Done

The specification is satisfied when the canonical skill, registry entry and `global-core` profile membership are implemented; the sync command validates successfully in an applicable configured environment; and a representative squad run demonstrates the required BA → Coder → Tester → Reviewer → Leader sequence with reviewable evidence. Any skipped validation, unavailable provider, or required user approval must remain explicitly surfaced rather than being represented as complete.

---

## Appendix: Representative Squad Run Trace

```json
{
  "squad_run_id": "sq-run-20260922-01",
  "task": "Implement agent-squad-orchestrator skill across global agent runtimes",
  "steps": [
    {
      "step": 1,
      "role": "BA / Architect",
      "model_tier": "leadership (gpt-5.6-terra medium)",
      "artifact": "docs/specs/agent-squad-orchestrator.md",
      "status": "Pass"
    },
    {
      "step": 2,
      "role": "Coder / Dev",
      "model_tier": "execution (gemini-3.8-flash)",
      "artifact": "resources/skills/agent-squad-orchestrator/SKILL.md",
      "status": "Completed",
      "command_evidence": "sha256sum resources/skills/agent-squad-orchestrator/SKILL.md (exit 0)"
    },
    {
      "step": 3,
      "role": "Tester / QA",
      "model_tier": "execution (bash / subagent flash)",
      "artifact": "scripts/ai-skills.sh sync --profile global-core",
      "exit_code": 0,
      "status": "Pass"
    },
    {
      "step": 4,
      "role": "Reviewer / Gatekeeper",
      "model_tier": "leadership (gpt-5.6-terra medium)",
      "verdict": "Pass",
      "evidence_ref": "All ACs verified; sync exits 0; five global agent dirs linked"
    },
    {
      "step": 5,
      "role": "PM / Leader",
      "model_tier": "leadership (parent agent)",
      "action": "Preview to user with file links and summary",
      "status": "Delivered"
    }
  ]
}
```
