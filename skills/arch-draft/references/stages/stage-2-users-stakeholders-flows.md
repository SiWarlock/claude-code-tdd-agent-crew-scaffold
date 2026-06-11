<!--
  Part of the arch-draft playbook — stage file, read JUST-IN-TIME as the interview enters its phases
  (the spine's phase index points here). Sources are concatenated into the full playbook artifact by
  scripts/build-playbook.sh; edit HERE, never in the generated concat.
-->

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
5. What is the demo path? (only if a demo is in scope)
6. What is the recovery path?
7. What state is created?
8. What state is updated?
9. What state is deleted or finalized?
10. What should happen if an external dependency fails?
11. What should happen if the user abandons halfway through?
12. What does the system need to show the user at each step?
```

### Stop Condition

Every in-scope requirement should map to a flow.

If a requirement has no flow, either:
- add a flow
- mark the requirement as deferred
- mark it as unclear

---

