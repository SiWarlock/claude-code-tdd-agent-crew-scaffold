<!--
  Part of the arch-draft playbook — stage file, read JUST-IN-TIME as the interview enters its phases
  (the spine's phase index points here). Sources are concatenated into the full playbook artifact by
  scripts/build-playbook.sh; edit HERE, never in the generated concat.
-->

## 4. Phase 0 — Intake and Initial Read

### Goal

Understand the PRD without proposing architecture yet.

### Required Output

Add to `PRESEARCH.md`:

```md
## Phase 0 — PRD Intake

### Product in One Sentence
...

### What the Product Is
...

### What the Product Is Not
...

### Primary Problem
...

### Primary User
...

### Core Workflow
...

### Explicit PRD Requirements
...

### Implied Requirements
...

### External Dependencies
...

### Ambiguities / Open Questions
...

### Initial Risk Areas
...

### Recommended Planning Mode
...

### Build Posture
_production-grade (default) | MVP / prototype — the delivery target, **confirmed with the user**; steers Phase-8 inference + every downstream decision._
...
```

### Prompt

```text
Read the PRD end-to-end.

Do not propose architecture yet.

Extract:
1. Product in one sentence.
2. What the product is.
3. What the product is not.
4. Primary problem.
5. Primary user.
6. Core workflow.
7. Explicit requirements.
8. Implied requirements.
9. External dependencies.
10. Ambiguous terms.
11. Initial technical risks.
12. Initial product risks.
13. Initial acceptance / evaluation risks (incl. demo risk — only if a demo is in scope).
14. Recommended planning mode.
15. Recommended build posture (production-grade by default — to be confirmed with the user).

Then ask the highest-leverage clarification questions before moving on.
```

### Interview Questions

Use these when the PRD is light:

```text
1. What is the one thing the product must prove for acceptance (to its evaluator / user — in a demo only if one is in scope)?
2. Who is the primary user?
3. What is the user's starting point and desired end state?
4. What must happen automatically vs manually?
5. What state changes in the system?
6. What data does the product create, read, update, or delete?
7. What external systems must it integrate with?
8. What technologies are required, preferred, or forbidden?
9. What is the timebox?
10. What would make the project fail from a reviewer perspective?
```

### Stop Condition

Do not proceed until the agent can explain the product in plain English and the user confirms or corrects it.

---

## 5. Phase 1 — Product Mechanics Clarification

### Goal

Understand how the product works at the level of mechanics, not stack.

This phase is critical when the product has domain concepts like bets, markets, cases, workflows, claims, approvals, agents, documents, money, permissions, or state transitions.

### Required Output

Add to `PRESEARCH.md`:

```md
## Phase 1 — Product Mechanics

### Core Object of Value
...

### State-Changing Actions
...

### Lifecycle
...

### Units / Prices / Scores / Claims / Documents / Records
...

### Who or What Creates the Main Objects
...

### Who or What Resolves / Completes Them
...

### Hidden Mechanics
...

### Confirmed Mechanics
...

### Still Ambiguous
...
```

### Prompt

```text
Explain the product mechanics before architecture.

Answer:
- What is the core object of value?
- What does the user create, view, trade, approve, submit, analyze, or resolve?
- What state changes?
- What is the lifecycle from creation to completion?
- Who creates the main entities?
- Who or what resolves them?
- What are the key units: money, tokens, files, claims, tasks, jobs, records, scores, etc.?
- What are the edge cases?
- What is likely obvious to the PRD author but not explicit in the PRD?

If any mechanics are unclear, interview me before moving on.
```

### Deep Interview Questions

```text
1. Walk me through the user's first successful use of the product.
2. What does the system know before the user arrives?
3. What does the user provide?
4. What does the system generate?
5. What state must persist?
6. What state is temporary?
7. What is the unit of work?
8. What is the unit of value?
9. What events start and end the workflow?
10. What actions should be impossible?
11. What is the simplest possible version of the workflow?
12. What part of the workflow would be hardest to explain to a reviewer?
```

### Output Quality Bar

The agent should be able to produce a plain-English walkthrough like:

```text
A user starts at X, performs Y, the system creates Z, then A happens, then B resolves the workflow, and success means C.
```

---

## Phase-bound micro-prompts (stage 1)

### Product Mechanics

```text
Before architecture, explain the product mechanics in plain English.

What is the user trying to do?
What changes state?
What is the unit of work?
What is the unit of value?
What starts the workflow?
What ends the workflow?
What are the success/failure states?
What hidden lifecycle rules exist?
What is unclear?
```

