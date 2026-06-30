# M-0013 — Add the `host` field to the provenance manifest (schema v3)

> Manifest-schema migration. Generation now stamps `"host": "claude" | "codex"` (schema v3) — the
> generation target — so the upgrade engine can resolve the host-derived token map and pick the
> host-correct `generatedFiles[].dest` paths from the single shared `templates/` tree. This migration
> backfills the field on v1/v2 manifests. The backfill value is **always `"claude"`**: a pre-v3 manifest
> is, by definition, a Claude project (the `host` axis did not exist when it was generated), so there is
> no user decision here — unlike M-0006's posture, the value is forced, not asked.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0013",
  "title": "Add the host field to .scaffolding/manifest.json (schema v3)",
  "introducedAtSha": "9109910dafdcac59fb3e48061933baedf1451bc6",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "manifest:host-field+schema-v3",
  "touches": [".scaffolding/manifest.json"]
}
```

(`introducedAtSha` is the schema-v3 engine commit — where `SKILL_SCHEMA` became `3` and the engine began
reading `.host`. A project generated before that SHA has no `host` field, so `base < introducedAtSha <= to`
selects this migration exactly for those projects; fresh Codex projects are born at a later base and never
select it. `kind: new-required-section` — the "section" is a manifest field, same handler semantics:
insert the missing structure, never fabricate content.)

## What changed upstream, and why

`scaffold_upgrade.sh` (`SKILL_SCHEMA=3`) now reads `host` (`.host // "claude"`) and surfaces it in
`precheck.json`; `host_token_map` resolves `{{ROOT_MEMORY}}` / `{{COMMANDS_HOME}}` / `{{HOOKS_CONFIG}}` /
`{{USER_GLOBAL_DIR}}` / `{{PROJECT_DIR_ENV}}` / `{{HOST_NAME}}` / `{{AREA_MEMORY}}` from it, and
`host_prune_stream` resolves the `<!-- ▼ HOST [...] ▼ -->` regions. `GENERATE-WITH-CLAUDE.md` §4.0 / §12.5
stamp `"host"` and `"schemaVersion": 3`. An absent `host` is treated as `"claude"` everywhere, so this
migration is purely about making an old manifest schema-v3-explicit; it does not change any generated
output for a Claude project.

## Handler steps

1. **Idempotency pre-check:** if the manifest already has a `host` field and `schemaVersion >= 3`, or
   `.scaffolding/.migrations/M-0013.done` exists — journal `.done` and stop.
2. **Backfill (no fabrication, no question):** set `"host": "claude"` — this is the only correct value for
   a pre-v3 manifest. (If the project is being hand-migrated to Codex, that is a re-generation, not this
   migration; do not infer `codex` here.)
3. **Write:** set `"host": "claude"` and `"schemaVersion": 3` in `.scaffolding/manifest.json` (`jq`-edit;
   validate it still parses).
4. Journal `.scaffolding/.migrations/M-0013.done`.

## Idempotency & journal

Step 1's field+version check makes re-runs a no-op; the `.done` touchfile short-circuits. The `jq` write is
atomic per run; an interrupted upgrade re-enters at step 1.

## Risk & gating

**LOW** — one field with a forced value. Human-gated for consistency with the manifest-field migration
convention (the human reviews the one-line `jq` edit), but there is nothing to decide: the value is always
`"claude"` for any manifest old enough to select this migration.
