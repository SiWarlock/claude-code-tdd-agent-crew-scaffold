# M-0004 — Add the `## Parallelization plan` (Track map) section to `IMPLEMENTATION_PLAN.md` (team mode only)

> Filled copy of `_TEMPLATE.md`. The matching entry is in `registry.json`.
> **One migration per file.** Append-only — never edit a shipped migration in place; fix with a NEW
> migration at a later SHA. SHA-window-gated (fires once when `base < introducedAtSha <= to`),
> idempotent, journaled (touchfile `.scaffolding/.migrations/M-0004.done`), per-migration failure non-fatal.

> **`introducedAtSha` is wired to the commit that ships the parallelization feature** —
> `a7d3cbbb86eef42976960edf0380edf6178ba181` (the commit that added the `[id=parallelization-plan]` block to
> `templates/IMPLEMENTATION_PLAN.md` and bumped the §10 region count to 26). It was set in a follow-up commit —
> the two-step pattern `a939bd0` used for M-0001/M-0002 and the M-0003 wire-up — since the shipping SHA can't
> be known until that commit exists.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0004",
  "title": "Add the '## Parallelization plan' EXAMPLE BLOCK (phase/track DAG + critical path) to IMPLEMENTATION_PLAN.md (team mode only)",
  "introducedAtSha": "a7d3cbbb86eef42976960edf0380edf6178ba181",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "section:IMPLEMENTATION_PLAN:parallelization-plan",
  "touches": ["IMPLEMENTATION_PLAN.md", "manifest.exampleBlocks"]
}
```

- **kind** = `new-required-section` — inserts a new `## Parallelization plan (Track map)` section, wrapped in
  the `<!-- ▼ EXAMPLE BLOCK [id=parallelization-plan] … ▼ -->` markers, into the tracker. A plain 3-way merge
  cannot do this: the tracker is classified **`accreted`** (its living body is never auto-touched), so the
  migration registry is the only path allowed to add a section to it — exactly M-0001's situation for the
  reviewer-policy section.
- **gate** = `human` — structural + accreted-file-touching. Insert the skeleton + markers; **never fabricate**
  the DAG/track content (the project fills it, or the operator may offer to derive it from `{{ARCH_DOC}}` §2.5
  + the dep graph).
- **Mode-gated: team only** — skip when the manifest's `mode == "single-operator"` (parallel tracks are a
  team-mode construct; a solo build walks the DAG serially and has no Track map). This is the one wrinkle vs.
  M-0001, which was unconditional.

## What changed upstream, and why

`IMPLEMENTATION_PLAN.md` gained a `## Parallelization plan (Track map)` section — the phase/track dependency
DAG + critical path + the `track → phases → area(s) → worktree → team-name` table that `/team-start <track>`
reads to run each independent track in its own git worktree with its own agent team. (`/tasks-gen` authors it
from `{{ARCH_DOC}}` §2.5 refined by the per-task `Depends on:` graph.) A plain 3-way merge can't add a section
to the `accreted` tracker, and the section is `[id=parallelization-plan]` EXAMPLE-BLOCK content the project
must fill — hence a migration. (The companion per-task `Depends on:` line lands purely via the updated
template + `/tasks-gen` for new tasks; back-filling it into existing task bodies is intentionally NOT migrated
— low value, high risk on accreted bodies.)

## Handler steps

**Idempotency + mode pre-check FIRST (skip the whole migration if ANY holds):**

1. `.scaffolding/.migrations/M-0004.done` exists, OR
2. `IMPLEMENTATION_PLAN.md` already contains the `[id=parallelization-plan]` marker (already applied), OR
3. `jq -r '.mode' .scaffolding/manifest.json` is `"single-operator"` — parallel tracks are team-only; report
   `"single-operator project — no Track map; skipping"` and stop, OR
4. the project's tracker file does not exist (nothing to add the section to).

**Then (model, human-gated):**

1. Insert the `## Parallelization plan (Track map)` section from the upgraded `templates/IMPLEMENTATION_PLAN.md`
   — the `<!-- ▼ EXAMPLE BLOCK [id=parallelization-plan]: … ▼ -->` markers + the skeleton (DAG + critical-path
   callout + track table + integration/merge order + shared-contracts line) — at the correct anchor: **after
   the `[id=deliverable-map]` block, before the `## Phase exit checklist`**. Never fabricate the project's
   actual DAG/tracks; insert the skeleton marked for the project to fill (the operator MAY offer to derive it
   from `{{ARCH_DOC}}` §2.5 + the task dep graph, with confirmation).
2. Add the `exampleBlocks[]` row to `.scaffolding/manifest.json`:
   `{ "file": "IMPLEMENTATION_PLAN.md", "id": "parallelization-plan", "status": "illustrative" }` (the
   sanctioned manifest-edit path; `touches: manifest.exampleBlocks`). No `generatedFiles[]` change (the file
   already exists), no placeholder change, no `schemaVersion` bump (`exampleBlocks[]` is an open array).
3. Touch the journal: `mkdir -p .scaffolding/.migrations && touch .scaffolding/.migrations/M-0004.done`.

## Idempotency & journal

Re-running is a no-op once the `[id=parallelization-plan]` marker is present (state check) or
`.scaffolding/.migrations/M-0004.done` exists. The mode pre-check (#3) also makes it a permanent no-op on any
single-operator project. Safe after a partial/interrupted upgrade — the section insert + manifest row are each
individually idempotent (the marker-presence check guards re-insertion).

## Risk & gating

Risk tier: **MED** — inserts a section into an `accreted` file + adds one manifest `exampleBlocks` row; no
behavior change to existing tracker content; team-mode-gated. Structural ⇒ human-gated. Never fabricate the
DAG/track content (insert the skeleton + EXAMPLE-BLOCK markers, marked for the project to fill).
