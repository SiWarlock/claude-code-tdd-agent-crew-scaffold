# MVP_TASKS.md — FixtureTracker

> **Phase note.** Two-phase MVP: P0 lands the ingestion spine (event intake → dedup → typed store), P1 the read API. Locked: Pydantic-strict models everywhere; no ORM (raw asyncpg). Refreshed when a major phase boundary is crossed.

> **Session protocol:**
> - **At session start** — orchestrator runs `/orchestrate-start`; implementer runs `/session-start`. Confirm with the user what's targeted this session.
> - **At session end** (only when the user says we're done):
>   - **Implementer** runs `/session-end` — TDD audit + cross-doc audit + Step-9 list + create session doc + `/preflight`. Does NOT touch this doc.
>   - **Orchestrator** runs `/orchestrate-end` — verify hot routing landed, reconcile checkbox state, append Log entry, update Decisions / Carry-forward / Currently in progress, **triage Carry-forward**, round commit + push.

> **Reference deadlines:**
> - P0 demo — 2026-06-12
> - P1 read API — 2026-06-20

> **Spec-anchor convention (architecture-as-contract).** Each phase header below carries a `**Spec anchors:**` block listing the `ARCHITECTURE.md` sections the phase implements. Orchestrator + implementer re-read the listed anchors at session start. If a slice surfaces a behavior the anchors don't cover, that's a cross-doc invariant flag at Step 9 — either the anchor is missing or the implementation has drifted. Architecture is contract; drift surfaces structurally, not silently.

---

## Currently in progress

**P0 underway.** P0.1 + P0.2 landed; P0.3 (typed store) is the next slice.

**Next session target:** P0.3.

<!-- Refreshed at every /orchestrate-end: last commit hash, suite count, next session target, anything blocking. -->

---

## Carry-forward to upcoming briefs

Items the orchestrator MUST fold into upcoming slice briefs. **Triaged at every `/orchestrate-end`** — this section is NOT append-only. New entries carry an origin marker `(origin: YYYY-MM-DD <slice-id>)`.

- Dedup-hash rule (LESSONS §1) must be cited in every ingestion-touching brief. (origin: 2026-06-02 P0.2)

---

## Deliverable map

| Deliverable | Status | Delivered by |
|---|---|---|
| Ingestion endpoint (dedup, typed) | 🟡 | P0 |
| Read API | ❌ | P1 |

<!-- ▼ EXAMPLE BLOCK [id=deliverable-map]: deliverable map — replace rows with the project's real required outputs (docs, deployed app, reports, etc.). ▼ -->
<!-- ▲ END EXAMPLE BLOCK [id=deliverable-map] ▲ -->

---

## Phase exit checklist (template — applies to every phase)

Before ticking a phase complete:

- [ ] **All phase task checkboxes ticked.** Conservative — partial work stays unchecked with a Log entry note.
- [ ] **Acceptance criterion met.** `/preflight` clean + manual smoke if there's runtime behavior to validate.
- [ ] **`/preflight` clean.** Includes any architecture-invariant tests.
- [ ] **Cross-doc invariants verified.** No model field changes without a `ARCHITECTURE.md` edit in the same round.
- [ ] **Session doc(s) for this phase exist** and list every file created/modified.
- [ ] **Commits pushed to origin.**

---

## Phase P0 — ingestion spine

**Spec anchors:** §2, §3.1
**Goal:** upstream events land deduplicated in a typed store.
**Acceptance criteria:** posting the same event twice yields one row; unknown payload keys are a 422.

- [x] P0.1 Intake endpoint skeleton. Files: app/main.py (NEW). Cross-doc invariant: none.
- [x] P0.2 Event-hash dedup. Files: app/ingest.py (NEW). Cross-doc invariant: none.
- [ ] P0.3 Typed store. Files: app/store.py (NEW), app/models.py (NEW). Cross-doc invariant: NEW.

## Phase P1 — read API

**Spec anchors:** §3.2
**Goal:** consumers can query stored events.
**Acceptance criteria:** filtered list endpoint with typed responses.

- [ ] P1.1 List endpoint. Files: app/read.py (NEW). Cross-doc invariant: extended.

---

## Decisions tabled

_(none)_

---

## Log

- 2026-06-02 — P0.1+P0.2 landed (commit abc1234); suite 14 green; next: P0.3.

---

## Trims

_(none)_
