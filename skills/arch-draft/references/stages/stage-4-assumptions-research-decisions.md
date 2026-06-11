<!--
  Part of the arch-draft playbook — stage file, read JUST-IN-TIME as the interview enters its phases
  (the spine's phase index points here). Sources are concatenated into the full playbook artifact by
  scripts/build-playbook.sh; edit HERE, never in the generated concat.
-->

## 13. Phase 9 — Assumptions and Open Questions

### Goal

Track uncertainty explicitly.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `ASSUMPTIONS.md` and `OPEN_QUESTIONS.md`.

### Prompt

```text
List assumptions and open questions.

For assumptions:
- assumption
- category
- why it matters
- validation path
- fallback

For open questions:
- question
- why it matters
- current best guess
- when it must be answered
- fallback
- status

Do not silently resolve important unknowns.
```

### Deep Interview

```text
1. What are we assuming about users?
2. What are we assuming about data?
3. What are we assuming about APIs?
4. What are we assuming about deployment?
5. What are we assuming about budget/time?
6. What are we assuming about evaluator expectations?
7. Which assumptions are dangerous?
8. Which assumptions can be validated quickly?
9. Which assumptions need fallback architecture?
```

---

## 14. Phase 10 — Research Plan and Research Execution

### Goal

Validate unstable/current/external facts before locking architecture.

### Required Output

`RESEARCH.md`

### Research Triggers

Research is required when a fact is:

- current or likely to have changed
- external dependency-related
- pricing/limits-related
- legal/regulatory/compliance-related
- third-party integration-related
- unfamiliar
- niche
- critical to architecture feasibility

### Template

```md
# RESEARCH.md

## Research Questions

| ID | Question | Why It Matters | Decision It Informs | Status |
|---|---|---|---|---|

## Findings

### R-001 — [Topic]
Question:
Findings:
Sources:
Impact:
Decision Implication:
Remaining Risk:
```

### Prompt

```text
Create a research plan for all unstable or external facts.

For each research item:
- question
- why it matters
- what decision it informs
- what source type is needed
- what would change the architecture

Then perform the research and summarize:
- findings
- sources
- architecture impact
- remaining risk
- recommended decision implication
```

### Research Quality Bar

Each researched fact should answer:

```text
Can we rely on this for this build, and what is the fallback if not?
```

---

## 15. Phase 11 — Architecture Decision Discovery

### Goal

Compare options before locking decisions.

### Required Output

`DECISIONS.md`

### ADR Template

```md
## ADR-001 — [Decision Title]

Status: Proposed / Locked / Deferred / Superseded

### Context
...

### Options Considered
| Option | Pros | Cons | Build Risk | Demo Risk | Security Risk | PRD Alignment |
|---|---|---|---|---|---|---|

### Recommendation
...

### Decision
...

### Rationale
...

### Tradeoffs
...

### Fallback
...

### What Would Change This Decision
...

### Related Requirements
...

### Related Architecture Anchors
...
```

### Prompt

```text
For each major architecture decision, create an ADR-style decision record.

Compare:
- options
- pros/cons
- build risk
- demo risk
- security risk
- PRD alignment
- recommendation
- fallback
- what would invalidate the choice

Do not lock decisions until I confirm them unless the PRD mandates them.
```

### Common Decision Domains

```text
frontend framework
backend framework
database/storage
auth
deployment
scheduler/queue
agent framework
LLM model/provider
retrieval/indexing
API style
data model
security boundary
observability
test strategy
demo strategy (optional — only if a demo is in scope)
build posture & scope (production-grade vs MVP/prototype; in-scope vs deferred)
```

---

## 16. Phase 12 — Decision Locking

### Goal

Create a stable baseline before architecture drafting.

### Required Output

Add to `DECISIONS.md` and later `ARCHITECTURE.md`:

```md
## Locked Decision Summary

| Area | Decision | Status | Rationale | Fallback |
|---|---|---|---|---|
| ... | ... | Locked | ... | ... |
```

### Prompt

```text
Summarize all proposed decisions.

For each:
- area
- decision
- rationale
- fallback
- remaining risk
- open verification

Ask me to confirm which are locked.
After confirmation, treat them as the current architecture baseline.
```

### Stop Condition

Do not draft `ARCHITECTURE.md` until the major load-bearing decisions are locked or explicitly marked open.

---

## Phase-bound micro-prompts (stage 4)

### Decision Matrix

```text
For this decision, produce a decision matrix.

Columns:
- option
- pros
- cons
- build risk
- demo risk
- security/data risk
- PRD alignment
- recommendation
- fallback
```

