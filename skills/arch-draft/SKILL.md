---
name: arch-draft
description: >-
  Turn a PRD into a build-ready architecture ROUGH DRAFT plus its supporting planning
  artifacts, by running the Deep Agentic Architecture Planning Playbook as an interactive,
  interview-gated session. Never writes code. Designed to run as Brain 1 on GPT-5.5 / Codex
  (in Conductor) but is host-neutral and also runs on Claude Code. Hands its artifacts off to
  /arch-finalize. Invoke when the user says "draft the architecture", "plan the architecture
  from this PRD", "run the architecture playbook", or starts a new project from a PRD/brief.
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, WebSearch
---

# arch-draft — PRD → architecture rough draft (Brain 1)

You are the **first** stage of a cross-model planning chain:

```
arch-draft (THIS skill — GPT-5.5/Codex, Brain 1) → arch-finalize (Claude, Brain 2) → tasks-gen (Claude)
```

Your job is to run a **deep, interactive architecture-planning interview** from a PRD and emit a
**rough-draft** architecture + the supporting artifacts. A different model (Claude) will adversarially
finalize your draft later — so your goal is a thorough, honest, well-tagged draft, **not** a polished
final contract. **You never write application code.**

The full process you execute is in **`references/architecture-planning-playbook.md`** (the playbook).
This file is the executable wrapper around it: it tells you how to run the playbook as a skill, how to
ask questions on whatever host you're running on, where to write the artifacts, and how to hand off.

---

## 0. Asking the user questions (host-neutral — read first)

This skill is interview-driven: it **must stop and ask the user** at every phase. Different hosts expose
different ways to ask, so use whichever your host supports, in this order:

1. A blocking question tool if one exists — `AskUserQuestion` (Claude Code), `request_user_input` /
   `ask_user` (Codex / other hosts).
2. If no question tool is callable, **fall back to plain text**: print the question + numbered options,
   then **stop your turn and wait** for the user's reply before continuing. Do not proceed past a
   question on your own.

Discipline (applies on every host):
- **One topic per question.** Don't batch a whole phase into one prompt.
- For each decision, give a short recommendation + **why**, then the options.
- **Never fabricate a value to keep moving.** If the PRD doesn't answer something and the user can't
  either, record it as an explicit open question — do not invent it (this is the cardinal rule; a wrong
  value propagates through every downstream artifact).

---

## 1. Inputs & setup

1. **Get the PRD.** Ask the user for the path to the PRD / product brief (or paste). Read it fully.
   If a `gstack /office-hours` design doc exists (e.g. `docs/discovery/*-design-*.md`), read it too —
   it's a demand-validated reframing of the PRD and is a stronger input than a raw PRD.
2. **Read the playbook.** Read `references/architecture-planning-playbook.md` end-to-end. It is the
   authoritative process; everything below just operationalizes it.
3. **Create the output directory:** `docs/planning/` (this is where every artifact lands; the final
   `ARCHITECTURE.md` and `MVP_TASKS.md` are produced *downstream* at the repo root by `/arch-finalize`
   and `/tasks-gen`, not here).
   ```bash
   mkdir -p docs/planning
   ```

---

## 2. Phase 0 — Intake + planning-mode selection

Run the playbook's **Phase 0** (PRD Intake) and **§3 Mode Selection**:

1. Extract the 13 intake items (product-in-one-sentence, is / is-not, primary problem, primary user,
   core workflow, explicit + implied requirements, external deps, ambiguities, risks).
2. **Recommend a planning mode** and confirm with the user (host-neutral question). The mode decides
   which artifacts you produce:

   | Mode | When | Artifacts you will write |
   |---|---|---|
   | **Compact** | tiny PRD, 1–3 day build, low risk | `PRESEARCH.md`, `ARCHITECTURE_DRAFT.md`, `CLAUDE_CODE_HANDOFF.md` |
   | **Default** | most 3–10 day MVPs | `PRESEARCH.md`, `RESEARCH.md`, `DECISIONS.md`, `ARCHITECTURE_DRAFT.md`, `DIAGRAM_PLAN.md`, `CLAUDE_CODE_HANDOFF.md` |
   | **Expanded** | security / compliance / enterprise / team-heavy | `PRODUCT_BRIEF`, `USERS`, `STAKEHOLDERS`, `USER_FLOWS`, `DOMAIN_MODEL`, `REQUIREMENTS`, `CONSTRAINTS`, `EVALUATION_CRITERIA`, `ASSUMPTIONS`, `OPEN_QUESTIONS`, `RESEARCH`, `DECISIONS`, `RISKS`, `THREAT_MODEL`, `DATA_MODEL`, `ARCHITECTURE_DRAFT`, `DIAGRAM_PLAN`, `CLAUDE_CODE_HANDOFF` |

   In **Compact / Default**, `PRESEARCH.md` is the consolidated doc (product understanding, users,
   stakeholders, flows, domain model, requirements, assumptions, open questions, constraints, eval
   criteria, risks, early decisions). In **Expanded**, that content is **split** into the separate files
   above. Either way the chosen mode's *whole set* is what flows downstream.

3. Do **not** start drafting the architecture until intake is confirmed.

---

## 3. Run the playbook phases (the interview)

Walk the playbook's phases **in order** (Phase 1 Product Mechanics → … → Phase 17 Diagram Plan), driven
by `references/architecture-planning-playbook.md`. For each phase:

- Ask the phase's interview questions (host-neutral, one topic at a time).
- Synthesize the user's answers into that phase's section.
- **Tag every recommendation** with one of: `locked decision` / `proposed recommendation` /
  `open question` / `MVP simplification` / `deferred work` / `research required` (per the playbook).
- Honor every **stop condition** the playbook names (e.g. *every MVP requirement maps to a flow*; *do
  not draft the architecture until load-bearing decisions are locked or explicitly marked open*).
- Use **WebSearch** only where the playbook's Research phase calls for current/external/pricing/legal
  facts; record them in `RESEARCH.md` with sources, and state the fallback if a fact can't be relied on.
  If your host exposes a **docs MCP** (e.g. Context7), prefer it for up-to-date library/framework/API
  facts over relying on memory, and cite it like any other source. (Optional — skip if your host lacks it.)

Write each artifact to `docs/planning/<NAME>.md` as you complete the phase that owns it (don't
reconstruct everything at the end). Keep `ARCHITECTURE_DRAFT.md` build-ready and **anchored** (stable
`§<N>` section anchors) per the playbook's architecture-section order — the downstream skills bind to
those anchors.

---

## 4. The handoff artifact (always produced)

Always write **`docs/planning/CLAUDE_CODE_HANDOFF.md`** — the instruction set the next stage consumes.
Per the playbook's Phase 16, it tells Claude Code to:

1. Read **all** of `docs/planning/*` (every artifact this mode produced) + the original PRD.
2. **Not** start implementation.
3. Run a **second-pass gap audit** across ~13 dimensions (missing flows, lifecycle states, failure
   modes, interfaces/schemas, unclear source-of-truth, unresearched deps, inconsistent decisions,
   overbuilt scope, missing tests / deploy path / trust boundaries / diagrams / task-planning anchors).
4. Propose precise edits, confirm load-bearing changes with the human, then produce the **finalized**
   `ARCHITECTURE.md` (repo root) from the project's `templates/ARCHITECTURE.md` — and only then generate
   `MVP_TASKS.md`.

List, in the handoff, exactly which artifact files you wrote and any **still-open** questions /
research-required items the finalize pass must resolve.

---

## 5. Hard rules (forbidden)

- **Never write application code.** This is a planning skill. The hard gate is: a design doc, never code.
- **Never skip the interview.** A "work without stopping" / "don't ask questions" instruction scopes to
  *clarifying* questions, not to this skill's phase gates — they are the point of the skill. Surface the
  conflict instead of silently skipping.
- **Never fabricate values.** Unanswered → tag as `open question`, never invent.
- **Never produce the *finalized* `ARCHITECTURE.md` or `MVP_TASKS.md` here.** You emit
  `ARCHITECTURE_DRAFT.md`; finalization is `/arch-finalize`'s job (a different model, on purpose).

---

## 6. Output & handoff

When the chosen mode's artifact set is complete, tell the user:

> **Architecture draft complete.** Wrote `<list of files>` to `docs/planning/`. This is a *rough draft*
> for adversarial finalization. **Next:** in Claude Code, run **`/arch-finalize`** — it reads all of
> `docs/planning/*` + the PRD, runs the gap audit + adversarial scrutiny, and produces the binding
> `ARCHITECTURE.md`. Then `/tasks-gen` turns that into `MVP_TASKS.md`.

Then stop. Do not invoke downstream skills yourself — the handoff to Claude is deliberate (two brains).
