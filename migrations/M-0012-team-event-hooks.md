# M-0012 — Install the warn-only team-event hooks (TeammateIdle + TaskCompleted)

> Adds `scripts/hooks/team-event-log.sh` and the matching `.claude/settings.json` hook entries.
> Same shape as M-0007's added-template handling (a generated script + a settings MERGE). The hook is
> **warn-only** (always exit 0), so even if it never fires on a given Claude Code version, nothing breaks.

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0012",
  "title": "Install warn-only team-event hooks: scripts/hooks/team-event-log.sh + TeammateIdle/TaskCompleted settings entries",
  "introducedAtSha": "<set by the follow-up wiring commit — the enhancement-B commit>",
  "kind": "added-template",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "added:team-event-hooks@v1",
  "touches": ["scripts/hooks/team-event-log.sh", ".claude/settings.json", "manifest.generatedFiles"]
}
```

(Gate **human** — it touches the user-owned `.claude/settings.json` via a MERGE, never a replace.)

## What changed upstream, and why

Claude Code exposes `TeammateIdle` / `TaskCompleted` / `TaskCreated` hook events (payloads carry
`hook_event_name`, `session_id`, `teammate_name`, `task_id`, `task_subject`; `team_name` is deprecated).
The scaffolding now ships a warn-only `team-event-log.sh` wired under `TeammateIdle` + `TaskCompleted`
that appends a durable event line to `~/.claude/team-events/<label>.jsonl` — giving the lead an
idle/completion timeline beyond the harness's ephemeral idle-notifications, and a way to spot the
documented drift "a teammate idled but never marked its in-progress task completed."

**Deliberately warn-only.** The script always exits 0 and never emits `{"continue": false}`. An exit-2
`TeammateIdle` ("keep working") would break the `/tdd` Step-2.5 / Step-9 idle-for-review pattern (the
implementer idling while it waits for `APPROVED.` is correct) and the slice-atomicity rule. Enforcement
stays at the checkpoints + gates; this hook only observes.

## Handler steps

1. **Idempotency pre-check:** `.scaffolding/.migrations/M-0012.done`, else: skip `scripts/hooks/team-event-log.sh`
   if it already exists; skip the settings entries if `.claude/settings.json` already has a `TeammateIdle`
   hook pointing at it.
2. Write `scripts/hooks/team-event-log.sh` (placeholder-free; `chmod +x`); append its `generatedFiles[]`
   row (kind `verbatim`).
3. **Merge** the `TeammateIdle` + `TaskCompleted` entries into `.claude/settings.json` `hooks` (these keys
   take no `matcher`). Present a MERGE diff; never overwrite the project's existing settings. If the project
   has no `.claude/settings.json` (pre-M-0007 hooks suite), M-0007 installs the base first — selection
   order guarantees M-0007 (earlier SHA) runs before M-0012 in a shared window.
4. Journal `.scaffolding/.migrations/M-0012.done`.

## Idempotency & journal

The file-exists + settings-has-`TeammateIdle` checks + the `.done` touchfile. Re-running is a no-op.

## Risk & gating

**LOW** — additive, warn-only, no behavior change to existing flows. Human-gated only because it merges
the user-owned settings file. A version where the hook events don't fire degrades to "no event log" —
harmless.
