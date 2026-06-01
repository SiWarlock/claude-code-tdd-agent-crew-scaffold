# cc-crew — a project-agnostic workflow from PRD to production

> **cc-crew** is an opinionated, project-agnostic workflow for building non-trivial software with AI agents.
> It runs a **cross-model planning front** (one model drafts the architecture, a second adversarially
> finalizes it), turns the result into a **binding architecture contract** and a **spec-anchored task plan**,
> generates a **three-role TDD agent team** into your repo, and keeps that scaffolding **upgradeable** over
> the project's life. Your methodology is the spine; Compound Engineering, gstack, Opus 4.8 Ultracode, and a
> couple of MCP tools compose **around** it.

The core (this repo) works on its own. Everything else in the [Tools & plugins](#tools--plugins) table is
**optional** — composed in when installed, a silent no-op when not.

---

## The problem it solves

If a project is more than one session of work, these failure modes show up:

- **The planning gap.** A PRD isn't buildable. Going PRD → architecture → tasks by hand (or in a single
  model pass) leaves gaps that surface mid-build as rework.
- **One model grading its own homework.** A single model that drafts *and* reviews its own architecture
  misses what a second, independent model would catch.
- **Scope drift across sessions.** Week 3 re-derives what week 1 settled, slightly wrong.
- **TDD-by-vibes.** "I'll write the tests after" is the default failure mode.
- **Cross-doc drift.** Typed models drift from spec; spec drifts from code; test pins drift from spec.
- **Context-budget pressure.** One session planning + coding + committing burns context fast; agents that
  can't self-report context reliably burn through their windows mid-task.
- **Lost session output + channel-bleed** in multi-session, multi-team work.
- **Scaffolding rot.** The harness improves upstream, but already-generated projects can't pull the
  improvements without clobbering their own customizations.

cc-crew addresses each with concrete machinery: a two-brain planning chain, a binding `ARCHITECTURE.md`
contract, a spec-anchored `MVP_TASKS.md`, a hard 10-step `/tdd` walker, hot-routed Step-9 categorization, a
4-category escalation taxonomy, per-slice context monitoring with auto-cycle, and a provenance-manifest
3-way-merge upgrade path.

---

## How it works — end to end

```
 PRD
  │
  ▼  ┌─ Brain 1: GPT-5.5 / Codex (host-neutral) ──────────────────────────┐
 /arch-draft ── deep architecture-planning interview ──▶ docs/planning/*   │  rough draft + artifacts
  │            (PRESEARCH, RESEARCH, DECISIONS, DIAGRAM_PLAN, … by mode)    │
  ▼  ┌─ Brain 2: Claude Code (Opus 4.8 + Ultracode) ─────────────────────┐
 /arch-finalize ── ~13-dimension gap audit + adversarial scrutiny ──▶ 🔒 ARCHITECTURE.md   (binding contract)
  │
  ▼
 /tasks-gen ── decompose, anchor every task to a §  ──────────────────▶ 🔒 MVP_TASKS.md     (spec-anchored plan)
  │
  ▼
 /scaffold-generate ── personalize the harness + stamp provenance ───▶ .claude/ + CLAUDE.md + docs/ + .scaffolding/manifest.json
  │
  ▼
 the 🔒 /tdd agent-team engine builds it slice by slice
  │      (team lead · orchestrator · implementer-per-area · 10-step TDD walker)
  ▼
 review · ship · deploy · compound        ← composed plugins (gstack / CE), see ROUTING.md
  │
  └─▶ /scaffold-upgrade ── pull later scaffolding improvements via 3-way merge, anytime
```

**Two brains, on purpose.** `arch-draft` runs on **GPT-5.5/Codex** (Brain 1); `arch-finalize` runs on
**Claude Opus 4.8** (Brain 2). Two independent models over the architecture — one drafts, the other
adversarially finalizes — catch more than one model reviewing its own work twice. The handoff is
file-based (`docs/planning/`). Claude then writes the task spec and runs the whole build; GPT can return as
an optional cross-model reviewer at finalize.

**Three guardrails are owned by cc-crew's own skills and never delegated to a plugin:** the binding
`ARCHITECTURE.md` contract, the spec-anchored `MVP_TASKS.md`, and the hard `/tdd` ordering (the 🔒 above).
Plugins feed-into or review *around* them — they never author them.

---

## The skills (the planning chain)

Five custom skills run the planning/scaffolding chain (below), plus a standalone **`bug-hunt`** debug skill —
all run from this checkout (see `skills/README.md` to install). `arch-draft` and `bug-hunt` are host-neutral
(Codex or Claude); the rest run on Claude Code.

| Skill | Runs on | What it does |
|---|---|---|
| **`arch-draft`** | GPT-5.5 / Codex (host-neutral) | PRD → architecture **rough draft** + supporting artifacts, via the Deep Architecture-Planning Playbook (interview-gated; never codes) → `docs/planning/` |
| **`arch-finalize`** | Claude Code | gap audit + adversarial scrutiny of the draft → the binding **`ARCHITECTURE.md`** |
| **`tasks-gen`** | Claude Code | decompose the contract → spec-anchored **`MVP_TASKS.md`** (every task anchored to a `§`) |
| **`scaffold-generate`** | Claude Code | personalize the agent-team harness into the project + stamp `.scaffolding/manifest.json` |
| **`scaffold-upgrade`** | Claude Code | keep an already-generated project's scaffolding current via a provenance-manifest **3-way merge** (propose-don't-clobber) |

`skills/ROUTING.md` is the thin routing layer: which skill owns each lifecycle stage and where the composed
plugins (and the conditional MCP tools) slot in around them.

**Plus a standalone skill — `bug-hunt`** (host-neutral; Codex or Claude, any session, any repo): on-demand
root-cause debugging — reproduce-with-a-failing-test (strong default) → localize → root cause → fix through
the `/tdd` loop → verify → opt-in compound into a `LESSONS.md` lesson + forbidden-pattern. It's **not** a
lifecycle stage; run it whenever a bug or incident surfaces.

---

## The agent-team engine (the build)

Once generated, the project runs **three Claude Code sessions**, each a distinct role, communicating through
files + bounded direct messages:

- **Team lead** (thin, durable) — the human's interface + escalation conduit. Persists across many cycles.
  Owns `/team-start` and `/team-end`. Silent on routine traffic.
- **Orchestrator** — plans, scopes, authors `/tdd` briefs, reviews test designs at Step 2.5, routes Step-9
  flags hot, writes every commit message.
- **Implementer (per code area)** — runs the **10-step `/tdd` walker**: `0 restate → 1 files → 2 RED →
  2.5 ⏸ test-design review → 3 confirm-RED → 4 GREEN → 5 confirm-GREEN → 6 refactor → 7 full suite →
  7.5 reachability → 8 type+lint → 9 hot-route → 10 atomic commit`.

**Four escalation categories** reach the human via the lead (critical/safety design questions, findings,
deferment approvals, load-bearing architectural decisions); everything else the orchestrator and implementer
settle directly. **Per-slice context monitoring + auto-cycle** (team mode) cleanly cycles teammates at a
threshold, never mid-slice. **Single-operator fallback** drops the lead and the human bridges two sessions.

Full detail: **`SCAFFOLDING-GUIDE.md`**. The generator procedure: **`GENERATE-WITH-CLAUDE.md`**.

---

## Tools & plugins

cc-crew is a **stack at different altitudes**, not a monolith. Only the core is required; the rest compose in
when present and are a silent no-op when absent.

| Tool | Role | Required? |
|---|---|---|
| **This repo** — the TDD agent-crew scaffolding + the 5 cc-crew skills | The methodology spine: planning chain → binding contract → spec-anchored tasks → 3-role TDD engine → upgrade path | **Required** (the core) |
| **Opus 4.8 Ultracode / Workflows** | In-session deterministic multi-agent execution substrate — speeds up fan-out-heavy steps (the gap-audit, multi-persona review, migrations). Serial fallback always exists. | Optional (amplifier) |
| **Compound Engineering** (`compound-engineering-plugin/`, everyinc) | Compounding-knowledge loop + a review-rubric panel + a skill/agent library. Composes at review + ship + compound stages. | Optional plugin |
| **gstack** (`gstack/`, Garry Tan) | Product discovery (`/office-hours`) on the left; cross-model arch review (`/plan-eng-review`, `/codex`) at finalize; and the only path reaching production (`/ship` → `/land-and-deploy` → `/canary`) + cross-project memory. | Optional plugin |
| **Conductor** | A host that runs Claude Code **and** Codex side by side — the natural home for the cross-model planning lane (GPT drafts, Claude finalizes) and for parallel sprints. | Optional host |
| **CodeGraph** (code-intelligence MCP) | An indexed code graph. When present, agents prefer it for "where is X", callers/callees, call-path traces, and impact-of-change over `grep`+read loops. | Optional MCP (conditional) |
| **Context7** (docs MCP) | Up-to-date library/framework documentation, API references, setup/config steps, version-correct examples. When present, agents prefer it over memory — without being asked. | Optional MCP (conditional) |

The conditional MCP preference is codified throughout the generated scaffolding (`CLAUDE.md`, `/tdd`, the
orchestrator briefing), in all five skills, and in the user's global `~/.claude/CLAUDE.md` — always phrased
so it's a no-op when the MCP isn't installed. **How the composed plugins slot into each lifecycle stage is
the job of `skills/ROUTING.md`.**

---

## Quick start

1. **Have an architecture document** (or run the planning chain to produce one). It's the **primary input**
   to generation — the more it captures (stack, code areas, subsystem boundaries, safety invariants,
   deliverables), the less the generator interviews you.

2. **Clone this repo**, then **install the skills** — symlink them into your global skills dirs:
   `arch-draft` into **both** `~/.codex/skills/` and `~/.claude/skills/` (it's host-neutral), the other four
   into `~/.claude/skills/`. Exact commands in **`skills/README.md`**. A *global* install means Conductor
   picks them up in **both** its Claude and Codex lanes; restart the host session to discover them.

3. **Plan (optional but recommended):** in Codex/Conductor run **`/arch-draft`** from your PRD → in Claude
   run **`/arch-finalize`** → **`/tasks-gen`**. This yields a binding `ARCHITECTURE.md` + `MVP_TASKS.md`.

4. **Generate the harness:** run **`/scaffold-generate`** (or hand a fresh Claude Code session
   `GENERATE-WITH-CLAUDE.md` + your arch doc). It interviews you for anything it can't infer — it **never
   fabricates** — pauses for plan approval, writes the scaffolding, pauses again before any commit. You
   commit yourself.

5. **Build:** `/team-start <track>` (team) or `/orchestrate-start` + `/session-start` (single-operator), then
   the `/tdd` walker builds each slice against the contract + the task plan.

6. **Stay current:** as this repo evolves, run **`/scaffold-upgrade --check`** in your project to see drift,
   then `/scaffold-upgrade` to merge improvements without clobbering your customizations.

---

## What's in the box

```
cc-crew/
├── README.md                  ← you are here
├── SCAFFOLDING-GUIDE.md       ← how the agent-team pattern works (read for context)
├── GENERATE-WITH-CLAUDE.md    ← the Claude-facing generation procedure (§7 steps, §10 placeholders, Step 12.5 manifest)
├── skills/                    ← the 5 cc-crew skills (SKILL.md + bundled references/) + README.md + ROUTING.md
│   ├── arch-draft/  arch-finalize/  tasks-gen/  scaffold-generate/  scaffold-upgrade/
├── migrations/                ← structural-migration registry for /scaffold-upgrade (registry.json + _TEMPLATE.md)
├── docs/archive/              ← superseded docs kept for reference (e.g. the playbook, now bundled into arch-draft)
└── templates/                 ← every scaffolding file as a project-agnostic template
    ├── CLAUDE.md              ← root project conventions + shared comm rules
    ├── area-CLAUDE.md         ← per-code-area conventions
    ├── area-LESSONS.md        ← per-code-area lessons (empty at bootstrap)
    ├── MVP_TASKS.md           ← state + phase plan skeleton
    ├── ARCHITECTURE.md        ← design-contract skeleton (used only if the user has none)
    ├── .scaffolding/          ← generator-owned provenance (manifest.json + README) — enables clean upgrades
    ├── docs/                  ← team-protocol · orchestrator-briefing · tdd-brief-template · scaffolding-reference
    ├── scripts/               ← user-global helpers (statusline + context-check; install to ~/.claude/ once per machine)
    └── .claude/
        ├── commands/          ← slash commands (12 team / 9 single-operator + 2 optional)
        └── agents/            ← README + 4 optional starter subagents
```

Each template uses two substitution mechanisms:

- **`{{PLACEHOLDER}}`** — inline single-value substitution (e.g. `{{PROJECT_NAME}}`, `{{TEST_CMD}}`).
- **`<!-- ▼ EXAMPLE BLOCK [id=<slug>]: … ▼ -->` … `<!-- ▲ END EXAMPLE BLOCK [id=<slug>] ▲ -->`** — wholesale
  block replacement for project-specific sections (forbidden patterns, safety rules, layer DAG, worked
  examples). The `[id=<slug>]` is stable across versions so `/scaffold-upgrade` can merge each block
  independently. The full placeholder manifest + the id map are in `GENERATE-WITH-CLAUDE.md §10`.

A **provenance manifest** (`.scaffolding/manifest.json`) is stamped at generation (Step 12.5): the
scaffolding commit, your resolved placeholder values, and a ledger of every generated file + EXAMPLE-BLOCK
region. It's what makes `/scaffold-upgrade` a clean 3-way merge instead of a hand-diff.

---

## When to use this — and when not

**Team pattern:** multi-session/multi-week projects, architectural invariants that matter (safety, security,
correctness), multiple code areas, parallel work streams, bisectable atomic commits.
**Single-operator fallback:** solo dev, fits in a sprint, one code area, no parallel tracks.
**Skip it entirely:** a one-session script or throwaway spike — just write the code.

---

## What you provide vs what you don't

**You provide:** an architecture document (the primary input), a target repo, and answers during the
interview. **You don't have to provide:** a full phase plan (a skeleton of phase IDs + one-line goals is
enough), conventions/forbidden-patterns/lessons (these seed near-empty and accrete through real work), or a
task tracker (the generator stubs one). **Critical:** the generator does not fabricate values — an
unanswerable gap is a real gap to resolve before the scaffolding lands.

---

## Keeping a generated project current

Run **`/scaffold-upgrade`** (the `scaffold-upgrade` skill) from a scaffolding checkout pointed at your
project — **never hand-diff**. Using the provenance manifest, it re-derives the templates at your generation
commit and at the target ref with your stored values and does a **3-way merge**: it auto-applies only the
machinery you never touched (`theirs == base`) and **proposes — never clobbers —** everything you
customized, leaving accreted state (`LESSONS.md`, your task tracker) and your architecture doc alone.
Structural changes a text-merge can't express ride version-gated, idempotent **migrations**. Two PAUSE gates
mirror the generation discipline; conflicts surface inline (never `.rej`) and block the commit until
resolved. `--check` reports drift without writing. Detail: **`SCAFFOLDING-GUIDE.md §11`**.

---

## Status

cc-crew's agent-team engine is in **active use** in real projects; the planning chain + upgrade path are the
newer cross-model + provenance layers around it. The composed plugins (CE, gstack), Ultracode, and the MCP
tools are optional and degrade gracefully when absent.

---

## License

[Add license of your choice — MIT and Apache-2.0 are common for tooling like this.]

---

## Acknowledgments

This workflow evolved through real project use. Earlier versions used a two-session pattern with the human as
manual bridge; the agent-team model emerged when multi-week safety-critical projects needed durable
coordination state across orchestrator/implementer session cycles. The 4-category escalation taxonomy and
track-prefix naming surfaced from specific incidents — channel-bleed in parallel-team work, awareness-ping
fatigue, and the realization that load-bearing architectural decisions deserve their own escalation lane. The
cross-model planning front and the provenance-manifest upgrade path were added to close the planning gap and
the scaffolding-rot gap, respectively.
