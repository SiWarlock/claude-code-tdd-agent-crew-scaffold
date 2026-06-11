# M-0005 — Retrofit `[id=]` block slugs + bounded-section rules into tasks-gen-authored trackers

> Closes a drift window: between 1f6cf8e (canonical `templates/IMPLEMENTATION_PLAN.md` gained stable
> `[id=<slug>]` EXAMPLE-BLOCK markers + bounded living-section rules) and the 2026-06-10 pair sync, the
> bundled `skills/tasks-gen/references/implementation-plan-template.md` was stale — so **trackers authored
> by `/tasks-gen` in that window lack the slugs and the bounded-section rules**, while trackers authored by
> scaffold-generate Step 4 already have them. The idempotency pre-check makes both populations safe.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0005",
  "title": "Retrofit [id=] EXAMPLE-BLOCK slugs + bounded living-section rules into the task tracker",
  "introducedAtSha": "<set by the follow-up wiring commit — the W1-1 pair-sync commit>",
  "kind": "accreted-format",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "tracker-structure:id-slugs+bounded-sections@v1",
  "touches": ["IMPLEMENTATION_PLAN.md", "manifest.exampleBlocks"]
}
```

## What changed upstream, and why

Canonical `templates/IMPLEMENTATION_PLAN.md` (since 1f6cf8e/a7d3cbb) carries:

1. **Paired `[id=<slug>]` EXAMPLE-BLOCK markers** — `deliverable-map`, `parallelization-plan` (team mode),
   `task-entry-format`, `optional-demo-phase` — each with an opening `▼ EXAMPLE BLOCK [id=…]` line **and** a
   closing `▲ END EXAMPLE BLOCK [id=…]` line. `/scaffold-upgrade` keys per-region merges on these ids.
2. **Bounded living-section rules**: the header **Reading discipline** paragraph (sectioned reads), the
   Carry-forward **~7-item cap + force-triage** rule, the Currently-in-progress **REPLACE-don't-append**
   comment, the **bounded Log** (~10 rounds → `docs/archive/TASKS-LOG.md`), Trims pruning, and the
   Decisions-tabled move-to-Log rule.

A tracker authored from the stale bundled template has single-line, slug-less block markers and append-only
living sections. A plain 3-way merge cannot express this: the tracker is **accreted** (its body is real
project state), so the content diff deliberately leaves it alone.

## Handler steps

1. **Idempotency pre-check:** if `.scaffolding/.migrations/M-0005.done` exists, or the tracker already
   contains all applicable `[id=]` opening **and** `END EXAMPLE BLOCK [id=]` closing markers *and* the
   "Reading discipline" header paragraph — journal `.done` and stop.
2. **Marker retrofit (deterministic):** for each EXAMPLE BLOCK present in the tracker, rewrite its opening
   marker to the canonical `[id=<slug>]` form and add/normalize the matching `END EXAMPLE BLOCK [id=<slug>]`
   closing line. Slug assignment is positional-by-section (deliverable map → `deliverable-map`, Track map →
   `parallelization-plan`, task-entry format comment → `task-entry-format`, demo phase → `optional-demo-phase`).
   **Marker lines only — never touch block contents.**
3. **Bounded-section rules (skeleton insert, PROPOSE):** show the user a unified diff inserting the
   Reading-discipline paragraph, the Carry-forward cap sentence, the Currently-in-progress REPLACE comment,
   and the bounded-Log/Trims/Decisions rule lines, copied verbatim from `templates/IMPLEMENTATION_PLAN.md`.
   Apply only on approval. **Never reflow, re-order, or summarize existing task/phase/Log content.**
4. **Manifest:** ensure `manifest.exampleBlocks[]` has one row per retrofitted region, keyed by `[id=]`
   (status `customized` if the project filled it, `illustrative` otherwise).
5. Journal `.scaffolding/.migrations/M-0005.done`.

## Idempotency & journal

Re-running detects "already applied" via the marker + header-paragraph check in step 1 and the `.done`
touchfile. Steps 2–4 are each individually re-runnable (a marker already in canonical form is left as-is;
an existing manifest row is not duplicated), so an interrupted upgrade resumes safely.

## Risk & gating

**MED.** Touches an accreted body (the project's live tracker), hence `accreted-format` + **human-gated**
with a before/after sample per the kind's rules. The deterministic surface is marker lines only; all prose
insertions go through an explicit PROPOSE diff. No content is fabricated — every inserted line is verbatim
template text.
