---
name: tasks-gen
description: >-
  Decompose the finalized ARCHITECTURE.md into an extremely prescriptive, spec-anchored IMPLEMENTATION_PLAN.md that
  the /tdd agent-team engine implements against. Every phase references the ARCHITECTURE.md anchors it
  implements; every task carries Files (NEW/extended), a cross-doc-invariant tag, and happy/edge/error/
  integration test scenarios. Runs on Claude Code. Flags (never invents) tasks that need absent
  architecture. Invoke when the user says "generate the tasks", "make the implementation plan", "decompose the
  architecture into tasks", or after /arch-finalize has produced the binding ARCHITECTURE.md.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Task
---

# tasks-gen — ARCHITECTURE.md → spec-anchored IMPLEMENTATION_PLAN.md (Brain 2)

You are the **third** stage of the planning chain. The binding `ARCHITECTURE.md` contract exists (from
`/arch-finalize`). Your job: produce the **prescriptive, spec-anchored `IMPLEMENTATION_PLAN.md`** that the `/tdd`
agent-team engine will implement against — prescriptive enough that an implementer never has to guess,
and anchored so drift surfaces structurally at TDD Step 9.

**You do not write application code, and you do not modify `ARCHITECTURE.md`** (it's the binding contract).

---

## 1. Read the inputs

1. **`ARCHITECTURE.md`** (repo root) — **PRIMARY.** This is the source you decompose; every task anchors
   to its `§<N>` sections and Appendix A models. Read it fully, including the **`Build posture:`** line in the
   executive summary (`production-grade` | `MVP/prototype` — it sizes the build order, whether to emit the
   optional Demo phase, and how aggressively to defer; see §2), **`§2.5` — the subsystem dependency DAG /
   parallelization seams** (the input you derive parallel build **tracks** from; see §2), and the Spec Anchor
   Index.
2. **`references/implementation-plan-template.md`** — the canonical `IMPLEMENTATION_PLAN.md` format + the **spec-anchor
   convention** + living-state sections. The file you write MUST match this structure so the orchestrator,
   `/orchestrate-start`, and the cross-doc-invariants flow all work.
3. **Supporting planning artifacts** (`docs/planning/*`, if present) for richer, more prescriptive tasks:
   `REQUIREMENTS.md` / `PRESEARCH.md` (acceptance criteria + req IDs), `DECISIONS.md` (locked choices),
   `RISKS.md` / `THREAT_MODEL.md` (safety-critical ordering), `DIAGRAM_PLAN.md` / `DATA_MODEL.md` (flows +
   models for scenario detail).

**Tools (use when available):** if a docs MCP (e.g. Context7) is present, use it to confirm library/API specifics when writing test scenarios; prefer a code-intelligence MCP (e.g. CodeGraph) over `grep` when tracing existing code. Optional — no-op if absent.

---

## 2. Decompose into phases + tasks

Generate `IMPLEMENTATION_PLAN.md` per the template. Rules:

- **Phases.** Each `## Phase` block carries a `**Spec anchors:**` line listing the `ARCHITECTURE.md §`
  sections it implements, a one-line Goal, and per-phase Acceptance criteria.
- **Tasks.** Dense checkbox bullets (not pre-written briefs — the orchestrator authors the `/tdd` brief).
  Each task carries:
  - a **`Files:`** line — which files are NEW vs extended;
  - a **`Cross-doc invariant:`** line — `NEW` / `extended` / `none` (a typed model that must mirror
    `ARCHITECTURE.md` Appendix A + the area `CLAUDE.md` invariants table);
  - **test scenarios** — happy / edge / error / integration (these become the Step-2.5 test designs).
- **Build order (posture-aware) = invariants → lifecycle correctness → tests → [optional: walking-skeleton /
  local demo — ONLY if a demo is in scope] → hardening/polish.** Order tasks so load-bearing invariants and
  lifecycle correctness come first, polish last (per the playbook's handoff rule). Safety-critical pins (from
  `RISKS.md` / `THREAT_MODEL.md`) get their own early tasks. Honor the **Build posture** recorded in the
  `ARCHITECTURE.md` executive summary (§1):
  - **production-grade** → promote production concerns (error paths, idempotency, observability, security
    pins, deploy/rollback) to first-class **early** tasks, not deferred. **Do not** emit a demo phase unless
    the architecture explicitly calls for one.
  - **MVP / prototype** → IF a demo is in scope, a lean local-demo slice is the natural near-final step (still
    the optional Demo phase, never folded into the spine); deeper hardening may be deferred (and flagged as a
    deferral).
  When a demo IS in scope, emit it as the clearly-labelled **optional Demo phase** from the template (the
  `optional-demo-phase` block) — never fold it silently into the mandatory spine.
- **Trace requirements → tasks.** Every **in-scope** requirement (REQ-* / acceptance signal — sized to the
  chosen build posture) should map to at least one task; surface any requirement with no task.
- **Dependency graph + parallel tracks (proactive).** The build-order bullet above gives the *default serial
  spine*; this makes the **true partial order** explicit so independent work can be unstacked into parallel
  tracks (each runnable in its own git worktree + agent team — see `/team-start <track>`):
  1. **Per-task deps.** Every task carries a **`Depends on:`** line (task IDs, or `none`) — derived from
     data/contract flow (a task consuming an Appendix-A model depends on the task that defines it), NOT from
     sequential-by-habit ordering. The dependency graph is the build-order spine *minus* edges that are merely
     sequential rather than sequential-by-contract.
  2. **Tracks from the architecture, refined by the graph.** Tracks are **phase-level**, derived from
     `ARCHITECTURE.md` **§2.5** (the subsystem dependency-DAG + independent-subsystem callout), then refined by
     the task dep graph — a "seam" the graph shows is actually serially coupled collapses into one track; a
     phase that splits cleanly along a contract seam can become two. Tag each phase with `**Track:**` + a
     phase-level `**Depends on (phases):**` edge.
  3. **Phase/track DAG + critical path.** Build the phase/track DAG, mark the **critical path** (the longest
     dependency chain — the serial floor on build time) and any **forced-serial bottleneck** (a phase every
     track waits on — typically the shared-contract / schema phase).
  4. **Posture-aware sizing.** Under **production-grade**, tracks are real (e.g. a security/observability track
     parallel to feature tracks); under **MVP/prototype**, keep it lean — a **single track is a valid answer**,
     recorded as such (don't over-parallelize a small build).
  Encode the result in the template's **`## Parallelization plan`** (Track map) section: the DAG, the critical
  path, and the `track → phases → area(s) → worktree → team-name (<track>-<area>-<role>)` table that
  `/team-start <track>` consumes. **Team mode only** — single-operator builds walk the DAG serially in one tree.

### Workflow-or-serial

If Ultracode / the Workflow tool is available, you may fan out per-phase decomposition + a
requirement-coverage check **+ the dependency-graph / track derivation (run after the per-phase fan-out
merges, since it reads every phase's deps)** in parallel and merge; otherwise do it serially (via `Task` or
inline). Same result either way.

---

## 3. The cardinal rule — flag, never invent

If a task would require **architecture that isn't in `ARCHITECTURE.md`**, do **not** invent it. Stop and
surface it: *"Task X needs architecture not in the contract — §? is missing. Add it to ARCHITECTURE.md
(re-run /arch-finalize) before I add this task."* The architecture is the contract; tasks may not exceed
it. (`AskUserQuestion` to let the user choose: amend the contract, defer the task, or descope.)

---

## 4. Optional review (tagged OPTIONAL)

- **CE `ce-doc-review`** on the generated `IMPLEMENTATION_PLAN.md` — catches self-contradiction + scope drift
  pre-code. Harvest findings; you author the file.
- **gstack `/spec`** (downstream, optional) — export individual tasks to backlog-ready GitHub issues. An
  export convenience, not a replacement for the living tracker.

---

## 5. Human gate

Present a compact summary (phases, task counts, **the Track map: N tracks, the critical path, and any
forced-serial bottleneck phase**, any requirements with no task, any architecture gaps you hit) and confirm
scope before finalizing — Path A auto-proceed for a clean decomposition, Path B confirm if anything is
ambiguous or you had to flag a gap. **If the plan yields >1 track** (parallel worktrees/teams are
recommended), surface the `track → worktree → team-name` map + the critical path explicitly and **confirm the
parallel build strategy (Path B)** — spinning up N worktrees + N teams is an operational decision, not a
silent default. A single-track plan stays Path A.

---

## 6. Hard rules (forbidden)

- **No application code; don't modify `ARCHITECTURE.md`.**
- **Never invent architecture** to satisfy a task — flag it (§3).
- **Every task anchors to the contract.** No orphan tasks; no phase without `Spec anchors:`.
- **`IMPLEMENTATION_PLAN.md` living-state sections start empty** (Currently-in-progress, Carry-forward, Log,
  Decisions-tabled) — they accrete through real `/tdd` work, not at generation. **The `Parallelization plan`
  (Track map) is the exception among new sections: it IS authored at generation** (it's plan structure, like
  the Deliverable map + phase blocks), not accreted living state.

---

## 7. Output & handoff

> **IMPLEMENTATION_PLAN.md generated** (repo root) — `<N>` phases, `<M>` tasks, every phase anchored to
> `ARCHITECTURE.md`. `<K>` requirements with no task / `<J>` architecture gaps flagged (listed). `<T>` parallel
> tracks identified (critical path: `<phase chain>`; `<B>` forced-serial bottleneck phase(s)) — recorded in the
> **Parallelization plan** (Track map).
> **Next:** run **`/scaffold-generate`** to personalize the agent-team harness into the project, then
> **`/team-start <track>` per parallel track** (each scopes that track's phases + sets up its worktree) — or a
> single `/team-start` / `/orchestrate-start` solo for a single-track plan — and the **`/tdd`** engine builds
> it slice by slice.

Then stop.
