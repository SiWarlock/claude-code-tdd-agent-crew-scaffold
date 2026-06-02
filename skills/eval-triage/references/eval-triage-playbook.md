# eval-triage — playbook

The depth behind `SKILL.md`: how to read an agentic/LLM eval suite, the failure taxonomy with tells +
debug steps, the question bank, diagnosis patterns, and narration cues. Treat a failing eval like a
**production bug**, not "the LLM is bad."

---

## The one-sentence process

> Reproduce the failure → understand what the eval asserts (and whether that's correct) → compare it to a
> passing eval → trace the agent pipeline to the **first point reality diverges** → categorize the failure →
> make the **smallest** targeted change → rerun the failing eval **and** the full suite to confirm no
> regressions. Use Claude to accelerate orientation and hypotheses; verify every claim by running things.

---

## Orient: the three questions that change everything

Most people skip these and waste time. Answer them *first*:

1. **How does each eval grade?**
   - **exact-match / regex / substring** — brittle; a correct answer can fail on wording. 
   - **embedding / semantic similarity** — threshold-sensitive.
   - **LLM-as-judge / rubric** — the *judge* can be the failure: miscalibrated, over-strict rubric, judge
     nondeterminism, or a bad judge prompt. Inspect the judge separately from the app.
   - **tool-call assertion** — checks a tool was called / args — failure may be routing, not the answer.
2. **Are model calls live, mocked, or replayed/recorded?** Replay (cassettes/fixtures) ⇒ deterministic +
   free ⇒ "run it 10× for flakiness" is meaningless; the bug is in code/prompt/fixture. Live ⇒ may be flaky,
   costs tokens ⇒ rerun a *few* times, mind cost.
3. **Is the model pinned, and when did this eval last pass?** Model/provider drift is a top real cause.
   `git log -- <eval>` and `git blame` the eval + code path is often the fastest root cause.

---

## The agent pipeline (where divergence hides)

```
user input → routing/intent → prompt construction → retrieval/context → tool selection → tool execution
→ state/scratchpad update → final generation → output parsing/schema → eval assertion (maybe an LLM judge)
```

**Bisect, don't linear-scan.** Check the **midpoint** first — *did the model receive the right evidence/
context?* Yes ⇒ look **downstream** (generation, parsing, judge). No ⇒ look **upstream** (routing,
retrieval, tools). That halves the search and reads as deliberate.

---

## Failure taxonomy — tells + debug steps

**A. Eval / judge bug.** Tell: the actual answer looks correct. Causes: stale fixture, exact-match where
semantic is meant, asserts a tool that isn't required, miscalibrated/over-strict judge, judge nondeterminism.
Debug: read the assertion + fixture; run the judge on a known-good answer; check fixture vs app data.
**→ never silently "fix" the eval — gather evidence and ask whether the eval or the app is the source of truth.**

**B. Prompt.** Tell: model has the info but does the wrong thing. Causes: no rule for *when* to use a tool,
conflicting instructions, missing output contract, missing business rule, works on simple case not the edge.
Debug: read the exact final prompt; diff vs the passing case. Fix: clarify the rule, add a decision rule or a
single few-shot, strengthen the output contract — minimally.

**C. Retrieval (RAG).** Tell: answer wrong because evidence never reached context. Causes: query dropped key
terms, wrong chunk, over-restrictive metadata filter, `top_k` too low, stale index, reranker dropped it.
Debug: log the retrieval query + retrieved chunks + scores; manually search the corpus for the expected
evidence; temporarily bump `top_k` / disable reranker. *"If the evidence never made it into context, this is
not a generation problem."*

**D. Tool-use.** Tell: agent answers from prior knowledge; no/var wrong tool call in the trace. Causes: vague
tool description/schema, no rule requiring the tool, tool result hard to interpret, silent tool error.
Debug: log tool calls + args + outputs; run the tool manually with the expected args; confirm the result
re-enters the prompt.

**E. State / memory.** Tell: right tool, right data, wrong final answer. Causes: history not passed, a step
result overwritten, missing scratchpad field, loop terminates early, retry loses context. Debug: print state
before/after each node; check graph transitions + termination conditions.

**F. Nondeterminism / model drift.** Tell: passes sometimes, or broke after a model/provider change. Causes:
temperature differs eval vs prod, no seed, unpinned model, provider update. Debug: check temperature/seed,
pin the model, prefer structured output + semantic (not exact) assertions; check git history for when it broke.

**G. Output / parsing / schema.** Tell: answer is semantically correct, eval still fails. Causes: markdown
instead of JSON, missing field, extra prose before JSON, wrong enum, citation format. Debug: print raw model
output before parsing. Fix: structured-output mode, simpler schema, retry-on-parse-failure, or a less brittle
assertion.

---

## Question bank (ask *after* orienting, targeted)

- Is the failing eval deterministic, or is some flakiness expected?
- Are model calls live, mocked, or replayed? Are tools/retrieval/indexes local, mocked, or external?
- Are evals black-box final-answer checks, or may I inspect intermediate traces?
- Is it OK to add temporary logging/instrumentation?
- Should I avoid changing eval expectations unless I find evidence they're wrong?
- Smallest targeted fix, or is refactoring acceptable if the root cause is structural?
- Is the goal the single failing eval, or correct behavior across the whole suite (no regressions)?

---

## Diagnosis patterns (corrected)

1. **Retrieval miss** — answer wrong → retrieved chunks lack the source → query dropped key terms / filter
   too tight → fix query/filter/`top_k`/reranker → evidence now in context, eval passes.
2. **Tool not called** — answers from prior knowledge → no tool call in trace → prompt never *requires* the
   tool → add "for account-specific questions, call `get_account_data` first" → tool fires, result used.
3. **Schema mismatch** — answer correct, eval fails → missing field / wrong shape → underspecified prompt or
   brittle parser → structured output / retry-on-validation → validates, answer unchanged.
4. **Eval is wrong** — actual answer correct, expected contradicts the fixture (fixture 30 days, eval expects
   14) → **surface the contradiction and ask** which is the source of truth → only then update the eval
   *with explanation*, or fix the app to match the fixture. Never edit the eval to go green silently.

---

## Cues

- *"I'm reproducing first, and checking whether it's deterministic — and whether responses are live or replayed."*
- *"The other passing evals are controls; I'm diffing the failing ones against its nearest passing sibling."*
- *"I'm checking the midpoint: did the model even have the evidence? If not, this is retrieval, not generation."*
- *"The tool returned the right data but the answer ignored it — so I'm looking at state propagation / final synthesis."*
- *"The answer is correct but the eval fails on phrasing — I'm checking whether the assertion is too brittle, and I'll ask before changing it."*
- *"I'll make the smallest change at the root cause, then rerun the failing evals and the full suite to check for regressions."*

## What reads as senior

Reproduce before fixing · inspect intermediate artifacts not just final answers · compare passing vs failing
· ask "did the model have the evidence?" · distinguish app bug from eval bug (and never quietly edit the
eval) · minimal change · rerun the whole suite · narrate tradeoffs · use Claude to accelerate, not replace.
