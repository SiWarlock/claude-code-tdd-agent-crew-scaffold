<!--
  Part of the arch-draft playbook — stage file, read JUST-IN-TIME as the interview enters its phases
  (the spine's phase index points here). Sources are concatenated into the full playbook artifact by
  scripts/build-playbook.sh; edit HERE, never in the generated concat.
-->

## 20. Phase 16 — Claude Code Review Instructions

### Goal

Tell Claude Code what to do with the draft architecture before building.

### Required Output

`CLAUDE_CODE_HANDOFF.md`

### Template

```md
# Claude Code Handoff

## Goal

Review the attached architecture draft and supporting docs, identify gaps, finalize the architecture, then create IMPLEMENTATION_PLAN.md from the user's provided template.

## Build Posture

<production-grade | MVP/prototype> — the delivery target the user confirmed at planning start. **Finalize and audit AGAINST it:**
- production-grade → treat missing production concerns (error paths, idempotency, observability, security, deploy/rollback) as critical gaps; a demo is OPTIONAL.
- MVP / prototype → deliberate deferral is acceptable; flag every deferral, never silently expand scope.

## Inputs

- PRD
- PRESEARCH.md
- RESEARCH.md
- DECISIONS.md
- ARCHITECTURE.md
- DIAGRAM_PLAN.md
- user's IMPLEMENTATION_PLAN.md template

## Instructions

1. Read all docs end-to-end.
2. Do not start implementation.
3. Perform an architecture gap audit, honoring the Build posture above.
4. Identify inconsistencies, missing decisions, unclear boundaries, untestable requirements, and scope creep.
5. Propose precise edits to ARCHITECTURE.md.
6. Ask for human confirmation on any load-bearing changes.
7. Apply confirmed edits.
8. Only after architecture is finalized, create IMPLEMENTATION_PLAN.md using the provided template.
9. Every task must reference architecture anchors.
10. Do not invent architecture in IMPLEMENTATION_PLAN.md.
```

### Gap Audit Prompt

```text
Perform a second-pass architecture gap audit.

Look for:
- missing user flows
- missing lifecycle states
- missing failure modes
- missing interfaces or schemas
- unclear source-of-truth boundaries
- unresearched external dependencies
- inconsistent decisions
- overbuilt scope
- missing tests
- missing deployment path (and demo path, if a demo is in scope)
- missing security/trust boundaries
- missing diagram needs
- missing anchors for task planning

Return:
1. Critical gaps
2. Important gaps
3. Nice-to-have improvements
4. Proposed architecture edits
5. Questions requiring human decision
```

---

## 21. Phase 17 — Diagram Plan

### Goal

Plan diagrams after architecture, not before.

### Required Output

`DIAGRAM_PLAN.md`

### Template

```md
# Diagram Plan

## Full-Scope Architecture Diagram

Purpose:
...

Must show:
...

Spec anchors:
...

## Sub-Diagrams

### 1. [Name]
Purpose:
Must show:
Spec anchors:
Priority:
Format:
```

### Prompt

```text
Create a diagram plan from ARCHITECTURE.md.

Include:
- one full-scope architecture diagram
- prioritized sub-diagrams
- purpose of each diagram
- what each diagram must show
- spec anchors each diagram maps to
- recommended format

Favor diagrams that clarify hard mechanics, lifecycle flows, trust boundaries, and implementation seams.
```

### Common Diagram Types

```text
Full-system architecture map
User flow diagram
Lifecycle sequence diagram
Domain model diagram
Data flow diagram
Frontend data-plane diagram
Contract/module internals
External integration diagram
Automation/scheduler diagram
Security/trust-boundary diagram
Testing/phase-gate diagram
Deployment topology diagram
```

---

## 22. Optional Phase — IMPLEMENTATION_PLAN Handoff, Not Generation

This playbook no longer requires generating `IMPLEMENTATION_PLAN.md`.

The recommended workflow is:

```text
Planning agent produces ARCHITECTURE.md draft.
Claude Code reviews and finalizes architecture.
User provides IMPLEMENTATION_PLAN.md template.
Claude Code generates IMPLEMENTATION_PLAN.md from finalized architecture + template.
```

### Handoff Requirements

The architecture package should make this easy by including:

```text
stable anchors
implementation order
test strategy
repo scaffold
preflight gates
open verifications
decision summary
deferred work
```

### Handoff Prompt for Claude Code

```text
After finalizing ARCHITECTURE.md, create IMPLEMENTATION_PLAN.md using my provided template.

Rules:
- Every task must reference ARCHITECTURE.md anchors.
- Do not invent architecture.
- If a task requires architecture not present in the doc, flag it before adding the task.
- Build order must prioritize invariants, lifecycle correctness, and tests first, hardening/polish last —
  honoring the chosen Build posture. Under production-grade, promote production concerns (error paths,
  idempotency, observability, security pins, deploy/rollback) to early tasks. A local demo is an OPTIONAL
  phase — include it only if a demo is in scope, never as a mandatory step.
```

---

## 23. Quality Review Checklist

Before accepting the architecture package:

### Product

```text
[ ] Product definition is clear.
[ ] Primary user is clear.
[ ] Stakeholders are identified.
[ ] Core workflows are clear.
[ ] Domain model is clear.
[ ] Success / acceptance criteria are clear (per the Build posture).
```

### Requirements

```text
[ ] Explicit requirements are captured.
[ ] Inferred requirements are marked.
[ ] Inferences match the chosen Build posture (production-grade is not penalized for inferring hardening).
[ ] Constraints are captured.
[ ] Evaluation criteria are captured.
[ ] Non-goals are clear.
```

### Decisions

```text
[ ] Major decisions are documented.
[ ] Alternatives are compared.
[ ] Tradeoffs are explicit.
[ ] Fallbacks exist.
[ ] Open decisions are tracked.
[ ] Research-dependent decisions cite research.
```

### Architecture

```text
[ ] System overview is clear.
[ ] Boundaries are clear.
[ ] Source-of-truth ownership is clear.
[ ] Data flows are clear.
[ ] Lifecycle/state rules are clear.
[ ] Integration paths are clear.
[ ] Automation/background jobs are clear.
[ ] Deployment path is clear (demo path only if a demo is in scope).
```

### Build Readiness

```text
[ ] Repo scaffold exists.
[ ] Interfaces/APIs/contracts are specified.
[ ] Required environment variables are listed.
[ ] Test strategy is specific.
[ ] Preflight gates are listed.
[ ] Runbooks exist where needed.
[ ] Implementation order is suggested.
[ ] Architecture has stable anchors.
[ ] Claude Code handoff is explicit.
```

### Risks

```text
[ ] Trust boundaries are identified.
[ ] Security risks are listed.
[ ] Data risks are listed.
[ ] External dependency risks are listed.
[ ] Demo risks are listed (if a demo is in scope).
[ ] Scope risks are listed.
[ ] Deferred work is explicit.
```

---

## 24. Common Failure Modes and Fixes

| Failure Mode | Symptom | Fix |
|---|---|---|
| One-shot architecture | Agent drafts too early | Force phases and interview loops |
| Thin PRD confusion | Agent invents missing mechanics | Run product mechanics interview |
| Generic architecture | Could apply to any product | Add domain model and workflows |
| Missing stakeholders | Architecture misses CTO/CISO/reviewer concerns | Add stakeholder phase |
| Missing lifecycle | Bugs in edge states | Add state machines and flow tables |
| Hidden assumptions | Surprises during build | Add assumptions/open questions |
| Unvalidated dependency | Integration fails late | Add research/preflight phase |
| Decisions not defensible | Reviewer asks "why?" | Add ADR-style decision log |
| Overbuilt for the posture | Timebox explodes / gold-plating | Add constraints/non-goals/deferred work |
| Under-built for production posture | Ships shortcuts; missing hardening/operability | Promote the missing production concern to a required task |
| Architecture not buildable | Claude Code invents details | Add build-ready specs and handoff |
| No parallelization seams | Build serializes; one engineer blocks all others | Capture the import DAG + independent-subsystem callout in §2.5 (Phase 13) |
| Task plan invents architecture | IMPLEMENTATION_PLAN diverges | Require anchors and Claude Code gap audit |

---

## Phase-bound micro-prompts (stage 6)

### Architecture Gap Audit

```text
Audit this architecture draft for gaps.

Find:
- missing workflows
- missing domain entities
- missing state transitions
- missing integrations
- missing data ownership
- missing security boundaries
- missing testing
- missing deployment path (and demo path, if a demo is in scope)
- unclear decisions
- overbuilt scope
- untracked assumptions

Return:
- critical gaps
- important gaps
- nice-to-have improvements
- suggested edits
- questions for human decision
```

---

## 26. Final Success Condition

The process is successful when Claude Code can receive:

```text
PRD
PRESEARCH.md
RESEARCH.md
DECISIONS.md
ARCHITECTURE.md
DIAGRAM_PLAN.md
CLAUDE_CODE_HANDOFF.md
IMPLEMENTATION_PLAN.md template
```

and then:

```text
1. Review/finalize ARCHITECTURE.md.
2. Create IMPLEMENTATION_PLAN.md from the finalized architecture and user template.
3. Build without relying on hidden chat context.
```

The planning process exists to make that possible.