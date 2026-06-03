# cc-crew routing — when to use what

The thin routing layer: which skill owns each lifecycle stage, and where the **installed plugins**
(gstack, Compound Engineering) and **Ultracode** compose around your core. Pin this where you'll see it.

**🔒 Owned by your skills, never ceded:** the binding `ARCHITECTURE.md` (stage 3), the spec-anchored
`MVP_TASKS.md` (stage 5), and the hard `/tdd` ordering (stage 6). Plugins feed-into or review *around*
them — they never author them.

## Default happy-path (one tool per stage)

| Stage | Owner | Tool | Rule |
|---|---|---|---|
| 0 Bootstrap (once/machine) | one-time | gstack `/setup-deploy`, CE `ce-setup`; defer `/setup-gbrain` | run once, never per feature |
| 1 Discovery / PRD reframe | gstack | `/office-hours` *(GPT/Codex lane)* | optional — for "should this exist + narrowest wedge"; feeds the PRD into `arch-draft` |
| 2 Architecture draft | **you** | **`arch-draft`** (Codex/GPT-5.5) | the playbook interview → `docs/planning/` |
| 3 **Architecture CONTRACT** | **🔒 you** | **`arch-finalize`** (Claude) | gap-audit + adversarial → binding `ARCHITECTURE.md` |
| — arch review (during 3) | gstack/CE | `/plan-eng-review` + `/codex` (cross-model), CE `ce-doc-review` | READ-ONLY findings into the gap-audit; **never** `/autoplan` (it generates a plan) |
| 4 **Task tracker** | **🔒 you** | **`tasks-gen`** (Claude) | → spec-anchored `MVP_TASKS.md` |
| 5 Scaffold | **you** | **`scaffold-generate`** (Claude) | personalize the harness + stamp manifest |
| 6 **Implementation** | **🔒 you** | **`/tdd`** agent-team engine | forbid CE `ce-work` / gstack `/spec --execute` as the engine |
| 7 Code review | you → escalate | your 3 subagents → CE `ce-code-review` (rubric) → gstack `/review`+`/codex` (high-stakes) | never 4 passes on a trivial diff |
| 8 Security | gstack | `/cso` (OWASP+STRIDE) | at phase/release boundaries on sensitive surfaces |
| 9 QA (web) | gstack | `/qa`, `/design-review` | **skip entirely off-web** (backend/CLI/lib) |
| 10 Ship | CE | `ce-commit-push-pr` + `ce-resolve-pr-feedback` | atomic Step-10 commits stay inside `/tdd` |
| 11 Deploy / observe | gstack | `/land-and-deploy` + `/canary` + `/benchmark` | GitHub + web only; no auto-rollback (revert is a human gate) |
| 12 Compound | you + CE | `LESSONS.md` (in-build) + CE `ce-compound` | pick ONE durable store to start; defer GBrain |
| 13 Retro | gstack | `/retro global` | cross-project compounding visibility |
| 14 Orchestration | by shape | your agent-team (default) · Ultracode (in-session fan-out) · gstack Conductor (many sprints) | pick by altitude |
| 15 Debug / safety | gstack | `/investigate`, `/careful`, `/freeze`, `/guard`; CE `ce-debug` | `/freeze` is NOT a security boundary |

## Overlap resolutions (pick ONE)
- **Code review:** your subagents (default) → CE rubric (when you want the persisted confidence-anchor rubric) → gstack `/review`+`/codex` (cross-vendor, high-stakes only). Never triple-run on a trivial diff.
- **Planning front:** gstack `/office-hours` for the founder reframe; **your** playbook (`arch-draft`/`arch-finalize`) authors the contract; Ultracode SKIP.
- **Compounding store:** `LESSONS.md` (in-build) + CE `ce-compound` (one per-repo store); GBrain only when you commit to cross-machine memory.
- **Commit/ship:** your atomic Step-10 commits in `/tdd`; CE at the PR boundary; gstack `/ship` only when deploying next.

## Skip (don't reach for these)
- CE `ce-plan`/`ce-work` as the contract/engine · gstack `/spec --execute` (bypasses TDD) · gstack `/autoplan` as the arch reviewer (it's generative) · the 4 interactive gstack planners inside your crew/headless (they BLOCK) · `/freeze` as security · gstack QA/deploy/design for non-web · Ultracode as a methodology or for contract/tracker authoring.

## Keeping a generated project current
After bootstrap, pull later scaffolding improvements with **`scaffold-upgrade`** (run from a scaffolding checkout pointed at the project; `/scaffold-upgrade --check` for drift). It re-derives the templates at your generation commit + at HEAD using your stored placeholder values and **3-way-merges** upstream changes — auto-applying only machinery you never touched, *proposing* (never clobbering) everything you customized, leaving accreted state + your arch doc alone. This is a **maintenance operation, not a per-feature stage**. Detail: `SCAFFOLDING-GUIDE.md §11`.

## Standalone skills (on-demand, any session — NOT stages)
**`bug-hunt`** (host-neutral; Codex or Claude, any repo) — the cc-crew-owned, TDD-disciplined root-cause
loop: reproduce-with-a-failing-test (strong default) → localize → root cause → fix via `/tdd` → verify →
opt-in compound into a `LESSONS.md` entry + forbidden-pattern. Two modes (in-build / incident). Owns the loop
but can optionally lean on gstack **`/investigate`** or CE **`ce-debug`** for a heavy dig when installed.
Prefer it over a bare `/investigate` when you want the reproduce-first + compounding discipline.

**`eval-triage`** (host-neutral) — guided, **participatory** diagnosis of a failing **agentic/LLM eval**:
reproduce → contract → compare vs a passing eval → bisect the pipeline (midpoint-first) → categorize
(eval/judge · prompt · retrieval · tool-use · state · nondeterminism/drift · parsing) → minimal-fix proposal
→ verify. It coaches + pauses at each phase and is diagnostic-first (never auto-fixes the app or silently
edits an eval). Use it for eval-suite failures; use `bug-hunt` for general code bugs.

## End-of-project comprehension pair (on-demand, fresh session — NOT a per-feature stage)
Run these **near the end of a build, from inside the finished project**, to understand and teach what was made:

**`layer-docs`** (host-neutral) — deep end-to-end analysis of the **code + the planning/architecture docs**
(`ARCHITECTURE.md`, the `/arch-draft` artifacts, `/office-hours` & `/plan-ceo-review` output, `MVP_TASKS.md`)
→ derive the project's real **layers** → write a full-scope `docs/layers/OVERVIEW.md` + one digestible doc
per layer (executive summary first, depth below). Faithful (cites `file:line`, flags architecture-vs-code
drift); prefers CodeGraph/Context7 when present; degrades to code-only when planning docs are absent. **Re-runnable + incremental** — run it again as the code evolves and it detects what changed and updates only the affected docs (preserving hand-edits) via a stamped `docs/layers/.layer-docs.json` state file; `/layer-docs --check` reports which docs are stale without writing — the signal a knowledge base / drift detector uses.

**`learn-site`** (Claude Code) — consumes `docs/layers/` and builds an **interactive learning website** in
`docs/learn-site/`: a clickable layer map, a "follow a request" walkthrough, search, and a **Plain-English ⇄
Deeper-Dive** toggle per topic. Static/zero-build by default; React only when interactivity earns it. Run it
**after `layer-docs`** (it builds *from* those docs). This pair closes the loop — the same conditional
CodeGraph/Context7 preference below applies to `layer-docs`'s analysis.

## External code-intelligence / docs MCPs (conditional — all stages)
Independent of the gstack/CE composition above: if a **code-intelligence MCP** (e.g. CodeGraph) is installed, prefer it for code navigation / callers / traces / impact over `grep`+read loops; if a **docs MCP** (e.g. Context7) is installed, prefer it for up-to-date library/API docs + setup steps, without being asked. Both no-op when absent. The generated root `CLAUDE.md`, `/tdd`, and the orchestrator briefing all carry this rule, so every role inherits it.

> Full reasoning: `workflow-analysis/synthesis/recommendation.md` (compose-vs-build verdict + the 16-stage detail) and `routing-map.md`.
