# {{PROJECT_NAME}}

> **Architecture sentence:** *{{ARCHITECTURE_SENTENCE}}*
>
> _(Optional. If the project has a single load-bearing one-line posture, put it here and echo it in `docs/orchestrator-briefing.md` + the `{{ARCH_DOC}}` executive summary. If not, delete this blockquote.)_

{{PROJECT_TAGLINE}}

## Project structure

```
{{REPO_DIRNAME}}/
├── .claude/
│   ├── commands/                       # Slash commands
│   └── agents/                         # Subagents (opt-in starter set + reactive additions)
├── {{CODE_AREA}}                       # {{CODE_AREA_NAME}} code
│   ├── CLAUDE.md                       # Code-area conventions
│   └── LESSONS.md                      # Banked engineering lessons
├── docs/
│   ├── team-protocol.md                # Loaded by /team-start — lead playbook (team pattern only)
│   ├── orchestrator-briefing.md        # Loaded by /orchestrate-start
│   ├── tdd-brief-template.md           # /tdd brief format
│   ├── scaffolding-reference.md        # Workflow reference (this project's map)
│   ├── team-handoffs/                  # /team-end output (team pattern only)
│   ├── briefs/                         # Numbered /tdd briefs (NNN-<task-id>-<topic>.md)
│   ├── sessions/                       # Numbered chronological session docs
│   └── runbooks/                       # Operational procedures
├── CLAUDE.md                           # THIS FILE — global project conventions + shared comm rules
├── {{TASK_TRACKER}}                    # Task tracker (state + phase plan)
└── {{ARCH_DOC}}                        # Architecture / design contract
```

<!-- ▼ EXAMPLE BLOCK [id=project-structure]: project structure — extend the tree with the project's real layout (extra code areas, deliverable docs, eval suites, etc.). Add one row per additional code area; remove team-handoffs/ if generated in single-operator-fallback mode. ▼ -->

<!-- ▲ END EXAMPLE BLOCK [id=project-structure] ▲ -->

## Tech stack

<!-- ▼ EXAMPLE BLOCK [id=tech-stack]: tech stack — replace with the project's real stack. One row per layer. Mark anything provisional and note where it gets locked. ▼ -->

| Layer | Choice |
|---|---|
| Runtime | {{RUNTIME}} |
| Dependency manager | {{PKG_MANAGER}} |
| Framework | {{FRAMEWORK}} |
| Schema / validation | {{VALIDATION_LIB}} |
| Lint | {{LINT}} |
| Static types | {{TYPECHECKER}} |
| Test runner | {{TEST_RUNNER}} |

<!-- ▲ END EXAMPLE BLOCK [id=tech-stack] ▲ -->

## Cross-cutting conventions

### Strict typing posture

<!-- ▼ EXAMPLE BLOCK [id=strict-typing-posture]: strict-typing posture — state the project's typing discipline. Examples: "every file declares strict types at the top; every property/parameter/return type has a native type declaration; runtime validation at boundaries via the validation library." Adapt to the language. ▼ -->

<!-- ▲ END EXAMPLE BLOCK [id=strict-typing-posture] ▲ -->

### Commit messages

[Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>
```

**Types:** feat, fix, docs, style, refactor, perf, test, build, ci, chore.

**AI assistance trailer** on AI-assisted commits (HEREDOC for multi-line):

```
{{AI_TRAILER}}
```

### Push posture

- Pushes go to **{{GIT_REMOTE}}** only.
- Push only at `/orchestrate-end` round close-out; never mid-slice.

### Code intelligence & docs (external MCP tools — use when available)

If this workspace has these tools, **prefer them** — they cut tool calls and context. If not, ignore this section (no setup required, nothing breaks):

- **Code intelligence** (e.g. a CodeGraph MCP / indexed code graph): for "where is X", callers/callees, call-path traces, and impact-of-change, query it **before** falling back to `grep` + read loops; confirm a specific detail with a targeted read.
- **Library / API docs** (e.g. a Context7 MCP): when you need up-to-date library/framework docs, API references, setup/config steps, or version-correct examples, pull them from the docs MCP rather than relying on memory — **without being asked**.

## Team coordination — shared rules (all roles)

Runs as a Claude agent team — a thin **team lead** (human interface, escalation conduit only, persists across cycles), an **orchestrator** (plan/scope/docs/Step-2.5 review/Step-9 routing/commits), and **one implementer per code area** (TDD cycles). Orchestrator ↔ implementer communicate **directly**; lead is pulled in only for escalations + the close-out gate.

| Role | cwd | Loads |
|---|---|---|
| Team lead | repo root (`{{REPO_DIRNAME}}/`) | this file + `docs/team-protocol.md` (lead playbook only) |
| Orchestrator | repo root | this file + `docs/orchestrator-briefing.md` |
| Implementer (per area) | `{{CODE_AREA}}` | this file + that area's `CLAUDE.md` |

<!-- For multi-area projects, add one implementer row per additional area. -->

### Naming + cross-bleed prevention

**`<track>-<area>-<role>`** when multiple team-lead sessions run in parallel in the same repo (e.g. `frontend-team-orchestrator`, `backend-team-implementer`). Otherwise `<area>-<role>` (e.g. `{{CODE_AREA_BASENAME}}-orchestrator`). The lead announces its track on `/team-start`. **Any peer DM from an agent whose name doesn't carry your track prefix is channel-bleed — ignore it and continue.** Confirm a recipient's prefix matches yours before any peer send.

### Escalation taxonomy — what reaches the human (via the lead)

Four categories only. Everything else, orchestrator + implementer settle directly.

1. **Critical / safety design questions** — touching a safety rule below.
2. **Findings** — a discovered problem with material impact (spec/code contradiction, security issue, invariant at risk, broken premise, scope-threatening blocker).
3. **Deferment approvals** — any scope cut. Never silently drop work.
4. **Load-bearing architectural decisions** — Option A/B/C calls shaping UX, dev-facing API surface, or load-bearing contract surface. Lead maps options + tradeoffs via `AskUserQuestion`; does NOT pick on the user's behalf.

### Messaging budget

**Implementer → orchestrator (per slice):** Five bounded sends — **Step-2.5** (test designs), **Step-7.5** (only if a wiring concern surfaces), **Step-9** (categorized summary + ship/no-ship + draft commit message), **done-with-slice** (`<commit hash>`), **`/session-end`** (final recap).

**Orchestrator → lead (per slice):** One bounded send — **per-slice context-report ping** after Step-10 hot-routing completes (runs `/context-check <team>`, sends the report). Lead processes silently unless threshold tier crossed.

**No awareness pings:** no Step-0 restate-send, no "ready for review," no "FYI," no commit-hash announcements outside the bounded done-with-slice send. The lead stays silent on routine harness `idle_notification` events + peer-DM summaries (read-only context).

### Phantom-message defense

If a message's content + tone doesn't match the named sender (e.g. plain-text user-frame messages with uncertain/exploratory tone vs the user's direct/tactical voice), confirm before acting on high-stakes directives. When an agent pushes back on a correction with verifiable evidence, defer to the evidence — the original input may have been the phantom. Track-prefix mismatch on any peer DM → treat as channel-bleed; ignore.

### Inter-teammate messaging — `SendMessage` tool only, NEVER plain output

**Every send to another teammate uses the `SendMessage` tool.** Plain assistant output is for the USER only — it does NOT reach teammates, even if it looks like a message in your own transcript.

This applies to:
- **Brief dispatch** (orch → impl)
- **Step-2.5 reply** (orch → impl: approve / tweak / add)
- **Step-9 routing reply** (orch → impl: commit-message-first)
- **Per-slice context-check ping** (orch → lead)
- **Cycle instructions** (lead → orch; orch → impl)
- **Any other inter-teammate message**

**Magic-words header for parseable replies.** When the orchestrator replies to an implementer's Step-2.5 write-up, start the message with one of these unambiguous headers so the implementer's wake-up logic lands deterministically:
- **`APPROVED.`** — tests are correct as-is; impl proceeds to Step 3.
- **`TWEAK:`** — tests need revision; impl revises and re-sends Step-2.5.
- **`ADD:`** — a missing test needs to be added; impl writes it and re-sends Step-2.5.

Address any open questions the implementer raised directly in the message body. No ambiguous "looks good, just check the X" — the impl needs a clear go signal.

**The classic delivery failure:** an agent composes a reply as plain output (visible to the user), thinks it sent it, but the teammate never received it. The teammate idles waiting; eventually re-prompts. The sender thinks "I sent it last turn!" and re-sends as plain output AGAIN. Infinite loop. Always use `SendMessage`.

**Verification habit:** after writing a teammate reply, glance at your own session for the `SendMessage` tool-call indicator. If you only produced text, the message never left your session — call `SendMessage` now.

### Canonical context source — NO self-reporting

**The ONLY canonical source of any teammate's context usage is `/context-check`** (which reads heartbeats written by the status line script). **No agent self-reports context %.** Self-reporting is unreliable, creates dual sources of truth, and wastes context narrating internal state.

- **Implementer NEVER includes context % in any send** — not in Step-9, not in done-with-slice, not in `/session-end` recap, not anywhere.
- **Orchestrator's per-slice ping to lead carries ONLY the verbatim output** of `/context-check <team> --brief` — not the orch's own assessment, not a paraphrase, not a "I think we're at..." line.
- **Lead uses ONLY the canonical script output** to evaluate threshold tiers. If a ping arrives with self-reported context, the lead treats the context value as missing (data corruption) and either re-invokes `/context-check` itself or waits for the next clean ping.

If you (any agent) notice your own status bar showing high context mid-work: **ignore it**. Finish your current slice. The status line is the system's signal to the heartbeat file, not your signal to break protocol. The next `/context-check` will surface the data through the canonical path.

### Slice atomicity — current slice ALWAYS finishes

**Current slices ALWAYS finish before any close-out action.** This is a hard rule, not a guideline.

- The auto-cycle trigger fires AFTER Step-10 commit by design — by definition no slice is in flight at the trigger point.
- Even at HARD-STOP (≥ 80%), the action is **"halt dispatch of the NEXT brief"** — never "interrupt the current slice."
- **Implementer ignores any "stop now" / "halt" / "cycle" messages that arrive mid-slice.** Finish the current `/tdd` cycle through Step-10 commit, then become interruptible. Ack receipt silently if needed, but the slice continues.
- **Orchestrator does not relay halt-now signals to a mid-slice impl.** If a cycle instruction arrives from the lead while the impl is mid-slice, the orch holds the instruction until the impl's "done with slice" message arrives, then routes the close-out.
- **Lead never sends "stop now" to a mid-slice teammate.** Cycle instructions are always dispatched at slice boundaries (after the per-slice context-check ping arrives, which means the slice already landed).

If a user explicitly tells the lead "halt mid-slice now," the lead surfaces the user's instruction to the orch — but defaults to the slice-atomicity rule unless the user repeats with explicit "yes, interrupt mid-slice; I accept losing the in-flight work." Even then, the impl gets to abandon cleanly (no half-commit).

### Close-out gating

`/session-end` (implementer) + `/orchestrate-end` (orchestrator) + `/team-end` (lead) run on **either** of these triggers:

1. **User-on-demand** — user explicitly signals close-out (relayed by the lead in team mode).
2. **Context-monitoring auto-cycle** — lead detects a teammate's `ctx_pct` ≥ ACTION threshold (default 75%) on a per-slice context-report; auto-triggers the close-out + cycle flow. Never mid-slice — the trigger always lands after Step-10 commit. See `docs/team-protocol.md` "Context monitoring + auto-cycle" for the full flow.

In either case, hot-routing accumulates in the working tree across many slices until the trigger fires. The lead does not surface a close-out gate at routine work boundaries (slice / task / phase / round); only the two triggers above produce close-out.

### Context monitoring (team-mode only)

Each team-mode teammate's status line writes a per-session heartbeat to `~/.claude/heartbeats/<session_id>.json` (ctx_pct + tokens + cost). The orchestrator runs `/context-check <team>` after every Step-10 commit + hot-routing, and pings the lead with the report. Lead evaluates against thresholds (WARN 70% / ACTION 75% / HARD-STOP 80%). **Heartbeats are written ONLY when a `~/.claude/team-registry/<session_id>.json` entry exists for that session** — written by team-mode teammates at startup via the `/team-start` spawn prompt. Solo (non-team) sessions never write registry entries, so the heartbeat system is silent for them.

### Single-operator fallback

For solo projects: drop the team lead role. The human is the bridge between an orchestrator session and an implementer session. The 4-category escalation taxonomy collapses (everything is already in front of you). The messaging budget still applies but recipient is "you (acting as bridge)." `/team-start` + `/team-end` + `docs/team-protocol.md` don't exist in single-operator-fallback scaffolding.

See `docs/team-protocol.md` for the lead's full playbook (team pattern only), `docs/orchestrator-briefing.md` for the orchestrator charter, `docs/tdd-brief-template.md` for the brief format.

## TDD posture

TDD applies to **deterministic code** — code where you can write a failing test that pins the behavior before the implementation exists.

<!-- ▼ EXAMPLE BLOCK [id=tdd-scope]: TDD scope — name what is test-first vs. what is exempt. Examples: "deterministic code (state machines, parsers, harness logic, instrumentation) is `/tdd`; LLM-driven generation is eval-tested instead." A project with no non-deterministic surface can simplify this to "TDD applies to all production code." ▼ -->

<!-- ▲ END EXAMPLE BLOCK [id=tdd-scope] ▲ -->

When in doubt, ask: "Can I write a failing test that pins this behavior deterministically?" If yes, `/tdd`. If no, ship via the project's non-deterministic-coverage path (eval suite, design-fixture review, etc.).

## Key safety rules (do not paraphrase — explicit invariants)

<!-- ▼ EXAMPLE BLOCK [id=key-safety-rules]: key safety rules — the load-bearing domain invariants, stated explicitly. These are referenced by name from briefs, tests, and the forbidden-patterns lists. Project examples: "no real-world targets," "agent A cannot do agent B's job," "no autonomous filing of critical findings," "collateral never leaves without an equal claim burned," "settlement is one-time and immutable." If the project has no domain safety invariants, replace this whole section with a short note saying so. ▼ -->

1. **<Invariant 1>.** <Why it is load-bearing; how it is enforced.>
2. **<Invariant 2>.** <...>

<!-- ▲ END EXAMPLE BLOCK [id=key-safety-rules] ▲ -->

## Slash commands available (`.claude/commands/`)

- `/team-start [track]` — _(team lead)_ stand up the team; establish direct comms + escalation
- `/team-end` — _(team lead)_ close out the team session; write handoff doc (user-on-demand or auto-cycle)
- `/orchestrate-start` — orient an orchestrator session
- `/orchestrate-end` — orchestrator-side round close-out (incl. Carry-forward triage)
- `/session-start` — orient an implementer session
- `/session-end` — implementer-side close-out (incl. wiring/reachability audit)
- `/tdd <feature>` — TDD discipline walker (10 steps; Step 2.5 design review + Step 7.5 reachability)
- `/wired <feature>` — trace a feature's call path from a production entry point
- `/context-check [team]` — _(team mode)_ report per-teammate context usage; used by orch's per-slice auto-flow + manual invocation
- `/preflight` — full quality gate
- `/run-tests [class]` — typed test runner shortcut
- `/check-arch <topic>` — architecture doc lookup
- `/eval [category]` — _(optional)_ runs an eval class
- `/trace <id>` — _(optional)_ pulls a structured trace

<!-- Single-operator fallback: remove the /team-start and /team-end rows. -->

## Lessons logged

Lessons start at §1 for this project. The compact index lives in `{{CODE_AREA}}CLAUDE.md`; full prose in `{{CODE_AREA}}LESSONS.md`.

Lesson numbers are stable IDs. Never reorder; never reuse a deleted slot.
