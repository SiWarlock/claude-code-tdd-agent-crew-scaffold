# Deep Agentic Architecture Planning Playbook

> **Status:** Project-agnostic, deep-planning operating procedure for turning any PRD, product idea, or lightweight prompt into a build-ready first-draft `ARCHITECTURE.md`.
>
> **Audience:** You, a fresh ChatGPT/Claude planning session, Claude Code after it reviews the draft, technical reviewers, and future project sessions that need a rigorous architecture-first workflow.
>
> **Primary purpose:** Reproduce the deep planning process used in past projects: product mechanics clarification, user/workflow analysis, posture-scoped inference, research, decision discovery, decision locking, architecture section planning, and then a build-ready architecture draft.
>
> **Important workflow boundary:** This playbook does **not** require generating `IMPLEMENTATION_PLAN.md`. In this workflow, Claude Code reviews the architecture draft and supporting docs, performs a second-pass gap audit/finalization, and then creates `IMPLEMENTATION_PLAN.md` from the user's task-template structure.
>
> **Core principle:** The planning phase should feel like a structured interview plus architecture review, not a one-shot summary. When the PRD is light, the agent must interview the user until enough information exists to write a useful architecture draft.

---

## 0. Copy-Paste Kickoff Prompt

Use this at the start of a fresh architecture planning session.

```text
You are helping me turn a PRD, project brief, or lightweight product idea into a build-ready first-draft ARCHITECTURE.md for my agentic coding workflow.

Follow the attached Deep Agentic Architecture Planning Playbook.

Do not jump to implementation.
Do not produce IMPLEMENTATION_PLAN.md.
Do not draft ARCHITECTURE.md until we have completed the deep planning process:
- PRD/product intake
- product mechanics clarification
- user/persona/stakeholder analysis
- workflow/lifecycle discovery
- domain model discovery
- explicit + inferred requirements extraction
- constraints/evaluation analysis
- open questions/assumptions
- research plan and research where needed
- architecture decision discovery
- decision locking
- section-by-section architecture planning

If the PRD is light or ambiguous, interview me. Ask focused batches of questions. After each batch, synthesize what you learned, identify gaps, and ask me to confirm or correct it.

Classify every recommendation as:
- locked decision
- proposed recommendation
- open question
- scope simplification (a posture-gated cut — justified, never silent)
- production-hardening (load-bearing under a production-grade posture)
- deferred work
- research required

The final output should be a comprehensive first-draft ARCHITECTURE.md with stable anchors and enough implementation detail that Claude Code can review it, perform a second pass for gaps, finalize it, and then create IMPLEMENTATION_PLAN.md from my template.

Start with Phase 0: Intake and Planning Mode Selection.
```

---

## 1. Philosophy and Operating Model

### 1.1 Why This Playbook Exists

Most AI architecture attempts fail because they skip discovery.

They jump from:

```text
PRD → stack suggestion → implementation plan
```

This playbook forces:

```text
PRD or idea
→ product mechanics
→ users/stakeholders
→ workflows
→ domain model
→ requirements
→ constraints
→ research
→ decisions
→ locked baseline
→ section-by-section architecture
→ architecture draft
→ Claude Code second-pass gap audit
→ final architecture
→ IMPLEMENTATION_PLAN.md generated separately
```

### 1.2 The Planning Session Should Be Interactive

The process is intentionally conversational. The agent should not try to answer everything in one shot.

The expected loop is:

```text
Agent reads / extracts
→ Agent asks focused questions
→ User answers / corrects
→ Agent synthesizes
→ Agent proposes decisions
→ User locks or redirects
→ Agent moves to next phase
```

### 1.3 Deep Planning vs Artifact Writing

Do not confuse planning with artifact generation.

Planning outputs may be conversational, messy, and iterative.

Final artifacts should be structured, stable, and reusable.

The planning phase creates enough understanding to write:

```text
PRESEARCH.md
RESEARCH.md
DECISIONS.md
ARCHITECTURE_DRAFT.md
DIAGRAM_PLAN.md
CLAUDE_CODE_HANDOFF.md
```

`IMPLEMENTATION_PLAN.md` is intentionally not required here.

---

## 2. Recommended Artifact Set

### 2.1 Default Artifact Set

For most projects, produce:

```text
PRESEARCH.md
RESEARCH.md
DECISIONS.md
ARCHITECTURE.md
DIAGRAM_PLAN.md
CLAUDE_CODE_HANDOFF.md
```

### 2.2 Artifact Responsibilities

| Artifact | Purpose |
|---|---|
| `PRESEARCH.md` | Captures product understanding, users, stakeholders, workflows, domain model, requirements, assumptions, open questions, constraints, evaluation criteria, risks, and early decision candidates. |
| `RESEARCH.md` | Records current/external facts verified through research, with sources, findings, and architecture impact. |
| `DECISIONS.md` | ADR-style decision log showing options, tradeoffs, locked choices, fallbacks, and invalidation conditions. |
| `ARCHITECTURE.md` | Build-ready first-draft architecture spec with stable anchors and implementation-facing sections. |
| `DIAGRAM_PLAN.md` | Plans the full-scope architecture diagram and sub-diagrams. |
| `CLAUDE_CODE_HANDOFF.md` | Tells Claude Code how to review/finalize the architecture draft and then generate `IMPLEMENTATION_PLAN.md` from the user's provided template. |

### 2.3 Expanded Artifact Set

Use expanded mode for complex/security-heavy projects:

```text
PRODUCT_BRIEF.md
USERS.md
STAKEHOLDERS.md
USER_FLOWS.md
DOMAIN_MODEL.md
REQUIREMENTS.md
CONSTRAINTS.md
EVALUATION_CRITERIA.md
ASSUMPTIONS.md
OPEN_QUESTIONS.md
RESEARCH.md
DECISIONS.md
RISKS.md
THREAT_MODEL.md
DATA_MODEL.md
ARCHITECTURE.md
DIAGRAM_PLAN.md
CLAUDE_CODE_HANDOFF.md
```

### 2.4 Compact Artifact Set

Use compact mode for very fast projects:

```text
PRESEARCH.md
ARCHITECTURE.md
CLAUDE_CODE_HANDOFF.md
```

But even in compact mode, the agent must still perform the planning interview.

---

## 3. Planning Mode & Build Posture Selection

Two **independent** classify-first decisions precede any architecture work — answer **both**, they are orthogonal:
- **Planning mode** (§3.1–3.2) — *how much planning ceremony / how many artifacts*, sized to build duration and risk.
- **Build posture** (§3.3–3.4) — *the quality / delivery target the design and implementation aim at*. This steers
  every downstream inference and decision and **must be explicitly confirmed by the user — never assumed.**

### 3.1 Mode Options

| Mode | When to Use | Output |
|---|---|---|
| Compact | Tiny PRD, 1–3 day build, low risk | `PRESEARCH.md`, `ARCHITECTURE.md`, `CLAUDE_CODE_HANDOFF.md` |
| Standard | Most multi-day builds | `PRESEARCH.md`, `RESEARCH.md`, `DECISIONS.md`, `ARCHITECTURE.md`, `DIAGRAM_PLAN.md`, `CLAUDE_CODE_HANDOFF.md` |
| Expanded | Security/compliance/enterprise/team-heavy projects | Separate product/users/stakeholders/domain/etc docs plus architecture package |

### 3.2 Mode Selection Prompt

```text
Before starting, classify the planning mode.

Given the PRD/project brief:
- Is the PRD detailed or light?
- Is the domain familiar or novel?
- Are there high-stakes security/data/compliance concerns?
- Is there a hard timebox?
- Is the architecture expected to be reviewed by technical stakeholders?
- Will Claude Code build from this?

Recommend Compact, Standard, or Expanded mode.
Explain why.
Ask me to confirm.
```

### 3.3 Build Posture Options

The build posture is the **delivery target** the architecture and the implementation plan aim at. It is
orthogonal to planning mode (a production-grade build can be Compact; an MVP can be Expanded). **Default
recommendation: production-grade — but ALWAYS ask and confirm; never assume a posture.**

| Posture | What it means | How it steers design + implementation |
|---|---|---|
| **Production-grade** (default) | The system is meant to run for real and be maintained. | Architecturally-correct, best-practice choices are the baseline. Auth, input validation, error paths, idempotency, observability/logging, secrets handling, and a deploy/rollback path are **in-scope requirements**, not deferrable "nice-to-haves." Phase-8 inference asks *"what must a correct production build handle?"* Cuts are explicit, justified `production-hardening` deferrals — flagged, never silent. A demo is OPTIONAL. |
| **MVP / prototype** | A timeboxed proof — validate the idea, a demo, or a narrow wedge. | Lean, timebox-bounded. Robustness concerns may be deliberately deferred (and flagged as deferrals so the hardening work stays visible). A local demo, **if in scope**, is the natural near-final slice (optional under this posture too — still asked, not assumed). |

Even under MVP posture, **load-bearing safety / security / correctness invariants are never cut** — posture
governs *scope and polish*, not whether the system is correct on its load-bearing paths.

### 3.4 Build Posture Selection Prompt

```text
Now choose the build posture (separate from planning mode — both are required).

Given the PRD/project brief:
- Is this meant to run in production and be maintained, or is it a timeboxed proof / prototype / demo?
- Who depends on it being correct and available, and what breaks if it isn't?
- Is there a hard timebox that forces deferrals?

I recommend PRODUCTION-GRADE unless this is explicitly a prototype/MVP.
State the recommendation and WHY, then ASK me to confirm production-grade or choose MVP/prototype.
Do NOT proceed until I confirm — then record the chosen posture in PRESEARCH.md and the handoff.
```

---

## Phase Index — goals, stop conditions, stage files

The 18 phases run IN ORDER in every mode (compact mode compresses outputs, never skips phases).
Read the stage file **just-in-time** as the interview enters its phases; the stop condition for every
phase is its **Required Output captured + the user's confirmation of the synthesis** — never the
agent's own satisfaction. After Phase 17 comes the optional IMPLEMENTATION_PLAN handoff note, the
Quality Review Checklist, and the Final Success Condition (all in stage 6).

| Phase | Title | Goal | Stage file |
|---|---|---|---|
| 0 | Intake and Initial Read | Understand the PRD without proposing architecture yet | `stages/stage-1-intake-and-mechanics.md` |
| 1 | Product Mechanics Clarification | Understand how the product works at the level of mechanics, not stack | `stages/stage-1-intake-and-mechanics.md` |
| 2 | Users, Actors, and Permissions | Identify who uses the system, who operates it, who reviews it, and what each actor can/cannot do | `stages/stage-2-users-stakeholders-flows.md` |
| 3 | Stakeholders and Reviewers | Understand who will judge the architecture and what evidence they need | `stages/stage-2-users-stakeholders-flows.md` |
| 4 | User Flows and Lifecycle Flows | Define all critical workflows before architecture | `stages/stage-2-users-stakeholders-flows.md` |
| 5 | Domain Model and State Machines | Define the nouns, relationships, state machines, and invariants | `stages/stage-3-domain-requirements-constraints-scope.md` |
| 6 | Requirements Extraction | Turn PRD + interview outputs into testable requirements | `stages/stage-3-domain-requirements-constraints-scope.md` |
| 7 | Constraints, Evaluation, and Timebox | Constrain the architecture to what is buildable and what will be judged | `stages/stage-3-domain-requirements-constraints-scope.md` |
| 8 | Scope Inference (posture-aware) | Infer hidden requirements — sized to the chosen **Build posture** (§3.3): neither overbuilding nor under-building | `stages/stage-3-domain-requirements-constraints-scope.md` |
| 9 | Assumptions and Open Questions | Track uncertainty explicitly | `stages/stage-4-assumptions-research-decisions.md` |
| 10 | Research Plan and Research Execution | Validate unstable/current/external facts before locking architecture | `stages/stage-4-assumptions-research-decisions.md` |
| 11 | Architecture Decision Discovery | Compare options before locking decisions | `stages/stage-4-assumptions-research-decisions.md` |
| 12 | Decision Locking | Create a stable baseline before architecture drafting | `stages/stage-4-assumptions-research-decisions.md` |
| 13 | Section-by-Section Architecture Planning | Plan the architecture in sections before drafting | `stages/stage-5-section-planning-security-drafting.md` |
| 14 | Security, Risk, and Failure Modes | Ensure architecture covers failure modes and reviewer concerns | `stages/stage-5-section-planning-security-drafting.md` |
| 15 | Architecture Drafting | Create the first build-ready `ARCHITECTURE.md` | `stages/stage-5-section-planning-security-drafting.md` |
| 16 | Claude Code Review Instructions | Tell Claude Code what to do with the draft architecture before building | `stages/stage-6-handoff-review-diagrams.md` |
| 17 | Diagram Plan | Plan diagrams after architecture, not before | `stages/stage-6-handoff-review-diagrams.md` |

---

## 25. Reusable Micro-Prompts

These two are **cross-cutting** — usable from ANY phase. The phase-bound micro-prompts (Product
Mechanics, Posture-Scoped Inference, Decision Matrix, Architecture Gap Audit) live in their owning
stage files.

### Interview the User

```text
The PRD is too light to proceed.

Interview me in a focused batch of 8–12 questions.
Prioritize questions that affect architecture decisions.
After I answer, synthesize what changed and identify remaining gaps.
Do not ask low-value questions.
```

### Deepen a Thin Section

```text
This section is too thin.

Rewrite it as a build-ready planning section:
- exact responsibilities
- boundaries
- source of truth
- inputs/outputs
- data types/schemas
- lifecycle rules
- validation rules
- failure modes
- tests
- scope simplifications (posture-gated cuts) + any production-hardening requirements
- deferred work
```

