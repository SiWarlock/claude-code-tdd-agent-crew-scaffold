# M-0015 — Plan-doc compaction to the 2026-07 one-checkbox State-line standard

> `accreted-format` migration — the ONLY kind allowed to rewrite accreted tracker bodies (precedent:
> M-0005). Converts an existing project's `IMPLEMENTATION_PLAN.md` (or `{{TASK_TRACKER}}`) from the
> old multi-checkbox / inline-Log format to the standard the updated templates generate and
> `plan-lint.sh` (M-0014) enforces. Human-applied PROPOSE checklist — the prose→State-line mapping
> requires judgment; the lint is the mechanical completion backstop.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0015",
  "title": "Plan-doc compaction: inline Log -> docs/archive/IMPLEMENTATION_LOG.md, checklists -> Gate: pointers, tasks -> one State line, Carry-forward drained, format-contract header + Owner-gates section",
  "introducedAtSha": "98e2094597499085a037e33605103f7c8d1f4456",
  "kind": "accreted-format",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "accreted:plan-format-2026-07@v1",
  "touches": ["IMPLEMENTATION_PLAN.md", "docs/archive/IMPLEMENTATION_LOG.md", "docs/archive/phase-exit-*.md"]
}
```

(No `hosts` filter — format is host-neutral.)

## What changed upstream, and why

The 2026-07-19 RCA on a degraded downstream tracker (1,812 → 4,283 lines, zero net-prunes, state
divorced from checkboxes — a phase certified COMPLETE with 0/7 boxes ticked) traced six pathologies
to the old format + un-enforced caps. The templates now generate: a format-contract header; ONE
state-checkbox line per task; an archive-only Log (`docs/archive/IMPLEMENTATION_LOG.md`); phase-exit
checklists materialized in `docs/archive/phase-exit-<phase>.md` behind a one-line `**Gate:**`
pointer; a ≤3-item REPLACED Currently-in-progress; a ≤7-item delete-not-annotate Carry-forward with
per-phase `#### Residuals` overflow; an `## Owner gates & arming ledgers` section. Existing projects
must be compacted once to match — the template merge cannot do it (the tracker body is accreted /
leave-alone).

## Detection / no-op (already-migrated projects)

Skip (journal `.done`, no changes) when BOTH hold:
1. `docs/archive/IMPLEMENTATION_LOG.md` exists, AND
2. `scripts/plan-lint.sh {{TASK_TRACKER}}` exits 0.

(The reference downstream repo — SoW-build — was compacted 2026-07-19 during the RCA cleanup and
satisfies this; M-0015 selects there and no-ops cleanly.)

## Handler steps (PROPOSE checklist — human-applied, sampled before/after)

1. **Archive extraction (verbatim, zero-loss):** copy the tracker's `## Log` content + any round
   narratives parked in "Currently in progress" + any materialized phase-exit checklists + the old
   Carry-forward into `docs/archive/IMPLEMENTATION_LOG.md` as typed parts (verbatim line ranges —
   never paraphrase). Materialized checklists may alternatively land as
   `docs/archive/phase-exit-<phase>.md` per gate.
2. **Verify-before-flip (recommended, per the reference cleanup):** claimed states should be
   verified against the repo (commits/tests/audits) before rewriting — at minimum, do not mark a
   task DONE on prose alone; anything not verifiably done STAYS in the live plan (open/partial),
   never archive-only.
3. **Task conversion:** each `### N.M` task gets ONE state line as its first content line
   (`- [x] DONE · `hash` · date` / `- [~] PARTIAL · landed…; remaining… → target` / `- [ ] OPEN` /
   `- [ ] DEFERRED → … · owner-ref` / `- [ ] OWNER-GATED ⛔ Owner-Gates §ARM-…`); metadata bullets
   become plain `**Kind:**/**Spec:**/**Depends:**/**Blocks:**/**Files:**` lines; state tokens leave
   headings; every task carries a `**Spec:**` anchor or explicit `arch_gap`.
4. **Living sections:** replace "Currently in progress" with a ≤3-item snapshot; drain Carry-forward
   to ≤7 (resolved DELETED with archive pointers; live overflow → owning phase `#### Residuals`);
   add the format-contract header + `## Owner gates & arming ledgers` (collect any owner
   ledgers/hard-lines buried in narratives); replace the `## Log` section with the 2-line archive
   pointer stub.
5. **Backstop:** `scripts/plan-lint.sh {{TASK_TRACKER}}` must exit 0; sample 3–5 tasks before/after
   (hash resolves, state matches evidence). Journal `M-0015.done`.

## Ordering

Apply **after M-0014** (same SHA window, id-ordered) — the lint is this migration's completion
gate.

## Idempotency & journal

The detection rule makes re-runs no-ops; partial application resumes from the lint's violation list.

## Risk & gating

**HIGH** — rewrites the project's central tracker body. Human-gated PROPOSE with before/after
sampling at PAUSE 1; the verbatim archive step precedes any pruning so nothing is lost even on a
botched pass (git + archive both hold the pre-state).
