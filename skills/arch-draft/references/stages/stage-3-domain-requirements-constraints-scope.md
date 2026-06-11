<!--
  Part of the arch-draft playbook — stage file, read JUST-IN-TIME as the interview enters its phases
  (the spine's phase index points here). Sources are concatenated into the full playbook artifact by
  scripts/build-playbook.sh; edit HERE, never in the generated concat.
-->

## 9. Phase 5 — Domain Model and State Machines

### Goal

Define the nouns, relationships, state machines, and invariants.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `DOMAIN_MODEL.md`.

### Template

```md
## Phase 5 — Domain Model

### Core Entities
| Entity | Definition | Key Fields | Source of Truth |
|---|---|---|---|

### Relationships
...

### State Machines
...

### Business Rules
...

### Invariants
...

### Glossary
...

### Ambiguous Terms
...
```

### Prompt

```text
Build the domain model.

Identify:
- entities
- relationships
- state machines
- lifecycle transitions
- business rules
- invariants
- units and precision
- terminology
- ambiguous terms

Do not design services yet. First define the domain language.
```

### Deep Domain Questions

```text
1. What are the nouns?
2. Which nouns are persistent entities?
3. Which nouns are derived views?
4. Which nouns are external objects?
5. What are the lifecycle states?
6. What transitions are allowed?
7. What transitions are forbidden?
8. What invariants must never be broken?
9. What data is authoritative?
10. What data is cached/derived/display-only?
11. What data can be stale?
12. What data must be real-time?
```

---

## 10. Phase 6 — Requirements Extraction

### Goal

Turn PRD + interview outputs into testable requirements.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `REQUIREMENTS.md`.

### Template

```md
## Phase 6 — Requirements

### Functional Requirements
| ID | Requirement | Source | Priority | Acceptance Signal |
|---|---|---|---|---|

### Non-Functional Requirements
...

### Data Requirements
...

### Security Requirements
...

### UX Requirements
...

### Operational Requirements
...

### Integration Requirements
...

### Testing Requirements
...

### Acceptance / Evaluation Requirements (demo-specific items only if a demo is in scope)
...

### Deferred Requirements
...
```

### Prompt

```text
Extract explicit and inferred requirements.

Classify each requirement as:
- functional
- non-functional
- data
- security
- UX
- operational
- integration
- testing
- demo/evaluation
- deferred

For each requirement:
- assign a stable ID
- identify source: explicit / inferred / user-confirmed — an `explicit` requirement MUST carry a
  PRD citation in the Source column (section heading or short quote, e.g. `explicit — PRD §3
  "exports must be idempotent"`); `inferred` and `user-confirmed` are tagged as such (with the
  interview answer that confirmed them, when applicable). A requirement you cannot cite or tag
  is not extractable — ask, don't mint it.
- priority: must-ship / stretch / deferred (sized to the chosen Build posture)
- acceptance signal
- related user flow
```

> **Why the citation matters:** the PRD→REQ hop is the head of the whole traceability spine
> (REQ → §-anchor → task → test). `/arch-finalize` audits this table against the PRD and persists
> a PRD→REQ coverage table; a dropped or re-interpreted PRD requirement with no REQ row is
> invisible to every downstream check, so the citation is what makes the audit mechanical.

### Requirement IDs

```text
REQ-F-001   Functional
REQ-NF-001  Non-functional
REQ-D-001   Data
REQ-S-001   Security
REQ-UX-001  UX
REQ-O-001   Operational
REQ-I-001   Integration
REQ-T-001   Testing
REQ-E-001   Evaluation/demo
```

> **REQ-NF seeds (production-grade):** elicit explicit numbers for latency/throughput budgets on the
> hot paths the PRD implies, availability target, data durability, and cost ceiling — from the PRD or
> the user ONLY (Phase 7 captures the same budgets as constraints). A budget nobody stated is a
> question, never an invented number; "no budgets — deliberate deferral" is a recordable answer.

---

## 11. Phase 7 — Constraints, Evaluation, and Timebox

### Goal

Constrain the architecture to what is buildable and what will be judged.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `CONSTRAINTS.md` and `EVALUATION_CRITERIA.md`.

### Prompt

```text
Identify constraints and evaluation criteria.

Capture:
- timebox
- team size
- available tooling
- required technologies
- forbidden technologies
- preferred technologies
- deployment constraints
- data/security/compliance constraints
- performance budgets for the hot paths the PRD implies — numbers from the PRD or the user ONLY,
  never model-invented; "no budgets — deliberate deferral" is a recordable answer
- demo constraints
- reviewer/evaluator expectations
- what technical depth will be rewarded
- what would be disqualifying
```

### Deep Questions

```text
1. How many days/hours are available?
2. Who will build it?
3. What tooling will be used?
4. What must be demoed live? (only if a demo is in scope)
5. What can be mocked?
6. What cannot be mocked?
7. What must be deployed?
8. What must run locally?
9. What does the evaluator care about most?
10. What tradeoffs need to be defended?
11. What would be considered scope creep?
12. What must be explicitly deferred?
```

---

## 12. Phase 8 — Scope Inference (posture-aware)

### Goal

Infer hidden requirements — sized to the chosen **Build posture** (§3.3): neither overbuilding nor under-building.

### Required Output

Add to `PRESEARCH.md`:

```md
## Phase 8 — Scope Inferences (posture: <production-grade | MVP/prototype>)

| Inference | Why It Matters | Classification | Architecture Impact |
|---|---|---|---|
| ... | ... | must-handle / production-hardening / simplification (posture-gated cut) / deferred / research | ... |
```

### Prompt

```text
Infer what the PRD does not explicitly say but a CORRECT build AT THE CHOSEN BUILD POSTURE must handle.

For each inference:
- state the inference
- explain why it matters
- classify as one of:
  - must-handle        (in-scope for this posture — load-bearing correctness / lifecycle)
  - production-hardening (auth, input validation, error paths, idempotency, observability, secrets, deploy/
                          rollback — IN-SCOPE under production-grade; a flagged deferral under MVP/prototype)
  - simplification     (a deliberate, justified scope cut — never a silent omission)
  - deferred
  - research required
- describe architecture impact

Posture discipline:
- production-grade → infer what a correct, maintainable, operable build must handle. Do NOT under-build —
  treat the production-hardening items as in-scope requirements, not optional extras.
- MVP / prototype → stay within the timebox; record every simplification/deferral so the hardening work
  stays visible later.
Either way: NEVER cut a load-bearing safety / security / correctness invariant — posture governs scope and
polish, not whether the system is correct on its load-bearing paths.
```

### Common Hidden Requirements

```text
authentication/authorization
admin/operator flows
background jobs
state lifecycle
failure recovery
idempotency
data validation
auditability/logging
secrets management
deployment envs
demo seed data
test fixtures
fallbacks for external dependency failure
```

---

## Phase-bound micro-prompts (stage 3)

### Posture-Scoped Inference

```text
Infer missing requirements a CORRECT build at the chosen Build posture must handle.

Classify each as:
- must-handle (in-scope correctness / lifecycle)
- production-hardening (in-scope under production-grade; a flagged deferral under MVP/prototype)
- simplification (a justified, recorded scope cut)
- deferred
- research required

Production-grade → do not under-build (hardening is in-scope). MVP/prototype → stay within the timebox and
flag deferrals. Never cut a load-bearing safety / security / correctness invariant.
```

