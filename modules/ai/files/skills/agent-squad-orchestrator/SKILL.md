---
name: agent-squad-orchestrator
description: "Multi-role squad orchestrator across Codex CLI, Antigravity CLI/IDE, and Claude Code CLI. Coordinates PM, BA, Coder, Tester, and Reviewer with model tiering, cross-provider routing (codex exec, invoke_subagent, OmniRoute, 9Router), and evidence-based handoffs."
---

# Agent Squad Orchestrator

Canonical multi-role orchestrator standardizing five specialized roles across Codex CLI, Antigravity CLI/IDE, and Claude Code CLI with strict role separation, model tiering, and evidence-based verification.

## 1. Five Specialized Roles & Strict Boundaries

1. **PM / Leader (Conductor)**: Scopes, decomposes work, coordinates handoffs, and delivers user previews. **NEVER** edits code, executes raw commands, or generates fake test evidence.
2. **BA / Architect**: Defines requirements, non-goals, Given/When/Then acceptance criteria (AC), test matrix, and stop conditions.
3. **Coder / Dev**: Implements approved scope, produces git diff and executed command logs. **NEVER** self-approves or declares QA Pass.
4. **Tester / QA**: Runs tests/linters/builds independently, records exact commands, working directory, and integer exit codes.
5. **Reviewer / Gatekeeper**: Audits git diff and test evidence against BA AC. Emits `Pass`, `Reject`, or `Blocked`. Missing, stale, or mismatched evidence or non-zero exit code on mandatory commands MUST yield `Reject` or `Blocked`, never `Pass`.

## 2. Model Tiering Matrix

- **Leadership / High Reasoning Tier** (Terra, Sol/Astra, Gemini Pro, DeepSeek Pro): Assigned to Leader, BA, and Reviewer. Focuses on planning, risk assessment, AC formulation, and gatekeeping.
- **Execution / Speed Tier** (Luna, Gemini Flash, DeepSeek-V non-Pro): Assigned to Coder and Tester. Focuses on file edits, test/build execution, and telemetry capture.
*Rule*: Never use Leadership tier to bypass worker isolation. If execution tier is unavailable, mark `Blocked`.

## 3. Evidence-Based 5-Step Lifecycle

1. **Specification**: Leader frames scope; BA outputs `BA Specification Package` (AC + test matrix).
2. **Implementation**: Coder implements strictly within scope; outputs `Coder Handoff` (diff + command logs).
3. **Verification**: Tester validates diff against AC; outputs `Tester Evidence Package` (exact commands + exit codes).
4. **Gatekeeping**: Reviewer verifies diff and test logs against AC; outputs `Reviewer Decision Package`. Reject/Blocked if evidence fails or commands exit non-zero.
5. **User Preview**: Leader summarizes status to user ONLY after Reviewer `Pass` (or surfaces blockers).

## 4. Cross-Provider Invocations

- **CLI Subprocess**:
  - `codex exec` for OpenAI/Codex execution.
  - `invoke_subagent` for Google Antigravity/Gemini execution.
  - Record provider/model, executed command/method, and redacted outcome in handoff.
- **Local Gateways**:
  - **OmniRoute** (`http://127.0.0.1:20129/v1/chat/completions`): OpenAI-compatible endpoint for DeepSeek/Claude.
  - **9Router** (`http://127.0.0.1:20128`): Antigravity multi-OAuth pool gateway. Adhere strictly to active runtime configuration; do not assume fixed paths, auth headers, or hardcoded model catalogs.
- **Security & Failure Transparency**: Redact tokens/secrets from all prompts, diffs, and logs. On timeout/error, record provider, route, and redacted error telemetry; attempt authorized fallback routes before marking `Blocked`. Never fabricate evidence.

## 5. Handoff Contracts

- **Work Item**: `id`, `title`, `owner_role`, `tier`, `provider`/`model`, `scope`, `inputs`, `expected_output`, `status` (`Planned`, `In Progress`, `Ready for QA`, `QA Failed`, `Ready for Review`, `Pass`, `Reject`, `Blocked`).
- **Invocation Record**: `provider`, `model`, `route` (`subprocess` | `gateway`), `target`, `redacted_outcome` | `redacted_error`.
- **BA Package**: `scope` + `non_goals` + `assumptions` + `acceptance_criteria[]` + `test_matrix[]` + `risks[]` + `stop_conditions[]`.
- **Coder Package**: `work_item_id` + changed files + `git diff` + executed commands + limitations.
- **Tester Evidence**: `tested_diff` + `commands[{command, cwd, exit_code, result}]` + `criterion_coverage[]` + limitations.
- **Reviewer Decision**: `decision` (`Pass` | `Reject` | `Blocked`) + `criteria[{criterion_id, result, diff_ref, evidence_ref, rationale}]`.
