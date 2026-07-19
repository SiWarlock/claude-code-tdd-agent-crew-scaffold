# M-0014 — Install `scripts/plan-lint.sh` (the `/orchestrate-end` Step-6.5 plan-format gate)

> `added-template` migration delivering the structural lint for the one-checkbox State-line plan
> standard (see M-0015 for the companion format migration of the tracker body itself). Precedent:
> M-0007 (spec-lint.sh delivery).

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0014",
  "title": "Install scripts/plan-lint.sh — the /orchestrate-end Step-6.5 blocking plan-format gate",
  "introducedAtSha": "98e2094597499085a037e33605103f7c8d1f4456",
  "kind": "added-template",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "added:plan-lint.sh@v1",
  "touches": ["scripts/plan-lint.sh", "manifest.generatedFiles"]
}
```

(No `hosts` filter — the tracker + `/orchestrate-end` exist on both hosts; the script must reach
Claude AND Codex projects.)

## What changed upstream, and why

The 2026-07-19 downstream RCA (`docs/plans/2026-07-19-rca-fix-application-plan.md`) showed the plan
doc's caps and format rules eroded because **nothing enforced them mechanically** — 156 tracker
commits, zero net-prunes, a 4,283-line doc. `templates/scripts/plan-lint.sh` is the enforcement:
section caps (≤3-item Currently-in-progress, ≤7-item Carry-forward, pointer-only Log), exactly one
state-checkbox line per `### N.M` task (`DONE `hash` date` / `PARTIAL remaining:` / `OPEN` /
`DEFERRED` / `OWNER-GATED §ARM-*`), no state tokens on headings, a `**Spec:**` anchor or `arch_gap`
per task, Owner-Gates ledger integrity, numeric heading order. `/orchestrate-end` now runs it as the
blocking **Step 6.5** before staging; committing a non-zero round is Forbidden.

## Handler steps

1. **Idempotency pre-check:** skip if `.scaffolding/.migrations/M-0014.done` exists or
   `scripts/plan-lint.sh` already exists (record `divergence: pre-existing` if its content is
   unrelated).
2. Substitute placeholders from the manifest (`{{TASK_TRACKER}}` — the script's bare-run default
   argument), write `scripts/plan-lint.sh`, `chmod +x`.
3. Append its `generatedFiles[]` row: `{dest: "scripts/plan-lint.sh", template:
   "templates/scripts/plan-lint.sh", kind: "placeholder-only"}`.
4. Journal `M-0014.done`.

## Coupling

Ships in the same window as the `/orchestrate-end` Step-6.5 edit (same `introducedAtSha`) — the
command references the script; delivering one without the other leaves either a dangling reference
or an unused script. **Note:** on a tracker that has NOT yet been compacted to the new standard
(M-0015 pending), the lint will exit non-zero by design — apply M-0015 before relying on the
Step-6.5 gate, or expect the first `/orchestrate-end` to stop at Step 6.5.

## Idempotency & journal

Presence check + `.done` touchfile; re-run is a no-op.

## Risk & gating

**LOW-MED** — additive file, but it changes `/orchestrate-end` behavior (a blocking gate that fails
on the old format until M-0015 lands); human-gated so the operator sequences M-0015 consciously.
