<!--
  TEMPLATE: area {{AREA_MEMORY}} → write to <code-area>/{{AREA_MEMORY}} (e.g. app/{{AREA_MEMORY}}).
  One per code area. For a multi-area project, generate one per area, each with
  its own stack + launch-protocol row. Keep the launch protocol, session
  start/end protocol, cross-doc-invariants discipline, layer rule, and
  lessons-index meta-rules VERBATIM — those are workflow machinery. Fill the
  stack + commands; leave the lookup table, forbidden patterns, cross-doc table,
  and lessons index near-empty (1-2 illustrative rows + a "populate as you go"
  note). Delete this comment.
-->

# {{PROJECT_NAME}} `{{CODE_AREA}}` — Build Guide

> **You're in `{{CODE_AREA}}`.** This file plus root `{{ROOT_MEMORY}}` both load. The root file covers global project conventions + shared comm rules (track-prefix, escalation taxonomy, messaging budget); this file owns code-area conventions for {{CODE_AREA_NAME}}.

## Launch protocol

| Working on... | cwd | Loads |
|---|---|---|
| Planning / docs / commits | repo root (`{{REPO_DIRNAME}}/`) | root `{{ROOT_MEMORY}}` only |
| {{CODE_AREA_NAME}} code | `{{CODE_AREA}}` | this `{{AREA_MEMORY}}` + root |

<!-- For a multi-area project, add a row per additional code area. -->

If you find yourself fighting the wrong conventions, check your cwd.

## Session start/end protocol

**At session start:**
1. Read `{{TASK_TRACKER}}` (repo root) **by section, not whole** — `grep -n "^##" {{TASK_TRACKER}}` for offsets, then Read with offset/limit just "Currently in progress" + the active phase. (The file grows; never load it whole.)
2. Confirm with the user what feature this session is targeting.
3. Read the relevant section of `{{ARCH_DOC}}` from the lookup table below.

**At session end** (only when the user explicitly says we're done):

1. **Implementer runs `/session-end`.** Implementer writes ONLY:
   - `{{CODE_AREA}}` code files (the slice's implementation)
   - test files (the slice's tests)
   - dependency manifest / lockfile (deps the slice adds)
   - `docs/sessions/<NNN>-<date>-<topic>.md` (session doc, created at `/session-end` Step 5)

   **Implementer must NOT touch (all orchestrator territory).** *This list is the canonical statement
   of the territory rule — `/session-end`, the brief template, and the generated
   `scripts/guards/territory-guard.sh` PreToolUse hook (which mechanically enforces it in team mode)
   all point here.*
   - `{{TASK_TRACKER}}`
   - `{{CODE_AREA}}LESSONS.md`
   - `{{CODE_AREA}}{{AREA_MEMORY}}` (entire file — both the Cross-doc invariants table AND the Lessons logged index)
   - `{{ARCH_DOC}}`
   - `docs/orchestrator-briefing.md` / `docs/tdd-brief-template.md` / `docs/briefs/` / `docs/runbooks/`
   - other top-level deliverable / design docs
   - `.gitignore` and root-level dotfiles (unless adding a new artifact to ignore, flagged at Step 9)

   At Step 10: **explicit `git add <path>` per slice file; never `git add -A`/`.`; never stage an orchestrator-territory file.** Changes to any orchestrator-territory file (a new cross-doc model, a lesson, an arch note) are **flagged at Step 9**, not edited here — the orchestrator writes them hot (root `{{ROOT_MEMORY}}` + the Step-9 matrix).

2. **Orchestrator runs `/orchestrate-end`** for round close-out + Carry-forward triage + round terminal commit + push.

## Lookup table — where to find canonical info

Don't paste these sections into the prompt. Grep the file:section, read only what you need. `/check-arch <topic>` dispatches off this table.

| Topic | File (relative to repo root) | Section |
|---|---|---|
| <subsystem A> | `{{ARCH_DOC}}` | §X |
| <subsystem B> | `{{ARCH_DOC}}` | §Y |
| Lessons logged (full prose) | `{{CODE_AREA}}LESSONS.md` | by lesson # |

<!-- Starts near-empty. Add a row whenever a topic is looked up twice. -->

**Code intelligence & docs (when available):** prefer a code-intelligence MCP / docs MCP over grep+read loops — see root `{{ROOT_MEMORY}}` "Code intelligence & docs."

## Stack

<!-- ▼ EXAMPLE BLOCK [id=area-stack]: stack quick-reference for implementer sessions. Canonical stack lives in root {{ROOT_MEMORY}} + {{ARCH_DOC}}; this is the cheat sheet. ▼ -->

- **Runtime:** {{RUNTIME}}
- **Framework:** {{FRAMEWORK}}
- **Validation:** {{VALIDATION_LIB}}
- **Lint / types / tests:** {{LINT}} / {{TYPECHECKER}} / {{TEST_RUNNER}}

<!-- ▲ END EXAMPLE BLOCK [id=area-stack] ▲ -->

## Standard commands

```bash
# Install deps (run once; re-run when the manifest changes)
{{INSTALL_CMD}}

# Run the dev server (if applicable)
{{DEV_CMD}}

# Tests
{{TEST_CMD}}

# Quality
{{LINT_CMD}}
{{FORMAT_CHECK_CMD}}
{{TYPECHECK_CMD}}

# Preflight (use before saying "done" with a feature)
{{LINT_CMD}} && {{TYPECHECK_CMD}} && {{TEST_CMD}}
```

## TDD protocol

**Write the failing test first.** Applies to deterministic code — see the TDD posture in root `{{ROOT_MEMORY}}` for what is test-first vs. exempt.

**Commit per slice when practical.** Never bundle a safety-critical slice with anything else.

## Forbidden patterns

<!-- ▼ EXAMPLE BLOCK [id=forbidden-patterns]: forbidden patterns — 3-5 narrow, enforceable, domain-specific rules. Shape: "Don't <pattern X> because <reason / past incident>; use <alternative Y>." Test-pin them where possible. Starts small; accretes as lessons surface. ▼ -->

Do not:

1. **Write code without a failing test first** (for deterministic code). Even one-line functions.
2. **<Pattern>** — <reason>; use <alternative> instead.
3. **<Pattern>** — <reason>; use <alternative> instead.

**Enforcement patterns (machine-readable — `/preflight` warn-greps the staged diff against these).**
One `grep -E` (or `ast-grep`) expression per line, each tied to a numbered rule above. Rules that can't
be expressed as a pattern carry a `pin:` (test ref) or `accepted:` note on the rule itself instead.

```forbidden-patterns
# <rule 2>: <pattern — e.g.>  datetime\.now\(\)
# <rule 3>: <pattern>
```

<!-- ▲ END EXAMPLE BLOCK [id=forbidden-patterns] ▲ -->

## Cross-doc invariants — schema/docs mirroring

Several typed models in this codebase are **contracts** mirrored in `{{ARCH_DOC}}` and indexed in the table below. The architecture doc is the canonical contract; the model is the executable enforcement. Drift produces silent disagreement.

**Authoring discipline (orchestrator owns this table).** The implementer never edits this table or `{{ARCH_DOC}}` directly — it flags a field add/remove/rename at Step 9 as a `Cross-doc invariant change`; the orchestrator writes the row + the arch edit hot the same round (see root `{{ROOT_MEMORY}}` + `docs/orchestrator-briefing.md`). Commits stagger; the working tree stays aligned within the round.

| Model | `{{ARCH_DOC}}` section | Notes |
|---|---|---|
| <model> | §X | <field summary> |

<!-- Starts empty (or with the first model if one exists). Populated as contract models land. -->

## Module organization

<!-- ▼ EXAMPLE BLOCK [id=module-layout]: module layout + layer dependency rule. Replace with the project's real directory tree and import-direction DAG. ▼ -->

```
{{CODE_AREA}}
  <directory layout>
```

Layer dependency direction (top depends on bottom, never reverse):

```
<your layer DAG>
```

Cross-cutting layers can be imported from anywhere. Enforce the rule mechanically with a test where possible — the test *is* the spec for the rule.

<!-- ▲ END EXAMPLE BLOCK [id=module-layout] ▲ -->

## Subagents

See `.claude/agents/README.md` for the canonical inventory + integration points.

<!-- ▼ EXAMPLE BLOCK [id=area-subagent-candidates]: area-specific subagent candidates — list candidates that would earn their keep specifically in this area (e.g. an ABI/types syncer for a frontend area, a Pyth/feed verifier for a contracts area). Build only on real friction. ▼ -->

<!-- ▲ END EXAMPLE BLOCK [id=area-subagent-candidates] ▲ -->

## Lessons logged from prior sessions

The full prose for each lesson lives in `{{CODE_AREA}}LESSONS.md`. This index is the compact orientation surface.

**Lesson numbers are stable IDs** — once assigned, they don't change. New lessons get the next sequential number. `/session-end` proposes additions when it detects them; the user approves before the entry is written and a row is added here.

Lessons start at §1.

| # | Date | Topic | Rule (one-liner) |
|--:|---|---|---|
| | | | |

<!-- Starts empty. Each row links to its `LESSONS.md` anchor. -->

<!-- Slash commands: see root {{ROOT_MEMORY}} "Slash commands available." Implementer pair: /session-start + /session-end. -->
