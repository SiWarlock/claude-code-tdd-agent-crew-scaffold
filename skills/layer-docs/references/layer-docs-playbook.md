# layer-docs — playbook

The depth behind `SKILL.md`: where to find the inputs, how to identify a project's real layers, the doc
templates, readability rules, the tooling, and the faithfulness discipline. The goal is a doc set someone
could hand a new engineer to understand the system in an afternoon — and that `/learn-site` can build on.

---

## Where the inputs live (gather all that exist)

- **Code:** entry points (`main`, `cli`, `app`, server bootstrap, route registration), the dir tree, package
  manifests (`package.json`, `pyproject.toml`, `go.mod`, …), config, migrations, infra (`Dockerfile`, IaC),
  tests (often the clearest spec of intended behavior).
- **Binding design:** `ARCHITECTURE.md` (the cc-crew contract), ADRs, API specs (OpenAPI/GraphQL schema).
- **Planning artifacts:** `docs/planning/*` from `/arch-draft` (`ARCHITECTURE_DRAFT.md`,
  `CLAUDE_CODE_HANDOFF.md`, interview notes), `/office-hours` output (problem/wedge framing),
  `/plan-ceo-review` & `/plan-eng-review` notes, `MVP_TASKS.md` (what was actually scoped/built).
- **Accreted knowledge:** `LESSONS.md`, `README`s, `CHANGELOG`, issue/PR templates.

If planning docs are absent, the code is the source of truth — proceed, noting you couldn't cross-check
intent.

---

## Identifying the layers (heuristics, not a template)

Derive layers from how *this* system is actually organized and what each part is *responsible for*. Signals:
- **Directory & module boundaries** that group by responsibility.
- **Dependency direction** — a layer depends inward/downward; find the natural strata from the import graph
  (CodeGraph `codegraph_callers`/`codegraph_callees`/`codegraph_impact`).
- **Change reasons** — code that changes for the same reason belongs together (a layer ≈ one axis of change).
- **The seams** — process/network/IO boundaries, public interfaces, ports & adapters.

A **common starting vocabulary** (adopt only the ones that fit, rename to match the repo):
*entry / UI / CLI · API / interface · application / orchestration · domain / business logic · data /
persistence · integration / external services · messaging / events · cross-cutting (auth, config, logging,
observability, error handling) · infrastructure / deploy.*

Anti-patterns to avoid: forcing a 3-tier template onto a project that isn't 3-tier; making one doc per
directory regardless of responsibility; inventing a layer the code doesn't actually have. When something
doesn't fit a layer cleanly, say so and place it where it's most cohesive (or give cross-cutting concerns
their own doc).

---

## Overview doc template — `docs/layers/OVERVIEW.md`

```
# <Project> — System Overview

## What it is
<2–4 sentences: the product/purpose, who/what it serves.>

## At a glance
- Stack: <languages, frameworks, datastores, key services>
- Shape: <CLI | service | web app | library | platform>, <monolith | services>
- Entry points: <how work enters the system>

## The layers
<a diagram: boxes for each layer + arrows for the main flow / dependency direction>
| Layer | Responsibility | Doc |
|-------|----------------|-----|
| <name> | <one line> | [NN-<slug>.md](NN-<slug>.md) |

## How it fits together
<one walkthrough: follow a representative request / job / command from entry to result, naming the layers it
crosses. This is the spine learners hang everything on.>

## Cross-cutting concerns
<auth, config, observability, error handling — where they live and how they thread through.>

## Key decisions & trade-offs
<the handful of choices that shape the system; link to ADRs/architecture doc. Note any drift: "the doc says
X; the code does Y because …".>

## Map
<TOC linking every layer doc, in reading order.>
```

---

## Per-layer doc template — `docs/layers/NN-<slug>.md`

```
# <Layer name>

## Executive summary
<3–6 sentences a non-expert can follow: what this layer is, why it exists, what it owns, and how it relates
to the rest. Someone should grasp the layer's role from this block alone.>

## Responsibilities
- <what it is accountable for> · <and explicitly what it is NOT>

## Key components
| Component | What it does | Where |
|-----------|--------------|-------|
| <module/class> | <one line> | `path/to/file.ext:line` |

## Interfaces & contracts
<public API / functions / events this layer exposes, and what it expects from others. Inputs → outputs.>

## Data & state
<the important data structures, schemas, and where state lives.>

## Dependencies
- **Depends on:** <inward layers/services> — why.
- **Used by:** <who calls in> — how.

## How it works (flow)
<step the reader through the layer's main path with `path:line` anchors; a small diagram if it helps.>

## Design decisions & rationale
<why it's built this way; alternatives considered; trade-offs.>

## Gotchas & sharp edges
<non-obvious behavior, footguns, invariants, perf/security notes, drift from the architecture doc.>

## Connects to
<the adjacent layers and the exact handoff points — link their docs.>
```

---

## Readability rules

- **Summary first, always.** A reader should get value from the top block without reading the rest.
- **Plain English over jargon;** define a term the first time it appears.
- **Show, don't assert** — link `path:line`, paste a tiny signature, draw a 4-box diagram, rather than long
  prose.
- **Short paragraphs and bullets;** one idea per bullet.
- **Consistent structure** across layer docs so readers learn the shape once.
- **Two registers:** keep the executive summary genuinely plain; let the depth sections be technical. (This
  plain/deep split is exactly what `/learn-site` turns into its two views.)

---

## Tooling

- **CodeGraph (code-intelligence MCP), when available:** `codegraph_context` to orient on an area;
  `codegraph_explore` to survey related symbols; `codegraph_trace` for end-to-end flows; `codegraph_impact`
  to understand blast radius and dependency direction (great for finding layer boundaries). Prefer it over a
  grep+read loop, then confirm specifics with a targeted `Read`.
- **Context7 (docs MCP), when available:** for version-correct framework/library behavior you're about to
  describe — don't guess.
- **Explore subagents (`Agent` tool):** on a large repo, fan out one reader per subsystem in parallel; have
  each return a structured summary (entry points, key modules, responsibilities, external deps); you
  synthesize and make the layer call. Keep judgment central; don't let a subagent invent the taxonomy.

---

## Faithfulness discipline (this is the whole value)

- Anchor every non-trivial claim to `path:line`. If you can't, mark it `UNVERIFIED` and ask — never smooth it
  over.
- Describe what the code **does**, not what a doc **says** it does; when they differ, document both and label
  the drift.
- Prefer the test suite as a tie-breaker on intended behavior.
- Don't editorialize beyond the evidence; "I didn't find X" is a valid, useful statement.
