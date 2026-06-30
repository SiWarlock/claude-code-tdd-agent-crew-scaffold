---
name: team-end
description: "EXPERIMENTAL/WIP Codex team lead — close out the spawn-tree overlay: enforce slice atomicity, write a handoff doc, close_agent the orchestrator (cascades to its children), summarize what's next, and surface the circuit-breaker if open."
argument-hint: "<short topic>"
---

<!-- ⚠ EXPERIMENTAL — Codex multi-agent team overlay (WIP). Built on Codex's unstable
collaboration_mode / spawn_agent v2 APIs (expect churn; pin a known-good version). No native git-worktree
isolation; `codex exec` exits 0 even on failure (verify via git log + test re-run, never the exit code);
--output-schema only on the gpt-5 family (coding roles report via a filesystem ledger); OFF by default.
Full caveats + design: docs/codex/team-overlay.md. -->

<!--
  TEMPLATE NOTE (delete when generating): EXPERIMENTAL TEAM OVERLAY ONLY. Generated only when
  host = codex + mode = team + opt-in. Skip in solo-core and Claude-host scaffolding. Fill the
  {{PLACEHOLDER}} tokens + the handoff template; keep the slice-atomicity gate, the close_agent
  cascade, and the Forbidden section VERBATIM. Shared comm rules (slice atomicity, escalation
  taxonomy) live in root AGENTS.md; this file points there.
-->

**Role guard — TEAM LEAD (the root depth-0 Codex session) only.** `/team-end` is the lead's *pause-the-whole-tree* close-out. It is **not** `/orchestrate-end` (the orchestrator's round close-out) or `/session-end` (the implementer's per-session close-out) — those run per-session, below you. Use `/team-end` only when **fully pausing** the team (end of day, arc complete, lead/session swap to solo).

Argument: `$ARGUMENTS` — a short topic for the handoff-doc filename (e.g. `eod-YYYY-MM-DD`, `arc-X-complete`).

**When to invoke:** end of day/weekend · an arc/milestone landed cleanly · swapping the session to solo mode. **When NOT:** per slice / per phase / per round (those close out via the orchestrator's/implementer's own commands) or mid-arc at a natural work boundary.

## Step 0 — Trigger check (one legitimate trigger only)

Codex exposes **no context-% signal**, so the mechanical auto-cycle ACTION/HARD-STOP trigger that the Claude lead has is **dropped here** — there is no statusline heartbeat, no `/context-check`. The legitimate triggers are therefore:

1. **User-on-demand** — the human asked to pause the team.
2. **Circuit-breaker tripped** — the orchestrator wrote `circuit_open` to the ledger (3 consecutive slice failures) and the session already flipped to solo; you are closing out the dead tree (see Step 4).

A natural work boundary alone (end of a phase/arc/round) is **not** a trigger — that is the auto-pause the Forbidden section bans. Step 1's gate applies on both triggers, unchanged.

## Step 1 — Gate: slice atomicity — the current slice ALWAYS finishes

**Before closing anything**, the in-flight slice must be **landed and verified**. This is a hard rule (root `AGENTS.md` "Slice atomicity"), and it is *especially* load-bearing on Codex because **`close_agent` cascades**: closing the orchestrator transitively closes its depth-2 implementer + depth-3 reviewer children — so closing mid-slice would abandon in-flight work with no clean half-commit.

The lead only talks to the orchestrator, so confirm via the orchestrator + the ledger:

1. **Ask the orchestrator** (`followup_task` / `send_message`) to confirm the active implementer child returned its Step-10 hash **and** the orchestrator independently verified it (hash in `git log` + `{{TEST_CMD}}` green). Its `agent_result` is your go/no-go.
2. **Cross-check the ledger** — the last task row must be `completed` with a verified hash, not a bare spawn:
   ```bash
   tail -n 3 ".codex-team/<TEAM_LABEL>/tasks.jsonl"
   ```
   A row that shows a slice **spawned but not `completed`** (or a missing/`null` result row) means a slice is in flight — **STOP**. Surface to the human; ask whether to (a) wait for the slice to land + the orchestrator to seal its round, or (b) abort the close-out. **Never `close_agent` the orchestrator with a slice in flight.** (Remember: a missing/`null` row is FAIL, not "pending" — but for *teardown* purposes an unfinished spawn means wait, not close.)

Do not proceed to Step 2 until the gate passes.

## Step 2 — Read state pointers (handoff inputs)

```bash
git log --oneline -5
tail -n 10 ".codex-team/<TEAM_LABEL>/tasks.jsonl"     # round-seal hash + final slice rows + circuit state
tail -n 10 ".codex-team/<TEAM_LABEL>/events.jsonl"    # SubagentStart/Stop trail
```

Plus `{{TASK_TRACKER}}` ("Currently in progress" + "Next session target" + "Carry-forward to upcoming briefs" + last Log entry) and the most recent `docs/sessions/<NNN>-*.md`. You already hold the team composition + active arc from the orchestrator's `agent_result`s — re-read `{{TASK_TRACKER}}` only if unsure. **Do not deep-load `{{ARCH_DOC}}`** — the handoff records pointers, not architecture.

## Step 3 — Compute the handoff number

```bash
ls docs/team-handoffs/ 2>/dev/null | tail -20
```

Next `NNN` = (max existing) + 1, zero-padded to 3 (first is `001`). Filename: `docs/team-handoffs/<NNN>-<YYYY-MM-DD>-<topic>.md` from `$ARGUMENTS`. **Single-track v1 uses the plain `<NNN>-…` form** (no `<track>-` prefix — multi-track is deferred).

## Step 4 — Surface the circuit-breaker state

Read the ledger for a `circuit_open` row:

```bash
grep -c '"circuit_open"' ".codex-team/<TEAM_LABEL>/tasks.jsonl" 2>/dev/null
```

- **If OPEN:** the overlay already stopped spawning and ran solo after 3 consecutive failures (a failure = spawn error, missing/`null` result row, or a verification mismatch — hash absent from `git log`, or suite not green). Surface it to the human as a **Finding** at the top of the close-out, and record it in the handoff doc (which slice tripped it, the last good commit, that the remainder ran solo). This converts Codex's most dangerous failure mode — a child that "succeeds" (exit 0) but did nothing — into a bounded, surfaced stop.
- **If closed:** note "Circuit-breaker: closed (armed)" in the handoff.

## Step 5 — Write the handoff doc

Write `docs/team-handoffs/<NNN>-<YYYY-MM-DD>-<topic>.md`. **Note the resume caveat:** the root session *is* the lead, bound to the human's live TUI — if it ends, the spawn tree dies with it. There is **no live lead handoff**; this doc is consumed by the **next `codex` session's `/team-start`** to re-derive state and re-spawn. So the orchestrator re-spawn prompt below is load-bearing.

```markdown
<!-- ⚠ EXPERIMENTAL — Codex multi-agent team overlay (WIP). See docs/codex/team-overlay.md. -->
# Team Handoff <NNN> — <topic>

**Date:** YYYY-MM-DD
**Host/overlay:** Codex team overlay (EXPERIMENTAL) · single-track v1
**Team label / ledger:** `<TEAM_LABEL>` → `.codex-team/<TEAM_LABEL>/tasks.jsonl`
**Predecessor handoff:** <docs/team-handoffs/NNN-1-...md if any, else "first handoff">
**Successor handoff:** _(filled in when the next /team-end runs)_
**Round-seal commit at handoff:** `<hash from git log>`
**Circuit-breaker:** <OPEN — tripped on slice <id>, ran solo from `<hash>` | closed (armed)>

## Why this handoff exists
<one sentence: end-of-day / arc-complete / circuit-open / solo-swap>

## Team composition at close (spawn tree)
- **Lead:** this root session (depth 0; dies with the TUI — no live handoff).
- **Orchestrator:** depth-1 — last `agent_result` summary + last commit; **closed via `close_agent` at this handoff**.
- **Implementer(s):** depth-2, one-per-slice — already `close_agent`'d at each slice's Step-10 (per-slice teardown).
- **Reviewers:** depth-3 (reviewer-quality / reviewer-security) — fan-out only; closed with their implementer.

## Active arc + where it landed
<2-3 sentences: the arc, what landed in the closing round, the next planned slice (task ID).>

## In-flight at close (should be empty — Step-1 gate)
<list anything started-but-not-landed, OR "None — clean close (slice-atomicity gate passed)">

## Ledger pointer
- Last `completed` slice row: `<task id>` @ `<verified hash>`.
- `circuit_open`: <present/absent>. Events trail: `.codex-team/<TEAM_LABEL>/events.jsonl`.

## Carry-forward to the next team session
- `{{TASK_TRACKER}}` "Currently in progress" / "Next session target" deltas.
- Load-bearing deploy/env/decision context the next session needs.

## Orchestrator re-spawn prompt (paste into the next /team-start Step 4)
```
<the exact orchestrator spawn template from /team-start Step 4, with <TEAM_LABEL> + the
"Activated because:" line filled to where THIS session leaves off — so the next /team-start
re-derives coordination state from this doc instead of from scratch.>
```
```

## Step 6 — `close_agent` the orchestrator (cascades to its children)

**Only after Step 1's gate passes and the handoff doc is written:**

```
close_agent("orchestrator")     # depth-1; transitively closes any live depth-2 implementer + depth-3 reviewers
```

Closing the long-lived orchestrator tears down the rest of the tree in one move (fork-join teardown) and reclaims all child context. Per-slice implementers were already `close_agent`'d at each Step-10, so in the normal case the orchestrator is the only live child left. Confirm the close returned a success edge — but do **not** trust it blindly; a stuck child is the circuit-breaker's job upstream, not something to discover here.

## Step 7 — Update `{{TASK_TRACKER}}`, then commit

Add one line under "Currently in progress":

```markdown
- **Team paused <YYYY-MM-DD>** — handoff: `docs/team-handoffs/<NNN>-<date>-<topic>.md` · last round-seal: `<hash>` · next-slice: <task ID or "TBD per handoff"> · circuit: <open/closed>
```

Stage explicitly (never `git add -A` — that is banned project-wide) and commit with Conventional Commits + the AI trailer:

```bash
git add docs/team-handoffs/<NNN>-<date>-<topic>.md {{TASK_TRACKER}}
git status --short   # verify ONLY the handoff doc + {{TASK_TRACKER}} are staged
git commit -m "$(cat <<'EOF'
chore(team): handoff <NNN> — <topic>

<one paragraph: why the team is pausing, what landed in the closing round,
where the next session resumes. Reference the predecessor handoff if any.>

{{AI_TRAILER}}
EOF
)"
```

If a predecessor handoff exists, update its "Successor handoff" link in the same commit. **Do NOT push** unless a remote is configured and the human explicitly approves — the orchestrator (which normally pushes at `/orchestrate-end`) is now closed, so a handoff push is a separate, explicit human decision.

## Step 8 — Tell the human

Report: the handoff path; that the orchestrator (and its children) are `close_agent`'d; the **circuit-breaker state** (Finding-level if open); the next-slice target; and **how to resume** — a fresh `codex` session running `/team-start`, which reads this handoff + `{{TASK_TRACKER}}` and re-spawns the orchestrator from the embedded prompt (no re-orient overhead — this doc *is* the orient).

## Forbidden in this command

- **Tearing down mid-slice.** Step 1's slice-atomicity gate is non-negotiable on both triggers; `close_agent` cascades, so closing the orchestrator with a slice in flight abandons in-flight work.
- **Auto-pausing at a natural work boundary** (end of phase/arc/round) with neither trigger present.
- **Pushing without explicit human approval.** Handoff commits are not pushed silently.
- **Trusting `codex exec` / the close exit code, or treating a missing ledger row as "pending."** Verify via the ledger + `git log` + `{{TEST_CMD}}`; a missing/`null` result row is FAIL.
- **Omitting the orchestrator re-spawn prompt from the handoff doc.** It is load-bearing — without it the next `/team-start` re-derives coordination state from scratch.
