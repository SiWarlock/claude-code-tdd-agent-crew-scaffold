<!--
  TEMPLATE: {{TASK_TRACKER}} → write to repo root.
  This is the single source of truth for current state + the phase plan.
  Fill the phase note, deadlines, deliverable map, and phase sections with the
  project's real plan. Everything else (Currently in progress, Carry-forward,
  Decisions tabled, Log, Trims) starts EMPTY — it accretes through real work.
  Task entries are dense checkbox bullets, NOT pre-written briefs. Delete this comment.
-->

# {{TASK_TRACKER}} — {{PROJECT_NAME}}

> **Phase note.** <One paragraph: the doc's scope, any locked decisions, archive policy. Refreshed when a major phase boundary is crossed.>

> **Session protocol:**
> - **At session start** — orchestrator runs `/orchestrate-start`; implementer runs `/session-start`. Confirm with the user what's targeted this session.
> - **At session end** (only when the user says we're done):
>   - **Implementer** runs `/session-end` — TDD audit + cross-doc audit + Step-9 list + create session doc + `/preflight`. Does NOT touch this doc.
>   - **Orchestrator** runs `/orchestrate-end` — verify hot routing landed, reconcile checkbox state, append Log entry, update Decisions / Carry-forward / Currently in progress, **triage Carry-forward**, round commit + push.

> **Reference deadlines:**
> - <milestone 1 — date>
> - <milestone 2 — date>

> **Spec-anchor convention (architecture-as-contract).** Each phase header below carries a `**Spec anchors:**` block listing the `{{ARCH_DOC}}` sections the phase implements. Orchestrator + implementer re-read the listed anchors at session start. If a slice surfaces a behavior the anchors don't cover, that's a cross-doc invariant flag at Step 9 — either the anchor is missing or the implementation has drifted. Architecture is contract; drift surfaces structurally, not silently.

---

## Currently in progress

**Bootstrap session.** Scaffolding landed; first `/tdd` slice not yet started.

**Next session target:** <first task ID>.

<!-- Refreshed at every /orchestrate-end: last commit hash, suite count, next session target, anything blocking. -->

---

## Carry-forward to upcoming briefs

Items the orchestrator MUST fold into upcoming slice briefs. **Triaged at every `/orchestrate-end`** — this section is NOT append-only. New entries carry an origin marker `(origin: YYYY-MM-DD <slice-id>)`.

_(Empty at project start; populated as Step-9 routing surfaces operational items.)_

---

## Deliverable map

| Deliverable | Status | Delivered by |
|---|---|---|
| <required deliverable 1> | ❌ / 🟡 / 🟢 | <phase> |
| <required deliverable 2> | ❌ / 🟡 / 🟢 | <phase> |

<!-- ▼ EXAMPLE BLOCK: deliverable map — replace rows with the project's real required outputs (docs, deployed app, reports, etc.). ▲ -->

---

## Phase exit checklist (template — applies to every phase)

Before ticking a phase complete:

- [ ] **All phase task checkboxes ticked.** Conservative — partial work stays unchecked with a Log entry note.
- [ ] **Acceptance criterion met.** `/preflight` clean + manual smoke if there's runtime behavior to validate.
- [ ] **`/preflight` clean.** Includes any architecture-invariant tests.
- [ ] **Cross-doc invariants verified.** No model field changes without a `{{ARCH_DOC}}` edit in the same round.
- [ ] **Session doc(s) for this phase exist** and list every file created/modified.
- [ ] **Commits pushed to {{GIT_REMOTE}}.**

---

## Final-submission acceptance criteria (project-level)

The project is "done" when:

- [ ] <project-level "done" condition 1>
- [ ] <project-level "done" condition 2>

---

## Phase {{PHASE_IDS}} — <phase name>

**Goal:** <one-paragraph goal>.

**Spec anchors:** `{{ARCH_DOC}} §X`, §Y.

### <phase-id>.1 — <task name>

<!-- ▼ EXAMPLE BLOCK: task entry format — dense checkbox bullets, NOT a pre-written brief. The orchestrator authors the /tdd brief from this entry + carry-forward + recent context. ▼ -->

- [ ] <acceptance behavior 1>
- [ ] <acceptance behavior 2>
- [ ] Files: <concrete paths — NEW vs. extended>
- [ ] Cross-doc invariant: <NEW / extended / none>

<!-- ▲ END EXAMPLE BLOCK ▲ -->

### <phase-id>.2 — <task name>

- [ ] ...

### Acceptance criteria (<phase-id>)

- [ ] All <phase-id>.X task checkboxes ticked.
- [ ] <phase-specific criteria>

---

<!-- Repeat the phase block for each phase in the plan. -->

---

<!-- ▼ EXAMPLE BLOCK: OPTIONAL Demo phase — include ONLY if a demo / live walkthrough is an explicit deliverable (check the Build posture in {{ARCH_DOC}}: production-grade usually OMITS it; MVP/prototype makes it the natural near-final slice). Delete this block when no demo is in scope. ▼ -->

## Phase D — Demo (OPTIONAL)

> **Optional phase.** A demo never substitutes for the invariant → lifecycle → test → hardening work above — it sits *after* the system is correct. Under a production-grade posture, prefer a deployable/operable slice and omit this phase.

**Goal:** <the narrowest end-to-end path the demo must prove>.

**Spec anchors:** `{{ARCH_DOC}} §X`.

### D.1 — <demo slice>

- [ ] <demo happy-path behavior that runs end-to-end>
- [ ] Files: <demo entrypoint / seed data / script — NEW vs. extended>
- [ ] Cross-doc invariant: none

### Acceptance criteria (D)

- [ ] The in-scope demo path runs end-to-end against the real system (no mocks on the load-bearing path).
- [ ] No invariant / test / hardening task was cut to make the demo work.

<!-- ▲ END EXAMPLE BLOCK ▲ -->

---

## Trims / Nice-to-Haves Catalog

Deferred items with come-back guidance: why deferred, where it belongs, files to modify, tests to add, cross-doc invariant impact.

_(Empty at project start; populated as scope cuts surface.)_

---

## Decisions tabled

Open scope/design questions awaiting resolution, with rationale.

_(Empty at project start.)_

---

## Log

Append-only, date-stamped, the orchestrator's framing of each round.

_(Empty at project start; populated at every `/orchestrate-end`.)_
