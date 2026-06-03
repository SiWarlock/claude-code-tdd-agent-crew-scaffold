---
name: layer-docs
description: >-
  Derive AND continuously maintain a project's layer documentation. On the FIRST run it does a deep
  end-to-end comprehension pass — analyzing the whole codebase AND its planning/architecture artifacts
  (ARCHITECTURE.md, the /arch-draft docs in docs/planning/, any /office-hours or /plan-ceo-review output,
  MVP_TASKS.md, READMEs) — derives the project's REAL layers (not a generic template), and writes a
  full-scope overview plus one digestible doc per layer (executive summary first, depth below) into
  docs/layers/. On LATER runs it works INCREMENTALLY: it figures out what changed (new code, new features,
  refactors, deletions) since the docs were last generated and updates ONLY the affected layer docs — never
  clobbering human edits — stamping a small state file so the docs stay in sync as the project evolves. A
  --check mode reports which docs are stale without writing. Every claim is anchored to the actual code
  (file:line); drift between the architecture doc and the real code is flagged, not hidden. Output is read by
  humans AND consumed by /learn-site and a project knowledge base. Standalone, on-demand; runs from inside
  the target project; host-neutral (Claude or Codex). Prefers a code-intelligence MCP (e.g. CodeGraph) for
  structure/impact and a docs MCP (e.g. Context7) for framework facts when present. Invoke when the user says
  "layer-docs", "document the layers", "update the layer docs", "refresh the docs", "the code changed update
  the docs", "what docs are stale", "map the architecture from the code", or wants to create OR keep current
  a comprehension doc set.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
---

# layer-docs — derive and keep current a project's layer documentation

A **standalone, on-demand** skill that reads a project — **code + its planning/architecture docs** —
understands how it actually works, decides what its **layers** really are, and writes a **clear, faithful doc
set** into `docs/layers/`: one **full-scope overview** plus **one doc per layer**, each opening with an
**executive summary** then going deep while staying easy to read. It is meant to be run **more than once**:
the first run derives the set; later runs **keep it in sync** as the code evolves. Runs on **Claude or
Codex**, from **inside the target repo**. Its output feeds **`/learn-site`** and a project knowledge base.

**It is faithful first.** Every non-trivial claim is anchored to real code (`path:line`); where the
architecture doc says one thing and the code does another, it **flags the drift**; where it isn't sure, it
says so. It **never modifies the project's source** — it only writes docs under `docs/layers/`.

**It derives layers from THIS project**, not from a checklist — and on updates it **only touches what
changed** and **preserves your hand-edits**.

Depth — input sources, layer heuristics, doc templates, readability rules, the faithfulness discipline, and
the **incremental-update mechanics** (change detection, the state file, don't-clobber) — is in
**`references/layer-docs-playbook.md`**. Read it first.

---

## 0. Asking the user questions (host-neutral — read first)

This skill has gates. Use whatever your host supports to ask:
1. A blocking question tool — `AskUserQuestion` (Claude Code), `request_user_input` / `ask_user` (Codex / other).
2. Else **plain text** — print the question + options, then **stop and wait**.

Discipline: one topic per check-in · recommend an option + **why** · **never invent** a layer, a component,
or a behavior to fill a gap — anchor it in code or mark it `UNVERIFIED` and ask.

---

## Modes (auto-detected; the user can force one)

Decide the mode by whether `docs/layers/` already has a doc set + a state file (`docs/layers/.layer-docs.json`):
- **Initial** — no existing set → do the full derivation (§§1–6, initial path). This is also right when the
  user passes `--full` (force a clean regen) or the set is too stale to update sanely.
- **Update** (default when a set exists) — figure out **what changed** since the docs were last generated and
  refresh **only the affected** docs, preserving human edits. Also right for `--update` or `--layer <name>`.
- **Check** (`--check`) — report which layer docs are **stale** vs the code (and which were hand-edited)
  **without writing anything**. Read-only; safe in CI; this is what a knowledge base / drift detector calls.

State the detected mode up front so the user knows whether you're creating or updating.

## The state file — `docs/layers/.layer-docs.json`

The skill stamps a small machine-owned state file so later runs can detect change without guessing. It records
the generation point and, per layer, the doc, its source globs/files, and a content hash; plus a hash of each
source file at last generation. (Full schema in the playbook.) On every write, **re-stamp it.** It works
without git (hashes are the source of truth); a git sha is stored as fast-path provenance when available.

---

## 1. Gather the inputs — code, docs, and prior state

> *Goal: assemble everything that describes the system, plus what was documented last time.*

1. **Read the state file** if present (`docs/layers/.layer-docs.json`) — it tells you the prior layer set,
   the source→layer mapping, and the last-generation hashes/sha. Absent ⇒ Initial mode.
2. **Map the repo.** `Glob`/`Bash` the tree; find entry points, manifests, structure, tests. If a
   **code-intelligence MCP (CodeGraph)** is available, use it (`codegraph_status`, `codegraph_files`,
   `codegraph_context`) for the symbol/edge map instead of a grep-and-read sweep.
3. **Collect the design record.** `ARCHITECTURE.md`, `docs/planning/*` (the `/arch-draft` artifacts), any
   `/office-hours` or `/plan-ceo-review` output, `MVP_TASKS.md`, `LESSONS.md`, `README`s, ADRs, API specs.
   No planning docs ⇒ proceed from the **code as source of truth**.

⏸ **Check-in:** confirm the mode + the input inventory before the deep read.

## 2. Build or refresh the system model

> *Goal (Initial): an accurate model of the whole system. Goal (Update): pinpoint exactly what changed.*

**Initial / `--full`:**
1. **Trace the spine.** From each entry point, follow the main flows (`codegraph_trace`/`codegraph_callees`
   when available, else targeted reads). Identify major modules, data flow, external deps, seams.
2. **Check framework facts** with a docs MCP (Context7) when library behavior matters — don't guess.
3. **Cross-reference intent vs reality** — hold the architecture/planning docs next to the code; record
   agreement and **drift**.
4. **Large codebase?** Fan out `Explore` subagents (via `Agent`) over subsystems in parallel; synthesize
   yourself.

**Update / Check — detect what changed (the core of incremental mode):**
1. **Diff the sources** since the state file's generation point: prefer `git diff --name-status <generatedAt>..HEAD`;
   otherwise re-hash the source tree and compare to the stored `sourceHashes`. Produce **changed / added /
   deleted / renamed** file lists. Use `codegraph_impact` when available to widen to truly affected symbols.
2. **Map changes to layers** via each layer's stored `sourceGlobs` **and** the `file:line` anchors already in
   the layer docs. Result: the set of **affected layers** (plus the overview if the layer map itself shifts).
3. **Spot the unmapped.** Added files that fit **no** existing layer are a signal of a **possible new layer**
   (or a reassignment) — hold them for the §3 gate. Deleted files mean content to prune.
4. **Detect human edits.** For each layer doc, compare its current file hash to the stored `docHash`. A
   mismatch means **a human edited it** — that doc is now partly hand-owned; you must preserve those edits
   (§5), not overwrite them.

⏸ **Check-in:** Initial → share the system model. Update → present the **change report**: which layers are
affected, what's new/unmapped, which docs were hand-edited. (Check mode **stops here** with that report — it
writes nothing.)

## 3. Layers — derive (initial) or reconcile (update)

> *Goal: keep the decomposition correct — it drives every doc.*

- **Initial:** propose the layer list derived from the real structure/responsibilities (only the layers this
  project actually has, named the way it names them), each with a one-line scope + anchoring evidence; note
  anything that doesn't fit cleanly. **Pause for the user to confirm/adjust** (merge, split, rename, add, drop).
- **Update:** the layer set usually holds. Only when §2 surfaced an **unmapped new area** or a removed one do
  you propose a change (new layer · merge · rename · retire) — and **pause** for that decision. If the set is
  unchanged, say so and proceed without a gate.

## 4. Overview — write (initial) or update on map change

> *Goal: the whole system at a glance, kept honest.*

- **Initial:** write **`docs/layers/OVERVIEW.md`** — what the project is/does · the **layer map** + a simple
  flow diagram · cross-cutting concerns · stack · key decisions + flagged drift · a **TOC linking every layer
  doc**. Exec-summary energy up top; skimmable.
- **Update:** refresh the overview **only if** the layer map, the flow, the stack, or the cross-cutting story
  changed; otherwise leave it. Always re-check the TOC links and any "last updated" line.

## 5. Layer docs — write all (initial) or update only the affected (don't clobber)

> *Goal: a digestible deep-dive per layer — summary first, depth below — kept current without losing edits.*

- **Initial:** write **`docs/layers/NN-<slug>.md`** for each confirmed layer, per the playbook template
  (executive summary → responsibilities · key files (`path:line`) · interfaces · data · deps in/out ·
  control/data flow · decisions+rationale · gotchas · connections). Readable: short paragraphs, bullets, a
  small diagram, real code refs over prose.
- **Update:** rewrite **only the affected** layer docs (and add a doc for a confirmed new layer; retire a
  removed one). For each:
  - **If the doc was hand-edited** (§2.4): do **not** overwrite it wholesale. Update the stale **sections**
    (the template's sections are stable), leave hand-written prose intact, and if a human edit now conflicts
    with the code, **flag it for the user** rather than silently resolving — same don't-clobber discipline as
    `scaffold-upgrade`.
  - Refresh `path:line` anchors that moved; prune references to deleted code; add new components.

## 6. Cross-check, cross-link, and stamp state

> *Goal: leave the set trustworthy, navigable, and re-syncable.*

1. **Coverage:** every major component appears in some layer doc; nothing important is orphaned.
2. **Faithfulness:** spot-check `path:line` anchors resolve and match the code; mark residual `UNVERIFIED`.
3. **Navigation:** the overview TOC + inter-layer links resolve.
4. **Stamp `docs/layers/.layer-docs.json`** — update the per-layer source globs, the new `docHash`es, the
   `sourceHashes`, and the generation sha. (Without this, the next run can't detect change.)

⏸ **Check-in:** confirm the set; offer the next steps — **`/learn-site`** to (re)build the learning site, and
a **knowledge-base sync** to replace the changed docs' chunks (the updated docs are content-hash-replaceable).

---

## Hard rules (forbidden)

- **Faithful to the real code** — anchor claims to `path:line`; **never invent** components, behavior, or
  layers. Unsure → mark `UNVERIFIED` and ask.
- **Incremental by default when a set exists** — detect what changed and touch **only** the affected docs;
  don't silently rewrite the whole set (use `--full` for that, and say so).
- **Never clobber human edits** — a doc whose hash drifted from the state file is partly hand-owned; update
  its stale sections, preserve the prose, and flag genuine conflicts instead of resolving them silently.
- **Derive layers from THIS project** — no boilerplate taxonomy; on update, only change the layer set behind
  the §3 gate.
- **Flag drift** between the architecture/planning docs and the actual code; don't silently pick one.
- **Docs only** — never modify the project's source.
- **Executive-summary-first and readable** — each doc opens with the gist; optimize for a human learning the
  system.
- **Always stamp the state file** on any write; **`--check` writes nothing.**
- **Pause on layer-set changes** (§3) and the final set (§6).
- **Prefer CodeGraph/Context7 when available** for structure/impact and framework facts; fall back gracefully.

---

## Output & handoff

> **layer-docs** — **Mode:** `<initial | update | check>`. **Analyzed:** `<#files / subsystems>` (`<code-only | code + planning docs>`).
> **Layers:** `<N>` — `<list>` (`<unchanged | +new | renamed | retired>`).
> **Changed since last run:** `<files/areas>` → **docs updated:** `<which>` (**created:** `<which>`, **preserved hand-edits in:** `<which>`).
> **Drift flagged:** `<count / one-line>`. **Open/UNVERIFIED:** `<to confirm>`. **State:** `docs/layers/.layer-docs.json` re-stamped.
> **Next:** **`/learn-site`** to (re)build the learning site · sync the changed docs into the knowledge base.

Then stop.
