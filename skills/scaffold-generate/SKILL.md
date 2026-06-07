---
name: scaffold-generate
description: >-
  Personalize the agent-team scaffolding into a target project from the finalized ARCHITECTURE.md +
  IMPLEMENTATION_PLAN.md + the planning artifacts, then stamp a provenance manifest so future upgrades are clean.
  Runs on Claude Code, from the scaffolding repo checkout. The 4th stage of the planning chain (after
  /tasks-gen) and the last step before the /tdd engine runs. Invoke when the user says "generate the
  scaffolding", "personalize the scaffolding", "set up the agent-team harness", or after IMPLEMENTATION_PLAN.md exists.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# scaffold-generate — personalize the harness into the project (Brain 2)

The **4th** stage of the planning chain. The binding `ARCHITECTURE.md` and the spec-anchored
`IMPLEMENTATION_PLAN.md` exist; now generate the customized agent-team scaffolding (slash commands, layered
`CLAUDE.md`, briefing docs, area `LESSONS.md`, optional subagents) into the target project so the `/tdd`
engine can run. This skill **runs from the scaffolding-repo checkout** (it reads `templates/` there).

**You do not write application code, and you do not author `ARCHITECTURE.md` / `IMPLEMENTATION_PLAN.md`** (they're
the binding contract + tracker — read-only inputs here).

---

## 1. The procedure (bundled)

`references/generate-procedure.md` is `GENERATE-WITH-CLAUDE.md` — the authoritative 7-stage build
procedure (§2 stages, §7 the 13 generation steps, §10 the placeholder manifest, the `{{PLACEHOLDER}}` +
`<!-- EXAMPLE BLOCK -->` substitution system). Read it fully and follow it. This file adds three things on
top: which inputs to read, the manifest-stamping step, and the artifact-driven personalization.

The `templates/` tree it generates from lives in the scaffolding repo checkout you're running from.

---

## 2. Read the inputs (artifact-driven personalization — not just the arch doc)

Per `GENERATE-WITH-CLAUDE.md §3` the architecture doc is the **primary** input, but use the whole
planning context to personalize and to know what to interview the user on:

1. **`ARCHITECTURE.md`** (repo root, PRIMARY) — stack per area, code areas + layout, layer DAG, the
   architecture sentence, deliverables, Appendix A model inventory.
2. **`IMPLEMENTATION_PLAN.md`** (repo root) — phase IDs + phase plan + deliverable map (seeds `{{PHASE_IDS}}`, the
   tracker, the deliverable map).
3. **Planning artifacts in `docs/planning/`** (mode-dependent) to drive personalization + the gap/inference
   interview: `THREAT_MODEL.md` / `CONSTRAINTS.md` → **key safety rules + forbidden patterns**;
   `DECISIONS.md` → locked choices to bake into conventions; `REQUIREMENTS.md` → deliverable map;
   `DOMAIN_MODEL.md` / `DATA_MODEL.md` → the cross-doc-invariants table + Appendix A mirroring.

Pull every value you can from these before interviewing — only ask the user for what the artifacts can't
answer (and **never fabricate** a placeholder; a wrong value propagates across many files).

**Tools (use when available):** prefer a code-intelligence MCP (e.g. CodeGraph) over `grep`+read loops when inspecting the target repo's existing layout/stack, and a docs MCP (e.g. Context7) for library/API specifics. Optional — no-op if absent.

---

## 3. Follow the generate procedure

Execute `GENERATE-WITH-CLAUDE.md`'s stages, with these notes:

- **Mode choice (§4)** — team pattern vs single-operator (via `AskUserQuestion`); this fans out which
  commands + docs get written.
- **Interview (§5, batches A–E)** — ask **only** for what the artifacts didn't supply. Quote the key
  safety rules back **verbatim** (don't paraphrase) per the procedure.
- **Plan + PAUSE (§6)** — present the one-screen generation plan with the filled-placeholder table; **write
  nothing** until the user approves.
- **Generate (§7, 13 steps)** — fill `{{PLACEHOLDER}}`s from the artifacts/interview; swap `EXAMPLE BLOCK`
  regions with project content; keep the workflow machinery (`/tdd` 10 steps, Step-9 routing, commit
  cadence, escalation taxonomy) **verbatim**.
- **PAUSE for review (§8) + handoff (§9)** — do **not** commit unless the user asks.

---

## 4. Stamp the provenance manifest (`.scaffolding/manifest.json`)

After generating (and before the final PAUSE), write **`.scaffolding/manifest.json`** and copy
`templates/.scaffolding/README.md` into the project's `.scaffolding/README.md` (generator-owned;
do-not-hand-edit; rewritten by upgrades). This makes future `scaffold-upgrade` runs clean 3-way merges
instead of hand-diffs. The full schema + assembly rules are in **`GENERATE-WITH-CLAUDE.md` Step 12.5**
(bundled as `references/generate-procedure.md`); record:

- `schemaVersion`; `scaffoldingRepo` + **`generatedFromSha`** (`git -C <scaffolding-checkout> rev-parse HEAD`)
  + `generatedFromRef` + `generatedAt`; `lastUpgradedFromSha: null`.
- `mode` + `track` + `optionalCommands` + `optionalSubagents` (the foundational choices).
- `placeholders{}` + per-area `codeAreas[]` — every resolved value, exactly as substituted.
- `generatedFiles[]` — one row per written file: `{dest, template, kind, area?}` where `kind` ∈
  `verbatim | placeholder-only | mixed | accreted | user-canonical`. Build this list **as you write each file**.
- `exampleBlocks[]` — one row per EXAMPLE BLOCK region: `{file, id, status: customized | illustrative}`.

Validate it parses (`jq . .scaffolding/manifest.json`).

> Note: every `EXAMPLE BLOCK` region now carries a stable `[id=<slug>]` in **both** its opening and closing
> marker (the canonical id map is in `GENERATE-WITH-CLAUDE.md §10`). Record each `exampleBlocks` row by that
> `[id=<slug>]` — not by heading text — and classify `kind` from the §7 bookkeeping table. `scaffold-upgrade`
> keys per-region merges on these ids, so **never alter a marker line or its `[id=`** when filling a block.

---

## 5. Hard rules (forbidden)

- **No application code.** This generates the harness, not the product.
- **Don't author / edit `ARCHITECTURE.md` or `IMPLEMENTATION_PLAN.md`** — read-only inputs.
- **Never fabricate placeholder values** — pull from artifacts, else ask; an unanswerable gap is a real
  blocker to resolve, not a value to invent (`GENERATE-WITH-CLAUDE.md` Rule).
- **Keep the workflow machinery verbatim** — the `/tdd` walker, Step-9 routing, commit cadence, escalation
  taxonomy ship unchanged. Don't redesign the workflow.
- **Don't commit** unless the user asks.

---

## 6. Output & handoff

> **Scaffolding generated** into `<project>`: `<command count>` slash commands, layered `CLAUDE.md`, briefing
> docs, task tracker, + `.scaffolding/manifest.json`. **Next:** start the engine — `/team-start` (team mode)
> or `/orchestrate-start` + `/session-start` (single-operator) — and the **`/tdd`** walker builds each slice
> against `ARCHITECTURE.md` + `IMPLEMENTATION_PLAN.md`. Compose gstack/CE inserts per `skills/ROUTING.md`.

Then stop.
