# M-0007 — Install the wave-2 generated-file set (spec-lint, hooks suite, /phase-exit, arch-drift-auditor)

> Consolidated `added-template` migration for the 2026-06 drift-spine wave. One migration, four
> additions — each individually idempotent and mode/option-filtered, so a project picks up exactly the
> subset that applies to it.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0007",
  "title": "Install the wave-2 generated-file set: scripts/spec-lint.sh, .claude/settings.json + scripts/guards/, /phase-exit, arch-drift-auditor",
  "introducedAtSha": "<set by the wiring commit after the last wave-2 template lands (W2-6)>",
  "kind": "added-template",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "added:wave2-drift-spine-set@v1",
  "touches": ["scripts/spec-lint.sh", ".claude/settings.json", "scripts/guards/", ".claude/commands/phase-exit.md", ".claude/agents/arch-drift-auditor.md", "manifest.generatedFiles"]
}
```

(Gate is **human** — not auto — because one member (`.claude/settings.json`) must MERGE into any
existing project settings rather than be written fresh, and the guard hooks change enforcement behavior.)

## What changed upstream, and why

The 2026-06 wave added four generated artifacts that close the drift spine:

1. **`scripts/spec-lint.sh`** (placeholder-only; fill `{{ARCH_DOC}}`/`{{TASK_TRACKER}}`) — the
   brief/tests/reqs traceability linter. Both modes.
2. **`.claude/settings.json` + `scripts/guards/`** (PreToolUse hooks: git-guard, territory-guard,
   secrets-guard) — mechanical enforcement of the prose-only git/territory rules. Both modes
   (territory-guard no-ops without a team-registry entry). **Merge-don't-replace** into an existing
   `settings.json`.
3. **`.claude/commands/phase-exit.md`** — the row→executor mapper that executes the tracker's
   phase-exit checklist. Both modes (the orchestrator role exists in single-operator too).
4. **`.claude/agents/arch-drift-auditor.md`** — the phase-boundary spec-vs-code auditor. Offered like
   the other starter subagents (skip if the project declined the starter set; record the choice).

## Handler steps

1. **Idempotency pre-check:** `.done` touchfile, else per-item: skip any item whose dest already exists
   (record `divergence: pre-existing` if its content is unrelated to ours).
2. For each applicable item (filtered by `mode` / `optionalSubagents`): substitute placeholders from the
   manifest, write the file, append its `generatedFiles[]` row.
3. `.claude/settings.json`: if the project already has one, present a MERGE diff (hooks appended, nothing
   removed) — never overwrite. The guard scripts' territory path list derives from manifest values
   (TASK_TRACKER, ARCH_DOC, per-area CLAUDE/LESSONS paths).
4. Tick each item's name into the journal dir as it lands (`.scaffolding/.migrations/M-0007/<item>`);
   journal `M-0007.done` when all applicable items are present.

## Related (no separate migration)

The `[id=forbidden-patterns]` region in area `CLAUDE.md` gained a machine-readable
` ```forbidden-patterns ` sub-block (W2-7) that `/preflight` warn-greps. It rides the existing
per-region merge machinery — illustrative blocks auto-eligible, customized blocks PROPOSE — so no
migration entry is needed; this note exists so upgraders know the sub-block is expected.

## Idempotency & journal

Per-item presence checks + the per-item journal make re-entry resume mid-set. Re-running with everything
present is a no-op.

## Risk & gating

**MED** — additive files only, but the hooks change enforcement behavior and the settings merge touches a
user-owned file; human-gated with a per-item plan at PAUSE 1.
