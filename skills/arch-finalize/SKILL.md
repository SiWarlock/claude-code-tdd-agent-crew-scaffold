---
name: arch-finalize
description: >-
  Take the rough architecture draft + ALL planning artifacts produced by /arch-draft, run a second-pass
  gap audit and adversarial scrutiny against the PRD, and produce the binding, anchored ARCHITECTURE.md
  contract from the repo's architecture template. Runs on Claude Code (Opus 4.8) as Brain 2 — a different
  model than the one that drafted, on purpose. Uses Ultracode workflows for the gap-audit fan-out when
  available, with a serial fallback. Invoke when the user says "finalize the architecture", "run the gap
  analysis", "scrutinize the architecture draft", or after /arch-draft has written docs/planning/.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Task
---

# arch-finalize — gap-audit + adversarial scrutiny → the binding contract (Brain 2)

You are the **second** stage of the cross-model planning chain. A *different* model (GPT-5.5/Codex, via
`/arch-draft`) produced a rough draft + planning artifacts. Your job is to **adversarially finalize** it:
find what's missing or wrong against the PRD, resolve it with the human, and produce the **binding,
anchored `ARCHITECTURE.md`** that the whole downstream workflow (tasks, TDD crew, cross-doc invariants)
will bind to. Two independent brains over the doc — that's the point.

**You do not write application code, and you do not generate `IMPLEMENTATION_PLAN.md`** (that's `/tasks-gen`).

---

## 1. Read everything (the draft is NOT your only input)

1. **The PRD / product brief** (ask for the path if not obvious) — the ground truth for the audit.
2. **All of `docs/planning/*`** — *every* artifact the draft's mode produced, not just the architecture
   draft. List and read them: `ls docs/planning/` then read each. Depending on mode this includes
   `ARCHITECTURE_DRAFT.md`, `PRESEARCH.md`, `RESEARCH.md`, `DECISIONS.md`, `DIAGRAM_PLAN.md`,
   `CLAUDE_CODE_HANDOFF.md`, and (Expanded) `REQUIREMENTS.md`, `THREAT_MODEL.md`, `DATA_MODEL.md`,
   `USERS.md`, `CONSTRAINTS.md`, etc. The gap audit is *only possible* against these source artifacts —
   the draft alone can't tell you what it's missing.
3. **`CLAUDE_CODE_HANDOFF.md`** — the instruction set the draft wrote for you. Follow it; the audit
   dimensions below are the canonical list if the handoff is thin.
4. **`references/architecture-template.md`** — the repo's canonical `ARCHITECTURE.md` structure (open-ended
   `§<N>` anchors, the Spec Anchor Index, **Appendix A — model/contract inventory**). The finalized doc
   you write MUST conform to this structure so downstream tooling (IMPLEMENTATION_PLAN spec-anchors, the cross-doc
   invariants table, `/check-arch`) works.

**Tools (use when available):** when reading existing code during the audit, prefer a code-intelligence MCP (e.g. CodeGraph) over `grep`+read loops; for external-dependency facts (dimension 6 below), prefer a docs MCP (e.g. Context7) over memory. Both optional — skip silently if absent.

---

## 2. The gap audit (~13 dimensions)

**First, read the Build posture** recorded in `CLAUDE_CODE_HANDOFF.md` (and the draft header):
`production-grade` | `MVP/prototype`. **The audit is judged against that posture** — under
**production-grade**, dimensions 9 (testing) and 10 (deploy/rollback) are **required** (not nice-to-have) and
dimension 8a applies; under **MVP/prototype**, deliberate deferrals are acceptable if flagged. Audit the
draft + artifacts against the PRD across these dimensions, bucketing every finding as
**critical / important / nice-to-have / proposed-edit / question-for-human**:

1. Missing user/lifecycle **flows** (every in-scope requirement maps to a flow).
2. Missing **lifecycle states** / state-machine transitions.
3. Unhandled **failure modes** / error paths.
4. Underspecified **interfaces / schemas / data contracts**.
5. Unclear **source-of-truth** for any piece of state.
6. **Unresearched external deps** (pricing, limits, auth, legal) — anything `RESEARCH.md` left open.
7. **Inconsistent or unlocked decisions** (a `DECISIONS.md` entry that contradicts the draft, or a
   load-bearing decision still tagged `open`).
8. **Overbuilt scope (posture-relative)** — under **MVP/prototype**, flag anything beyond the agreed scope
   that should be deferred. Under **production-grade**, judge "overbuilt" against the *agreed scope*, NOT
   against an MVP yardstick — do not push to defer correctness/operability work.
8a. **Under-built for the posture** (production-grade) — flag *missing production concerns* as **critical**
    gaps: error paths, idempotency, observability/logging, authn/z, input validation, secrets handling,
    deploy/rollback. A shortcut that's fine for an MVP is a gap for a production-grade build.
9. Missing **testing strategy** / untestable designs.
10. Missing **deployment / rollback path**.
11. Missing **security / trust boundaries** (cross-check `THREAT_MODEL.md` if present).
12. Missing **diagrams** the design needs (cross-check `DIAGRAM_PLAN.md`).
13. **Missing or unstable task-planning anchors** — every load-bearing section needs a stable `§<N>`
    anchor so `tasks-gen` and the cross-doc-invariants table can reference it.

### Run it as a workflow when you can, serial otherwise

- **If Ultracode / the Workflow tool is available** (you're on Claude Code with `/effort ultracode`, or you
  can author a dynamic workflow): structure the audit as a **perspective-diverse verifier fan-out** — one
  agent per dimension above, each reading the relevant artifacts and returning structured findings
  (`{dimension, severity, finding, evidence, proposed_fix}`), plus a **completeness critic** that asks
  "what whole category did we miss?" Write each finding set to `docs/gap-audits/NNN.json` so it persists
  past the ephemeral workflow.
- **Otherwise (serial fallback):** dispatch the same dimensions as sequential subagents via the `Task`
  tool, or work through them inline. Same dimensions, same output buckets — Ultracode is a speedup, never
  a correctness dependency.

---

## 3. Optional cross-model + multi-lens review (tagged OPTIONAL)

These *widen the net* but are **advisory** — your anchor/invariant-coverage audit (§2) stays the
verification of record, because these tools produce no anchors to check against:

- **gstack `/codex`** — brings GPT-5.5 (Brain 1) back as an independent cross-vendor reviewer of the
  *finalized draft*. Agreement is a confidence signal, not a decision.
- **gstack `/plan-eng-review`** — multi-lens architecture review (data-flow/ASCII diagrams, failure
  scenarios, test matrix). Harvest its findings into your buckets; do **not** let it author the doc.
- **CE `ce-doc-review`** — coherence / feasibility / scope-guardian lenses on the doc.

Run these only if installed and the stakes warrant it; fold their findings into the §2 buckets. **Never
route the binding contract *through* a generative planner** (e.g. gstack `/autoplan` writes its own plan).

---

## 4. Human gate — confirm load-bearing changes before writing

Mirror the scaffolding's two-PAUSE discipline. Present the bucketed findings to the user (critical first),
and **`AskUserQuestion` on every load-bearing change** (one decision at a time, with a recommendation +
why). Apply confirmed edits; record any the user defers. Do **not** silently resolve a load-bearing gap or
fabricate a missing value — surface it. (A "work without stopping" instruction does not override this
gate; it scopes to clarifying questions.)

---

## 5. Produce the binding `ARCHITECTURE.md`

Write the finalized **`ARCHITECTURE.md` at the repo root**, conforming to `references/architecture-template.md`:

- The canonical section structure with **stable `§<N>` anchors** + a **Spec Anchor Index**.
- **Appendix A — model/contract inventory:** every typed model that is a cross-doc invariant (this is what
  the area `CLAUDE.md` cross-doc-invariants table and `IMPLEMENTATION_PLAN` anchors will mirror).
- Content drawn from the draft + planning artifacts + the confirmed gap-audit fixes. Decisions reflected
  as **locked** (with their `DECISIONS.md` rationale); remaining `open` items called out explicitly.
- A `Build contract` line at the top: downstream skills treat this file as the source of truth.
- A **`Build posture:` line** in the Executive summary (`production-grade` | `MVP/prototype`, carried from the
  handoff) — `tasks-gen` and the `/tdd` engine read it to size the build order, the demo (optional), and how
  aggressively to defer. Do not drop or silently change the posture; if the audit surfaced a reason to revisit
  it, raise it at the §4 human gate.

This file is the **binding contract** — it is owned by this skill; gstack/CE never author it.

---

## 6. Hard rules (forbidden)

- **No application code; no `IMPLEMENTATION_PLAN.md`.** Finalize the architecture only.
- **Don't fabricate.** An unresolved gap is a `question-for-human`, never an invented answer.
- **Don't let an external reviewer or generative planner become the contract.** Harvest findings; you
  author `ARCHITECTURE.md`.
- **Preserve anchor stability.** Don't renumber `§` anchors gratuitously — downstream references bind to them.

---

## 7. Output & handoff

> **ARCHITECTURE.md finalized** (repo root). Resolved `<N>` critical / `<M>` important findings; `<K>`
> items deferred (listed). Gap-audit detail in `docs/gap-audits/`. **Next:** run **`/tasks-gen`** to turn
> this contract into the spec-anchored `IMPLEMENTATION_PLAN.md`, then `/scaffold-generate` to personalize the
> agent-team harness, then the `/tdd` engine builds it.

Then stop.
