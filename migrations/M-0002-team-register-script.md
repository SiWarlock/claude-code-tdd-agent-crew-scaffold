# M-0002 — Install the user-global team-register.sh (team mode)

> Filled copy of `_TEMPLATE.md`. The matching entry is in `registry.json`.
> Append-only; SHA-window-gated; idempotent; journaled (`.scaffolding/.migrations/M-0002.done`);
> per-migration failure non-fatal.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0002",
  "title": "Install ~/.claude/scripts/team-register.sh (team mode) — spawn prompts now call it",
  "introducedAtSha": "<SET-ON-COMMIT: the SHA that lands the context-optimization change>",
  "kind": "added-template",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "script:team-register.sh-installed",
  "touches": ["~/.claude/scripts/team-register.sh"]
}
```

- **kind** = `added-template` — a new user-global helper script. **Mode-filtered: team mode only**
  (single-operator has no context monitoring).
- **gate** = `human` — installs a script outside the repo; the user confirms.

## What changed upstream, and why

The `/team-start` registry-write (lead self-register + the two spawn prompts) was inline `jq`, duplicated
three times. It is now a single helper `~/.claude/scripts/team-register.sh` (installed alongside
`check-team-context.sh`), and the upgraded `team-start.md` spawn prompts call it as each teammate's first
action. An existing team-mode project that upgrades its `team-start.md` would reference a script that isn't
installed yet — so the upgrade must prompt the install. (User-global scripts are not part of the per-project
file merge — same as `check-team-context.sh`.)

## Handler steps

Team mode only (skip for single-operator). Idempotency pre-check FIRST: skip if
`~/.claude/scripts/team-register.sh` exists and is executable, or `.scaffolding/.migrations/M-0002.done` exists.

Then (model, human-gated):
1. Tell the user the upgraded `team-start.md` calls `~/.claude/scripts/team-register.sh`, and offer to
   install it:
   `cp <scaffolding-checkout>/templates/scripts/team-register.sh ~/.claude/scripts/team-register.sh && chmod +x ~/.claude/scripts/team-register.sh`
2. Confirm (`ls -x ~/.claude/scripts/team-register.sh`).

## Idempotency & journal

Re-running is a no-op once the script is installed (presence check) or the
`.scaffolding/.migrations/M-0002.done` touchfile exists.

## Risk & gating

Risk tier: **LOW** — additive; installs a small helper; no project-file change. Human-gated because it
writes outside the repo. If skipped, team-mode context monitoring won't register teammates until the script
is installed — a graceful degradation, not a correctness break.
