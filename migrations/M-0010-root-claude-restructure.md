# M-0010 — Root CLAUDE.md restructure: close-out/monitoring pointers + role-pairing command note

> The always-loaded root `CLAUDE.md` was slimmed: Close-out gating is now a pointer at the canonical
> three-way spec (`/orchestrate-end` Step 8), Context monitoring is a pointer at the canonical tier
> table (`docs/team-protocol.md`) + the script's env defaults, the 16-line command list collapsed to a
> 3-line role-pairing note, threshold numbers no longer hardcoded, and mode-specific prose became
> template-only MODE pruning regions. A 3-way merge handles most of it for untouched files; this
> migration re-anchors customized copies.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0010",
  "title": "Root CLAUDE.md restructure: close-out/monitoring pointers, role-pairing command note, de-hardcoded thresholds",
  "introducedAtSha": "<set by the follow-up wiring commit — the W3-1 commit>",
  "kind": "moved-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "root-claude:closeout+monitoring-pointers@v1",
  "touches": ["CLAUDE.md", "docs/team-protocol.md", "docs/scaffolding-reference.md", "docs/orchestrator-briefing.md", ".claude/commands/session-end.md", ".claude/commands/tdd.md", ".claude/commands/team-end.md"]
}
```

## What changed upstream, and why

1. Root `CLAUDE.md` "Close-out gating" → 3-line pointer (canonical: `/orchestrate-end` Step 8; lead
   mechanics: team-protocol). "Context monitoring" → 3-line pointer (canonical tier table:
   team-protocol; numbers = `check-team-context.sh` env defaults). Command list → role-pairing note.
   Phantom defense trimmed to 3 lines. Hardcoded `70/75/80` numbers removed from every prose copy
   except the canonical tier table.
2. Mode-specific prose across root `CLAUDE.md`, `team-protocol.md`, `tdd.md`, `session-end.md`,
   `orchestrator-briefing.md`, `team-end.md` now sits in **template-only MODE pruning regions** —
   generated files carry only their own mode's prose (the upgrade script replays the pruning when
   rebuilding base/ours, shipped in the same commit).

## Handler steps

1. **Idempotency pre-check:** if the project's root `CLAUDE.md` already says "canonical three-way
   close-out spec is `/orchestrate-end` Step 8", journal `.done` and stop.
2. The 3-way merge absorbs the restructure for untouched files (the trees on both sides are pruned
   identically). For files the project **customized** in the moved sections: re-anchor the project's
   customized content per the moved-section handler — their close-out/monitoring customizations move
   WITH the section's new home (team-protocol or /orchestrate-end), never silently dropped. Show each
   re-anchor as a PROPOSE diff.
3. Verify no threshold number got reintroduced into the pointer copies (the canonical tier table is
   the one numeric home).
4. Journal `.scaffolding/.migrations/M-0010.done`.

## Idempotency & journal

Step 1's probe + `.done`. Re-anchors are per-file PROPOSE diffs; re-running skips files already in the
new shape.

## Risk & gating

**MED** — touches the always-loaded root file and re-anchors customized prose; human-gated
(moved-section rule). Honest benefit: ~800–1.2k tokens/session on the always-loaded path, ×2 cycled
roles per auto-cycle.
