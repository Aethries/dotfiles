# Feature Specification: <Feature Name>

**Status:** Draft | In Review | Approved  
**Author:** <Agent / Author>  
**Target Path:** `docs/specs/<feature-name>.md`  

---

## 1. Context & Problem Statement
- What user problem does this feature solve?
- What is the current status or limitation?

## 2. Goals & Non-Goals
- **Goals**: Measurable outcomes achieved by this feature.
- **Non-Goals**: Explicitly out-of-scope capabilities for this phase.

## 3. Actors & Permissions
| Actor / Role | Description | Allowed Actions |
| :--- | :--- | :--- |
| Guest / Unauth | Unauthenticated visitor | Read-only public endpoints |
| User | Standard registered user | Create, read, and manage own resources |
| Admin | System administrator | Full tenant oversight and management |

## 4. User Journeys & Flows
1. **Primary Happy Path**: Step-by-step end-to-end user interaction.
2. **Alternative Flows**: Secondary actions or shortcuts.
3. **Error Paths**: Recovery flows when actions fail or validation rejects.

## 5. Functional Requirements & Business Rules
- **REQ-1**: Functional behavior specification.
- **REQ-2**: Business invariant or boundary calculation rule.

## 6. UI States & Edge Cases
- **Empty State**: Messaging and call-to-action when dataset is empty.
- **Loading State**: Visual indicator during asynchronous operations.
- **Error State**: User-facing error messaging and retry actions.
- **Boundary / Overflow**: Maximum character lengths, line clamping, long inputs.

## 7. Data Models & API Contracts
- **Key Entities & Attributes**: High-level schema and types.
- **Events & Payloads**: API inputs and expected responses.

## 8. Security & Privacy Considerations
- Authentication & tenant isolation requirements.
- Data protection, rate limiting, and sanitization boundaries.

## 9. Acceptance Criteria
- [ ] **Scenario 1**: Given <preconditions>, When <action taken>, Then <expected result>.
- [ ] **Scenario 2**: Given <invalid input>, When <submission attempted>, Then <validation error returned>.
