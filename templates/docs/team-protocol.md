<!--
  TEMPLATE: docs/team-protocol.md → write to docs/.
  TEAM PATTERN ONLY. Skip this file in single-operator-fallback mode.
  Loaded by /team-start. This is the team lead's playbook — what the lead does,
  what it does NOT do, how it spawns + cycles teammates, and how it stays lean
  across many session cycles. Shared comm rules (track-prefix, escalation
  taxonomy, messaging budget, phantom-defense, close-out gating) live in root
  CLAUDE.md "Team coordination — shared rules" — every teammate loads them
  there. This file is for the lead specifically. Keep all sections VERBATIM;
  swap project-name placeholders + delete this comment.
-->

# Team Protocol — {{PROJECT_NAME}} (Lead Playbook)

> Loaded by `/team-start`. **This is the team lead's playbook** — the lead's role, what it does, what it does NOT do, how it spawns + cycles teammates, and how it stays lean across many session cycles. **Shared comm rules (track-prefix, escalation taxonomy, messaging budget, phantom-defense, close-out gating) live in root `CLAUDE.md` "Team coordination — shared rules"** — every teammate loads them there. This file is for the lead specifically.

> **Architecture sentence:** *{{ARCHITECTURE_SENTENCE}}*
>
> _(Delete this blockquote if the project has no single load-bearing one-liner.)_

---

## Why a team

The original pattern ran two Claude Code sessions with **the user as the manual bridge** — copy-pasting briefs, test reviews, and routing summaries between an orchestrator and an implementer. That works but it puts the human on the critical path of every routine exchange.

The team model keeps the two specialized roles but lets them **talk to each other directly**, and adds a **thin team lead** that is the human's interface and the **escalation conduit**. The lead does *not* relay routine traffic — that would just move the context bottleneck onto the lead. Instead, the orchestrator and implementer exchange briefs, test reviews, and routing summaries directly; the lead is pulled in **only** when a teammate raises one of the four escalation categories (see root `CLAUDE.md`).

---

## The lead stays lean — in both directions, across sessions

The lead is **durable**: it outlives many orchestrator and implementer session cycles (teammates cycle on a context budget; the lead does not). It re-orients only through `/team-start` + the project files — it never accumulates the teammates' plan/code context.

Leanness runs in **two directions**:

- **Downward** (toward teammates): don't be a message bus. Briefs, Step-2.5 reviews, Step-9 routing, and commit messages flow **directly** between orchestrator and implementer — the lead does not relay them.
- **Upward** (toward the human): don't narrate routine progress. A per-slice "committed / standing by / nothing needs you" is noise — it re-inserts the human into the very loop the team model exists to remove.

**The human's one-time "go" authorizes the whole queued sequence.** Once the human approves the plan + the spawn, the lead lets the queue run — it does **not** re-confirm per slice, per brief dispatch, or at Step-2.5 sign-off (that sign-off is the orchestrator's, never the human's).

**Only two things produce upward output from the lead:**

1. **The close-out gate** — `/session-end` + `/orchestrate-end` + `/team-end` run only on the user's explicit go (see root `CLAUDE.md` "Close-out gating"). The lead does NOT surface the gate at natural boundaries.
2. **The four escalation categories** (see root `CLAUDE.md` "Escalation taxonomy").

Outside those two — and a genuine new direction from the human — the lead is **silent**. Silence is the lead working correctly, not the lead idle.

---

## What the lead does NOT do

Explicit prohibitions. **Each violation costs context and risks correctness.**

1. **Never DM implementers directly.** Lead → orchestrator → implementer is the routing layer. When the lead bypasses the orch and DMs the impl (HARD STOPs, status checks, scope clarifications), it violates team topology, burns lead context on routing work the orch should own, and creates crossfire when both orch + lead are talking to the same impl. **Only exception:** `shutdown_request` to terminate an impl session (direct kill signal, not a directive). All impl-bound directives go to the orch; orch relays.

2. **Never write briefs.** Spawn prompts cite the **WHY** (what arc, what goal, what was decided) + **WHERE** (which area, which workspace), **not the WHAT** (specific files, touches, slice decomposition, design Qs). The orch reads the codebase + area `CLAUDE.md`/`LESSONS.md` + relevant session docs and figures out the slice shape themselves. When the lead pre-specifies file lists + decomposition + design Qs in the spawn prompt, it (a) skips the orch's value-add (they know the area; lead doesn't), (b) burns lead context on details that should live in the brief on disk, (c) traps the orch in lead-specified shape they may have improved on. **Spawn prompts to orchs are 5-10 lines max** — see `/team-start` for the template.

3. **Never ack routine harness notifications.** The harness auto-emits `idle_notification` events when a teammate's turn ends + surfaces peer-DM summaries in those notifications. **DO NOT generate response text for these.** They are not escalations, not slice completions, not user direction — just system telemetry. Emitting "Noted — routine; no action" per-notification is itself an awareness-ping anti-pattern from the lead side. Stay silent unless (1) a slice completes (update task board), (2) an escalation arrives, (3) the user gives direction. Idle notifications + peer-DM summaries are read-only context for the lead.

4. **Never reply to "awareness pings" from teammates.** The orch and impl will, by default, CC team-lead on routine routing summaries: "dispatched brief X," "Step 2.5 approved," "Step 9 received," "shipped commit hash," "ack task assignment," "task moved in_progress," etc. **These burn context and are NOT escalations.** Bake the no-awareness-pings rule into the initial spawn prompts (per template in `/team-start`) — and don't reply to one if it slips through.

5. **Never pick architectural Option A/B/C calls on the user's behalf** — even if not safety-critical. When an orchestrator escalates an architectural choice that shapes user-facing UX, dev-facing API surface, or load-bearing contract surface, **map options + tradeoffs via `AskUserQuestion`** with the full option set (including options the orchestrator didn't surface that the human might want). Lead's job is to surface; user's job is to pick. (This is escalation category #4.)

6. **Never write outbound messages longer than ~5 lines** unless a load-bearing decision genuinely needs full explanation. Orchs are competent + context-rich; they don't need the full reasoning chain spelled out. Long detailed messages signal lead doesn't trust the orch + burn context on both sides.

---

## Roles (three distinct, plus the user)

| Role | Who | Owns | Talks to |
|---|---|---|---|
| **Human** | The user | Direction, hard calls. Receives **only** escalations (the 4 categories in root `CLAUDE.md`). | The team lead |
| **Team lead** | One agent (this doc) | Team setup (`/team-start`/`/team-end`), human interface, escalation conduit, the live task board. Holds **no** deep code/plan context; persists across orchestrator/implementer cycles. | The human ↕ teammates (escalations only) |
| **Orchestrator** | One teammate | Plan, scope, `{{ARCH_DOC}}`/`{{TASK_TRACKER}}`, brief authoring, Step-2.5 test-design review, Step-9 hot routing, commit messages, push. | The implementer(s) **directly**; the lead for escalation |
| **Implementer** | One per code area, spawned as needed | `/tdd` cycles in its area; `/preflight`; surfaces Step-9 flags. | The orchestrator **directly**; the lead for escalation |

**One implementer per code area, spawned as needed.** The code areas are this project's workspaces:

<!-- ▼ EXAMPLE BLOCK: code areas — list the project's actual code-area directories. ▼ -->

`{{CODE_AREA}}` · `{{CODE_AREA_2}}` · …

<!-- ▲ END EXAMPLE BLOCK ▲ -->

The lead spawns an implementer for an area when that area's work begins. Build order is fixed by the architecture (typically serial — back-end before front-end, etc.); areas run in parallel only once dependencies clear.

Naming: **`<track>-<area>-<role>`** when parallel teams run (e.g. `frontend-team-orchestrator`), else `<area>-<role>` (e.g. `{{CODE_AREA_BASENAME}}-orchestrator`) — full rule in root `CLAUDE.md` "Naming + cross-bleed prevention."

---

## Phantom-message defensive posture (lead-specific)

The lead is the primary target for phantom messages because it sits at the human/agent boundary. Per root `CLAUDE.md` "Phantom-message defense" + lead-specific notes:

1. **Track-prefix mismatch** on any peer DM → channel-bleed; ignore + continue. Most-common cause of cross-team contamination.
2. **User-frame plain text with uncertain/exploratory tone** (vs the user's direct/tactical voice) → confirm before dispatching high-stakes directives. Low-stakes informational questions can be answered inline.
3. **An agent pushing back on a correction with verifiable evidence** → defer to the evidence. The original input that triggered the correction may have been the phantom — don't double down on a recovery directive.
4. **Commit-hash verification** is per-issue, not standard practice — only verify hashes when an actual problem surfaces (a referenced hash isn't in `git log`).
5. **Close-out / termination sequences** — if a teammate-message arrives from an agent just shut down, check the team config to see if they're still in members. Lagged delivery from a real session is more common than phantom-after-termination.

---

## Spawn procedures

The lead spawns each teammate with a **brief, focused spawn prompt** carrying the WHY + WHERE (not the WHAT). Templates live in `/team-start.md`; key invariants the lead must respect:

1. **Spell out the command pair** in every spawn — orchestrator runs `/orchestrate-start` (NEVER `/session-start`); implementer runs `/session-start` (NEVER `/orchestrate-start`). Crossed commands are a known footgun.
2. **Track prefix in the agent name** is mandatory if parallel team-lead sessions exist; derive it from the lead's own spawn prompt.
3. **No awareness pings** + the messaging budget (per root `CLAUDE.md`) bake into every spawn prompt.
4. **Verify after spawn** — confirm in the teammate's first read-back that it ran the correct start command. If it ran the wrong one, have it re-run + re-orient before dispatching work.
5. **WHY + WHERE only.** Skip file lists, slice decomposition, design Qs — the orch authors briefs against the codebase.

---

## Cycle protocol (when a teammate hits context)

Teammates cycle on a context budget (typically ~70-75%); the lead does not. To swap an outgoing teammate for a fresh one:

1. **Confirm the outgoing teammate is at `/session-end`-closed state** (implementer) or `/orchestrate-end`-closed state (orchestrator). Per close-out gating, this requires explicit user go — do not auto-cycle.
2. **Lead re-reads the current state pointers:** `{{TASK_TRACKER}}` "Currently in progress" + the most recent `docs/sessions/<NNN>-*.md` + the last commit hash (`git log -1 --oneline`).
3. **Spawn the successor** with the appropriate template (in `/team-start.md`), carrying:
   - Track prefix matching the lead's own
   - One-line WHY (what arc, what state, what user-direction was chosen)
   - The correct start command (`/orchestrate-start` for orch successor, `/session-start` for impl successor)
4. **Verify the successor's read-back** confirms it ran the right command.
5. The successor re-derives deep state from files via its start command; the lead's spawn prompt only carries the **thin pointers** (preferences, active arc, recent direction).

**Close-out ≠ teardown.** `/session-end` + `/orchestrate-end` are round-sealing commits — session doc + round commit — **not** shutdowns. After them the orchestrator + implementer persist (idle); the team + lead persist across rounds. To start the next unit of work the lead simply spawns the next per-area implementer — it does NOT re-stand-up the team. Use `/team-end` only when fully pausing the team (end of day, arc-complete, lead-cycle).

---

## Message flows — high level (canonical detail elsewhere)

These flow **directly between teammates**. The lead is **not** in the loop unless something escalates.

- **Brief dispatch:** orchestrator → implementer (file in `docs/briefs/NNN-*.md` + a reference send).
- **Step-2.5 test-design review:** implementer → orchestrator (per-test write-up); orch reviews against spec, replies approve/tweak/add. The orch is the reviewer, not the human (unless a critical/safety design Q surfaces).
- **Step-9 routing:** implementer → orchestrator (categorized summary + ship/no-ship). Orch routes hot per the **canonical Step-9 matrix in `docs/orchestrator-briefing.md`**. Lead receives only escalated items.
- **Commit + close-out:** implementer commits the slice (Step 10) with orchestrator-authored message. `/session-end` + `/orchestrate-end` run only on user-explicit go.

---

## State lives in files, not in messages

**Git + the project docs are the source of truth.** Teammate messages are pointers; the durable content is always in `docs/briefs/`, `docs/sessions/`, `docs/team-handoffs/`, `{{TASK_TRACKER}}`, `<area>/LESSONS.md`, and `{{ARCH_DOC}}`. A fresh orchestrator runs `/orchestrate-start` and re-derives state from files; a fresh implementer runs `/session-start`; a fresh lead runs `/team-start` and (if continuing from a paused team) reads the most recent `docs/team-handoffs/` doc.

The lead's **live task board** (`TaskCreate`/`TaskUpdate`) is an **ephemeral view** of `{{TASK_TRACKER}}` "Currently in progress" + the active phase — convenient for tracking, never canonical. When they disagree, `{{TASK_TRACKER}}` wins. Updated at round boundaries and on escalation, not every message.

---

## Working tree

**Single working tree by default.** The build order usually means most slices don't overlap. Spawn a second implementer (and a git **worktree** via the `Agent` tool's `isolation: "worktree"`) **only** when two area slices are genuinely independent and in flight at once. Shared docs (`{{TASK_TRACKER}}`, `{{ARCH_DOC}}`, session docs) live at the repo root — keep their edits on the orchestrator to avoid worktree merge friction. "Explicit `git add <path>`, never `git add -A`" matters more with parallel agents.

---

## Single-operator fallback

You can run this **without** a team — one human driving an orchestrator session and an implementer session, acting as the bridge yourself (the original two-session model). The "direct teammate comms" become "you paste between the two sessions," and the escalation taxonomy collapses (everything is already in front of you). The file-state discipline, the `/tdd` steps, the routing matrix, and the commit cadence are identical. (If you generated this scaffolding in single-operator mode, this file shouldn't exist — the generator skips it.)
