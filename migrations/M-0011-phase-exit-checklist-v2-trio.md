# M-0011 — Phase-exit checklist v2: the posture-gated production trio (audit / security / perf)

> The tracker's checklist template gained three **posture-gated** rows — dependency audit
> (new-vs-baseline), whole-system security review (policy-resolved executor), and perf budgets.
> Same mechanism as M-0009; this one is additionally **filtered by the manifest `posture` field**
> (M-0006), which is why M-0006 runs first in any shared window.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0011",
  "title": "Phase-exit checklist v2: posture-gated dependency-audit, whole-system-security, and perf-budget rows",
  "introducedAtSha": "<set by the follow-up wiring commit — the W4-6 commit>",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "section:IMPLEMENTATION_PLAN:phase-exit-v2-trio@v1",
  "touches": ["IMPLEMENTATION_PLAN.md", "manifest.placeholders"]
}
```

## What changed upstream, and why

Three rows + a posture-gating comment in the "Phase exit checklist (template)" block (see
`templates/IMPLEMENTATION_PLAN.md`). `/phase-exit` executes whatever rows the tracker carries, so no
command change is needed — the rows ARE the feature. The dependency row introduces the
`{{AUDIT_CMD}}` placeholder (may be `null` when N/A).

## Handler steps

1. **Idempotency pre-check:** if the tracker's checklist template already contains
   "Dependency audit: no NEW findings", journal `.done` and stop.
2. **Posture filter (mechanical when possible):** read `posture` from the manifest (schema v2).
   `production-grade` → offer all three rows pre-selected; `MVP/prototype` → offer them
   de-selected (recordable opt-in); **`unknown` (v1 manifest)** → fully human-gated, ask per row.
   Record each answer in the manifest (mirrors the generation-time gate-pack).
3. **`{{AUDIT_CMD}}`:** ask for the project's dependency-audit command (e.g. `npm audit`,
   `pip-audit`, `cargo audit`) or `null`; add to `manifest.placeholders`. Never fabricate.
4. Insert the accepted rows + the gating comment verbatim from the new template (incomplete phases
   may also opt in per-phase, as in M-0009 step 3; completed phases are history). Show the diff;
   apply on approval.
5. Journal `.scaffolding/.migrations/M-0011.done`.

## Idempotency & journal

The "Dependency audit: no NEW findings" probe + `.done`; per-row presence checks make re-entry safe.

## Risk & gating

**MED** — adds gate rows that change what a phase needs to close; human-gated, posture-filtered,
per-row recorded. Never silently applied (the always-ask rule).
