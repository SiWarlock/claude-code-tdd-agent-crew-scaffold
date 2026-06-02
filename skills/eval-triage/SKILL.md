---
name: eval-triage
description: >-
  Guided, PARTICIPATORY walkthrough for diagnosing one or more failing evals in an agentic / LLM
  application — reproduce → understand the eval's contract → compare against a passing eval → bisect the
  agent pipeline to the first divergence → categorize (eval/judge · prompt · retrieval · tool-use · state ·
  nondeterminism / model-drift · parsing) → propose a minimal fix + verification plan. It is a COACH, not an
  autopilot: at each phase it spells out, step by step, exactly what it is doing and why — so you can follow
  along and explain it in your own words — runs/suggests the smallest diagnostic, ranks hypotheses by
  likelihood × cost-to-test, and PAUSES for you to inspect and decide. Diagnostic-first — it proposes; it
  does NOT auto-fix the app or silently edit an eval. Standalone, on-demand; host-neutral (Codex or Claude),
  any repo. Invoke when the user says "eval-triage", "triage this failing eval", "debug this eval", "an LLM
  eval is failing", or is working an agentic-eval debugging task.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# eval-triage — a guided, participatory eval-failure walkthrough

A **standalone, on-demand** skill for diagnosing one or more failing evals in an **agentic / LLM** app, on
**Codex or Claude**, in **any repo**. Built for the case where the failure could come from the prompt,
retrieval, tools, state, model nondeterminism or drift, output parsing, the **judge/rubric**, **or the eval
itself** — and you need to find *which*, systematically (whether it's one failing eval among several, or many
failing at once).

**It is a coach, not an autopilot.** It drives a disciplined phase-by-phase process, and at **every phase**
it does four things, in order:
1. **States the goal** — what this phase is doing and why, in plain terms (so you understand the move and can
   talk through it yourself — not a script to recite).
2. **Does / suggests the smallest diagnostic** — preferably a command *you* run, so you stay in control.
3. **Reports findings** — what we saw, and an updated **hypothesis tree ranked by likelihood × cost-to-test**.
4. **Pauses (⏸)** — for you to inspect and decide before it advances.

**Diagnostic-first.** It produces a reasoned **root cause + a minimal-change proposal + a verification
plan** — it does **not** auto-rewrite the app, and it **never** edits an eval to go green without your
explicit, evidence-backed decision. You drive; it keeps you systematic.

Full failure taxonomy, pipeline map, grading-mechanism guide, question bank, and diagnosis patterns:
**`references/eval-triage-playbook.md`** — read it first; it's the depth behind the phases below.

---

## 0. Asking the user questions (host-neutral — read first)

This skill is participatory: it **stops and checks in** every phase. Use whatever your host supports:
1. A blocking question tool — `AskUserQuestion` (Claude Code), `request_user_input` / `ask_user` (Codex / other).
2. Else **plain text** — print the question + options, then **stop and wait**.

Discipline: one topic per check-in · give a recommendation + **why** + the options · **never fabricate** a
root cause, a repro, or a grading mechanism to keep moving — confirm it.

---

## The cadence (every phase)

**STATE** (what this phase does + why, in plain terms) → **DO / SUGGEST** (the smallest diagnostic; prefer a
command *you* run) → **FINDINGS** (what we saw + the updated ranked hypothesis tree) → **⏸ CHECK-IN** (you
react / decide; I don't advance without your go). The two **decision gates** (§7 app-vs-eval, §8 the fix)
always pause, even if you say "move faster."

Each phase below lists the **explicit steps** it walks through, then how to **read** the result. The point of
spelling them out is that *you* see and own every move — surfacing the reasoning at each step **is the skill**.

---

## 1. Orient — map the ground (don't fix yet)

**Goal:** before forming any hypothesis, learn where the evals live, how they run, **how each one grades**,
and what the agent pipeline looks like. The grading mechanism and the harness mode dictate the entire approach.

**Steps:**
1. **Locate the evals + runner.** Check the `README`, the test config (`pytest.ini` / `vitest.config` /
   `jest.config`), and `grep -ri 'eval\|pytest\|vitest\|jest' .`. Note the exact command to run them.
2. **Map the agent pipeline, stage by stage:** routing/intent → prompt construction → retrieval/context →
   tool selection → tool execution → state/scratchpad → generation → output parse → assertion. Write down
   which of these stages this particular app actually has.
3. **Determine how each eval GRADES** (especially the failing ones): exact-match · regex/substring ·
   embedding/semantic similarity · **LLM-as-judge / rubric** · tool-call assertion. Record the mechanism per
   eval — *a judge failure is not an app failure.*
4. **Determine the harness mode:** are model calls **live, mocked, or replayed/recorded** (cassettes /
   fixtures)? (Replay ⇒ deterministic + free; live ⇒ possibly flaky + costs tokens.)
5. **Check pinning + history:** is the model/version pinned? When did the failing eval last pass?
   (`git log -- <eval>` and `git blame` on the eval + the code path — often the fastest root-cause oracle.)

**Read it as:** the per-eval grading mechanism + the harness mode set the strategy for everything that
follows. Don't proceed until they're known.

⏸ **Check-in:** confirm the pipeline map, the per-eval grading mechanism, and the harness mode before
touching anything.

## 2. Reproduce

**Goal:** confirm the failure is real and learn whether it's deterministic, before diagnosing anything.

**Steps:**
1. **Run the full suite** and record exactly which evals fail and which pass (the passing ones become your
   controls).
2. **Run each failing eval in isolation** to confirm it fails on its own.
3. **Establish determinism:** if calls are **replayed/recorded**, the result is deterministic — rerunning
   won't vary, so the bug is in code / prompt / fixture / cassette / eval. If calls are **live**, rerun a few
   times (token-aware) to tell a *flaky* failure from a *consistent* one.

**Read it as:** a reproduced, deterministic failure points at code/prompt/fixture/eval; a failure that flaps
under live reruns points at nondeterminism/drift (§6 class F).

⏸ **Check-in:** reproduced? deterministic or flaky?

## 3. The eval's contract

**Goal:** state precisely what the failing eval asserts — and flag (without yet deciding) whether that
assertion is even correct.

**Steps:**
1. **Read the failing eval end to end:** its input, the expected value, the **assertion**, and the
   fixture/data it relies on.
2. **State the contract in one sentence:** "given `<input>`, it asserts `<expected>` via `<mechanism>`."
3. **Note any smell** in the assertion itself (brittle exact-match, a hard-coded fixture value, a tool it
   requires) — but **hold judgment** on whether the eval is right; that's decided at §7.

⏸ **Check-in:** agree on the one-sentence contract.

## 4. Compare against a passing eval (your controls)

**Goal:** use the passing evals as controls. They share most of the pipeline with the failing one(s), so the
*difference* between them is the lead.

**Steps:**
1. **Pick the nearest passing eval** to the failing one (closest input/intent/pipeline path).
2. **Diff failing vs passing** across: input/intent · retrieved context · tool calls · output shape ·
   assertion. Name the single delta that most plausibly causes the failure.
3. **If several evals fail at once, look for a SHARED upstream cause first:** do multiple failures diverge at
   the *same* pipeline stage (the same planner step, retrieval, a tool, the state, the clock/fixtures)? One
   upstream bug can produce several red evals — fixing it may clear more than one, so don't assume "N reds =
   N bugs."

**Read it as:** a clean delta against a close control localizes the failure cheaply; a shared divergence
point across failures means hunt the single upstream cause before diagnosing each red separately.

⏸ **Check-in:** the leading delta (and any suspected shared cause).

## 5. Bisect the pipeline (midpoint-first)

**Goal:** find the **first** point where reality diverges from expectation — without linear-scanning every
stage.

**Steps:**
1. **Capture what the model actually saw** for the failing case: the exact prompt/messages **and** the
   retrieved context / tool results that reached it (use the agent's trace, or add temporary logging).
2. **Ask the midpoint question — did the model receive the right evidence/context?**
   - **Yes** → the divergence is **downstream**: generation, output parsing, or the judge.
   - **No** → the divergence is **upstream**: routing, retrieval, or tools.
3. **Instrument only the suspected boundary** — log *either* the retrieval query + chunks + scores, *or* the
   tool calls + args + results, *or* the raw model output before parsing. Not everywhere.

**Read it as:** the midpoint answer halves the search space in one step and reads as deliberate, senior work.

⏸ **Check-in:** where did it first diverge?

## 6. Categorize the divergence

**Goal:** name the failure class so the fix targets the right layer.

**Steps:**
1. **Pick the class:** eval/judge · prompt · retrieval · tool-use · state/memory · nondeterminism/model-drift
   · output-parsing.
2. **Cross-check the tells** against the playbook taxonomy (A–G) — confirm the evidence matches the class's
   signature, not just a guess.

⏸ **Check-in:** agree on the class + the leading hypothesis.

## 7. ⏸⏸ Decision gate — app bug, or eval bug?

**Goal:** decide whether the **application** is wrong or the **eval** is wrong. This is the gate that
separates senior work from "make it green."

**Steps:**
1. **Weigh the evidence** for each side. If the actual answer is correct and the **eval** is the problem
   (stale fixture, brittle exact-match where semantic is meant, asserts a tool that isn't actually required,
   a miscalibrated/over-strict judge), the fix belongs on the eval side — but **do NOT silently change it.**
2. **Present the contradiction and ask:** e.g. *"the fixture says X but the eval expects Y — should the app
   match the fixture, or is the eval itself the bug?"*
3. **Treat editing an eval as a flagged, signed-off decision.** In an interview, quietly editing an eval to
   go green is the one move that can sink you.

*(This gate always pauses for your explicit decision before anything is changed.)*

## 8. ⏸ Minimal-fix proposal

**Goal:** propose the smallest change at the root cause — not a redesign.

**Steps:**
1. **Describe the change** and exactly where it lands (which stage/file).
2. **Justify it:** why it's minimal, and why it won't regress the other evals.
3. **Prefer a deterministic contract** (structured output, an explicit "call tool T when …" rule, a semantic
   assertion) over a vague prompt tweak.
4. **Apply only on your go** — and **never** by weakening, skipping, or deleting a test.

## 9. Verify plan

**Goal:** prove the fix works and introduced no regressions.

**Steps:**
1. **Rerun the failing eval(s)** — confirm they now pass.
2. **Rerun the full suite** — confirm every previously-passing eval still passes.
3. **State residual risk;** if calls are live + nondeterministic, run it a few times to confirm stability.

---

## Hard rules (forbidden)

- **Diagnostic-first** — propose the fix; apply only on the user's go. **Never auto-rewrite the app.**
- **Never edit an eval to go green** without an evidence-backed, signed-off decision (§7).
- **Reproduce + understand the contract before hypothesizing** — an unproven cause is a hypothesis, not an answer.
- **Don't skip the step-by-step or the check-ins** — making each move explicit, and pausing for you at each
  phase, *is the point* (this skill exists to keep you participating, not to do it silently for you).
- **Cheapest + most-likely hypothesis first;** be token/time-aware on live reruns.
- **When several evals fail, look for one shared root cause before assuming many** — re-run the whole suite
  after each fix to see how many reds it clears.
- This skill **diagnoses + proposes** for *agentic/LLM eval* failures; it doesn't redesign the system. A
  general (non-eval) code bug → use **`bug-hunt`**.

---

## Output & handoff

> **eval-triage** — **Failing eval(s):** `<name(s)>` (`<what they assert>`). **Grading:** `<exact/regex/embedding/judge/tool>`.
> **Reproduced:** `<deterministic/flaky · harness mode>`. **First divergence:** `<stage>` → **class:** `<category>`.
> **Root cause:** `<one line + evidence>` (`<shared across N evals?>`). **App vs eval:** `<decision>`. **Minimal fix (proposed):** `<change>`.
> **Verify:** rerun the failing eval(s) + the full suite; `<result / plan>`. **Open questions:** `<for the interviewer>`.

Then stop.
