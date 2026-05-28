# Claude Agent-Team Scaffolding

> A project-agnostic Claude Code scaffolding + workflow for non-trivial software projects. **Three-role agent team** (team lead + orchestrator + implementer-per-area) with enforced TDD, hot-routed Step-9 categorization, cross-document invariants, atomic per-slice commits, and explicit close-out gating. **Single-operator fallback** for smaller projects.

A fresh Claude Code session reads this repo + your project's architecture document, interviews you for what it can't infer, and generates a customized scaffolding into your project — slash commands, briefing docs, area-specific `CLAUDE.md` files, task tracker skeleton, and optional starter subagents.

---

## Why use this

If your project is more than one session of work, you've probably hit these:

- **Scope drift across sessions** — week 3 re-derives what week 1 settled, slightly wrong.
- **TDD-by-vibes** — "I'll write the tests after" is the default failure mode.
- **Cross-doc drift** — typed models drift from spec; spec drifts from code; test pins drift from spec.
- **Lost session output** — "this should be a lesson" / "this needs a doc note" piles up in scratch files and never gets acted on.
- **Context-budget pressure** — one session doing planning + coding + commits + scope decisions burns context fast; agents that can't self-report context reliably burn through their windows mid-task.
- **Channel-bleed in multi-team work** — parallel sessions cross-message; debugging takes longer than the work.
- **Manually cycling agents at the right moment** — too early wastes work; too late degrades output.

This scaffolding addresses each via concrete machinery: a 10-step `/tdd` walker with a mandatory test-design review checkpoint, hot-routed Step-9 categorization, an enforced cross-doc invariants table, a 4-category escalation taxonomy, track-prefix naming for multi-team work, bounded messaging budgets, and **per-slice context monitoring with auto-cycle at threshold** (the lead detects when teammates hit the ACTION threshold and auto-triggers close-out + spawns successors at the next clean slice break).

---

## Quick start

1. **Have an architecture document** for your project (typically `ARCHITECTURE.md` at repo root, but any path works). This is the **primary input** — the generator reads it end-to-end and extracts everything it can: tech stack, code areas, subsystem boundaries, safety invariants, deliverables. The more your arch doc captures, the less the generator interviews you for.

2. **Clone or copy this scaffolding repo** somewhere accessible:
   ```bash
   git clone <this-repo> ~/scaffolding
   ```

3. **Open a fresh Claude Code session** at your project's repo root.

4. **Give it the package** with this prompt (adjust the paths):

   > I want to set up the Claude agent-team scaffolding for this project. I've placed the scaffolding template at `~/scaffolding/` and my architecture doc is at `./ARCHITECTURE.md`. Please read `~/scaffolding/GENERATE-WITH-CLAUDE.md` end-to-end first, then read my architecture doc end-to-end as the primary input for personalization. Interview me interactively for anything you can't infer or anything that's ambiguous — don't fabricate values. Once you've gathered everything you need, present a generation plan for my approval before writing any files. Don't commit the scaffolding; I'll review and commit it myself.

5. **Answer the interview.** The session will ask interactively (via `AskUserQuestion` for structured choices, conversationally for the rest). Topics: team pattern vs single-operator, code areas, stack details, phase plan, deliverables, safety invariants, optional commands, optional starter subagents.

6. **Approve the generation plan, then review what it wrote.** The session pauses before generating and again before commit. You commit yourself.

---

## What's in the box

```
scaffolding/
├── README.md                  ← you are here
├── SCAFFOLDING-GUIDE.md       ← how the pattern works (read for context)
├── GENERATE-WITH-CLAUDE.md    ← Claude-facing generation instructions
└── templates/                 ← every scaffolding file as a project-agnostic template
    ├── CLAUDE.md              ← root project conventions + shared comm rules
    ├── area-CLAUDE.md         ← per-code-area conventions
    ├── area-LESSONS.md        ← per-code-area lessons (empty at bootstrap)
    ├── MVP_TASKS.md           ← state + phase plan skeleton
    ├── ARCHITECTURE.md        ← design contract skeleton (used only if user has none)
    ├── docs/
    │   ├── team-protocol.md       ← lead playbook (team pattern only)
    │   ├── orchestrator-briefing.md ← workflow rulebook
    │   ├── tdd-brief-template.md  ← /tdd brief format
    │   └── scaffolding-reference.md ← project-specific scaffolding map
    ├── scripts/              ← user-global helpers (statusline + context-check; install to ~/.claude/ once per machine)
    └── .claude/
        ├── commands/          ← slash commands (13 team / 11 single-operator + 2 optional)
        └── agents/            ← README + 4 optional starter subagents
```

Each template uses two substitution mechanisms:

- **`{{PLACEHOLDER}}`** — inline single-value substitution (e.g. `{{PROJECT_NAME}}`, `{{TEST_CMD}}`).
- **`<!-- ▼ EXAMPLE BLOCK: ... ▼ -->` ... `<!-- ▲ END EXAMPLE BLOCK ▲ -->`** — wholesale block replacement for sections that are project-specific (forbidden patterns, safety rules, layer DAG, worked examples).

The full placeholder manifest is in `GENERATE-WITH-CLAUDE.md §10`.

---

## The pattern in 30 seconds

**Three Claude Code sessions, each a distinct role, communicating through files + bounded direct messages:**

- **Team lead** (thin, durable) — the human's interface + escalation conduit. Persists across many orchestrator/implementer cycles. Owns `/team-start` and `/team-end`. Stays silent on routine traffic.
- **Orchestrator** — plans, scopes, authors `/tdd` briefs, reviews test designs at Step 2.5, routes Step-9 flags hot, writes all commit messages. Talks directly to the implementer.
- **Implementer (per code area)** — runs `/tdd` cycles. Talks directly to the orchestrator.

**Four escalation categories** reach the human via the lead: critical/safety design questions, findings, deferment approvals, load-bearing architectural decisions. Everything else, the orchestrator and implementer settle directly.

**Per-slice context monitoring + auto-cycle** — the status line writes a heartbeat per session (team-mode only; solo sessions are unaffected); the orchestrator runs `/context-check <team>` after every Step-10 commit and pings the lead with each teammate's `ctx_pct`. Lead evaluates against tiers (WARN 70% / ACTION 75% / HARD-STOP 80%): silent below 70%; one-line surface at WARN with trajectory estimate; **auto-trigger close-out cycle at ACTION** (never mid-slice — the trigger fires after Step-10). **Both orch + impl cycle together** for clean handoff. Thresholds env-configurable.

**Close-out is user-on-demand OR auto-cycle** — `/session-end` / `/orchestrate-end` / `/team-end` run on explicit user go OR when context-monitoring detects ACTION threshold at a clean slice break. Never at routine work boundaries (slice/task/phase/round). Hot-routing accumulates in the working tree until the trigger fires.

**Commit cadence** is N+2 per round: N slice commits (Step 10) + 1 session-doc commit (`/session-end`) + 1 round commit (`/orchestrate-end`). The orchestrator authors every message. Push only at round end.

**Single-operator fallback:** drop the team lead, drop `/team-start`/`/team-end`, the human bridges between an orchestrator session and an implementer session. Everything else identical.

Full pattern documented in `SCAFFOLDING-GUIDE.md`.

---

## When to use this — and when not

### Use the team pattern when

- Project spans multiple sessions, ideally multiple weeks.
- Architectural invariants matter (safety, security, correctness — your project has rules you can't violate).
- Multiple code areas (e.g. backend + frontend).
- Parallel work streams are likely (e.g. you'll have a frontend track and a backend track running simultaneously).
- You want bisectable atomic commits with `why`-context in every message.

### Use the single-operator fallback when

- Solo developer, one human, no parallel tracks.
- Project fits in a sprint or so.
- One code area, simple stack.
- The team-lead role would just be you anyway.

### Skip this scaffolding entirely when

- It's a one-session script or a throwaway spike. Just write the code.
- Pre-existing scaffolding is working for you. Don't churn over preference.

---

## What you provide vs what you don't

**You provide:**
- An architecture document (the primary input).
- A target repo (where the scaffolding will land).
- Answers to clarifying questions during the interview.

**You don't have to provide:**
- A full phase plan — a skeleton with phase IDs + one-line goals is enough.
- Conventions, forbidden patterns, lessons — these seed near-empty and accrete through real work.
- A task tracker if you don't have one — the generator stubs one from your phase plan.

**Critical:** the generator does not fabricate values. If your architecture doc doesn't capture something and you can't answer the clarification, that's a real gap to resolve before the scaffolding lands.

---

## Project-specific vs workflow-universal

The pattern is universal; the content is yours. The generator personalizes the **project-specific** content:

- Stack (per code area)
- Code area names and directory layout
- Forbidden patterns
- Key safety rules / load-bearing invariants
- Architecture sentence (if your project has a one-line posture)
- Phase plan + phase ID convention
- Deliverable map
- Layer dependency rule + module organization
- Optional commands (`/eval`, `/trace`)
- Optional starter subagents (4 available, opt-in)

The **workflow machinery** stays verbatim — the 10-step `/tdd`, the Step-9 routing matrix, the commit cadence, the checkpoints, the escalation taxonomy, the close-out gating. Those are the *point* of the scaffolding.

---

## How to evolve your generated scaffolding

After bootstrap, when the workflow changes (new slash command, new routing destination, new convention), update the **scaffolding files**. When project state changes (phase advances, scope shifts), update the **state files** (`MVP_TASKS.md`, session docs, `LESSONS.md`). Don't mix the two.

Detail: `SCAFFOLDING-GUIDE.md §11` and the generated `docs/scaffolding-reference.md` in your project.

---

## Status

This scaffolding is in **active use** in real projects. The pattern has been refined through multiple project cycles; the template represents the current best-known version. Substantive evolution (new slash commands, new mechanisms, new subagents) lands in the template as it surfaces.

Updates to this repo are versioned via git; if you've generated scaffolding from an older version and want to incorporate later improvements, diff your generated files against the current templates and apply selectively.

---

## License

[Add license of your choice — MIT and Apache-2.0 are common for tooling like this.]

---

## Acknowledgments

This scaffolding evolved through real project use. Earlier versions used a two-session pattern with the human as manual bridge; the agent-team model emerged when multi-week safety-critical projects needed durable coordination state across orchestrator/implementer session cycles. The 4-category escalation taxonomy and track-prefix naming surfaced from specific incidents — channel-bleed in parallel-team work, awareness-ping fatigue, and the realization that load-bearing architectural decisions deserve their own escalation lane.
