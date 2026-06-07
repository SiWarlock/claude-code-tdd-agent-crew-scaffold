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
  `/plan-ceo-review` & `/plan-eng-review` notes, `IMPLEMENTATION_PLAN.md` (what was actually scoped/built).
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

---

## Incremental updates (re-running layer-docs to keep the set in sync)

The skill is meant to be run repeatedly. The first run derives the set; later runs **detect what changed and
refresh only the affected docs** without losing human edits. This is what lets a knowledge base keep
"owned" docs fresh (regenerate → replace the changed chunks).

### The state file — `docs/layers/.layer-docs.json`

Machine-owned; re-stamped on every write. It is the memory that makes change detection possible.

```json
{
  "schemaVersion": 1,
  "generatedAt": "<full git sha at last generation, or null>",
  "lastRun": "<git sha or hash-digest of the last run>",
  "layers": [
    {
      "slug": "01-api",
      "name": "API Layer",
      "doc": "01-api.md",
      "sourceGlobs": ["src/api/**", "src/routes/**"],
      "docHash": "sha256:<hash of 01-api.md as this skill last wrote it>"
    }
  ],
  "sourceHashes": { "src/api/server.py": "sha256:…", "src/api/routes.py": "sha256:…" }
}
```

- `sourceGlobs` per layer = the source→layer mapping used to route a changed file to the doc(s) it affects.
- `docHash` = the hash of each layer doc **as the skill last wrote it**; if the file's current hash differs,
  a human edited it (see don't-clobber below).
- `sourceHashes` = per-file hashes at last generation; the fallback change-detector when git isn't available.
- Works without git. Store the git sha when present purely as a fast-path / provenance.

### Change detection (Update / Check)

1. **Find changed files.** With git: `git diff --name-status <generatedAt>..HEAD` (or `git status` for
   uncommitted). Without git: re-hash the source tree and diff against `sourceHashes`. Classify into
   **added / modified / deleted / renamed**.
2. **Widen by impact.** When CodeGraph is present, run `codegraph_impact` on changed symbols to catch files
   that *depend on* the change (a changed interface can stale a doc whose file didn't itself change).
3. **Route changes to layers.** A changed file belongs to a layer if it matches that layer's `sourceGlobs`
   **or** appears as a `file:line` anchor in that layer's doc. Union → the **affected layers**.
4. **Classify the deltas:**
   - *modified within a mapped layer* → refresh that layer doc.
   - *added, unmapped* → candidate **new layer** or reassignment → §3 gate.
   - *deleted* → prune references; if a layer's whole basis is gone, propose retiring its doc.
   - *renamed/moved* → update anchors and `sourceGlobs`.
5. **Map-level change?** If the set of layers, the inter-layer flow, the stack, or cross-cutting concerns
   shifted → also refresh `OVERVIEW.md`.

### Don't-clobber: preserving human edits

A layer doc whose current hash ≠ its stored `docHash` has been **hand-edited** and is now partly human-owned.
On update, do **not** overwrite it wholesale:
- The per-layer template's sections are stable headings. Regenerate only the **stale** sections (the ones the
  change touched); leave hand-written prose and added sections intact.
- If a human-written statement now **contradicts the code**, surface it as a flagged conflict for the user to
  resolve — don't silently "correct" their words.
- After a clean update, recompute and store the new `docHash`.

This mirrors `scaffold-upgrade`'s propose-don't-clobber stance: machinery you own is refreshed automatically;
anything a human customized is preserved or flagged, never steamrolled.

### `--check` (drift report, writes nothing)

Run steps 1–4 and report, per layer: `fresh | stale (which sources changed) | hand-edited | new-area-unmapped`,
plus whether the overview needs a refresh. This is the read-only signal a knowledge base or CI uses to decide
when to trigger a real update. Exit without writing.

### Handoff to a knowledge base

After an update, the changed docs are **content-hash-replaceable**: a consuming index re-chunks only the
files whose hash changed and swaps the old chunks for the new. So "refresh the docs → new docs replace old in
the vector DB" needs nothing special here beyond writing the updated files + re-stamping the state — the
index keys on `source_path` + hash.
