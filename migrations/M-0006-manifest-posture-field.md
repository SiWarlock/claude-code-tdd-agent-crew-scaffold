# M-0006 — Add the `posture` field to the provenance manifest (schema v2)

> Manifest-schema migration. Generation now stamps `"posture": "production-grade" | "MVP/prototype"`
> (schema v2) so **posture-gated** upgrade content — e.g. the production-grade phase-exit checklist rows —
> can be filtered mechanically at upgrade time, the same way `mode`/`optionalCommands` filter
> `added-template` content. This migration backfills the field on v1 manifests. It sits early in the
> SHA-window on purpose: selection runs in commit order, so it fires **before** any later posture-gated
> migration in the same upgrade.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0006",
  "title": "Add the posture field to .scaffolding/manifest.json (schema v2)",
  "introducedAtSha": "<set by the follow-up wiring commit — the W1-10 commit>",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "manifest:posture-field+schema-v2",
  "touches": [".scaffolding/manifest.json"]
}
```

(`kind: new-required-section` — the new required "section" is a manifest field rather than a doc heading;
the handler semantics are the same: insert the missing structure, **never fabricate its content**.)

## What changed upstream, and why

`GENERATE-WITH-CLAUDE.md` Step 12.5 now stamps `"posture"` (copied from the `Build posture:` line of the
project's `{{ARCH_DOC}}` executive summary, confirmed in the interview) and `"schemaVersion": 2`.
`scaffold_upgrade.sh` (`SKILL_SCHEMA=2`) surfaces `posture` in `precheck.json`; a v1 manifest surfaces
`"posture": "unknown"`, which downgrades all posture-gated upgrade content to human-gated. A plain 3-way
merge can't express this — the manifest is machine-owned and not a generated template.

## Handler steps

1. **Idempotency pre-check:** if the manifest already has a `posture` field and `schemaVersion >= 2`, or
   `.scaffolding/.migrations/M-0006.done` exists — journal `.done` and stop.
2. **Determine the posture — never fabricate:**
   a. Read the `Build posture:` line from the project's `{{ARCH_DOC}}` executive summary, if present.
   b. **Confirm with the user** (AskUserQuestion: `production-grade` | `MVP/prototype`, pre-selecting the
      arch-doc value when found). If no arch-doc line exists, the user's answer is the value — there is no
      default to silently apply.
3. **Write:** set `"posture"` and `"schemaVersion": 2` in `.scaffolding/manifest.json` (`jq`-edit; validate
   it still parses).
4. Journal `.scaffolding/.migrations/M-0006.done`.

## Idempotency & journal

Step 1's field+version check makes re-runs a no-op; the `.done` touchfile short-circuits. The `jq` write is
atomic per run; an interrupted upgrade re-enters at step 1 and re-asks only if the field never landed.

## Risk & gating

**LOW** mechanically (one field), but **human-gated** because the value is a user decision: posture drives
which production-gate rows later migrations offer, and the always-ask rule applies — a recommended default
is presented, never silently applied.
