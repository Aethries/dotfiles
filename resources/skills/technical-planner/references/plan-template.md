# Technical Implementation Plan: <Feature Name>

**Spec Reference:** `docs/specs/<feature-name>.md`  
**Target Path:** `docs/plans/<feature-name>.md`  
**Status:** Proposed | Ready | In Progress | Completed  

---

## 1. Technical Context & Impacted Modules
- Existing codebase components impacted by this change.
- Upstream and downstream module dependencies.

## 2. Architecture Alternatives & Trade-Offs
| Option | Description | Pros | Cons | Decision |
| :--- | :--- | :--- | :--- | :--- |
| **Option A (Chosen)** | Native platform / stdlib approach | Minimal dependency overhead, simple lifecycle | Requires manual wiring | Selected |
| **Option B** | Third-party framework abstraction | Feature-rich out of the box | Adds heavy runtime dependency | Rejected |

## 3. File Modification Manifest
| Action | File Path | Description |
| :--- | :--- | :--- |
| `CREATE` | `src/services/new-service.ts` | Implementation of core business logic |
| `MODIFY` | `src/controllers/api.ts` | Add endpoint route handlers |
| `DELETE` | `src/legacy/old-util.ts` | Remove deprecated helper |

## 4. Phased Execution Roadmap

### Phase 1: Data Models & Interfaces
- **Objective**: Establish domain types and interfaces without side effects.
- **Tasks**:
  1. Define types/interfaces in `src/types/`.
  2. Implement unit tests for data validators.
- **Verification**: Discovered test command (e.g. `cargo test`, `pnpm test`, `nix flake check`).

### Phase 2: Core Domain Logic
- **Objective**: Implement service algorithms and state transitions.
- **Tasks**:
  1. Implement service methods.
  2. Add unit tests for edge cases and boundary inputs.
- **Verification**: Run unit test suite and type checker.

### Phase 3: Integration & External Boundaries
- **Objective**: Wire endpoints, database adapters, and UI components.
- **Tasks**:
  1. Wire controllers and route definitions.
  2. Connect UI components to service layer.
- **Verification**: Run integration test suite and quality gate.

## 5. Verification & Discovered Quality Gates
- **Lint**: Discovered project linter (e.g. `golangci-lint`, `cargo clippy`, `eslint`, `shellcheck`)
- **Format**: Discovered formatter (e.g. `nixfmt`, `cargo fmt`, `prettier --check`)
- **Typecheck**: Discovered typechecker (e.g. `tsc --noEmit`, `pyright`, `cargo check`)
- **Tests**: Discovered test runner
- **Build**: Discovered build command

## 6. Rollback & Contingency Plan
- Steps to revert changes if regressions are identified post-merge.
- Feature flag or environmental gating mechanisms.
