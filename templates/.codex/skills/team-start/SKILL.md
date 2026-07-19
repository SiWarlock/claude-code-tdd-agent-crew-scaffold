---
name: team-start
description: "EXPERIMENTAL/WIP Codex team lead — stand up the spawn-tree overlay: run the preflight churn-guard FIRST (else fall back to solo /tdd), confirm collaboration_mode/effort=ultra, init the ledger, spawn the depth-1 orchestrator. Single-track v1."
argument-hint: "[label]"
---

<!-- ⚠ EXPERIMENTAL — Codex multi-agent team overlay (WIP). Built on Codex's unstable
collaboration_mode / spawn_agent v2 APIs (expect churn; pin a known-good version). No native git-worktree
isolation; `codex exec` exits 0 even on failure (verify via git log + test re-run, never the exit code);
--output-schema was gpt-5-family only on some past Codex builds (openai/codex#4181, fixed by #4195) —
confirm on your pinned version rather than assuming either way (coding roles report via a filesystem
ledger regardless); OFF by default.
Full caveats + design: docs/codex/team-overlay.md. -->

<!--
  TEMPLATE NOTE (delete when generating): EXPERIMENTAL TEAM OVERLAY ONLY. Generated only when
  host = codex + mode = team + an explicit opt-in confirm. Skip in solo-core and in Claude-host
  scaffolding. Fill the {{PLACEHOLDER}} tokens; keep the preflight gate, the solo fallback, the
  spawn topology, and the Forbidden section VERBATIM — they are the safety contract. Shared comm
  rules (magic-words headers, no self-report, slice atomicity, escalation taxonomy) live in root
  AGENTS.md; this file points there, it does not restate them.
-->

You are the **team lead** for {{PROJECT_NAME}} on the Codex host. **The lead is the root Codex session itself** (depth 0 — the human's interactive TUI), so there is no `[agents.lead]` block to spawn: standing up the team means standing up the *spawn tree below you*. Your job is to gate the overlay on, spawn the **orchestrator** (depth-1), then stay thin — you are the human's interface + the escalation conduit, and you **only ever see the orchestrator's `agent_result`** (routine implementer/reviewer traffic never reaches you, for free). Read `docs/codex/team-overlay.md` (the design + operating contract) and the "Team coordination — shared rules" section of root `AGENTS.md` before standing up the tree.

Argument: `$ARGUMENTS` — an optional **label** keying this team's ledger/event-log dir (`.codex-team/<label>/`). **v1 ships single-track only** — there is no `<track>` prefix and no per-track worktree (multi-track = N spawn-trees over an unstable collab layer with no worktree isolation; **deferred**, hook point guarded off).

**No label given → `default`, and `default` is a single-team-only convention, not a generated unique ID.** Codex exposes no env var this skill can read for a real per-session identifier (unlike a hook script, which does receive a `session_id` field on its stdin payload — but Step 0 below runs as your own bash, with no such payload). So an omitted label always resolves to the literal string `default`; two concurrent or independently-started unlabeled teams would collide in the same `.codex-team/default/` ledger dir and corrupt each other's state. **Always pass an explicit label** (`/team-start <label>`) if more than one team might ever run at once, or when resuming a paused team — reuse the exact label from that team's `docs/team-handoffs/` doc (Step 3 item 4).

## Step 0 — Derive TEAM_LABEL ONCE, then preflight FIRST (the churn-guard + the solo gate) — MANDATORY

Derive the label **once, here**, and reuse this **exact same value** — do not recompute it in Step 2 or anywhere else. (A fresh derivation per bash invocation would drift: `$$` changes across separate shell calls, so a formula that falls back to it would silently produce a *different* label for the preflight probe than for the real ledger, orphaning the preflight's state.)

```bash
TEAM_LABEL="${ARGUMENTS:-default}"   # single-track v1 — no <track> prefix; "default" = single-team-only convention, see warning above
echo "TEAM_LABEL=${TEAM_LABEL}"   # capture this value; every later step reuses it verbatim
```

**Before anything else** — before confirming the gate, before initializing the ledger, before any `spawn_agent` — run the preflight probe against that same label. This is the one deterministic check that proves spawn/result/close on the *installed* Codex version (the whole overlay rides unstable v2 APIs; this is the churn guard):

```bash
scripts/codex-team-preflight.sh "$TEAM_LABEL"
```

It verifies (per `docs/codex/team-overlay.md` §6): `config.toml` parses + the role blocks load; a probe `spawn_agent(role=orchestrator)` returns a thread handle; a **trivial round-trip** — a child writes a sentinel to `.codex-team/<label>/probe.json`, returns it via `agent_result`, `wait_agent(timeout_ms)` returns inside the window, `close_agent` succeeds; the `SubagentStart`/`SubagentStop` hooks fire to `events.jsonl`; ledger read/write works; the per-role sandbox blocks an out-of-area write + a network push.

**On ANY failure (non-zero exit, spawn error, probe timeout, missing sentinel), the overlay disables itself.** Print verbatim and **STOP — spawn nothing**:

> *Codex collab layer unavailable — falling back to solo. Run `/tdd` directly in this session.*

The generated `AGENTS.md` carries the complete solo path, so solo is always a working mode. Do **not** retry, do **not** "try spawning anyway" — a failed preflight means the spawn tree is not trustworthy on this Codex build. (Reminder: never read success off `codex exec`'s exit code — it returns 0 even on failure; the preflight asserts on the *sentinel + handle*, not the exit code.)

## Step 1 — Confirm the runtime opt-in gate

The overlay activates at runtime **only** when Codex's `collaboration_mode` is enabled **and** `effort = ultra` is on — this gate is *the reason this overlay is WIP* and **cannot be deterministically verified** (§6). Confirm the session was launched with both. In practice the probe `spawn_agent` in Step 0 is the real test: if the gate is off, `spawn_agent` is unavailable and preflight already failed you into solo. If you cannot positively confirm `collaboration_mode` + `effort = ultra`, treat it as a preflight failure → solo fallback + STOP. With either switch off you get the supported **solo core**, not a degraded team.

## Step 2 — Initialize the ledger (reusing Step 0's TEAM_LABEL)

The orchestrator *owns* the ledger, but the lead initializes its dir so Step 4's spawn lands into an existing tree key. **Reuse the exact `TEAM_LABEL` value captured in Step 0 — do not recompute it** (this is what keeps the preflight's probe dir and the real ledger dir pointed at the same `.codex-team/<label>/`):

```bash
mkdir -p ".codex-team/${TEAM_LABEL}"
# CREATE-IF-ABSENT, never truncate — a re-stand-up of /team-start (e.g. after a cycle) must PRESERVE the
# orchestrator's accrued task ledger + circuit-breaker state. Use `:>` only for a deliberately fresh team.
[ -e ".codex-team/${TEAM_LABEL}/tasks.jsonl" ]  || : > ".codex-team/${TEAM_LABEL}/tasks.jsonl"   # orchestrator-owned task ledger (status + commit hashes + circuit-breaker state)
[ -e ".codex-team/${TEAM_LABEL}/events.jsonl" ] || : > ".codex-team/${TEAM_LABEL}/events.jsonl"  # SubagentStart/Stop append log (replaces team-event-log.sh)
# Capture the ledger's line count BEFORE spawning — Step 5 needs this to tell "a fresh init row from THIS
# spawn attempt" apart from a stale row left over from a prior successful run at the same label (the
# create-if-absent/never-truncate policy above means resuming a paused team's label starts from a
# NON-EMPTY ledger, so "does an init row exist anywhere in the file" is not a valid liveness check).
TASKS_LINES_BEFORE_SPAWN=$(wc -l < ".codex-team/${TEAM_LABEL}/tasks.jsonl" 2>/dev/null || echo 0)
echo "TASKS_LINES_BEFORE_SPAWN=${TASKS_LINES_BEFORE_SPAWN}"   # capture this value; Step 5 reuses it verbatim
```

**State the single-track v1 limit out loud:** *"This overlay runs ONE spawn-tree (one orchestrator → one implementer-per-slice → its reviewers). Multi-track parallelism is deferred; the worktree-provision hook is guarded off."* The ledger row is the **source of truth** for coding roles (whether `--output-schema` is available for `gpt-5-codex` on your pinned version or not, `gpt-5-codex` implementers report through the ledger, not structured output) — and a child that crashes still exits 0 while writing **no** row, so downstream you treat **a missing ledger row as FAIL, never as "still pending."**

## Step 3 — Read current state (focused; the lead stays lean)

Read just enough to brief the orchestrator's WHY — never enough to accumulate plan/code context (that belongs to the orchestrator + implementer, deliberately kept out of the lead):

1. **`{{TASK_TRACKER}}`** — "Currently in progress" + "Next session target" + the active phase's task IDs/topics; plus the last ~5 round entries in `docs/archive/IMPLEMENTATION_LOG.md` (the plan's `## Log` is only a pointer stub).
2. The most recent `docs/sessions/<NNN>-*.md` — what just landed (skim).
3. `git log --oneline -5` — anchor the state pointer.
4. **If resuming a paused team:** the most recent `docs/team-handoffs/<NNN>-*.md` — it carries the active arc + a ready-to-use orchestrator re-spawn prompt.

**Do NOT load `{{ARCH_DOC}}` or `{{CODE_AREA}}` deep content.** Note there is **no `/context-check`/heartbeat** in this overlay — Codex exposes no context-% signal, so the mechanical tier auto-cycle is *dropped* and replaced by per-slice teardown + heuristic orchestrator cycling (the single biggest fidelity loss vs the Claude layer; see the mapping table in the design doc).

## Step 4 — Spawn the orchestrator (depth-1) — the ONLY spawn the lead makes

The lead spawns **exactly one** child: the orchestrator. Implementers (depth-2, one per slice) are spawned *downward by the orchestrator*; reviewers (depth-3) are spawned *downward by the implementer* at Step-8 fan-out. The lead never spawns them.

```
spawn_agent(
  role = "orchestrator",            # loads .codex/agents/orchestrator.toml (model + sandbox writable-roots)
  task = "/root/orchestrate",       # canonical task path; the orchestrator long-lives here via followup_task
  name = "orchestrator",            # nickname (single-track v1 → no <track>- prefix)
  prompt = <orchestrator spawn template, below>
)
```

The lead does **not** block-wait the orchestrator to completion — it is long-lived (kept alive across the build via `followup_task`). The lead simply returns to the TUI and is woken by the orchestrator's `agent_result` at fork-join boundaries (escalations, the close-out ask). There is no `send_message` round-trip needed to stand it up.

### Orchestrator spawn prompt template (WHY + WHERE only — the orchestrator authors its own plan)

```
You are the orchestrator on the {{PROJECT_NAME}} Codex agent team (depth-1, spawned by the root lead).
Team label: <TEAM_LABEL>. Ledger: .codex-team/<TEAM_LABEL>/tasks.jsonl (you OWN it — write every slice's
status + verified commit hash + circuit-breaker state here; it is the source of truth, not codex-exec exit codes).
Events: .codex-team/<TEAM_LABEL>/events.jsonl. Single-track v1: one implementer-per-slice; no worktree, no track prefix.
Activated because: <one line of chat-only context the start command can't derive; e.g. "Option-D approval landed; next slice = <task ID>". Skip if none.>

BEFORE ANYTHING ELSE — as the very first bytes you write, before reading any other document — append
{"state":"init","label":"<TEAM_LABEL>","ts":...} to .codex-team/<TEAM_LABEL>/tasks.jsonl (the fixed
init-row shape defined in your "ledger is the source of truth" section). This is a lightweight bootstrap
write, not your first substantive action — it exists purely so the lead's liveness check (Step 5) can tell
you actually came up. Confirm in your first agent_result that this row landed, alongside the start command
you ran below.

THEN, your first substantive action: run /orchestrate-start (NOT /session-start — that is the
implementer's). It reads docs/orchestrator-briefing.md + {{TASK_TRACKER}} + {{ARCH_DOC}} itself; do not
expect them in this prompt.

Then, per slice (see docs/codex/team-overlay.md §4): spawn_agent(role=implementer, task="/root/slice-<id>")
for the slice's {{CODE_AREA}}; the implementer writes the failing test + returns its Step-2.5 write-up as
agent_result; you review → followup_task("APPROVED." | "TWEAK: …" | "ADD: …"); it runs GREEN→Step-8 (fanning
out reviewer-quality + reviewer-security at depth-3) and returns Step-9 flags; you route Step-9 → followup_task
the commit-message-first reply; it does the explicit `git add <impl> <test>` commit + writes its completed+hash
ledger row. THEN INDEPENDENTLY VERIFY: the hash is in `git log` AND `{{TEST_CMD}}` is green (mandatory — exit 0
is meaningless). On a verified pass, update the ledger + close_agent the implementer (context reclaimed for free).

Circuit breaker: a failure = spawn error OR missing/null result row after wait_agent OR a verification mismatch
(hash absent from git log, or suite not green). After 3 CONSECUTIVE failures: stop spawning, write `circuit_open`
to the ledger, escalate to me (the root) as a Finding, and run solo for the remainder.

Escalations (the 4 categories in root AGENTS.md) and the close-out ask surface to me via agent_result — I
relay to the human in this TUI (no AskUserQuestion).
```

## Step 5 — Verify the orchestrator came up

The preflight already proved spawn/result/close generically; now confirm *this* orchestrator is real:

1. The `spawn_agent` call returned a thread handle (not an error).
2. A **fresh** init row (`{"state":"init",...}`, per orchestrator.toml's "The ledger is the source of truth"
   section) landed in `.codex-team/<TEAM_LABEL>/tasks.jsonl` — check only the lines appended SINCE Step 2's
   `TASKS_LINES_BEFORE_SPAWN` baseline (reuse the exact value Step 2 echoed — do not recompute it), not the
   whole file. This matters for a **resumed** team: Step 2's
   ledger init is create-if-absent/never-truncate, so a paused-and-resumed label starts from a non-empty
   file already containing an OLD init row from a prior successful run — checking the whole file would
   report "OK" even if THIS spawn attempt silently failed.
   ```bash
   TASKS_FILE=".codex-team/${TEAM_LABEL}/tasks.jsonl"
   NEW_LINES=$(tail -n "+$((TASKS_LINES_BEFORE_SPAWN + 1))" "$TASKS_FILE" 2>/dev/null || true)
   printf '%s\n' "$NEW_LINES" | grep -q '"state":"init"' && echo "init row OK" || echo "init row MISSING"
   ```
   **A missing (or stale-only) init row is a FAIL, not "still booting"** (a crashed child exits 0 and writes nothing — and on a resumed label, a stale old row is indistinguishable from a live one without this before/after comparison). On a missing row, do not dispatch work — re-spawn once; if it fails again, fall back to solo (Step 0 message) and STOP.

## Step 6 — Confirm with the human, then get out of the way

Report to the human: overlay **up** (orchestrator spawned at depth-1; implementers/reviewers spawn downward on demand), **single-track v1**, the ledger path, the first slice target, the **circuit-breaker armed** (3 consecutive failures → stop + flip to solo), and the escalation path (orchestrator → root → you in this TUI). Then **stay lean** — you only see the orchestrator's `agent_result`; routine slice traffic is below you by construction. Re-engage only for an escalation (the 4 categories), the close-out gate (`/team-end`), or new human direction. Silence is the steady state; treat it as healthy.

## Forbidden in this command

- **Proceeding past a failed preflight.** Solo fallback + STOP is the only path — never "spawn anyway."
- **Spawning implementers or reviewers directly.** The lead spawns ONLY the orchestrator (depth-1); the rest of the tree spawns downward.
- **Multi-track / N spawn-trees.** Deferred for v1; the worktree hook is guarded off. Do not provision worktrees.
- **Reading success off `codex exec` / the spawn exit code.** Exit 0 is meaningless; verify via the ledger row (+ `git log` + `{{TEST_CMD}}` re-run downstream).
- **Treating a missing ledger row as "pending."** A missing/`null` row is FAIL.
- **Loading `{{ARCH_DOC}}` or `{{CODE_AREA}}` deep content into the lead**, or block-waiting the orchestrator, or relaying routine traffic — the lead stays thin (root `AGENTS.md` "What the lead does NOT do").
- **Restating the comm protocol** (magic-words headers, no self-report, escalation taxonomy) — it is in root `AGENTS.md`; every role loads it.
