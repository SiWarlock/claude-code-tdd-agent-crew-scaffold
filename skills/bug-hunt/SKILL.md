---
name: bug-hunt
description: >-
  Systematically hunt down and fix a bug with a root-cause discipline: reproduce it with a failing test
  (strong default), localize, find the TRUE root cause, fix it through the TDD loop, verify, and optionally
  compound the fix into a durable lesson + forbidden-pattern. Two modes — in-build (deterministic) and
  incident (production / observability). A STANDALONE, on-demand skill — NOT a lifecycle stage; host-neutral,
  runs on Codex or Claude, in any session and any repo. Invoke when the user says "bug-hunt", "debug this",
  "find the root cause", "this test is failing", "reproduce and fix", or reports a bug / production incident.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# bug-hunt — root-cause debugging with a reproduce-first discipline

A **standalone, on-demand** debugging skill you can run in **any session** (yours or an implementer's), on
**Codex or Claude**, in **any repo**. It is **not** a lifecycle stage and does not depend on the rest of the
cc-crew workflow — but when it runs inside a cc-crew project it uses that project's machinery (`/tdd`,
`/wired`, `LESSONS.md`, area-`CLAUDE.md` forbidden patterns) and **adapts gracefully** when they're absent.

**The discipline (what makes this more than "poke at it"):** find the **root cause, not the symptom**;
**reproduce the bug with a failing test** before fixing (strong default); leave a **permanent regression
test**; **never** go green by deleting or weakening a test; and **optionally compound** every fix into a
durable lesson so the same class of bug doesn't recur. The full playbook is in
`references/bug-hunt-procedure.md` — read it, then run the phases below.

---

## 0. Asking the user questions (host-neutral — read first)

This skill stops to confirm the mode and load-bearing calls. Hosts expose different ways to ask, so use
whichever yours supports, in this order:
1. A blocking question tool if one exists — `AskUserQuestion` (Claude Code), `request_user_input` / `ask_user`
   (Codex / other hosts).
2. If none is callable, **fall back to plain text**: print the question + numbered options, then **stop your
   turn and wait** for the reply.

Discipline: one topic per question · give a recommendation + **why** · **never fabricate** a value, a repro,
or a root cause to keep moving (an unproven cause is a hypothesis, not an answer).

---

## 1. Frame the bug + pick a mode

- Restate the symptom; **expected vs actual**; the trigger / repro steps the user already has; classify it
  (logic · wiring · data · perf · flaky · regression · security).
- **Pick a mode** (host-neutral question):
  - **Build mode** *(default)* — a deterministic bug in code you can run locally (a failing test, a wrong result).
  - **Incident mode** — a production / observability symptom (logs, traces, a report) that may not reproduce locally.

---

## 2. Reproduce (the strong default)

- **Build mode:** write the **smallest failing test** that captures the bug (RED), using the repo's own test
  runner. This test is the permanent regression pin. Do not start fixing before you've watched it fail.
- **Incident mode / genuinely non-deterministic** (concurrency, external service, true flakiness): the
  **escape hatch** — capture the bug via the observability path instead (a log/trace assertion, an eval case,
  or a documented manual repro) and **say so explicitly**. Never fake a deterministic test around a
  non-deterministic surface (this is exactly the line the scaffolding's TDD-scope rule draws).

---

## 3. Localize

- Trace from symptom → suspect code. If a **code-intelligence MCP** (e.g. CodeGraph) is available, prefer its
  callers / callees / call-path trace / impact over `grep`+read loops; otherwise grep + targeted reads. In a
  cc-crew project, `/wired <symbol>` traces the production call path.
- **Bisect** when it helps: `git bisect` for a regression, binary-search the input/state, or add temporary
  instrumentation — then remove the instrumentation before you finish.

---

## 4. Root cause (not symptom)

State the **actual cause in one sentence + the evidence**. Confirm the smallest change that flips the repro
red→green sits **at the cause**, not as a band-aid downstream. If the bug exposes a spec/architecture
contradiction or a missing requirement, **flag it** — in a cc-crew project route it as a Step-9-style finding
/ escalation; elsewhere surface it to the user. Don't quietly patch around a design problem.

---

## 5. Fix (through the TDD loop)

- Make the **minimal** change to pass the repro test (GREEN); refactor if warranted.
- **In a cc-crew project:** hand the fix into **`/tdd`** — the repro test is the new RED → GREEN → refactor →
  full suite → reachability → atomic commit. **Outside one:** do it inline (test → fix → refactor → verify).
- **Never** weaken/skip/delete a test to go green. If incident mode forces a **mitigation** first, label it a
  mitigation and keep the root-cause fix as an open task — don't let the symptom-suppression be the "fix."

---

## 6. Verify

Run the full suite (or the smallest sound scope) **and** reachability — the fixed behavior is reachable from a
real entry point, not only from its own test. Confirm the original symptom is gone and nothing regressed.

---

## 7. Compound (opt-in)

**Offer** (don't auto-write) to bank the fix as durable knowledge:
- a **`LESSONS.md`** entry — symptom, root cause, the guard that now prevents it;
- a proposed **forbidden-pattern** — a narrow *"don't do X because &lt;this incident&gt;; do Y"* rule, test-pinned
  where possible.

In a cc-crew project these land in `LESSONS.md` + the area `CLAUDE.md` forbidden-patterns list; elsewhere,
emit a portable lesson the user can place wherever they keep them. **Ask before writing anything.**

---

## 8. Hard rules (forbidden)

- **Root cause over symptom** — never ship a band-aid as the fix.
- **Reproduce-before-fix** is the strong default; the only escape hatch is a genuinely non-deterministic
  surface, documented and covered by an eval/observability check instead.
- **Never** delete, skip, or weaken a test to go green.
- **Every fix leaves a permanent regression test** (or, in the escape-hatch case, an eval/observability check).
- **Compounding is offered, never auto-written.**
- This skill **fixes bugs** — it does not redesign the architecture or run the planning chain. If the bug is
  really a design gap, flag it and stop.

---

## 9. Output & handoff

> **bug-hunt complete** — **Bug:** &lt;symptom&gt;. **Root cause:** &lt;one line + evidence&gt;. **Repro:** &lt;the failing
> test/check added&gt;. **Fix:** &lt;what changed&gt; (`&lt;commit&gt;` if routed through `/tdd`). **Verified:** full suite +
> reachability green; symptom gone. **Compounded:** &lt;lesson + forbidden-pattern banked&gt; / declined. &lt;Any
> design finding raised.&gt;

Then stop.
