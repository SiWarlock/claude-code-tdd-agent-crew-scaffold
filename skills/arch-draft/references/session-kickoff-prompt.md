# Start Deep Architecture Planning Session Prompt

Use this prompt to start a fresh ChatGPT, Claude, or Claude Code planning session with a new PRD or product idea.

---

## Prompt

You are helping me turn a PRD, project brief, or lightweight product idea into a build-ready architecture package for my agentic coding workflow.

I have attached:

1. The PRD or product brief.
2. The architecture-planning playbook (`references/architecture-planning-playbook.md` — the generated
   concatenation of the spine + stage files; attach this single file).

Read both end-to-end.

Follow the playbook phase by phase.

Do **not** jump to implementation.
Do **not** generate `IMPLEMENTATION_PLAN.md`.
Do **not** draft `ARCHITECTURE.md` immediately.
Do **not** invent architecture to fill gaps silently.

This should be a deep planning process, not a one-shot architecture summary.

If the PRD is light, interview me. Ask focused batches of high-leverage questions. After each batch, synthesize what you learned, identify what remains unclear, and wait for confirmation before moving on.

---

## Goal

Produce a comprehensive first-draft architecture package:

1. `PRESEARCH.md`
2. `RESEARCH.md` if current/external facts need validation
3. `DECISIONS.md`
4. `ARCHITECTURE.md`
5. `DIAGRAM_PLAN.md`
6. `CLAUDE_CODE_HANDOFF.md`

Do not create `IMPLEMENTATION_PLAN.md`. In my workflow, Claude Code reviews and finalizes the architecture first, then creates `IMPLEMENTATION_PLAN.md` from my template.

---

## Operating Rules

1. Start with product understanding, not architecture.
2. Separate explicit PRD requirements from inferred requirements.
3. Keep inferred requirements scoped to the chosen Build posture (production-grade: infer what a correct, maintainable, operable build must handle; MVP/prototype: stay within the timebox and flag every deferral).
4. Identify users, stakeholders, workflows, domain entities, constraints, assumptions, and open questions before architecture.
5. Research current/external/unstable facts before locking decisions.
6. For every major decision, compare options and tradeoffs.
7. Ask me to confirm load-bearing decisions before treating them as locked.
8. Track recommendations as:
   - locked decision
   - proposed recommendation
   - open question
   - scope simplification (a posture-gated cut)
   - production-hardening (load-bearing under a production-grade posture)
   - deferred work
   - research required
9. Draft `ARCHITECTURE.md` only after decision discovery and section-by-section architecture planning are complete.
10. The final `ARCHITECTURE.md` should be build-ready enough for Claude Code to audit, finalize, and create `IMPLEMENTATION_PLAN.md` from my template.

---

## Start Now

Begin with **Phase 0 — Intake, Planning Mode, and Build Posture Selection**.

Read the PRD end-to-end and respond with:

1. Product in one sentence.
2. What the product is.
3. What the product is not.
4. Primary problem.
5. Primary user.
6. Core workflow.
7. Explicit requirements.
8. Implied requirements.
9. External dependencies.
10. Ambiguities/open questions.
11. Initial risk areas.
12. Recommended planning mode: Compact, Standard, or Expanded.
13. Recommended build posture: production-grade (default) or MVP/prototype — to be confirmed with me (separate, orthogonal to planning mode).
14. The first batch of high-leverage clarification questions.

Then wait for my answers before moving to the next phase.