# M-0003 — Rename the task tracker `MVP_TASKS.md` → `IMPLEMENTATION_PLAN.md`

> Filled copy of `_TEMPLATE.md`. The matching entry is in `registry.json`.
> **One migration per file.** Append-only — never edit a shipped migration in place; fix with a NEW
> migration at a later SHA. SHA-window-gated (fires once when `base < introducedAtSha <= to`),
> idempotent, journaled (touchfile `.scaffolding/.migrations/M-0003.done`), per-migration failure non-fatal.

> **⚠ `introducedAtSha` must be wired to the commit that ships this rename** (the commit that flips the
> `{{TASK_TRACKER}}` default in `GENERATE-WITH-CLAUDE.md` + `generate-procedure.md` and `git mv`s
> `templates/MVP_TASKS.md` → `templates/IMPLEMENTATION_PLAN.md`). It currently holds the placeholder
> `"PENDING-wire-to-shipping-commit"`, which is unresolvable, so the script SKIPS this migration with a
> warning (safe — it cannot fire before it ships). After committing, set it to that commit's 40-char SHA —
> exactly the two-step pattern commit `a939bd0` used to wire M-0001/M-0002's `introducedAtSha`.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0003",
  "title": "Rename the task tracker MVP_TASKS.md -> IMPLEMENTATION_PLAN.md (neutral 'implementation plan' name) + update the {{TASK_TRACKER}} placeholder default",
  "introducedAtSha": "PENDING-wire-to-shipping-commit",
  "kind": "renamed-template",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "rename:task-tracker:MVP_TASKS.md->IMPLEMENTATION_PLAN.md",
  "touches": ["MVP_TASKS.md", "manifest.placeholders", "manifest.generatedFiles", "manifest.exampleBlocks"]
}
```

- **kind** = `renamed-template` — the upstream *template path* moved (`templates/MVP_TASKS.md` →
  `templates/IMPLEMENTATION_PLAN.md`) AND the resolved `dest` (the value of `{{TASK_TRACKER}}`) moves from
  `MVP_TASKS.md` to `IMPLEMENTATION_PLAN.md`. The handler does the on-disk `git mv` + the `generatedFiles[]`
  ledger remap + the cross-reference ripple, AND writes the new placeholder VALUE (the manifest-edit half,
  via the `manifest.placeholders` touch convention — the same sanctioned path M-0001 uses). NOTE: this is
  **not** `renamed-placeholder` — the placeholder *token* stays `{{TASK_TRACKER}}`; only its *value* changes.
- **gate** = `human` — structural; renames a tracked project file and edits the manifest.

## What changed upstream, and why

The task tracker was renamed from the MVP-framed `MVP_TASKS.md` to the neutral `IMPLEMENTATION_PLAN.md` (so
planning + implementation aren't biased toward demo-grade MVP shortcuts). Upstream this is a placeholder
DEFAULT change (`{{TASK_TRACKER}}` default flips in `GENERATE-WITH-CLAUDE.md` / `generate-procedure.md`) plus
a template-file rename (`templates/MVP_TASKS.md` → `templates/IMPLEMENTATION_PLAN.md`).

A plain 3-way merge cannot express this for an already-generated project: it would try to re-derive a NEW
`IMPLEMENTATION_PLAN.md` from the template (wrong — the tracker is `kind: "accreted"`, with a living body) and
leave the old `MVP_TASKS.md` orphaned, while the manifest's `placeholders.TASK_TRACKER` value and the
`generatedFiles[].dest` would still point at the old name. Hence a migration.

## Handler steps

**Idempotency + customization pre-check FIRST (skip the whole migration if ANY holds):**

1. `.scaffolding/.migrations/M-0003.done` exists, OR
2. `jq -r '.placeholders.TASK_TRACKER' .scaffolding/manifest.json` is **NOT** `"MVP_TASKS.md"` — the user
   already chose a different tracker filename (or already renamed it). **NEVER force-rename a customized
   value.** Report `"task tracker is '<value>', not the default — skipping rename"` and stop, OR
3. `MVP_TASKS.md` does not exist at the project root, OR `IMPLEMENTATION_PLAN.md` already exists (nothing to
   rename / would clobber).

**Then (model, human-gated):**

1. Rename the file **preserving its accreted body — NEVER re-derive from the template**:
   `git -C <project> mv MVP_TASKS.md IMPLEMENTATION_PLAN.md`
   (The diff/merge path deliberately skips `accreted` files, so all rename work happens HERE, not in the
   file-merge phase.)
2. Update `.scaffolding/manifest.json` (the sanctioned manifest-edit path — same as M-0001 step 3):
   - `placeholders.TASK_TRACKER = "IMPLEMENTATION_PLAN.md"`
   - the `generatedFiles[]` row whose `dest == "MVP_TASKS.md"`: set `dest = "IMPLEMENTATION_PLAN.md"` and
     `template = "templates/IMPLEMENTATION_PLAN.md"` (leave `kind: "accreted"` unchanged).
   - any `exampleBlocks[]` row with `file == "MVP_TASKS.md"`: set `file = "IMPLEMENTATION_PLAN.md"`.
3. Grep-and-update the cross-reference ripple (the `renamed-template` handler, `upgrade-skill.md §6.2`):
   every HARD-CODED literal `MVP_TASKS.md` inside the project's command bodies, `CLAUDE.md` layers, the
   orchestrator-briefing reads, and area tables → `IMPLEMENTATION_PLAN.md`. (References that use the
   `{{TASK_TRACKER}}` token resolve automatically on the next re-substitution — only literals need the ripple.)
4. Journal: `mkdir -p .scaffolding/.migrations && touch .scaffolding/.migrations/M-0003.done`.

## Idempotency & journal

Re-running is a no-op once `placeholders.TASK_TRACKER == "IMPLEMENTATION_PLAN.md"` (state-based check) or
`.scaffolding/.migrations/M-0003.done` exists. The customization guard (pre-check 2) also makes it a no-op on
any project that chose a different tracker name. Safe after a partial/interrupted upgrade — the rename,
manifest edit, and ripple are each individually idempotent (a `git mv` of an already-renamed file is caught
by pre-check 3). The journal touchfile is the flat `.scaffolding/.migrations/M-0003.done` form (the path the
shipped `scaffold_upgrade.sh` `cmd_migrations` idempotency check reads).

## Risk & gating

Risk tier: **MED** — renames a tracked, `accreted` project file + edits the manifest + ripples references; no
body rewrite (the `git mv` preserves the living content). Structural ⇒ human-gated. Hard rules: NEVER
force-rename a customized `{{TASK_TRACKER}}` value (pre-check 2); NEVER re-derive the accreted body (use
`git mv`, not a template re-render).
