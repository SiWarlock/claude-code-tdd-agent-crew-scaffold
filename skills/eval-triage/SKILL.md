---
name: eval-triage
description: >-
  Guided, PARTICIPATORY walkthrough for diagnosing a failing eval in an agentic / LLM application —
  reproduce → understand the eval's contract → compare against a passing eval → bisect the agent pipeline to
  the first divergence → categorize (eval/judge · prompt · retrieval · tool-use · state · nondeterminism /
  model-drift · parsing) → propose a minimal fix + verification plan. It is a COACH, not an autopilot: at
  each phase it says what it's doing and why (a line you can repeat aloud), runs/suggests the smallest
  diagnostic, ranks hypotheses by likelihood × cost-to-test, and PAUSES for you to inspect, narrate, and
  decide. Diagnostic-first — it proposes; it does NOT auto-fix the app or silently edit an eval. Standalone,
  on-demand; host-neutral (Codex or Claude), any repo. Invoke when the user says "eval-triage", "triage this
  failing eval", "debug this eval", "an LLM eval is failing", or is working an agentic-eval debugging task.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# eval-triage — a guided, participatory eval-failure walkthrough

A **standalone, on-demand** skill for diagnosing a failing eval in an **agentic / LLM** app, on **Codex or
Claude**, in **any repo**. Built for the case where the failure could come from the prompt, retrieval, tools,
state, model nondeterminism or drift, output parsing, the **judge/rubric**, **or the eval itself** — and you
need to find *which*, systematically (e.g. a suite of 7 with one failing).

**It is a coach, not an autopilot.** It drives a disciplined phase-by-phase process, but at **every phase**
it: (1) **says what it's doing and why** — in words you can repeat out loud to an interviewer; (2) runs or
suggests the **smallest diagnostic** (prefer a command *you* run, so you stay in control and can narrate);
(3) updates a **hypothesis tree ranked by likelihood × cost-to-test**; (4) **PAUSES** for you to inspect,
narrate, and decide before advancing.

**Diagnostic-first.** It produces a reasoned **root cause + a minimal-change proposal + a verification
plan** — it does **not** auto-rewrite the app, and it **never** edits an eval to go green without your
explicit, evidence-backed decision. You drive; it keeps you systematic and hands you the words.

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

**ANNOUNCE** (what + why — your narration line) → **DO / SUGGEST** (the smallest diagnostic; prefer a command
*you* run) → **FINDINGS** (what we saw + the updated ranked hypothesis tree) → **⏸ CHECK-IN** (you react /
decide / narrate; I don't advance without your go). The two **decision gates** (§7 app-vs-eval, §8 the fix)
always pause, even if you say "move faster."

---

## 1. Orient — map the ground (don't fix yet)

> *"First I'm orienting — where the evals live, how they run, **how each one grades**, and what the agent pipeline looks like."*

- Locate evals + runner (`README`, `grep -ri 'eval\|pytest\|vitest\|jest' .`, config) and the pipeline
  (routing → prompt → retrieval → tools → state → generation → parse → assert).
- **How does each eval GRADE?** exact-match · regex/substring · embedding similarity · **LLM-as-judge /
  rubric** · tool-call assertion. *(This dictates the whole approach — a judge failure ≠ an app failure.)*
- **Are model calls live, mocked, or replayed/recorded?** (replay ⇒ deterministic + free; live ⇒ maybe flaky + costs tokens.)
- **Is the model/version pinned? When did this eval last pass?** (`git log` / `git blame` on the eval + the code path — often the fastest root-cause oracle.)

⏸ **Check-in:** confirm the map, the grading mechanism, and the harness mode before touching anything.

## 2. Reproduce

> *"Before diagnosing, I reproduce the failure and check whether it's deterministic."*

- Run the **full suite** (see the 1 failing among the 7), then run **only** the failing eval.
- Determinism: **replayed** ⇒ deterministic (rerunning won't vary; the bug is in code/prompt/fixture). **live** ⇒ run it a few times (token-aware) to see if it's flaky vs consistently failing.

⏸ **Check-in:** reproduced? deterministic or flaky?

## 3. The eval's contract

> *"What is this eval actually asserting — and is that assertion even correct?"*

- Read the failing eval: input, expected, the **assertion**, the fixture/data it relies on. State the contract in one sentence. **Hold judgment** on whether the eval is right — that's decided at §7.

⏸ **Check-in.**

## 4. Compare against a passing eval (your controls)

> *"The other 6 evals are controls. I'll diff the failing one against its nearest **passing** sibling — they share most of the pipeline, so the difference is the lead."*

- Pick the closest passing eval; diff: input/intent · retrieved context · tool calls · output shape · assertion. Name the delta that plausibly causes the failure.

⏸ **Check-in.**

## 5. Bisect the pipeline (midpoint-first)

> *"Now I find the FIRST point reality diverges from expectation — and I check the midpoint first: did the model actually receive the right evidence/context?"*

- Inspect the midpoint: the exact prompt/messages + retrieved context the model saw for the failing case.
  - **Got the right evidence?** → divergence is **downstream**: generation, parsing, or the judge.
  - **Didn't?** → **upstream**: routing, retrieval, or tools.
- Add **targeted** instrumentation only at the suspected boundary (log the retrieval query + chunks, or the tool calls + args + results, or the raw model output before parsing) — **not everywhere**.

⏸ **Check-in:** where did it first diverge?

## 6. Categorize the divergence

Name the failure class (tells + debug steps for each are in the playbook): **eval/judge · prompt ·
retrieval · tool-use · state/memory · nondeterminism / model-drift · output-parsing.**

⏸ **Check-in:** agree on the class + the leading hypothesis.

## 7. ⏸⏸ Decision gate — app bug, or eval bug?

> *"Is the application wrong, or is the eval wrong?"*

If the evidence says the **eval** is wrong (stale fixture, brittle exact-match where semantic is meant,
asserts a tool that isn't actually required, a miscalibrated/over-strict judge), **do NOT silently change
it.** Present the evidence and **ask**: *"the fixture says X but the eval expects Y — should the app match
the fixture, or is the eval itself the bug?"* Editing an eval to go green is a flagged, signed-off decision —
in an interview, the one move that can sink you if done quietly.

## 8. ⏸ Minimal-fix proposal

> *"The smallest targeted change at the root cause."*

Propose (don't auto-apply): the change · why it's minimal · why it won't regress the other 6 evals. Prefer
**deterministic contracts** (structured output, an explicit "call tool T when …" rule, a semantic assertion)
over prompt vibes. **Only on your go** do I apply the minimal change — and **never** by weakening, skipping,
or deleting a test.

## 9. Verify plan

Rerun the **failing eval** + the **full suite (all 7)** → the failing one passes, the other 6 still pass.
State residual risk (and, if live + nondeterministic, run it a few times).

---

## Hard rules (forbidden)

- **Diagnostic-first** — propose the fix; apply only on the user's go. **Never auto-rewrite the app.**
- **Never edit an eval to go green** without an evidence-backed, signed-off decision (§7).
- **Reproduce + understand the contract before hypothesizing** — an unproven cause is a hypothesis, not an answer.
- **Don't skip the narration / check-ins** — surfacing the reasoning at each phase *is the point* (this skill
  exists to make you participate, not to do it for you).
- **Cheapest + most-likely hypothesis first;** be token/time-aware on live reruns.
- This skill **diagnoses + proposes** for *agentic/LLM eval* failures; it doesn't redesign the system. A
  general (non-eval) code bug → use **`bug-hunt`**.

---

## Output & handoff

> **eval-triage** — **Failing eval:** `<name>` (`<what it asserts>`). **Grading:** `<exact/regex/embedding/judge/tool>`.
> **Reproduced:** `<deterministic/flaky · harness mode>`. **First divergence:** `<stage>` → **class:** `<category>`.
> **Root cause:** `<one line + evidence>`. **App vs eval:** `<decision>`. **Minimal fix (proposed):** `<change>`.
> **Verify:** rerun the failing eval + all 7; `<result / plan>`. **Open questions:** `<for the interviewer>`.

Then stop.
