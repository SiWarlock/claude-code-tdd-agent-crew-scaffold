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
contract, a spec-anchored `IMPLEMENTATION_PLAN.md` with end-to-end traceability (PRD→REQ→§→task→`spec(§X)`-tagged
test, linted by `spec-lint`), a hard 10-step `/tdd` walker, hot-routed Step-9 categorization, PreToolUse
guard hooks that mechanically enforce the git/territory/secrets rules, an **executed** phase-exit gate
(`/phase-exit` runs the checklist: reachability + arch-drift + spec-coverage, plus posture-gated
audit/security/perf rows), a 4-category escalation taxonomy, per-slice context monitoring with auto-cycle,
and a provenance-manifest 3-way-merge upgrade path.

---

## How it works — end to end

```
 PRD
  │
  ▼  ┌─ Brain 1: GPT-5.5 / Codex (host-neutral) ──────────────────────────┐
 /arch-draft ── deep architecture-planning interview ──▶ docs/planning/*   │  rough draft + artifacts
  │            (PRESEARCH, RESEARCH, DECISIONS, DIAGRAM_PLAN, … by mode)    │
  ▼  ┌─ Brain 2: Claude Code (Opus 4.8 + Ultracode) ─────────────────────┐
 /arch-finalize ── ~15-dimension gap audit + adversarial scrutiny ──▶ 🔒 ARCHITECTURE.md   (binding contract + PRD→REQ coverage table)
  │
  ▼
 /tasks-gen ── decompose, anchor every task to a §  ──────────────────▶ 🔒 IMPLEMENTATION_PLAN.md     (spec-anchored plan + parallel track map)
  │
  ▼
 /scaffold-generate ── personalize the harness + stamp provenance ───▶ .claude/ + CLAUDE.md + docs/ + .scaffolding/manifest.json
  │
  ▼
 the 🔒 /tdd agent-team engine builds it slice by slice
  │      (team lead · orchestrator · implementer-per-area · 10-step TDD walker
  │       · guard hooks · /phase-exit gate per phase: audits + spec coverage + posture-gated rows)
  ▼
 review · ship · deploy · compound        ← composed plugins (gstack / CE), see ROUTING.md
  │
  ├─▶ /layer-docs → /learn-site ── document the layers + build an interactive learning site (near project's end)
  │
  └─▶ /scaffold-upgrade ── pull later scaffolding improvements via 3-way merge, anytime
```

**Two brains, on purpose.** `arch-draft` runs on **GPT-5.5/Codex** (Brain 1); `arch-finalize` runs on
**Claude Opus 4.8** (Brain 2). Two independent models over the architecture — one drafts, the other
adversarially finalizes — catch more than one model reviewing its own work twice. The handoff is
file-based (`docs/planning/`). Claude then writes the task spec and runs the whole build; GPT can return as
an optional cross-model reviewer at finalize.

**Three guardrails are owned by cc-crew's own skills and never delegated to a plugin:** the binding
`ARCHITECTURE.md` contract, the spec-anchored `IMPLEMENTATION_PLAN.md`, and the hard `/tdd` ordering (the 🔒 above).
Plugins feed-into or review *around* them — they never author them.

**Posture, demo, and parallelism are decided up front, not improvised.** Planning opens with an explicit
**build posture** gate — **production-grade** (the default: architecturally-correct, best-practice, with
auth / validation / observability / rollback *in scope*) or **MVP / prototype** (lean, with flagged
deferrals) — which steers the whole build; it's always asked, never silently assumed. A **demo** is an
explicit **optional** phase, never wired into the mandatory build order. And `tasks-gen` records the task
**dependency graph** + a **parallel track map** (derived from the architecture's `§2.5` subsystem dependency
DAG) — so independent tracks can each run in their **own git worktree with their own agent team**, collapsing
a serial build onto its critical path.

---

## The skills (the planning chain)

Five custom skills run the planning/scaffolding chain (below), plus two standalone debug skills (**`bug-hunt`**,
**`eval-triage`**) and an end-of-project comprehension pair (**`layer-docs`**, **`learn-site`**) — all run from
this checkout (see `skills/README.md` to install). `arch-draft`, `bug-hunt`, `eval-triage`, and `layer-docs`
are host-neutral (Codex or Claude); the rest run on Claude Code.

| Skill | Runs on | What it does |
|---|---|---|
| **`arch-draft`** | GPT-5.5 / Codex (host-neutral) | PRD → architecture **rough draft** + supporting artifacts, via the Deep Architecture-Planning Playbook (interview-gated; **sets the always-confirmed build posture** — production-grade vs MVP; captures the §2.5 dependency DAG; never codes) → `docs/planning/` |
| **`arch-finalize`** | Claude Code | gap audit + adversarial scrutiny of the draft → the binding **`ARCHITECTURE.md`** (incl. the `§2.5` parallelization seams the tasks layer reads) |
| **`tasks-gen`** | Claude Code | decompose the contract → spec-anchored **`IMPLEMENTATION_PLAN.md`** (every task anchored to a `§`; **+ a dependency graph + a parallel track map** for worktree-per-track builds) |
| **`scaffold-generate`** | Claude Code | personalize the agent-team harness into the project + stamp `.scaffolding/manifest.json` |
| **`scaffold-upgrade`** | Claude Code | keep an already-generated project's scaffolding current via a provenance-manifest **3-way merge** (propose-don't-clobber) |

`skills/ROUTING.md` is the thin routing layer: which skill owns each lifecycle stage and where the composed
plugins (and the conditional MCP tools) slot in around them.

**Plus two standalone skills** (host-neutral; Codex or Claude, any session, any repo — **not** lifecycle stages):
- **`bug-hunt`** — on-demand root-cause debugging: reproduce-with-a-failing-test (strong default) → localize →
  root cause → fix through the `/tdd` loop → verify → opt-in compound into a `LESSONS.md` lesson + forbidden-pattern.
- **`eval-triage`** — guided, *participatory* diagnosis of a failing **agentic/LLM eval**: reproduce → compare
  vs a passing eval → bisect the pipeline → categorize (eval/judge · prompt · retrieval · tool-use · state ·
  drift · parsing) → minimal-fix proposal → verify. It pauses at each phase so you stay in the loop and can
  narrate the reasoning.

**Plus an end-of-project comprehension pair** (run in a fresh session from inside the finished project — **not**
lifecycle stages; they degrade to code-only when planning docs are absent):
- **`layer-docs`** (host-neutral) — deep end-to-end analysis of the code **+** the planning/architecture docs →
  derive the project's real **layers** → write `docs/layers/OVERVIEW.md` + one digestible doc per layer
  (executive summary first, depth below). Faithful: cites `file:line`, flags architecture-vs-code drift.
  **Re-runnable** — later runs incrementally update only what changed (preserving hand-edits; `--check` for drift).
- **`learn-site`** (Claude Code) — turn `docs/layers/` into an **interactive learning website** in
  `docs/learn-site/` (clickable layer map, "follow a request" walkthrough, **Plain-English ⇄ Deeper-Dive**
  toggle per topic). Static/zero-build by default; React only when interactivity earns it. Runs **after `layer-docs`**.

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

**Mechanical guardrails:** PreToolUse hooks block `git add -A`, implementer pushes, orchestrator-territory
writes, and staged secrets (gitleaks); `scripts/spec-lint.sh` gates every brief pre-dispatch; **`/phase-exit`**
executes the phase-exit checklist (auditor fan-outs + spec coverage + the posture-gated audit/security/perf
trio) and a phase closes only on its CLEAR verdict.

**Four escalation categories** reach the human via the lead (critical/safety design questions, findings,
deferment approvals, load-bearing architectural decisions); everything else the orchestrator and implementer
settle directly. **Per-slice context monitoring + auto-cycle** (team mode) cleanly cycles teammates at a
threshold, never mid-slice. **Parallel tracks** (team mode): when the plan's track map marks independent
tracks, each runs in its **own git worktree with its own team** — `/team-start <track>` scopes the track's
phases + provisions the worktree, and merges follow a DAG-topological order; single-track plans run in one
working tree. **Single-operator fallback** (no agent-teams feature available) drops the lead and the human
bridges two sessions (serial build).

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
| **gstack** (`gstack/`, Garry Tan) | Product discovery (`/office-hours`) on the left; cross-model arch review (`/plan-eng-review`, `/codex`) at finalize; the only path reaching production (`/ship` → `/land-and-deploy` → `/canary`) + cross-project memory; `/cso` as the heavier security escalation at phase gates. | Optional plugin |
| **Claude Code built-ins** | `/security-review` is the default whole-system security tool at phase-exit gates (the branch's pending changes); gitleaks (if installed) makes the secrets hook blocking. | Built-in / optional |
| **Conductor** | A host that runs Claude Code **and** Codex side by side — the natural home for the cross-model planning lane (GPT drafts, Claude finalizes) and for parallel sprints. | Optional host |
| **CodeGraph** (code-intelligence MCP) | An indexed code graph. When present, agents prefer it for "where is X", callers/callees, call-path traces, and impact-of-change over `grep`+read loops. | Optional MCP (conditional) |
| **Context7** (docs MCP) | Up-to-date library/framework documentation, API references, setup/config steps, version-correct examples. When present, agents prefer it over memory — without being asked. | Optional MCP (conditional) |

The conditional MCP preference is codified throughout the generated scaffolding (`CLAUDE.md`, `/tdd`, the
orchestrator briefing), in all five skills, and in the user's global `~/.claude/CLAUDE.md` — always phrased
so it's a no-op when the MCP isn't installed. **How the composed plugins slot into each lifecycle stage is
the job of `skills/ROUTING.md`.**

---

## Host axis — Claude Code **or** Codex CLI

The generator can target two hosts from the **same `templates/` tree** (chosen at generation time;
recorded as `host` in the provenance manifest, so `/scaffold-upgrade` stays host-correct):

- **Claude Code (default)** — the `.claude/` layout: root + area `CLAUDE.md`, `.claude/commands/*.md`,
  `.claude/agents/*.md`, `.claude/settings.json`. Full team pattern + single-operator.
- **Codex CLI** — the Codex layout: root + nested `AGENTS.md`, slash commands as `.agents/skills/<name>/SKILL.md`
  (Codex's real skill loader never scans a bare-root `skills/`), `.codex/config.toml` (`[mcp_servers]` +
  `[[hooks.PreToolUse]]` guards — the confirmed canonical project-config location). The **solo core** (one
  Codex session running `/tdd` directly) is the **supported** Codex path — Codex has no peer-teammate /
  shared-task-list primitive, so the agent-team coordination layer can't port 1:1.

> ⚠️ **EXPERIMENTAL — Codex multi-agent team overlay (WIP).** An opt-in overlay maps the team layer onto
> Codex's **experimental, unstable** `collaboration_mode` / `spawn_agent` v2 APIs (root-session-as-lead →
> orchestrator → per-slice implementer → reviewers). It has real caveats — **no native git-worktree
> isolation, `codex exec` exits 0 even on failure, `--output-schema` support by model family is
> version-dependent (confirm on yours), no context-% signal** — and is **OFF by default** (two switches: opt in at generation AND enable Codex's
> collab mode at runtime; on any preflight failure it falls back to solo). **Do not depend on it**; pin a
> known-good Codex version and re-validate per release. Full design + the complete caveat list:
> **`docs/codex/team-overlay.md`**.

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
   run **`/arch-finalize`** → **`/tasks-gen`**. This yields a binding `ARCHITECTURE.md` + `IMPLEMENTATION_PLAN.md`.

4. **Generate the harness:** run **`/scaffold-generate`** (or hand a fresh Claude Code session
   `GENERATE-WITH-CLAUDE.md` + your arch doc). It interviews you for anything it can't infer — it **never
   fabricates** — pauses for plan approval, writes the scaffolding, pauses again before any commit. You
   commit yourself.

5. **Build:** `/team-start` — the team pattern is the default for all projects; a solo dev runs **team mode
   (single track)** (`/orchestrate-start` + `/session-start` only in the no-agent-teams fallback) — then the
   `/tdd` walker builds each slice against the contract + the task plan, and `/phase-exit` closes each phase.

6. **Stay current:** as this repo evolves, run **`/scaffold-upgrade --check`** in your project to see drift,
   then `/scaffold-upgrade` to merge improvements without clobbering your customizations.

---

## What's in the box

```
cc-crew/
├── README.md                  ← you are here
├── SCAFFOLDING-GUIDE.md       ← how the agent-team pattern works (read for context)
├── GENERATE-WITH-CLAUDE.md    ← the Claude-facing generation procedure (§7 steps, §10 placeholders, Step 12.5 manifest)
├── skills/                    ← all 9 cc-crew skills (SKILL.md + bundled references/) + README.md + ROUTING.md
│   ├── arch-draft/  arch-finalize/  tasks-gen/  scaffold-generate/  scaffold-upgrade/   ← planning chain
│   ├── bug-hunt/  eval-triage/                                                          ← standalone debugging
│   └── layer-docs/  learn-site/                                                         ← end-of-project comprehension
├── migrations/                ← structural-migration registry for /scaffold-upgrade (registry.json + M-NNNN docs)
├── scripts/release-check.sh   ← the repo's fail-loud release gate (pairs · census · migrations · upgrade-dryrun · playbook)
├── tests/                     ← frozen upgrade dry-run fixture + harness (runs the real scaffold_upgrade.sh end-to-end)
├── docs/plans/                ← committed implementation plans (e.g. the 2026-06 optimization wave)
├── docs/archive/              ← frozen snapshots kept for provenance (banner-marked; live copies in skills/)
└── templates/                 ← every scaffolding file as a project-agnostic template
    ├── CLAUDE.md              ← root project conventions + shared comm rules
    ├── area-CLAUDE.md         ← per-code-area conventions
    ├── area-LESSONS.md        ← per-code-area lessons (empty at bootstrap)
    ├── IMPLEMENTATION_PLAN.md ← state + phase plan skeleton
    ├── ARCHITECTURE.md        ← design-contract skeleton (used only if the user has none)
    ├── .scaffolding/          ← generator-owned provenance (manifest.json + README) — enables clean upgrades
    ├── docs/                  ← team-protocol · orchestrator-briefing · tdd-brief-template · scaffolding-reference
    ├── scripts/               ← user-global helpers (statusline + context-check) + project-local spec-lint.sh + guards/
    └── .claude/
        ├── settings.json      ← PreToolUse guard-hook wiring (generated project-local)
        ├── commands/          ← slash commands (13 team / 10 single-operator + 2 optional; incl. /phase-exit)
        └── agents/            ← README + 5 optional starter subagents (incl. arch-drift-auditor)
```

Each template uses two substitution mechanisms:

- **`{{PLACEHOLDER}}`** — inline single-value substitution (e.g. `{{PROJECT_NAME}}`, `{{TEST_CMD}}`).
- **`<!-- ▼ EXAMPLE BLOCK [id=<slug>]: … ▼ -->` … `<!-- ▲ END EXAMPLE BLOCK [id=<slug>] ▲ -->`** — wholesale
  block replacement for project-specific sections (forbidden patterns, safety rules, layer DAG, worked
  examples). The `[id=<slug>]` is stable across versions so `/scaffold-upgrade` can merge each block
  independently. The full placeholder manifest + the id map are in `GENERATE-WITH-CLAUDE.md §10`.
- **`<!-- ▼ MODE […] … ▼ -->` regions** (template-only) — mode-specific prose pruned at generation per the
  project's derived state (solo / team-single-track / team-multi-track), so each generated file carries only
  its own mode's text; `/scaffold-upgrade` replays the pruning when rebuilding its merge trees.

A **provenance manifest** (`.scaffolding/manifest.json`) is stamped at generation (Step 12.5): the
scaffolding commit, your resolved placeholder values, and a ledger of every generated file + EXAMPLE-BLOCK
region. It's what makes `/scaffold-upgrade` a clean 3-way merge instead of a hand-diff.

---

## When to use this — and when not

**Team pattern (the default — for ALL projects, including solo developers):** a solo dev runs **team mode
(single track)** — the full 3-role team in one worktree; parallel work adds tracks. Strongest where
architectural invariants matter (safety, security, correctness), across multiple code areas and work streams.
**Single-operator fallback:** environments without the agent-teams feature. Its two concrete losses: (1) the
human relays every Step-2.5/Step-9 exchange by hand; (2) no context monitoring or auto-cycle exists in solo mode.
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

Run **`/scaffold-upgrade`** (the `scaffold-upgrade` skill) **from inside your project** — **never hand-diff**.
The skill is global (never vendored) and **fetches the template source itself**: by default it clones the
manifest's `scaffoldingRepo` at the target ref into a throwaway checkout (use `--scaffold <path>` to point at
a local checkout instead) — so you never need this repo pre-cloned at a known path. Using the provenance
manifest, it re-derives the templates at your generation commit and at the target ref with your stored values
and does a **3-way merge**: it auto-applies only the
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

The **Codex host axis** (generate for Claude Code **or** Codex CLI from one templates tree) is newer: the
Codex **solo core** is verified end-to-end by a dedicated upgrade dry-run fixture (`tests/fixtures/upgrade-dryrun-codex/`).
The **Codex multi-agent team overlay** is **EXPERIMENTAL / WIP** — built on Codex's unstable
`collaboration_mode`/`spawn_agent` APIs, OFF by default, with a solo fallback; treat it as a preview and
re-validate per Codex release (`docs/codex/team-overlay.md`).

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
