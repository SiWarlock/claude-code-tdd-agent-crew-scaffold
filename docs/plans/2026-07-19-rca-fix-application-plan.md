# Applying the 7 IMPLEMENTATION_PLAN-degradation RCA fixes — application plan

> Source RCA: `SoW-build/docs/rca/2026-07-19-implementation-plan-degradation-rca.md` (produced by the downstream plan-doc cleanup; the downstream repo is ALREADY migrated — plan rebuilt, archive written, plan-lint passing).
> Reviewed against THIS repo @ HEAD `18a4c30` by a 5-reviewer fan-out (plan template · orchestrate-end · reader commands · ship machinery · full ripple sweep). **Every RCA quote survives verbatim at HEAD**; only metadata drifted.

## RCA corrections (apply these re-mappings when reading the RCA)

1. **Path prefix**: the RCA writes `scaffold/templates/...` — this repo has no `scaffold/`; the real prefix is `templates/...`.
2. **Line numbers**: command files gained a Codex HOST frontmatter overlay (`<!-- ▼ HOST [claude] ▼ -->` / `[codex]`, L1–14) — RCA line numbers are ~+9 low. Anchor on TEXT (verified verbatim), never on line numbers.
3. **"phase-exit.md is byte-identical / no placeholders" is STALE** — it now carries the HOST overlay + `{{TASK_TRACKER}}`/`{{ARCH_DOC}}`/`{{AUDIT_CMD}}`/`{{SECURITY_REVIEW_POLICY}}`/`{{AREA_MEMORY}}`.
4. **Host axis**: orchestrate-end.md + phase-exit.md bodies are host-SHARED (HOST markers only in frontmatter) → each body edit lands once and covers Claude AND Codex. No frontmatter changes needed.

## Three ship-critical facts the RCA missed

1. **The byte-paired twin.** `templates/IMPLEMENTATION_PLAN.md` ⟷ `skills/tasks-gen/references/implementation-plan-template.md` are byte-identical, hard-gated by `scripts/release-check.sh` (`pairs`). **Every plan-template edit must be `cp`'d over the twin in the same commit** or the build fails.
2. **The plan template is `accreted`.** scaffold-upgrade never rewrites accreted bodies — Fixes 1/3/4/7 reach EXISTING projects only via a human-gated **`accreted-format` migration (M-0015)**. Fresh generations get them directly.
3. **New template files are not auto-delivered.** The upgrade merge only walks `manifest.generatedFiles`; `templateSetDelta.added` is reporting-only. plan-lint.sh reaches existing projects only via an **`added-template` migration (M-0014)** (precedent: M-0007 delivered spec-lint.sh).

## The change set

### A. `templates/IMPLEMENTATION_PLAN.md` (+ byte-mirror to the tasks-gen twin, same commit)

| Anchor (verbatim text at HEAD) | Edit | Fix |
|---|---|---|
| L14 living-sections sentence ("…Currently-in-progress, Carry-forward, Log, Trims, Decisions) are **bounded** — pruned/archived at `/orchestrate-end`…") | Replace with the **format-contract blockquote** (RCA Fix 7 bullets: one State-checkbox line per `### N.M` task — vocabulary `DONE·hash·date / PARTIAL·remaining: / OPEN / DEFERRED / OWNER-GATED §ARM-*` — headings carry no state; CIP ≤3 items/≤15 lines REPLACED; Carry-forward ≤7, resolved DELETED; round history only in `docs/archive/IMPLEMENTATION_LOG.md`; Owner-gates section; `**Spec:**` anchor or `arch_gap` per task; phase-exit checklists in `docs/archive/` with a `**Gate:**` pointer). State caps ONCE here (RCA residual-risk 7: no re-stating). | F1+F7 |
| L217–221 `## Log` section (names `docs/archive/TASKS-LOG.md`, "~10 rounds inline") | Replace with the 2-line pointer stub (must contain the literal `docs/archive/IMPLEMENTATION_LOG.md` — plan-lint requires it): `## Log` / `Round history is **not** kept in this file. See docs/archive/IMPLEMENTATION_LOG.md (append-only, orchestrator-written at every /orchestrate-end).` | F1 |
| L6 build-comment "…Currently in progress, Carry-forward, Decisions tabled, Log, Trims) starts EMPTY…" | Drop `Log` from the list. | F1 |
| L7 "Task entries are dense checkbox bullets, NOT pre-written briefs." | → "Task entries carry ONE state-checkbox line + fielded metadata + a dense prose sketch, NOT pre-written briefs." | F7 |
| L20 session protocol "…append Log entry…" | → "…append the round's Log entry to `docs/archive/IMPLEMENTATION_LOG.md`…" | F2 |
| L26 "…field lines beneath are never individually marked" | Reconcile to the one-State-line rule (metadata lines are plain fields, never checkboxes). | F7 |
| L32 CIP comment "(≤ ~8 lines)" | → "≤3 items / ≤15 lines" (plan+command+lint agree). | F3 |
| L42 Carry-forward guidance | Append: "Resolved items are DELETED with an archive pointer (never annotated in place); overflow past ~7 goes to the owning phase's `#### Residuals`, not here." | F4 |
| L102–123 phase-exit checklist template section | Keep the row TEMPLATE in the plan; re-point the materialization convention: per-phase copies materialize in `docs/archive/phase-exit-<phase>.md`; the phase body keeps `**Gate:** <PENDING\|CLEAR\|BLOCKED> — see …`. Reword L107 "All phase task checkboxes ticked" → "All phase task **State lines** are DONE-class". | F6/F7 |
| L143–158 `[id=task-entry-format]` EXAMPLE BLOCK (multi-`[ ]` bullets) + L160–162 second example | Replace block CONTENT (markers preserved — census-safe) with the one-checkbox format: `- [ ] OPEN` first content line; `**Kind:** … · **Spec:** {{ARCH_DOC}} §X (or arch_gap) · **Depends:** … · **Blocks:** …`; `**Files:** …`; one dense acceptance paragraph; a comment documenting the state vocabulary. | F7 |
| L166 "All <phase-id>.X task checkboxes ticked" | → "All <phase-id>.X task State lines DONE-class". | F7 |
| L203 Trims "deleted with a one-line Log note" / L211 Decisions "Resolved entries move into the Log" | Re-point both at the archive log. | F1/F2 |
| NEW section (before the phases, near Carry-forward) | `## Owner gates & arming ledgers` skeleton: HARD-LINE preamble + one `### §ARM-<slug>` / `### §DEC-<slug>` per gate; guidance in a plain HTML comment, "delete this section if the project has no owner-gated crossings". **Ship as PLAIN machinery, NOT an EXAMPLE BLOCK** (keeps the §10 census at 26; plan-lint pairs OWNER-GATED tasks ⟷ defined ids). | F7 |
| NEW (optional, recommended) | `## Phase status (at a glance)` dashboard skeleton (`Ph | Title | Track | State ✅/🔶/⬜/⛔ | Gate | Open | Anchor`) — plain section, no EXAMPLE marker. Deliverable map stays (different question); dashboard first. | F7+ |

### B. `templates/.claude/commands/orchestrate-end.md` (host-shared body — one edit covers both hosts)

- **F2 — Step 4** (L50 heading + L52 body): heading → "Append a Log entry to `docs/archive/IMPLEMENTATION_LOG.md`"; body → the RCA Fix-2 text (plan carries NO inline Log; archive is append-only, read on demand; do not write round narratives into `{{TASK_TRACKER}}`). Kills the dead `TASKS-LOG.md` roll. Keep the format block (L56–65).
- **F3 — Step 5 CIP bullet** (L72): → REPLACE-not-append, ≤3 items/≤15 lines, no narratives, no parked checklists (RCA Fix-3 text).
- **F4 — Step 5.5** (L78 + after the outcome table): de-gate — "Apply DELETE and INLINE-TARGET mechanically — no user prompt… Only DEFER escalates"; insert the "Resolved items are DELETED, never annotated… overflow → `#### Residuals`" paragraph. (Resolves the existing internal contradiction with L88, which already half-de-gated — keep L88.)
- **F5 — new Step 6.5** (between Step 6 L100 and Step 7 L102): the blocking `scripts/plan-lint.sh {{TASK_TRACKER}}` gate (RCA Fix-5 text) + Forbidden list (L162–171) gains "Committing a round whose `plan-lint.sh` exits non-zero." (Step-1's orchestrator-only route "skip to Step 6" still flows through 6.5 — lint always runs.)
- **Ripples**: Step 3 L48 "The `- [ ]` field lines under a task are never individually checked" → the one-State-line rule; Step 5 L69 Decisions-relocate "move to the Log entry above" → the archive log; Step 7 L105 drop "Log entry," from the `{{TASK_TRACKER}}` parenthetical + git-add block (L114–119) adds `docs/archive/IMPLEMENTATION_LOG.md \`; Step 8 L148 "Log entry appended" → "…to docs/archive/IMPLEMENTATION_LOG.md".

### C. `templates/.claude/commands/phase-exit.md` (host-shared)

- **F6 — Step 1** (L34): materialize the checklist in **`docs/archive/phase-exit-<phase>.md`** (create if absent), NOT inline; plan phase keeps the one-line `**Gate:**` pointer; resume-from-first-unticked reads the archive file.
- **F6 gap-fix (REQUIRED, RCA-missed) — Step 3** (L59): "Record each row's tick in `{{TASK_TRACKER}}`" → "…in **`docs/archive/phase-exit-<phase>.md`**" (else Step 1 archives the checklist while Step 3 ticks a plan copy that no longer exists).
- **F6 — Step 4** (L63/L65/L66): verdict appends to `docs/archive/IMPLEMENTATION_LOG.md`; CLEAR updates the phase `**Gate:** CLEAR (evidence: …)` pointer; BLOCKED also sets `**Gate:** BLOCKED — see …` (no stale PENDING).
- **Ripple — Step 2 row** (L42): "verify every `- [ ]` under its tasks is `[x]` (or carries a partial-note + Log entry)" → "verify each task's single State line reads `- [x] DONE · hash · date` (or `- [~] PARTIAL · remaining:…` with an archive-log entry)".
- Note: orchestrate-end Step 4 (round framing) and phase-exit Step 4 (gate verdict) both append the archive log as DISTINCT entry kinds — intentional, do not collapse.

### D. NEW `templates/scripts/plan-lint.sh` (F5)

Copy from `SoW-build/scripts/plan-lint.sh` (passing reference implementation). One tokenization: `PLAN="${1:-IMPLEMENTATION_PLAN.md}"` → `PLAN="${1:-{{TASK_TRACKER}}}"` (kind=placeholder-only, mirrors spec-lint.sh); keep `docs/archive/IMPLEMENTATION_LOG.md` hardcoded. `chmod +x`.

### E. Read-path re-points (the Log left the plan)

- `templates/.claude/commands/orchestrate-start.md` L34: tail `docs/archive/IMPLEMENTATION_LOG.md` (optionally tighten Step-4.5's `-A 20` → `-A 15`).
- `session-start.md` L24 · `team-start.md` L79 · `team-end.md` L50: same re-point.
- `team-end.md` Step 5 (L112–118): pause-marker write reworded to REPLACE/refresh the CIP snapshot within the ≤3/≤15 cap (not "add one line").
- Codex-only twins (separate files, not HOST-covered): `templates/.codex/skills/team-start/SKILL.md` L81 + `templates/.codex/skills/team-end/SKILL.md` L61.
- `session-end.md`: NO change (its "Do NOT touch `{{TASK_TRACKER}}`" rule is intact and load-bearing).

### F. Generator + guides + skills prose

- `GENERATE-WITH-CLAUDE.md`: Step 11.5 emit bullet for plan-lint.sh (+ manifest `generatedFiles` row; + the Codex Step-11.5 list ~L295); L320–321 structure-verify list (Log → pointer-stub; add Owner-gates); §10 census untouched (no new EXAMPLE BLOCK).
- `README.md` L143–145 + L262: add plan-lint.sh beside spec-lint.sh.
- `SCAFFOLDING-GUIDE.md` L299 (tracker description: drop inline Log, TASKS-LOG→IMPLEMENTATION_LOG, CIP ≤3/≤15, Owner-gates, checklists→archive) + L191 archive tree + L245/L252 command table rows.
- `skills/tasks-gen/SKILL.md` L152 (living-sections list drops Log) + L52 (teach the State-line contract so NEW plans are born lint-clean).
- `skills/scaffold-upgrade/references/upgrade-skill.md` L134 (accreted-region list: Log no longer a living section).
- `templates/docs/orchestrator-briefing.md` L85 + triage prose (L63/L141/L154/L170–172): archive-append + F4 de-gating (this is the canonical charter the command points at). `templates/docs/scaffolding-reference.md` L139–141: same de-gating note.

### G. Migrations (both human-gated, NO `hosts` filter — must reach Claude + Codex)

- **M-0014 — added-template**: deliver `scripts/plan-lint.sh` + manifest `generatedFiles` row to existing projects (precedent M-0007). Couples with the Step-6.5 edit — same release window.
- **M-0015 — accreted-format**: the one-time plan-doc compaction for existing projects (Log→archive, checklists→Gate: pointers, tasks→State lines, Carry-forward drained, format-contract header + Owner-gates). Human-applied PROPOSE checklist (prose→State-line mapping needs judgment; precedent M-0005), plan-lint exit-0 as the completion backstop. **Detection/no-op**: skip when `docs/archive/IMPLEMENTATION_LOG.md` exists AND plan-lint exits 0 — SoW-build (already migrated 2026-07-19) no-ops cleanly.
- `migrations/registry.json`: both entries, id-ordered M-0014 → M-0015, `introducedAtSha` wired two-step after the template commit lands.

### H. Tests

- NEW: plan-lint.sh unit test (degraded fixture → exit 1 per rule class; clean fixture → exit 0).
- Extend `tests/run-upgrade-dryrun.sh`: M-0014 selected + file lands; M-0015 no-ops on a compacted tracker.
- Existing old-format fixtures (`tests/fixtures/upgrade-dryrun*/`): leave as-is (deliberate pre-migration state); add compacted goldens only if the dry-run test grows M-0015 coverage.

### I. Verification gate

`scripts/release-check.sh all` green (pairs — the twin! · census 26 unchanged · migrations · host-census) + generate a sample plan and run plan-lint on it (expect exit 0) + run plan-lint against `tests/fixtures` degraded fixture (expect exit 1).

## Sequencing

1. Commit 1 — templates + twin mirror + command edits + `templates/scripts/plan-lint.sh` + generator/guide/skill prose (everything in A–F).
2. Commit 2 — migrations M-0014/M-0015 + registry (wire `introducedAtSha` to commit 1's SHA).
3. Commit 3 — tests (lint unit test + dry-run extension).
4. Run `release-check all`; fix; done. Downstream: `/scaffold-upgrade` in SoW-build then no-ops M-0015 and picks up the command/script deltas.

## Open decisions (defaults chosen, flag if you disagree)

1. **Owner-gates + Dashboard ship as plain sections** (no EXAMPLE BLOCK → census stays 26; deletable via prose note). Alternative: EXAMPLE BLOCKs with census 26→28 + id-map + manifest + twin updates.
2. **plan-lint default arg tokenized** to `{{TASK_TRACKER}}` (placeholder-only kind). Alternative: verbatim copy (fallback only matches projects whose tracker is literally `IMPLEMENTATION_PLAN.md`).
