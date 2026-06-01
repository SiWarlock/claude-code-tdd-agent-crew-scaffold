# bug-hunt — procedure detail

The authoritative playbook behind `SKILL.md`. Two modes, the reproduce-first discipline, the localization
cookbook, and the compounding templates. Cc-crew-aware but degrades gracefully in any repo.

---

## The shape in one breath

```
Frame → pick mode → REPRODUCE (red test / captured signal) → Localize → ROOT CAUSE → Fix (TDD) → Verify → [opt-in] Compound
```

The non-negotiables: **root cause, not symptom** · **reproduce before you fix** · **leave a regression test** ·
**never go green by weakening a test** · **never fabricate a cause or a repro**.

---

## Mode A — Build (deterministic)

A bug you can run locally: a failing test, a wrong return, a crash with a stack trace.

1. **Reproduce.** Write the *smallest* failing test that pins the wrong behavior, using the repo's runner
   (`pytest`, `vitest`, `go test`, …). Watch it go RED. This is the permanent regression pin — it stays after
   the fix. If a test already fails, minimize it to the essence first.
2. **Localize.** Walk from the assertion to the cause:
   - prefer a **code-intelligence MCP** (CodeGraph) for callers/callees/trace/impact; else `grep` + reads;
   - in a cc-crew project, `/wired <symbol>` traces the production call path (catches "tested but unwired");
   - **`git bisect`** for a regression ("it worked last week"): `git bisect start; git bisect bad; git bisect good <sha>` → run the repro at each step;
   - binary-search the input/state; add temporary logging/instrumentation and **remove it before finishing**.
3. **Root cause.** One sentence + evidence. The fix must sit at the cause.
4. **Fix → `/tdd`** (cc-crew) or inline (test→fix→refactor→verify) elsewhere. Minimal change to GREEN.

## Mode B — Incident (production / observability)

A symptom from logs, traces, dashboards, or a user report — may not reproduce locally.

1. **Gather signal first.** Pull the trace/log lines, the failing request, the timestamps, the blast radius.
   In a cc-crew project the `/trace <id>` command pulls a structured trace; gstack `/investigate` is an
   optional heavier root-cause aid **if installed** (this skill owns the loop either way).
2. **Reproduce if you can; otherwise use the escape hatch.** Try to force a deterministic local repro
   (same inputs/state). If the surface is genuinely non-deterministic (concurrency, an external dependency,
   real flakiness), **don't fake a deterministic test** — capture it instead via:
   - an **eval case** (for non-deterministic / model-driven surfaces — the scaffolding's TDD-scope exemption),
   - a **log/trace assertion** or metric alarm that would catch a recurrence,
   - or a **documented manual repro** with the exact conditions.
   State explicitly which path you took and why a unit test wasn't possible.
3. **Mitigate vs fix.** If you must stop the bleeding first, label it a **mitigation** and keep the
   root-cause fix as an open task — a mitigation is never the closing "fix."
4. **Backfill coverage.** Once understood, add the regression check (test / eval / alarm) so it can't recur silently.

---

## Localization cookbook (quick reference)

| Situation | First move |
|---|---|
| "It worked before" (regression) | `git bisect` against the repro |
| "Where is X / what calls Y" | CodeGraph callers/callees/trace (else `grep -rn`) |
| "Is the new code even reached?" | `/wired <symbol>` (cc-crew) or trace the entry path manually |
| Intermittent / flaky | run N times; vary seed/order/timing; suspect shared state, ordering, time, network |
| Wrong value, no crash | assert at the boundary, bisect the data transform, check source-of-truth |
| Perf | measure first (profile/timing); find the hot path; don't guess |

---

## Compounding templates (opt-in — ask before writing)

**LESSONS.md entry:**
```
### Lesson <N> — <one-line title>
**Symptom:** <what was observed>
**Root cause:** <the actual cause>
**Fix / guard:** <what changed + the regression test that now pins it>
**Slice / area:** <where, if known>
```

**Forbidden-pattern (area `CLAUDE.md`):**
```
- Don't <pattern X> because <this incident / why it bites>; use <alternative Y>. (pinned by <test>)
```
Keep it narrow, enforceable, and test-pinned where possible. Outside a cc-crew repo, emit the same content as
plain markdown for the user to place in their own notes/conventions.

---

## What this skill does NOT do

- It doesn't redesign the architecture or run the planning chain — if a bug is really a design gap, **flag it**
  (Step-9-style finding in cc-crew; surface to the user otherwise) and stop.
- It doesn't become the contract/tracker, and it doesn't auto-commit or auto-push (the human/`/tdd` flow does).
- It doesn't suppress a symptom and call it done.
