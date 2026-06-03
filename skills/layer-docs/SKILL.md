---
name: layer-docs
description: >-
  Deep, end-to-end comprehension pass for a finished or near-finished project. Analyzes the WHOLE codebase
  AND its planning/architecture artifacts (ARCHITECTURE.md, the /arch-draft docs in docs/planning/, any
  /office-hours or /plan-ceo-review output, MVP_TASKS.md, READMEs), derives the project's REAL layers /
  components (not a generic template), then writes a full-scope overview plus one digestible doc per layer —
  executive summary first, depth below — into docs/layers/. Every claim is anchored to the actual code
  (file:line) and drift between the architecture doc's intent and the real code is flagged, not hidden. The
  output is built to be read by humans AND consumed by /learn-site. Standalone, on-demand; meant to run in a
  FRESH session from inside the target project; host-neutral (Claude or Codex). Prefers a code-intelligence
  MCP (e.g. CodeGraph) for structure/traces and a docs MCP (e.g. Context7) for framework facts when present.
  Invoke when the user says "layer-docs", "document the layers", "map the architecture from the code",
  "create the layer docs", "do an end-to-end analysis", or wants a comprehension doc set near a project's end.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
---

# layer-docs — derive and document a project's layers, end to end

A **standalone, on-demand** skill that reads an entire project — **code + its planning/architecture docs** —
understands how it actually works, decides what its **layers** really are, and writes a **clear, faithful doc
set** into `docs/layers/`: one **full-scope overview** plus **one doc per layer**, each opening with an
**executive summary** and then going deep while staying easy to read. Run it in a **fresh session near the
end of a project**, on **Claude or Codex**, from **inside the target repo**. Its output is the input to
**`/learn-site`**.

**It is faithful first.** Every non-trivial claim is anchored to real code (`path:line`); where the
architecture doc says one thing and the code does another, it **flags the drift** rather than papering over
it; where it isn't sure, it says so. It does **not** modify the project's code — it only writes docs.

**It derives layers from THIS project**, not from a checklist. A CLI library, a RAG service, and a web
platform have different layers; the decomposition is the one real judgment call, so it **pauses** for you to
confirm it before writing a word of the layer docs.

Depth — input sources, layer-identification heuristics, the doc templates, readability rules, and the
faithfulness discipline — is in **`references/layer-docs-playbook.md`**. Read it first.

---

## 0. Asking the user questions (host-neutral — read first)

This skill has gates. Use whatever your host supports to ask:
1. A blocking question tool — `AskUserQuestion` (Claude Code), `request_user_input` / `ask_user` (Codex / other).
2. Else **plain text** — print the question + options, then **stop and wait**.

Discipline: one topic per check-in · recommend an option + **why** · **never invent** a layer, a component,
or a behavior to fill a gap — anchor it in code or mark it `UNVERIFIED` and ask.

---

## 1. Gather the inputs — code AND docs

> *Goal: assemble everything that describes the system before forming an opinion about it.*

1. **Map the repo.** `Glob`/`Bash` the tree; find entry points, package/manifest files, the directory
   structure, and the test layout. If a **code-intelligence MCP (CodeGraph)** is available, use it
   (`codegraph_status`, `codegraph_files`, `codegraph_context`) to get the symbol/edge map fast instead of a
   grep-and-read sweep.
2. **Collect the design record.** Read whatever exists: `ARCHITECTURE.md`, `docs/planning/*` (the
   `/arch-draft` artifacts — `ARCHITECTURE_DRAFT.md`, `CLAUDE_CODE_HANDOFF.md`, etc.), any `/office-hours` or
   `/plan-ceo-review` / `/plan-eng-review` output, `MVP_TASKS.md`, `LESSONS.md`, `README`s, ADRs, API specs.
3. **Note what's missing.** If there are no planning docs, say so and proceed from the **code as the source of
   truth** (this skill works code-only, just with less intent-vs-reality cross-checking).

⏸ **Check-in:** confirm the input inventory (what you found, what's absent) before the deep read.

## 2. Analyze the system end to end

> *Goal: build an accurate mental model — entry points, flows, boundaries, dependencies — grounded in code.*

1. **Trace the spine.** From each entry point, follow the main flows through the system
   (`codegraph_trace` / `codegraph_callees` when available, else targeted reads). Identify the major modules,
   the data that moves between them, the external dependencies, and the seams/boundaries.
2. **Check framework facts** with a docs MCP (Context7) when a library's behavior matters to the explanation
   — don't guess version-specific API semantics.
3. **Cross-reference intent vs reality.** Hold the architecture/planning docs next to the code. Record where
   they agree, and **where the code diverged** from the plan (a finding worth documenting).
4. **For a large codebase, fan out.** Optionally dispatch `Explore` subagents (via the `Agent` tool) to read
   different subsystems in parallel and report structured summaries back — then you synthesize. Keep the
   synthesis (and the layer call) yourself.

⏸ **Check-in:** share the system model in a few lines; confirm it matches the user's understanding.

## 3. ⏸ Derive and confirm the layers (the key decision)

> *Goal: decide the project's real decomposition — this drives every doc that follows.*

1. **Propose the layer list** derived from the actual structure and responsibilities (e.g. for one project:
   *entry/UI · API · domain/business logic · data/persistence · integration/external · cross-cutting
   (auth, config, observability) · infra/deploy* — but **only the ones this project actually has**, named the
   way this project names them).
2. For each proposed layer give a one-line scope and the **anchoring evidence** (the dirs/modules that make
   it up). Note anything that doesn't fit cleanly (and how you'd handle it).
3. **Pause for the user to confirm or adjust** the decomposition — merge, split, rename, add, drop. This is
   the gate; do not write layer docs until it's agreed.

## 4. Write the full-scope overview

> *Goal: the whole system at a glance, as the front door to the set.*

Write **`docs/layers/OVERVIEW.md`**: what the project is and does · the **layer map** (and a simple diagram of
how layers interact / how a request or unit of work flows through them) · cross-cutting concerns · the tech
stack · key design decisions and any flagged drift · and a **table of contents linking every layer doc**.
Executive-summary energy up top; skimmable.

## 5. Write one doc per layer

> *Goal: a digestible deep-dive per layer — summary first, depth below.*

For each confirmed layer write **`docs/layers/NN-<slug>.md`** (e.g. `01-api.md`) using the per-layer template
from the playbook:
- **Executive summary** (top) — what this layer is, why it exists, its one-paragraph essence.
- **Responsibilities** · **key files/modules** (`path:line` anchors) · **public interfaces/contracts** ·
  **data structures** · **dependencies in and out** · **control/data flow** (how work enters, moves, leaves)
  · **design decisions + rationale** · **gotchas / sharp edges** · **how it connects to the adjacent layers**.
- Readable: short paragraphs, bullets, a small diagram where it helps, real code references over prose.

Keep each doc self-contained but cross-linked to the overview and to neighboring layers.

## 6. Cross-check and cross-link

> *Goal: make the set trustworthy and navigable.*

1. **Coverage:** every major component/module appears in some layer doc; nothing important is orphaned.
2. **Faithfulness:** spot-check the `path:line` anchors resolve and the descriptions match the code; mark any
   remaining `UNVERIFIED` claims plainly.
3. **Navigation:** the overview's TOC and the inter-layer links all resolve.

⏸ **Check-in:** confirm the set before handing off (and offer `/learn-site` as the next step).

---

## Hard rules (forbidden)

- **Faithful to the real code** — anchor claims to `path:line`; **never invent** components, behavior, or
  layers to make the story tidy. Unsure → mark `UNVERIFIED` and ask.
- **Derive layers from THIS project** — no boilerplate taxonomy pasted over a project it doesn't fit.
- **Flag drift** between the architecture/planning docs and the actual code; don't silently pick one.
- **Docs only** — never modify the project's source while documenting it.
- **Executive-summary-first and readable** — each doc opens with the gist; depth follows; optimize for a
  human learning the system, not for completeness theater.
- **Pause on the layer decomposition (§3)** and on the final set (§6) — the decomposition is the user's call.
- **Prefer CodeGraph/Context7 when available** for structure and framework facts; fall back gracefully.

---

## Output & handoff

> **layer-docs** — **Analyzed:** `<#files / subsystems>` (`<code-only | code + planning docs>`).
> **Layers:** `<N>` — `<list>`. **Written:** `docs/layers/OVERVIEW.md` + `<N>` layer docs.
> **Drift flagged:** `<count / one-line>`. **Open/UNVERIFIED:** `<anything to confirm>`.
> **Next:** run **`/learn-site`** to turn this into an interactive learning website.

Then stop.
