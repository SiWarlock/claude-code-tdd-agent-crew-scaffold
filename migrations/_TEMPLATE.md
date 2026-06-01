# M-NNNN — <imperative one-line title>

> Copy this file to `M-NNNN-<slug>.md` and add the matching entry below to `registry.json`. **One migration
> per file.** Migrations are **append-only** — never edit a shipped migration in place; fix a bug with a NEW
> migration at a later SHA. A migration is **SHA-window-gated** (fires exactly once when
> `base < introducedAtSha <= to`), **idempotent** (re-running is a no-op), **journaled** (a touchfile
> `.scaffolding/.migrations/M-NNNN.done` marks completion so an interrupted upgrade resumes), and
> **per-migration failure is non-fatal** (isolated + reported; the rest of the upgrade continues).

## Registry entry (add to `registry.json` `migrations[]`)

```json
{
  "id": "M-NNNN",
  "title": "<imperative one-liner>",
  "introducedAtSha": "<the scaffolding commit that introduced the change>",
  "kind": "renamed-placeholder",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "<stable key; e.g. placeholder:TEST_RUNNER->TEST_FRAMEWORK>",
  "touches": ["manifest.placeholders", ".claude/commands/tdd.md", "..."]
}
```

- **`kind`** is one of the seven (see the handler semantics in the skill `references/upgrade-skill.md §6`):
  `renamed-placeholder` · `moved-section` · `new-required-section` · `renamed-template` ·
  `deleted-template` (**PROPOSE-only — never auto-delete**) · `added-template` (mode/optional-filtered) ·
  `accreted-format` (**the only path allowed to rewrite accreted bodies** — human-gated, idempotent, sampled).
- **`gate`** = `human` for anything structural or accreted-body-touching; `auto` only for purely-additive,
  no-new-required-placeholder cases.

## What changed upstream, and why

<Describe the template change a plain 3-way merge can't express, and why a migration is needed.>

## Handler steps

<The deterministic steps the script performs + the prose steps the model performs. Order: idempotency
pre-check FIRST (skip if `idempotencyKey` already satisfied / `.done` touchfile present), then the change.
For `accreted-format`, ship a deterministic rewriter with a per-item idempotency key and show a before/after
sample of one item before applying across the body; if it can't be made deterministic, degrade to a PROPOSE
checklist the human applies.>

## Idempotency & journal

<How re-running detects "already applied" (the `idempotencyKey` check + the `.scaffolding/.migrations/M-NNNN.done`
touchfile). Re-running after a partial/interrupted upgrade must be safe.>

## Risk & gating

<Risk tier (HIGH/MED/LOW) and why. Confirm: structural/accreted ⇒ human-gated; `deleted-template` ⇒ PROPOSE
only; never fabricate content for a `new-required-section` (insert the skeleton + EXAMPLE-BLOCK markers,
marked for the project to fill).>
