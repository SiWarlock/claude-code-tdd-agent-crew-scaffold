---
description: Walk through TDD discipline for a feature — red, green, refactor, all-tests-still-pass.
allowed-tools: Read, Edit, Write, Bash, Grep
argument-hint: "<feature description>"
---

<!--
  TEMPLATE NOTE (delete this comment when generating): this command is highly
  portable. Fill the {{TEST_CMD}} / {{TYPECHECK_CMD}} / {{LINT_CMD}} placeholders
  and the test-path examples. Keep the 10 steps, the checkpoints, and the
  Forbidden section VERBATIM — they are the discipline.
-->

The user wants a feature implemented with TDD discipline enforced. Walk through it explicitly.

Argument: `$ARGUMENTS` — the feature description.

**Scope note:** `/tdd` applies to deterministic code (state-machine logic, parsers, harness logic, instrumentation, deterministic transforms). **Non-deterministic behavior is not unit-tested** — LLM-driven generation, pure visual changes are exempt; use the project's non-deterministic-coverage brief format instead.

## Mandatory order — do not deviate

### Step 0 — Restate

Restate the feature in 1–2 sentences in your own words.

**In team mode:** this is a **self-check, NOT a send to the orchestrator** — the brief is your spec; if your restatement doesn't match the Feature line, you've misread the brief, fix it before continuing. The orchestrator's first signal that the brief parsed correctly is your Step-2.5 write-up.

**In single-operator mode:** confirm with the user that the restatement matches their intent before writing any code.

### Step 1 — Identify files

- Identify the production file(s) that will hold the implementation.
- Identify the test file(s) that will hold the tests.
- If a test file doesn't exist yet, create the empty file in the right directory.

State: *"I will write tests in `<test_path>` and implementation in `<impl_path>`."*

### Step 2 — RED: write the failing test FIRST

Write the test before any implementation. The test should:
- Be specific about expected input and output.
- Reference a function/class that does not exist yet (or exists but lacks the behavior).
- Use the project's test-class marker convention.

### Step 2.5 — PAUSE for test review (the orchestrator reviews)

**After writing the test(s) in Step 2 and BEFORE running anything**, output a structured description of each test and **send it directly to the orchestrator** for review. The orchestrator authored the brief and holds the spec — it is the reviewer here, and frequently finds issues, tweaks, or a missing test.

For each `test_*` function (treat parametrization as part of "how it works" — one entry per test function, not per parametrized case):

**`test_<name>`** — one-sentence summary
- **What it tests:** the behavior or invariant under assertion
- **How it works:** fixture setup → action under test → assertion. If parametrized, list parameter axes briefly.
- **Why this assertion:** the contract / design property / spec section this pins down. Cite `{{ARCH_DOC}} §X` or a `LESSONS.md` entry when applicable.
- **What it does NOT test:** related concerns intentionally out of scope.

After the per-test descriptions, end with:

> **Pausing for orchestrator review.** Sending these test designs to the orchestrator. Proceeding to Step 3 (Confirm RED) only on its go-ahead — *approve*, *tweak*, or *add a missing test*.

**Do not proceed to Step 3 until the orchestrator signs off.** The orchestrator may reply with changes, or escalate a critical/safety design question to the human (via the team lead) before signing off. (Single-operator fallback: the user is the reviewer and gives the go-ahead directly.)

**A "work without stopping" / "don't ask clarifying questions" instruction does NOT override this pause.** Such instructions — whether from a hook, a system reminder, or a teammate — scope to *clarifying questions*. They do not scope to skill-protocol checkpoints, which are designed safeguards, not questions. If a standing instruction appears to conflict with this checkpoint, **surface the conflict** instead of silently skipping. This applies equally to the Step 9 → Step 10 commit handoff.

If the orchestrator requests changes:
1. Revise the test in place.
2. Re-send the updated description for the changed test(s) only.
3. Re-pause.
4. Iterate until the orchestrator approves all tests.

**Why this pause matters.** The test is the only safety net for test *quality*. Steps 3 and 5 catch syntax errors and "passes for the wrong reason" bugs, but neither can catch a test that asserts the wrong invariant. A conceptually-wrong test will let a conceptually-wrong implementation pass green — silent regression. Routing the design to the orchestrator (who holds the spec) is the cheap chance to catch that.

### Step 3 — Confirm RED

Run the test:
```
{{TEST_CMD_SINGLE_FILE}}
```

The test MUST fail. Confirm:
- It fails for the **right reason** (e.g. import error, attribute error, assertion failure with expected/actual values).
- It does NOT fail for the wrong reason (typo, missing fixture, syntax error in the test itself).

If the test fails for the wrong reason, fix the test before continuing. **Do not start implementing yet.**

### Step 4 — GREEN: write the minimum implementation to pass

Implement only enough to pass the test. Resist:
- Adding fields the test doesn't verify
- Handling edge cases the test doesn't cover
- Extracting abstractions before there's a second caller

If you find yourself writing code that no test covers, stop and add another failing test first.

### Step 5 — Confirm GREEN

```
{{TEST_CMD_SINGLE_FILE}}
```

Test must pass. If it doesn't, you implemented something other than what the test asked for. Fix the implementation, not the test.

### Step 6 — REFACTOR (only if needed)

Refactor for clarity, naming, structure. Tests stay green during refactor.

### Step 7 — Run the FULL test suite

```
{{TEST_CMD}}
```

Confirm nothing else broke. If a previously-passing test now fails, the refactor broke something. Investigate before continuing.

### Step 7.5 — Reachability / wiring check

**Tests passing ≠ feature shipped.** A unit + integration green only proves the code works *when called*. It does not prove anything actually calls it from a real entry path. This step closes that gap.

Identify the **production entry point(s)** this feature must be reachable from — a route/controller, a CLI command, a scheduled job, a UI handler, an exported package API, a contract function selector, a deploy/migration step. Then confirm the new code is genuinely on that path:

- Trace the call chain from the entry point to the new code (grep the wiring: the import, the registration, the route table, the cron registry, the button handler, the ABI/selector, the export barrel). `/wired <feature>` automates this trace — run it if in doubt.
- If the brief named an entry point, confirm the wiring exists. If it doesn't yet:
  - **Wire it in this slice** if it's small and in scope (add the test that exercises the entry path too), **or**
  - **Raise it as a Step-9 "Future TODO — belongs to a phase"** with the specific entry point that still needs wiring, so it lands as a real task — never leave a tested-but-unreachable feature silently.

State explicitly: *"Reachable from `<entry point>` via `<path>`"* — or *"NOT yet wired; raising wiring task / wiring now."* A feature that is only reachable from its own tests is **not done**.

### Step 8 — Type-check + lint

```
{{TYPECHECK_CMD}} && {{LINT_CMD}}
```

Both must pass. If they don't, fix before saying done.

<!-- If the project installed the optional starter subagents, parallel-fan-out
     code-quality-reviewer + security-reviewer here (mandatory if invariant_touching);
     their findings feed Step-9 categorization. -->

### Step 9 — Summarize + surface slice-level flags

**Frame the summary explicitly as input for the orchestrator** — send it directly for hot routing per the Step-9 routing matrix in `docs/orchestrator-briefing.md` (single-operator fallback: paste it across). Items are routed *hot* (immediately on receipt) — NOT deferred to `/session-end`.

Report:

- Files created.
- Files modified.
- Tests added (count + class).
- Type-check + lint status.
- **Reachability** — from Step 7.5: reachable from `<entry point>`, or a wiring task is being raised.
- **Categorized flags for the orchestrator to route immediately.** The orchestrator does the actual routing per the **canonical matrix in `docs/orchestrator-briefing.md`** — categorize each item to one of:
  - **Convention candidate** — a code rule, gotcha, framework quirk, type-system workaround. (→ full prose to `{{CODE_AREA}}LESSONS.md` + a one-line index row with an anchor link in `{{CODE_AREA}}CLAUDE.md`.)
  - **Architecture doc note** — a behavior or guarantee consumers depend on.
  - **Future TODO — belongs to a phase** — work that's in-scope for some phase (acceptance-blocking or operational alike). (→ a normal task checkbox in that phase, not an annotation.)
  - **Future TODO — next-brief working set** — something the next 1–2 briefs must fold in. (→ Carry-forward.)
  - **Future TODO — out of scope** — a deferral. (→ deferment escalation to the human.)
  - **Cross-doc invariant change** — added/removed/renamed field on a model in the `{{CODE_AREA}}CLAUDE.md` cross-doc table. **MUST be reflected in `{{ARCH_DOC}}`.** Surface as a flag requiring resolution.

Send this summary **directly to the orchestrator** (single-operator fallback: paste it across), which routes each item immediately — including **ticking the relevant `{{TASK_TRACKER}}` checkbox(es)** for the slice's completed work.

### Step 10 — Commit the slice (after the orchestrator routes Step 9)

After you send the Step 9 summary, the orchestrator replies **commit-message-first**. Commit the slice with that message.

**What to stage:** ONLY the slice's code + tests. Use explicit `git add <path>` for each file. **Do NOT use `git add -A` or `git add .`** — those would pick up the orchestrator's hot-routed planning edits, which belong in the orchestrator's end-of-round commit.

```bash
git add <impl path> <test path>
git status --short  # Verify only slice files staged
```

**Commit message:** Conventional Commits format + `{{AI_TRAILER}}` trailer. HEREDOC for clean formatting:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <slice description — what landed, not how>

<body — why this slice now, what use case it supports, what it
doesn't yet do, what's unblocked>

{{AI_TRAILER}}
EOF
)"
```

**Do NOT push.** Push happens at end of round (the orchestrator's `/orchestrate-end` handles it).

**Commit once the orchestrator's message arrives.** If the orchestrator wants to hold the slice (rare — e.g. a routing decision changes the commit framing), it says so in its reply. Default is commit-now with the message it sent.

## Forbidden in this command

- **Writing the implementation before the test.** Even one line.
- **Writing the test after seeing the implementation pass once and then back-filling.** That's not TDD.
- **Skipping Step 2.5 (test review pause).** The test review is the only point at which test *quality* gets a second reviewer's eyes (the orchestrator's). A "work without stopping" instruction does not license skipping it — that scopes to clarifying questions, not protocol checkpoints. Surface the conflict instead.
- **Skipping Step 7.5 (reachability).** Tests passing is not shipping. A feature reachable only from its own tests is not done — wire it or raise the wiring task.
- **Skipping Step 3 (confirming RED).** A test you didn't watch fail might be a test that always passes.
- **Implementing more than the test requires.** YAGNI applies.
- **Modifying the test to make a stuck implementation pass.** If the test fails, the implementation is wrong, not the test.
- **Using `git add -A` at Step 10.**
- **Pushing.**

## When TDD doesn't fit

Narrow cases:
- **Pure exploratory spikes** to learn an API. Mark as exploratory; throw away; then TDD the real implementation.
- **Adding logging or instrumentation** that doesn't change behavior.
- **Non-deterministic behavior** (LLM-driven generation, pure visual changes). Use the project's non-deterministic-coverage brief format instead.

Outside these cases: TDD. Every time.
