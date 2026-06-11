> **FROZEN SNAPSHOT — do not edit.** This is the pre-build-posture archive copy of the playbook,
> kept for provenance only (see `docs/archive/README.md`). The LIVE, maintained copy is
> `skills/arch-draft/references/architecture-planning-playbook.md` — all edits go there.

# Deep Agentic Architecture Planning Playbook

> **Status:** Project-agnostic, deep-planning operating procedure for turning any PRD, product idea, or lightweight prompt into a build-ready first-draft `ARCHITECTURE.md`.
>
> **Audience:** You, a fresh ChatGPT/Claude planning session, Claude Code after it reviews the draft, technical reviewers, and future project sessions that need a rigorous architecture-first workflow.
>
> **Primary purpose:** Reproduce the deep planning process used in past projects: product mechanics clarification, user/workflow analysis, MVP-scoped inference, research, decision discovery, decision locking, architecture section planning, and then a build-ready architecture draft.
>
> **Important workflow boundary:** This playbook does **not** require generating `MVP_TASKS.md`. In this workflow, Claude Code reviews the architecture draft and supporting docs, performs a second-pass gap audit/finalization, and then creates `MVP_TASKS.md` from the user's task-template structure.
>
> **Core principle:** The planning phase should feel like a structured interview plus architecture review, not a one-shot summary. When the PRD is light, the agent must interview the user until enough information exists to write a useful architecture draft.

---

## 0. Copy-Paste Kickoff Prompt

Use this at the start of a fresh architecture planning session.

```text
You are helping me turn a PRD, project brief, or lightweight product idea into a build-ready first-draft ARCHITECTURE.md for my agentic coding workflow.

Follow the attached Deep Agentic Architecture Planning Playbook.

Do not jump to implementation.
Do not produce MVP_TASKS.md.
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
- MVP simplification
- deferred work
- research required

The final output should be a comprehensive first-draft ARCHITECTURE.md with stable anchors and enough implementation detail that Claude Code can review it, perform a second pass for gaps, finalize it, and then create MVP_TASKS.md from my template.

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
→ MVP_TASKS.md generated separately
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

`MVP_TASKS.md` is intentionally not required here.

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
| `CLAUDE_CODE_HANDOFF.md` | Tells Claude Code how to review/finalize the architecture draft and then generate `MVP_TASKS.md` from the user's provided template. |

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

## 3. Planning Mode Selection

### 3.1 Mode Options

| Mode | When to Use | Output |
|---|---|---|
| Compact | Tiny PRD, 1–3 day build, low risk | `PRESEARCH.md`, `ARCHITECTURE.md`, `CLAUDE_CODE_HANDOFF.md` |
| Standard | Most 3–10 day MVPs | `PRESEARCH.md`, `RESEARCH.md`, `DECISIONS.md`, `ARCHITECTURE.md`, `DIAGRAM_PLAN.md`, `CLAUDE_CODE_HANDOFF.md` |
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

---

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
13. Initial demo/evaluation risks.
14. Recommended planning mode.

Then ask the highest-leverage clarification questions before moving on.
```

### Interview Questions

Use these when the PRD is light:

```text
1. What is the one thing the product must prove in the demo?
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

## 6. Phase 2 — Users, Actors, and Permissions

### Goal

Identify who uses the system, who operates it, who reviews it, and what each actor can/cannot do.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `USERS.md`.

### Template

```md
## Phase 2 — Users and Actors

### Primary User
- Role:
- Goal:
- Context:
- Pain points:
- Workflow:
- Success state:
- Failure state:

### Secondary Users
...

### Operators / Admins
...

### Non-Human Actors
...

### Permission Matrix
| Actor | Can Do | Cannot Do | Risk |
|---|---|---|---|

### User Questions Still Open
...
```

### Prompt

```text
Identify every human and non-human actor.

For each actor:
- goal
- workflow
- permissions
- what they can do
- what they cannot do
- what data they can see
- what data they can modify
- what failure looks like for them

Include non-human actors:
- background jobs
- agents
- external APIs
- schedulers
- wallets
- bots
- workers
- services
```

### Deep Interview Questions

```text
1. Who is the primary user?
2. Who is the buyer/customer if different from the user?
3. Who operates the system?
4. Who administers it?
5. Who reviews or audits it?
6. Are there roles with different permissions?
7. Are there external systems acting as users?
8. What should each actor never be able to do?
9. What data should each actor never see?
10. Are there background jobs or automation actors?
```

---

## 7. Phase 3 — Stakeholders and Reviewers

### Goal

Understand who will judge the architecture and what evidence they need.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `STAKEHOLDERS.md`.

### Template

```md
## Phase 3 — Stakeholders

| Stakeholder | Cares About | Would Reject If | Evidence Needed | Architecture Must Address |
|---|---|---|---|---|
| CTO | ... | ... | ... | ... |
| CISO | ... | ... | ... | ... |
| Product Owner | ... | ... | ... | ... |
| Reviewer/Evaluator | ... | ... | ... | ... |
```

### Prompt

```text
Identify stakeholders who may not directly use the product but care about the system.

For each:
- what they care about
- what would make them reject the architecture
- what evidence they need
- what tradeoffs they tolerate
- what parts of the architecture must speak to their concerns
```

### Stakeholder Categories

```text
CTO
CISO/security reviewer
Product owner
Engineering manager
Compliance/legal
Operations owner
Data owner
Customer/user representative
Investor/evaluator
Support/admin team
Developer/maintainer
```

---

## 8. Phase 4 — User Flows and Lifecycle Flows

### Goal

Define all critical workflows before architecture.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `USER_FLOWS.md`.

### Template

```md
## Phase 4 — User and System Flows

### Flow: [Name]

Actor:
Trigger:
Preconditions:
Steps:
1. ...
2. ...

System Responsibilities:
...

Success State:
...

Failure States:
...

Data Touched:
...

Security / Lifecycle Constraints:
...
```

### Prompt

```text
Extract and/or infer the main user and system flows.

For each flow:
- actor
- trigger
- preconditions
- step-by-step workflow
- system responsibilities
- success state
- failure states
- data touched
- permissions
- lifecycle constraints

Include background jobs and admin flows, not just frontend flows.
```

### Deep Flow Interview

```text
1. What is the happy path?
2. What is the failed path?
3. What is the admin/operator path?
4. What is the background automation path?
5. What is the demo path?
6. What is the recovery path?
7. What state is created?
8. What state is updated?
9. What state is deleted or finalized?
10. What should happen if an external dependency fails?
11. What should happen if the user abandons halfway through?
12. What does the system need to show the user at each step?
```

### Stop Condition

Every MVP requirement should map to a flow.

If a requirement has no flow, either:
- add a flow
- mark the requirement as deferred
- mark it as unclear

---

## 9. Phase 5 — Domain Model and State Machines

### Goal

Define the nouns, relationships, state machines, and invariants.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `DOMAIN_MODEL.md`.

### Template

```md
## Phase 5 — Domain Model

### Core Entities
| Entity | Definition | Key Fields | Source of Truth |
|---|---|---|---|

### Relationships
...

### State Machines
...

### Business Rules
...

### Invariants
...

### Glossary
...

### Ambiguous Terms
...
```

### Prompt

```text
Build the domain model.

Identify:
- entities
- relationships
- state machines
- lifecycle transitions
- business rules
- invariants
- units and precision
- terminology
- ambiguous terms

Do not design services yet. First define the domain language.
```

### Deep Domain Questions

```text
1. What are the nouns?
2. Which nouns are persistent entities?
3. Which nouns are derived views?
4. Which nouns are external objects?
5. What are the lifecycle states?
6. What transitions are allowed?
7. What transitions are forbidden?
8. What invariants must never be broken?
9. What data is authoritative?
10. What data is cached/derived/display-only?
11. What data can be stale?
12. What data must be real-time?
```

---

## 10. Phase 6 — Requirements Extraction

### Goal

Turn PRD + interview outputs into testable requirements.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `REQUIREMENTS.md`.

### Template

```md
## Phase 6 — Requirements

### Functional Requirements
| ID | Requirement | Source | Priority | Acceptance Signal |
|---|---|---|---|---|

### Non-Functional Requirements
...

### Data Requirements
...

### Security Requirements
...

### UX Requirements
...

### Operational Requirements
...

### Integration Requirements
...

### Testing Requirements
...

### Demo / Evaluation Requirements
...

### Deferred Requirements
...
```

### Prompt

```text
Extract explicit and inferred requirements.

Classify each requirement as:
- functional
- non-functional
- data
- security
- UX
- operational
- integration
- testing
- demo/evaluation
- deferred

For each requirement:
- assign a stable ID
- identify source: explicit / inferred / user-confirmed
- priority: MVP / stretch / deferred
- acceptance signal
- related user flow
```

### Requirement IDs

```text
REQ-F-001   Functional
REQ-NF-001  Non-functional
REQ-D-001   Data
REQ-S-001   Security
REQ-UX-001  UX
REQ-O-001   Operational
REQ-I-001   Integration
REQ-T-001   Testing
REQ-E-001   Evaluation/demo
```

---

## 11. Phase 7 — Constraints, Evaluation, and Timebox

### Goal

Constrain the architecture to what is buildable and what will be judged.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `CONSTRAINTS.md` and `EVALUATION_CRITERIA.md`.

### Prompt

```text
Identify constraints and evaluation criteria.

Capture:
- timebox
- team size
- available tooling
- required technologies
- forbidden technologies
- preferred technologies
- deployment constraints
- data/security/compliance constraints
- demo constraints
- reviewer/evaluator expectations
- what technical depth will be rewarded
- what would be disqualifying
```

### Deep Questions

```text
1. How many days/hours are available?
2. Who will build it?
3. What tooling will be used?
4. What must be demoed live?
5. What can be mocked?
6. What cannot be mocked?
7. What must be deployed?
8. What must run locally?
9. What does the evaluator care about most?
10. What tradeoffs need to be defended?
11. What would be considered scope creep?
12. What must be explicitly deferred?
```

---

## 12. Phase 8 — MVP-Scoped Inference

### Goal

Infer hidden requirements without overbuilding.

### Required Output

Add to `PRESEARCH.md`:

```md
## Phase 8 — MVP-Scoped Inferences

| Inference | Why It Matters | Classification | Architecture Impact |
|---|---|---|---|
| ... | ... | MVP-critical / simplification / deferred / research | ... |
```

### Prompt

```text
Infer what the PRD does not explicitly say but the MVP must still handle.

For each inference:
- state the inference
- explain why it matters
- classify as:
  - MVP-critical
  - MVP simplification
  - deferred
  - research required
- describe architecture impact

Do not expand beyond the timebox.
```

### Common Hidden Requirements

```text
authentication/authorization
admin/operator flows
background jobs
state lifecycle
failure recovery
idempotency
data validation
auditability/logging
secrets management
deployment envs
demo seed data
test fixtures
fallbacks for external dependency failure
```

---

## 13. Phase 9 — Assumptions and Open Questions

### Goal

Track uncertainty explicitly.

### Required Output

Compact mode: add to `PRESEARCH.md`.

Expanded mode: create `ASSUMPTIONS.md` and `OPEN_QUESTIONS.md`.

### Prompt

```text
List assumptions and open questions.

For assumptions:
- assumption
- category
- why it matters
- validation path
- fallback

For open questions:
- question
- why it matters
- current best guess
- when it must be answered
- fallback
- status

Do not silently resolve important unknowns.
```

### Deep Interview

```text
1. What are we assuming about users?
2. What are we assuming about data?
3. What are we assuming about APIs?
4. What are we assuming about deployment?
5. What are we assuming about budget/time?
6. What are we assuming about evaluator expectations?
7. Which assumptions are dangerous?
8. Which assumptions can be validated quickly?
9. Which assumptions need fallback architecture?
```

---

## 14. Phase 10 — Research Plan and Research Execution

### Goal

Validate unstable/current/external facts before locking architecture.

### Required Output

`RESEARCH.md`

### Research Triggers

Research is required when a fact is:

- current or likely to have changed
- external dependency-related
- pricing/limits-related
- legal/regulatory/compliance-related
- third-party integration-related
- unfamiliar
- niche
- critical to architecture feasibility

### Template

```md
# RESEARCH.md

## Research Questions

| ID | Question | Why It Matters | Decision It Informs | Status |
|---|---|---|---|---|

## Findings

### R-001 — [Topic]
Question:
Findings:
Sources:
Impact:
Decision Implication:
Remaining Risk:
```

### Prompt

```text
Create a research plan for all unstable or external facts.

For each research item:
- question
- why it matters
- what decision it informs
- what source type is needed
- what would change the architecture

Then perform the research and summarize:
- findings
- sources
- architecture impact
- remaining risk
- recommended decision implication
```

### Research Quality Bar

Each researched fact should answer:

```text
Can we rely on this for the MVP, and what is the fallback if not?
```

---

## 15. Phase 11 — Architecture Decision Discovery

### Goal

Compare options before locking decisions.

### Required Output

`DECISIONS.md`

### ADR Template

```md
## ADR-001 — [Decision Title]

Status: Proposed / Locked / Deferred / Superseded

### Context
...

### Options Considered
| Option | Pros | Cons | Build Risk | Demo Risk | Security Risk | PRD Alignment |
|---|---|---|---|---|---|---|

### Recommendation
...

### Decision
...

### Rationale
...

### Tradeoffs
...

### Fallback
...

### What Would Change This Decision
...

### Related Requirements
...

### Related Architecture Anchors
...
```

### Prompt

```text
For each major architecture decision, create an ADR-style decision record.

Compare:
- options
- pros/cons
- build risk
- demo risk
- security risk
- PRD alignment
- recommendation
- fallback
- what would invalidate the choice

Do not lock decisions until I confirm them unless the PRD mandates them.
```

### Common Decision Domains

```text
frontend framework
backend framework
database/storage
auth
deployment
scheduler/queue
agent framework
LLM model/provider
retrieval/indexing
API style
data model
security boundary
observability
test strategy
demo strategy
MVP vs deferred scope
```

---

## 16. Phase 12 — Decision Locking

### Goal

Create a stable baseline before architecture drafting.

### Required Output

Add to `DECISIONS.md` and later `ARCHITECTURE.md`:

```md
## Locked Decision Summary

| Area | Decision | Status | Rationale | Fallback |
|---|---|---|---|---|
| ... | ... | Locked | ... | ... |
```

### Prompt

```text
Summarize all proposed decisions.

For each:
- area
- decision
- rationale
- fallback
- remaining risk
- open verification

Ask me to confirm which are locked.
After confirmation, treat them as the current architecture baseline.
```

### Stop Condition

Do not draft `ARCHITECTURE.md` until the major load-bearing decisions are locked or explicitly marked open.

---

## 17. Phase 13 — Section-by-Section Architecture Planning

### Goal

Plan the architecture in sections before drafting.

### Required Output

A planning transcript and/or `ARCHITECTURE_OUTLINE.md`.

### Prompt

```text
Plan the architecture section by section before writing the final document.

For each section:
- purpose
- responsibilities
- boundaries
- components/modules/services/contracts
- data flow
- state/lifecycle rules
- integrations
- failure modes
- tests
- MVP simplifications
- deferred work
- open questions
```

### Recommended Section Planning Order

```text
1. Executive summary and architecture posture
2. Product definition and MVP scope
3. Locked decisions
4. System overview
5. Domain model
6. Core modules/services/contracts
7. Data/state model
8. User-facing flows
9. Background/automation flows
10. External integrations
11. Frontend architecture
12. Backend/API/indexer strategy
13. Shared package/config strategy
14. Testing strategy
15. Security/risk
16. Deployment/demo strategy
17. Alternatives considered
18. MVP boundaries/deferred work
19. Diagrams
20. Repo scaffold
21. Build contract
```

### Section Deepening Prompt

Use this when a section feels thin:

```text
This section is too high-level. Deepen it into a build-ready planning section.

Include:
- exact responsibilities
- exact inputs/outputs
- ownership/source of truth
- data types or schemas where possible
- lifecycle/state rules
- validation rules
- error cases
- tests
- MVP simplifications
- deferred work
- what Claude Code needs to know to build it
```

---

## 18. Phase 14 — Security, Risk, and Failure Modes

### Goal

Ensure architecture covers failure modes and reviewer concerns.

### Required Output

`RISKS.md` or `PRESEARCH.md` risk section, then architecture risk section.

### Prompt

```text
Identify product, technical, data, security, integration, operational, demo, scope, and regulatory/compliance risks.

For each:
- risk
- category
- severity
- likelihood
- mitigation
- fallback
- test/validation
- whether it must appear in ARCHITECTURE.md
```

### Trust Boundary Prompt

```text
Identify trust boundaries.

For each boundary:
- what crosses it
- who controls each side
- what validation happens
- what can go wrong
- what logs/auditability exist
- what secrets/sensitive data are involved
- what the MVP mitigation is
```

### Common Risk Categories

```text
auth/authorization
secrets
data leakage
financial/collateral correctness
external dependency failure
model hallucination
prompt injection
PII/PHI
payment failure
race conditions
idempotency
background job failure
deployment misconfiguration
user confusion
demo fragility
scope creep
```

---

## 19. Phase 15 — Architecture Drafting

### Goal

Create the first build-ready `ARCHITECTURE.md`.

### Required Output

`ARCHITECTURE.md`

### Required Characteristics

The architecture draft must be:

- comprehensive
- stable
- sectioned
- anchored
- implementation-facing
- explicit about decisions
- explicit about assumptions
- explicit about boundaries
- explicit about failure modes
- explicit about testing and deployment
- suitable for Claude Code second-pass review

### Header Template

```md
# [Project] Architecture

> **Status:** First-draft canonical architecture spec for the MVP.
>
> **Audience:** Project owner, technical reviewers, future Claude Code sessions.
>
> **Primary implementation constraint:** [timebox / team / constraints].
>
> **Companion docs:** `PRESEARCH.md`, `RESEARCH.md`, `DECISIONS.md`, `DIAGRAM_PLAN.md`, `CLAUDE_CODE_HANDOFF.md`.
>
> **Build contract:** Claude Code should treat this file as the first-draft source of truth, perform a second-pass gap audit, finalize it, and only then create `MVP_TASKS.md` from the user's template.
```

### Recommended Structure

```md
## 1. Executive Summary
## 1A. Goals & Non-Goals
## 2. Product Definition and Scope
## 3. Locked Architecture Decisions
## 4. System Overview
## 5. Domain Model
## 6. Core Module / Service / Contract Architecture
## 7. Data and State Model
## 8. User Flows
## 9. Integration Architecture
## 10. Automation / Background Jobs
## 11. Frontend Architecture
## 12. Backend / API / Indexer Strategy
## 13. Shared Package / Config Strategy
## 14. Testing Strategy
## 15. Security and Risk
## 16. Deployment Strategy
## 17. Alternatives Considered
## 18. MVP Boundaries and Deferred Work
## 19. Diagrams
## 20. Repo Scaffold
## 21. Decision Summary Table
## 22. Spec Anchor Index
## 23. Claude Code Review Instructions
```

### Drafting Prompt

```text
Draft ARCHITECTURE.md using all prior planning artifacts.

The document must be build-ready and include:
- stable anchors for every major section
- status/audience/build contract
- goals/non-goals
- locked decisions
- system overview
- domain model
- component/service/contract boundaries
- data/state model
- user and automation flows
- integration details
- frontend/backend strategy
- testing strategy
- security/risk
- deployment/demo strategy
- alternatives considered
- MVP boundaries/deferred work
- repo scaffold
- spec anchor index
- Claude Code review instructions

Do not include implementation tasks. Those come later after Claude Code reviews and finalizes the architecture.
```

---

## 20. Phase 16 — Claude Code Review Instructions

### Goal

Tell Claude Code what to do with the draft architecture before building.

### Required Output

`CLAUDE_CODE_HANDOFF.md`

### Template

```md
# Claude Code Handoff

## Goal

Review the attached architecture draft and supporting docs, identify gaps, finalize the architecture, then create MVP_TASKS.md from the user's provided template.

## Inputs

- PRD
- PRESEARCH.md
- RESEARCH.md
- DECISIONS.md
- ARCHITECTURE.md
- DIAGRAM_PLAN.md
- user's MVP_TASKS.md template

## Instructions

1. Read all docs end-to-end.
2. Do not start implementation.
3. Perform an architecture gap audit.
4. Identify inconsistencies, missing decisions, unclear boundaries, untestable requirements, and scope creep.
5. Propose precise edits to ARCHITECTURE.md.
6. Ask for human confirmation on any load-bearing changes.
7. Apply confirmed edits.
8. Only after architecture is finalized, create MVP_TASKS.md using the provided template.
9. Every task must reference architecture anchors.
10. Do not invent architecture in MVP_TASKS.md.
```

### Gap Audit Prompt

```text
Perform a second-pass architecture gap audit.

Look for:
- missing user flows
- missing lifecycle states
- missing failure modes
- missing interfaces or schemas
- unclear source-of-truth boundaries
- unresearched external dependencies
- inconsistent decisions
- overbuilt scope
- missing tests
- missing deployment/demo path
- missing security/trust boundaries
- missing diagram needs
- missing anchors for task planning

Return:
1. Critical gaps
2. Important gaps
3. Nice-to-have improvements
4. Proposed architecture edits
5. Questions requiring human decision
```

---

## 21. Phase 17 — Diagram Plan

### Goal

Plan diagrams after architecture, not before.

### Required Output

`DIAGRAM_PLAN.md`

### Template

```md
# Diagram Plan

## Full-Scope Architecture Diagram

Purpose:
...

Must show:
...

Spec anchors:
...

## Sub-Diagrams

### 1. [Name]
Purpose:
Must show:
Spec anchors:
Priority:
Format:
```

### Prompt

```text
Create a diagram plan from ARCHITECTURE.md.

Include:
- one full-scope architecture diagram
- prioritized sub-diagrams
- purpose of each diagram
- what each diagram must show
- spec anchors each diagram maps to
- recommended format

Favor diagrams that clarify hard mechanics, lifecycle flows, trust boundaries, and implementation seams.
```

### Common Diagram Types

```text
Full-system architecture map
User flow diagram
Lifecycle sequence diagram
Domain model diagram
Data flow diagram
Frontend data-plane diagram
Contract/module internals
External integration diagram
Automation/scheduler diagram
Security/trust-boundary diagram
Testing/phase-gate diagram
Deployment topology diagram
```

---

## 22. Optional Phase — MVP_TASKS Handoff, Not Generation

This playbook no longer requires generating `MVP_TASKS.md`.

The recommended workflow is:

```text
Planning agent produces ARCHITECTURE.md draft.
Claude Code reviews and finalizes architecture.
User provides MVP_TASKS.md template.
Claude Code generates MVP_TASKS.md from finalized architecture + template.
```

### Handoff Requirements

The architecture package should make this easy by including:

```text
stable anchors
implementation order
test strategy
repo scaffold
preflight gates
open verifications
decision summary
deferred work
```

### Handoff Prompt for Claude Code

```text
After finalizing ARCHITECTURE.md, create MVP_TASKS.md using my provided template.

Rules:
- Every task must reference ARCHITECTURE.md anchors.
- Do not invent architecture.
- If a task requires architecture not present in the doc, flag it before adding the task.
- Build order must prioritize invariants, lifecycle correctness, tests, and local demo before polish.
```

---

## 23. Quality Review Checklist

Before accepting the architecture package:

### Product

```text
[ ] Product definition is clear.
[ ] Primary user is clear.
[ ] Stakeholders are identified.
[ ] Core workflows are clear.
[ ] Domain model is clear.
[ ] MVP success criteria are clear.
```

### Requirements

```text
[ ] Explicit requirements are captured.
[ ] Inferred requirements are marked.
[ ] Inferences are MVP-scoped.
[ ] Constraints are captured.
[ ] Evaluation criteria are captured.
[ ] Non-goals are clear.
```

### Decisions

```text
[ ] Major decisions are documented.
[ ] Alternatives are compared.
[ ] Tradeoffs are explicit.
[ ] Fallbacks exist.
[ ] Open decisions are tracked.
[ ] Research-dependent decisions cite research.
```

### Architecture

```text
[ ] System overview is clear.
[ ] Boundaries are clear.
[ ] Source-of-truth ownership is clear.
[ ] Data flows are clear.
[ ] Lifecycle/state rules are clear.
[ ] Integration paths are clear.
[ ] Automation/background jobs are clear.
[ ] Deployment/demo path is clear.
```

### Build Readiness

```text
[ ] Repo scaffold exists.
[ ] Interfaces/APIs/contracts are specified.
[ ] Required environment variables are listed.
[ ] Test strategy is specific.
[ ] Preflight gates are listed.
[ ] Runbooks exist where needed.
[ ] Implementation order is suggested.
[ ] Architecture has stable anchors.
[ ] Claude Code handoff is explicit.
```

### Risks

```text
[ ] Trust boundaries are identified.
[ ] Security risks are listed.
[ ] Data risks are listed.
[ ] External dependency risks are listed.
[ ] Demo risks are listed.
[ ] Scope risks are listed.
[ ] Deferred work is explicit.
```

---

## 24. Common Failure Modes and Fixes

| Failure Mode | Symptom | Fix |
|---|---|---|
| One-shot architecture | Agent drafts too early | Force phases and interview loops |
| Thin PRD confusion | Agent invents missing mechanics | Run product mechanics interview |
| Generic architecture | Could apply to any product | Add domain model and workflows |
| Missing stakeholders | Architecture misses CTO/CISO/reviewer concerns | Add stakeholder phase |
| Missing lifecycle | Bugs in edge states | Add state machines and flow tables |
| Hidden assumptions | Surprises during build | Add assumptions/open questions |
| Unvalidated dependency | Integration fails late | Add research/preflight phase |
| Decisions not defensible | Reviewer asks "why?" | Add ADR-style decision log |
| Overbuilt MVP | Timebox explodes | Add constraints/non-goals/deferred work |
| Architecture not buildable | Claude Code invents details | Add build-ready specs and handoff |
| Task plan invents architecture | MVP_TASKS diverges | Require anchors and Claude Code gap audit |

---

## 25. Reusable Micro-Prompts

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

### Interview the User

```text
The PRD is too light to proceed.

Interview me in a focused batch of 8–12 questions.
Prioritize questions that affect architecture decisions.
After I answer, synthesize what changed and identify remaining gaps.
Do not ask low-value questions.
```

### MVP-Scoped Inference

```text
Infer missing requirements necessary for a credible MVP.

Classify each as:
- MVP-critical
- MVP simplification
- deferred
- research required

Do not expand beyond the timebox.
```

### Decision Matrix

```text
For this decision, produce a decision matrix.

Columns:
- option
- pros
- cons
- build risk
- demo risk
- security/data risk
- PRD alignment
- recommendation
- fallback
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
- MVP simplifications
- deferred work
```

### Architecture Gap Audit

```text
Audit this architecture draft for gaps.

Find:
- missing workflows
- missing domain entities
- missing state transitions
- missing integrations
- missing data ownership
- missing security boundaries
- missing testing
- missing deployment/demo path
- unclear decisions
- overbuilt scope
- untracked assumptions

Return:
- critical gaps
- important gaps
- nice-to-have improvements
- suggested edits
- questions for human decision
```

---

## 26. Final Success Condition

The process is successful when Claude Code can receive:

```text
PRD
PRESEARCH.md
RESEARCH.md
DECISIONS.md
ARCHITECTURE.md
DIAGRAM_PLAN.md
CLAUDE_CODE_HANDOFF.md
MVP_TASKS.md template
```

and then:

```text
1. Review/finalize ARCHITECTURE.md.
2. Create MVP_TASKS.md from the finalized architecture and user template.
3. Build without relying on hidden chat context.
```

The planning process exists to make that possible.