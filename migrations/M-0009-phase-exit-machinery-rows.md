# M-0009 — Add the three machinery rows to the phase-exit checklist (reachability / arch-drift / spec coverage)

> The tracker's "Phase exit checklist (template)" block gained three executable rows — and an
> "executed by `/phase-exit`" note — so the gate machinery installed by M-0007 has rows to execute.
> Same shape as M-0004 (a new-required-section on the accreted tracker).

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0009",
  "title": "Phase-exit checklist: add reachability-audit, arch-drift-audit, and spec-coverage rows (+ executed-by-/phase-exit note)",
  "introducedAtSha": "<set by the follow-up wiring commit — the W2-6 commit>",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "section:IMPLEMENTATION_PLAN:phase-exit-machinery-rows@v1",
  "touches": ["IMPLEMENTATION_PLAN.md"]
}
```

## What changed upstream, and why

`templates/IMPLEMENTATION_PLAN.md` "Phase exit checklist (template)" now carries:

- `- [ ] **Reachability audit clean per touched area** (\`reachability-auditor\`).`
- `- [ ] **Arch-drift audit clean over the phase's Spec anchors** (\`arch-drift-auditor\`).`
- `- [ ] **Spec coverage: every phase anchor has a tagged test or waiver** (\`scripts/spec-lint.sh tests <phase>\`).`

plus the header note that `/phase-exit <phase>` executes the checklist row-by-row, ticking each row as
it passes, dispatched at the START of a round. The tracker is **accreted** — the content diff leaves it
alone — so the rows reach existing projects only via this migration.

## Handler steps

1. **Idempotency pre-check:** if the project tracker's checklist template already contains
   "Arch-drift audit clean", journal `.done` and stop.
2. Insert the three rows (verbatim from the new template) into the "Phase exit checklist (template)"
   block, after the "Cross-doc invariants verified" row; update the header line with the
   executed-by-`/phase-exit` note. Show the diff; apply on approval.
3. Any phase sections that copied the OLD checklist and are **not yet complete**: offer to append the
   three rows there too (per-phase PROPOSE). **Completed phases are history — never retro-edit them.**
4. Journal `.scaffolding/.migrations/M-0009.done`.

## Idempotency & journal

The "Arch-drift audit clean" probe + `.done` touchfile. Step 3's per-phase inserts are individually
presence-checked.

## Risk & gating

**LOW-MED** — additive rows on an accreted file; human-gated per the new-required-section rule. Depends
on M-0007 having installed `/phase-exit`, `arch-drift-auditor`, and `spec-lint.sh` (selection order
guarantees M-0007 fires first — earlier introducedAtSha, same upgrade window).
