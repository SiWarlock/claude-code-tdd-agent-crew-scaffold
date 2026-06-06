# M-0001 — Add the Step-8 reviewer-policy section + placeholders to root CLAUDE.md

> Filled copy of `_TEMPLATE.md`. The matching entry is in `registry.json`.
> **One migration per file.** Append-only — never edit a shipped migration in place; fix with a NEW
> migration at a later SHA. SHA-window-gated (fires once when `base < introducedAtSha <= to`),
> idempotent, journaled (touchfile `.scaffolding/.migrations/M-0001.done`), per-migration failure non-fatal.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0001",
  "title": "Add Step-8 reviewer-policy section + {{SECURITY_REVIEW_POLICY}}/{{CODE_QUALITY_REVIEW_POLICY}} to root CLAUDE.md",
  "introducedAtSha": "7bad3fe9e6b958cec9fb1c0486bf770b00048381",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "section:root-CLAUDE:reviewer-subagents-step-8-policy",
  "touches": ["CLAUDE.md", "manifest.placeholders"]
}
```

- **kind** = `new-required-section` — a new `### Reviewer subagents — Step-8 policy` subsection under
  `## TDD posture` in root `CLAUDE.md`, plus the two new placeholders it references.
- **gate** = `human` — structural; inserts a section and asks for two values (never fabricate).

## What changed upstream, and why

The Step-8 reviewer fan-out (`code-quality-reviewer` + `security-reviewer`) used to run on every slice at
`opus`/`xhigh` — the single biggest per-slice token cost. It is now **policy-gated**: root `CLAUDE.md`
carries a `### Reviewer subagents — Step-8 policy` section with `{{SECURITY_REVIEW_POLICY}}` and
`{{CODE_QUALITY_REVIEW_POLICY}}` (each `off` · `invariant` · `every-slice` · `phase-boundary`), and `/tdd`
Step 8 reads it. A plain 3-way merge can bring the section prose in, but it cannot supply the two new
placeholder values for an existing project — hence a migration.

## Handler steps

Idempotency pre-check FIRST (script): skip if root `CLAUDE.md` already contains the
`Reviewer subagents — Step-8 policy` heading, or if `.scaffolding/.migrations/M-0001.done` exists.

Then (model, human-gated):
1. Insert the new `### Reviewer subagents — Step-8 policy` section from the upgraded `templates/CLAUDE.md`
   at the correct anchor (end of `## TDD posture`, before `## Key safety rules`) — the section skeleton +
   the two placeholder lines. Never fabricate content.
2. Ask the user for the two policy values (defaults: `security-reviewer = invariant`,
   `code-quality-reviewer = every-slice`; set a reviewer `off` if that subagent isn't installed) and
   substitute them.
3. Write `SECURITY_REVIEW_POLICY` + `CODE_QUALITY_REVIEW_POLICY` into `.scaffolding/manifest.json`
   `placeholders` so future upgrades resolve them.

## Idempotency & journal

Re-running detects "already applied" via the heading presence + the `idempotencyKey` + the
`.scaffolding/.migrations/M-0001.done` touchfile. Safe after a partial/interrupted upgrade.

## Risk & gating

Risk tier: **MED** — inserts a section + two manifest values; no behavior change to existing files.
Structural ⇒ human-gated. Never fabricate the policy values; ask, with the stated defaults.
