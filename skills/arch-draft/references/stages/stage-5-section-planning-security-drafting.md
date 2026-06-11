<!--
  Part of the arch-draft playbook — stage file, read JUST-IN-TIME as the interview enters its phases
  (the spine's phase index points here). Sources are concatenated into the full playbook artifact by
  scripts/build-playbook.sh; edit HERE, never in the generated concat.
-->

## 17. Phase 13 — Section-by-Section Architecture Planning

### Goal

Plan the architecture in sections before drafting.

### Required Output

A planning transcript and/or `ARCHITECTURE_OUTLINE.md`.

### Prompt

```text
Plan the architecture section by section before writing the final document.

For each section:
- purpose
- responsibilities
- boundaries
- depends-on / imports-from (which other sections this may import; the allowed import direction)
- independent of (sections this shares no dependency path with — candidate parallel build tracks)
- components/modules/services/contracts
- data flow
- state/lifecycle rules
- integrations
- failure modes
- tests
- scope simplifications (posture-gated cuts) + any production-hardening requirements
- deferred work
- open questions
```

### Dependency DAG & Parallelization Interview

Capture the import DAG explicitly — it becomes `ARCHITECTURE.md §2.5` and is the seam `/tasks-gen` derives parallel build tracks along:

```text
1. Which subsystems could a second engineer build at the same time without blocking the first?
2. What is the import direction — which layer/subsystem may import which? What import would be a violation?
3. What are the shared contracts (types / APIs / schemas) two parallel subsystems both touch — the integration points that must be frozen first?
4. Where do independent subsystems finally integrate, and who owns that merge?
```

### Recommended Section Planning Order

```text
1. Executive summary, architecture posture, and Build posture
2. Product definition and scope (per Build posture)
3. Locked decisions
4. System overview
5. Subsystem dependency DAG & parallelization seams (import-direction rule + independent-subsystem callout)
6. Domain model
7. Core modules/services/contracts
8. Data/state model
9. User-facing flows
10. Background/automation flows
11. External integrations
12. Frontend architecture
13. Backend/API/indexer strategy
14. Shared package/config strategy
15. Testing strategy
16. Security/risk
17. Deployment strategy (+ demo strategy only if a demo is in scope)
18. Alternatives considered
19. Scope boundaries / deferred work
20. Diagrams
21. Repo scaffold
22. Build contract
```

### Section Deepening Prompt

Use this when a section feels thin:

```text
This section is too high-level. Deepen it into a build-ready planning section.

Include:
- exact responsibilities
- exact inputs/outputs
- ownership/source of truth
- data types or schemas where possible
- lifecycle/state rules
- validation rules
- error cases
- tests
- scope simplifications (posture-gated cuts) + any production-hardening requirements
- deferred work
- what Claude Code needs to know to build it
```

---

## 18. Phase 14 — Security, Risk, and Failure Modes

### Goal

Ensure architecture covers failure modes and reviewer concerns.

### Required Output

`RISKS.md` or `PRESEARCH.md` risk section, then architecture risk section.

### Prompt

```text
Identify product, technical, data, security, integration, operational, demo, scope, and regulatory/compliance risks.

For each:
- risk
- category
- severity
- likelihood
- mitigation
- fallback
- test/validation
- whether it must appear in ARCHITECTURE.md
```

### Trust Boundary Prompt

```text
Identify trust boundaries.

For each boundary:
- what crosses it
- who controls each side
- what validation happens
- what can go wrong
- what logs/auditability exist
- what secrets/sensitive data are involved
- what the mitigation is (sized to the chosen Build posture)
```

### Common Risk Categories

```text
auth/authorization
secrets
data leakage
financial/collateral correctness
external dependency failure
model hallucination
prompt injection
PII/PHI
payment failure
race conditions
idempotency
supply chain (dependency provenance, lockfile discipline, audit cadence)
performance/scale failure modes (hot-path saturation, unbounded growth)
background job failure
deployment misconfiguration
user confusion
demo fragility
scope creep
```

---

## 19. Phase 15 — Architecture Drafting

### Goal

Create the first build-ready `ARCHITECTURE.md`.

### Required Output

`ARCHITECTURE.md`

### Required Characteristics

The architecture draft must be:

- comprehensive
- stable
- sectioned
- anchored
- implementation-facing
- explicit about decisions
- explicit about assumptions
- explicit about boundaries
- explicit about failure modes
- explicit about testing and deployment
- suitable for Claude Code second-pass review

### Header Template

```md
# [Project] Architecture

> **Status:** First-draft canonical architecture spec for this build (per the chosen Build posture: production-grade | MVP/prototype).
>
> **Audience:** Project owner, technical reviewers, future Claude Code sessions.
>
> **Primary implementation constraint:** [timebox / team / constraints].
>
> **Companion docs:** `PRESEARCH.md`, `RESEARCH.md`, `DECISIONS.md`, `DIAGRAM_PLAN.md`, `CLAUDE_CODE_HANDOFF.md`.
>
> **Build contract:** Claude Code should treat this file as the first-draft source of truth, perform a second-pass gap audit, finalize it, and only then create `IMPLEMENTATION_PLAN.md` from the user's template.
```

### Recommended Structure

```md
## 1. Executive Summary
## 1A. Goals & Non-Goals
## 2. Product Definition and Scope
## 3. Locked Architecture Decisions
## 4. System Overview
## 4A. Subsystem Dependency DAG & Parallelization Seams
## 5. Domain Model
## 6. Core Module / Service / Contract Architecture
## 7. Data and State Model
## 8. User Flows
## 9. Integration Architecture
## 10. Automation / Background Jobs
## 11. Frontend Architecture
## 12. Backend / API / Indexer Strategy
## 13. Shared Package / Config Strategy
## 14. Testing Strategy
## 15. Security and Risk
## 16. Deployment Strategy
## 17. Alternatives Considered
## 18. Scope Boundaries and Deferred Work
## 19. Diagrams
## 20. Repo Scaffold
## 21. Decision Summary Table
## 22. Spec Anchor Index
## 23. Claude Code Review Instructions
```

### Drafting Prompt

```text
Draft ARCHITECTURE.md using all prior planning artifacts.

The document must be build-ready and include:
- stable anchors for every major section
- status/audience/build contract
- goals/non-goals
- locked decisions
- system overview
- domain model
- component/service/contract boundaries
- data/state model
- user and automation flows
- integration details
- frontend/backend strategy
- testing strategy
- security/risk
- deployment strategy (+ demo strategy only if a demo is in scope)
- alternatives considered
- scope boundaries / deferred work
- repo scaffold
- spec anchor index
- Claude Code review instructions

Do not include implementation tasks. Those come later after Claude Code reviews and finalizes the architecture.
```

---

