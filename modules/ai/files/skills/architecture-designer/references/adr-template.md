# ADR-XXXX: <Short Title of Decision>

- **Status:** Proposed | Accepted | Superseded | Deprecated
- **Date:** YYYY-MM-DD
- **Author:** <Architect / Agent>
- **Deciders:** <Team / Stakeholders>

---

## 1. Context & Problem Statement
- What is the technical or architectural problem we are solving?
- What forces and constraints influence this decision (scale, team velocity, security, latency)?

## 2. Decision Drivers
- Driver 1: e.g., low-latency queries under 50ms.
- Driver 2: e.g., strict regulatory data residency requirements.
- Driver 3: e.g., team maintainability with minimal operational overhead.

## 3. Considered Options
- **Option 1**: <Title> - Description
- **Option 2**: <Title> - Description
- **Option 3**: <Title> - Description

## 4. Decision Outcome
Chosen option: **Option 1**, because <concise justification based on drivers>.

### Positive Consequences
- Gain 1: Direct benefit to system architecture.
- Gain 2: Reduced complexity or improved performance.

### Negative Consequences / Trade-offs
- Cost 1: Trade-off accepted (e.g., eventual consistency instead of strong consistency).
- Mitigation: How the negative consequence is controlled or monitored.

## 5. Architecture & Implementation Notes
- Diagram or component topology summary.
- Affected modules, repositories, or services.
- Data flow and communication protocols (Sync vs Async).

## 6. Validation & Compliance
- How will this architecture decision be enforced (linter, architecture-guardrails, test)?
