<!-- ╔══════════════════════════════════════════════════════════════════════════════╗ -->
<!-- ║  ⚠ EXPERIMENTAL — Codex multi-agent team overlay (WIP). Read the banner below.  ║ -->
<!-- ╚══════════════════════════════════════════════════════════════════════════════╝ -->

# Codex multi-agent team overlay (EXPERIMENTAL / WIP)

> ⚠️ **EXPERIMENTAL — Codex multi-agent team overlay (WIP).** Built on Codex's experimental
> `collaboration_mode` / `spawn_agent` v2 APIs, which are **unstable and expected to churn** — pin a
> known-good Codex version. Known constraints baked into this overlay:
> 1. **No native git-worktree isolation** — isolation is shell-implemented; out-of-repo edits are not
>    stash-protected.
> 2. **`codex exec` returns exit 0 even on failure** — results are verified independently (`git log` +
>    test re-run), never by exit code.
> 3. **`--output-schema` works only on the gpt-5 family, not `gpt-5-codex` / `codex-*`** — coding roles
>    report through a filesystem ledger, not structured output.
> 4. **`--full-auto` blocks network** — installs/tests that need network use `--yolo` (a trust escalation).
> 5. **No built-in `codex exec` timeout** — runaway children are bounded only by `job_max_runtime_seconds`.
> 6. **Codex is hierarchical parent→child, not peer teammates with a shared task list** — there is no
>    `addBlockedBy` auto-unblock; dependency ordering + status live in an orchestrator-owned ledger.
> 7. **No context-% signal** — the mechanical WARN/ACTION/HARD-STOP auto-cycle is degraded to per-slice
>    teardown + heuristic orchestrator cycling.
>
> **This overlay is OFF by default.** It is generated only when you opt in at generation time
> (`host = codex` + `mode = team` + an explicit confirm) AND it activates at runtime only when Codex's
> `collaboration_mode` / `effort = ultra` is enabled. With either switch off, you get the supported Codex
> **solo core** — `/tdd` run directly in a single session. Opt in only if you accept the above and will
> re-validate per Codex release.

This document is the design + operating contract for porting the Claude agent-team coordination layer onto
Codex's experimental multi-agent primitives. The **solo core** (see the project's `AGENTS.md`, `skills/`,
`config.toml`) is the supported path; this overlay is an opt-in accelerant for when Codex's collab layer is
available and you want orchestrator/implementer parallelism within one repo.

## 1. Why this can't be a 1:1 port

The Claude layer is a **durable peer mesh over shared state**: orchestrator and implementer are co-equal
sessions that talk both directions via `SendMessage`, coordinate through a *shared* task list
(`TaskCreate`/`TaskUpdate`/`TaskList` + `addBlockedBy`), and are watched by a durable, stateless lead that
outlives many teammate cycles; context is monitored *externally* by the statusline-heartbeat → tier
auto-cycle.

Codex v2 is a **hierarchical fork-join tree over private state**: `spawn_agent` makes a child `AgentThread`
under a canonical task path (`/root/task1/task_3`); the child runs and returns **once** via an
`agent_result` edge; `wait_agent(timeout_ms)` / `followup_task` / `send_message` / `close_agent` are the
controls. There is no shared task list, no `addBlockedBy`, no external context-% signal, and no native
worktree isolation.

So the port collapses a peer mesh into a spawn tree, replaces shared state with a filesystem ledger, and
replaces mechanical context-cycling with structural per-slice teardown.

## 2. Topology — the root session IS the lead

```
root Codex session  = LEAD          (depth 0; the human's interactive TUI — naturally persistent)
└── orchestrator     [agents.orchestrator]   (depth 1)  plans/scopes, Step-2.5 review, Step-9 routing, owns the ledger + push
    └── implementer   [agents.implementer]    (depth 2)  one child PER SLICE; runs /tdd; closed at Step-10
        ├── reviewer-quality   [agents.reviewer-quality]    (depth 3)  Step-8 fan-out
        └── reviewer-security  [agents.reviewer-security]   (depth 3)  Step-8 fan-out
```

`max_depth ≥ 3` is **mandatory** for the Step-8 reviewer fan-out. The lead has **no** `[agents.lead]` block —
it is the root TUI, configured by the top-level `config.toml` + the generated `AGENTS.md`. Routine traffic
that Claude keeps off the lead is naturally off the Codex root too (the root only sees `agent_result` from
the orchestrator), so the "lead stays lean" invariant holds for free.

**v1 ships single-track only.** Multi-track (N parallel spawn-trees over per-track worktrees) is **deferred**
— N spawn-trees over an unstable collab layer with no worktree isolation is too much risk surface. The
worktree-provision hook point exists but is guarded off.

## 3. Mapping table — Claude mechanism → Codex experimental

| Claude mechanism | Codex equivalent | Where the analogy breaks |
|---|---|---|
| `TeamCreate` + `team_name` | **dropped** — the team is implicit in the spawn tree; the label is a ledger/event-log dir key | no team object to "join"; every `spawn_agent` is a real child thread |
| `Agent(team_name,name,subagent_type)` | **`spawn_agent`** with `role=` + a canonical task path; `name`→nickname | fork-join, not "join a persistent team" — a child is expected to return |
| durable lead persisting across cycles | **root (depth-0) session = lead**; re-derives state from files | root is bound to the human's live session — if it ends, the tree dies (no fresh lead from a handoff doc without a new `codex` run) |
| orchestrator (peer) | **`[agents.orchestrator]`**, depth-1 child; long-lived via `followup_task` | becomes a child of the lead, not a peer beside it |
| implementer-per-area (peer) | **`[agents.implementer]`**, depth-2, spawned per slice, closed at Step-10 | per-slice fork-join ⇒ implementer never accumulates cross-slice context → cycling is **free** (just `close_agent`) |
| `SendMessage` wake | **`send_message`** (fire-and-wake) + **`agent_result`/`followup_task`** for blocking checkpoints | a child can't block mid-run on a reply from a parent that is itself in `wait_agent` (deadlock) → checkpoints become result-edge round-trips at fork-join boundaries |
| shared `TaskList` + `addBlockedBy` | **orchestrator-owned ledger** `.codex-team/<label>/tasks.jsonl`; dependency order = orchestrator walks the `IMPLEMENTATION_PLAN.md` `Depends on:` DAG | no scheduler auto-unblocks; the implicit dependency graph becomes an explicit orchestrator loop |
| statusline heartbeat + tier auto-cycle | **dropped** (no context-% signal); replaced by per-slice teardown + coarse orchestrator cycling on `job_max_runtime_seconds`/slice-count | the single biggest fidelity loss — Claude's design is mechanical, Codex can only be heuristic until a hook payload surfaces context |
| `team-event-log.sh` on `TeammateIdle`/`TaskCompleted` | **`[hooks]` `SubagentStart`/`SubagentStop`** → `.codex-team/<label>/events.jsonl` | no `TeammateIdle` analog (children return, they don't idle); "spawned but no result/ledger row" is the circuit-breaker signal |
| `territory-guard.sh` (PreToolUse role check) | **per-role sandbox writable-roots** (capability, stronger than a check) + optional `auto_review` guardian | Codex's confirmed extra hooks are `SubagentStart/Stop`, not a pre-edit hook |
| `git-guard.sh` (`add -A` ban; implementer push ban) | push-ban **free** (implementer `--full-auto` blocks network); `add -A` ban → commit-wrapper / guardian | two rules split across two enforcement surfaces |
| per-track git worktrees | shell `git worktree add` in `SubagentStart` (guarded off; single-track v1) | no native isolation; out-of-repo worktrees aren't stash-protected |
| 4-category escalation → lead → human | orchestrator returns/`send_message`s the escalation to the **root**, which asks the human in the TUI | cleaner — the root IS the interactive session (no `AskUserQuestion` relay) |
| `collaboration_mode` / `effort: ultra` | **the runtime opt-in gate itself** | experimental/unstable — this is *why* the overlay is WIP |

## 4. `/tdd` + phase-exit, re-expressed (fork-join with result-edge checkpoints)

One implementer child per slice, kept alive across the slice via `followup_task`, with the two Claude
checkpoints expressed as result-edge round-trips:

1. **Spawn (RED + Step-2.5):** orchestrator `spawn_agent(role=implementer, task="/root/slice-<id>")`. Child
   writes the failing test(s) (with the `spec(§X)` tag), then **returns the Step-2.5 test-design write-up as
   `agent_result`** and idles awaiting `followup_task`.
2. **Step-2.5 review:** orchestrator reviews against spec → `followup_task(child, "APPROVED." | "TWEAK: …" |
   "ADD: …")`. The magic-words headers survive verbatim.
3. **Continue (GREEN→Step-9):** the same child runs Steps 3–8. **Step-8 fan-out:** the child `spawn_agent`s
   `reviewer-quality` + `reviewer-security` in parallel (depth-3) **or** routes them through Codex
   `auto_review`/`guardian_subagent` (recommended). Child then **returns the Step-9 categorized flags +
   ship-ask as `agent_result`**.
4. **Step-9 routing → Step-10 commit:** orchestrator routes per the Step-9 matrix, then
   `followup_task(child, "<commit-message-first reply>")`. Child does the **explicit `git add <impl>
   <test>`** commit, writes its `completed`+hash row to the ledger, returns the hash. Orchestrator
   **independently verifies** the hash is in `git log` and the suite is green (mandatory — `codex exec` exits
   0 on failure), updates the ledger, then `close_agent` → child context reclaimed for free.
5. **Escalations** (4 categories) surface orchestrator → root → human in the TUI (no `AskUserQuestion` relay).

**`phase-exit` fan-out** maps cleanly (already fork-join): the orchestrator `spawn_agent`s
`reachability-auditor` + `arch-drift-auditor` (+ `reviewer-security` at a phase boundary) in parallel; each
writes its full report to `docs/audits/<phase>-<agent>.md` and returns a ≤10-line CLEAR/BLOCKED summary.
`scripts/spec-lint.sh tests <phase>` runs in the orchestrator's shell. BLOCKED rows escalate as Findings.

## 5. Generated layout (host = codex + mode = team + opt-in)

- **`config.toml`** is generated from **`templates/config.codex.team.toml`** (which **replaces** the solo
  `templates/config.codex.toml` when you opt in), adding `[agents]` (`max_threads`, `max_depth ≥ 3`,
  `job_max_runtime_seconds`, `interrupt_message`) + `[agents.<role>]` blocks + `[hooks]
  SubagentStart/SubagentStop`. These are **live** TOML — the overlay is OFF not because they're commented but
  because it stays dormant until Codex's runtime `collaboration_mode` / `effort = ultra` is enabled.
- **`.codex/agents/<role>.toml`** — role charters (orchestrator, implementer, reviewer-quality,
  reviewer-security, reachability-auditor, arch-drift-auditor), each layering model + sandbox writable-roots
  onto the role. Bodies are the direct port of the Claude `.claude/agents/*.md` review checklists.
- **`.codex/hooks/subagent-start.sh` / `subagent-stop.sh`** — event-log append (replaces
  `team-event-log.sh`) + the worktree-provision point (guarded off for single-track v1).
- **`scripts/codex-team-preflight.sh`** — the spawn round-trip probe + circuit-breaker bookkeeping (§6).
- **Codex `/team-start` + `/team-end` skills** — the lead's stand-up / close-out, re-expressed for the spawn
  tree (no `TeamCreate`; `spawn_agent` topology + the preflight gate + the solo fallback).

## 6. Verification + risk

**CAN be verified deterministically (run by `codex-team-preflight.sh` at `/team-start`):**
- `config.toml` parses and roles load; a probe `spawn_agent(role=orchestrator)` returns a thread handle.
- A trivial `spawn_agent` round-trip: root spawns a child that writes a sentinel to
  `.codex-team/<label>/probe.json` and returns it; `wait_agent` returns within `timeout_ms`; `close_agent`
  succeeds. This is the churn guard — it proves spawn/result/close on the *installed* Codex version.
- Ledger read/write, `SubagentStart/Stop` hooks firing, the territory sandbox blocking an out-of-area write +
  a network push. (Worktree shell ops are verifiable too, but the worktree-provision path is **dormant** in
  single-track v1 — see §2.)

**CANNOT be reliably verified (accepted risk; experimental):**
- That `collaboration_mode` / `effort = ultra` behaves consistently across Codex versions.
- Round-trip timing/reliability of the Step-2.5/Step-9 `agent_result` ↔ `followup_task` hops under load.
- Context-%-based auto-cycle — fundamentally unverifiable (no signal); this is why it's dropped, not untested.
- Structured `agent_result` on coding models — the `--output-schema` gap means **the ledger row is the
  source of truth**, and a child that crashes (exit 0!) writes *no* row → **treat a missing ledger row as
  FAIL, never as "still pending."**

**Degradation to solo:** `codex-team-preflight.sh` runs the trivial round-trip at `/team-start`. On any
failure (collab layer absent, spawn error, probe timeout) the overlay **disables itself** and prints:
*"Codex collab layer unavailable — falling back to solo. Run `/tdd` directly in this session."* The generated
`AGENTS.md` carries both the solo path and the gated team section, so solo is always a complete, working mode.

**3-failure circuit breaker:** the orchestrator tracks consecutive slice failures in the ledger. A failure =
`spawn_agent` error **or** a missing/`null` result row after `wait_agent` **or** an independent-verification
mismatch (hash not in `git log`, or suite not green). After **3 consecutive failures** the orchestrator stops
spawning, writes `circuit_open` to the ledger, escalates to root → human as a Finding, and flips the session
to solo for the remainder. This converts Codex's most dangerous failure mode — a child that "succeeds"
(exit 0) but did nothing — into a bounded, surfaced stop instead of an infinite no-op loop.

## 7. Open decisions (carry real risk — confirm per project)

- **Model-per-role split:** gpt-5 orchestrator (gets `--output-schema`) vs gpt-5-codex implementer (better
  coding, no schema → ledger). Recommended, but a real tradeoff.
- **Orchestrator cycle cadence** — the heuristic that replaces the mechanical tier table.
- **`max_depth` / `max_threads` sizing** — `max_depth ≥ 3` is mandatory for Step-8 fan-out; easy to under-set.
- **Multi-track: DEFERRED for v1** — the hook point exists, guarded off.
- **Territory enforcement via sandbox vs a future pre-tool hook** — sandbox is stronger but coarser.
- **`--yolo` network escalations** for dep-install / integration-test steps — each is a trust decision.
- **Project-dir env var + PreToolUse payload shape (D3)** — confirm against your Codex version; the guards
  fail safe (exit 0 on empty), so a mismatch silently disables enforcement rather than breaking.
