# Optimization implementation plan — 2026-06-10

> **Status:** APPROVED by the user 2026-06-10 for full implementation. Work happens on branch
> **`optimize/workflow-hardening`** (created from `main` @ d1b59a7). Conventional Commits, one commit per
> item (or per coupled group as marked), **never push** — the user reviews and pushes.
>
> **Provenance:** this plan is the synthesis of (1) a full end-to-end read of every repo file,
> (2) a 43-agent multi-lens audit (6 lenses → 45 findings → 18 merged → 2 adversarial verifiers each:
> 14 confirmed / 4 contested / 0 refuted), and (3) a 26-agent second pass (direction-of-fix validation
> per item + interaction/cost/sequencing auditors + completeness critic: 0 wrong-direction, 12
> needs-adjustment — all adjustments folded in below). Raw outputs (if still present):
> `~/.claude/projects/-Users-dreddy-Documents-Dev-AI-tools-claude-code-tdd-agent-crew-scaffolding/88d5f20a-790d-4666-89aa-2ab0e4273886/tool-results/bj0bt6yg2.txt` (pass 1, full)
> and `/private/tmp/claude-501/.../tasks/w0xalvsof.output` (pass 2, full). This document supersedes both —
> it is self-sufficient.
>
> **Honest framing (from the cost auditor):** this set is funded by **drift prevention** (user priority 1),
> not token reduction. Net tokens: lead ≈ −1,200/session; every session machine-wide ≈ −500 (description
> trims); orchestrator ≈ breakeven; implementer slightly additive; phase-exit rounds add ~1–1.5k to the
> orchestrator (after file-routed reports). Do not oversell token savings in the docs updates (Wave 5).

## User decisions already made (do NOT re-ask)

- Item 4 reframed: amend the **tasks-gen SKILL**, not the task template (test design stays at the brief layer).
- Item 11 scoped: session-end §2.5 bug fix + snapshot tests **only for §2.5-seam (shared-contract) models**;
  full coverage deferred (recorded as a tabled decision, revisited off /phase-exit verdicts).
- Item 15 confirmed as docs-only. **TEAM MODE IS THE DEFAULT for all projects including solo devs** —
  "single track" refers to the parallelization track map (one worktree), NOT to single-operator mode.
  Single-operator (two pasted sessions) survives only as the no-agent-teams-available fallback.
  Use the phrase **"team mode (single track)"** everywhere; never imply solo/single-operator is default.
- Generation-time recommended defaults must be **asked, never silently applied** — but batched into ONE
  grouped question (W4-7), not four separate gates.
- Wave 5 (added by user): SCAFFOLDING-GUIDE.md + README.md must be updated to reflect everything once
  implemented.

## Cross-cutting conventions (apply to every item)

1. **Twin-pair rule.** Any edit to `templates/IMPLEMENTATION_PLAN.md` or `templates/ARCHITECTURE.md` lands
   with its bundled skill twin (`skills/tasks-gen/references/implementation-plan-template.md`,
   `skills/arch-finalize/references/architecture-template.md`) **in the same commit** — the W1 release
   check enforces full-content identity. (The GENERATE-WITH-CLAUDE pair is eliminated by W1-2's stub.)
2. **Migration rule.** Every template change that affects already-generated projects ships, in the same
   commit: its `migrations/M-NNNN-*.md` + `registry.json` entry (append-only; `introducedAtSha` wired via
   the two-step pattern M-0003/M-0004 used — placeholder note, then a follow-up commit sets the real SHA),
   plus any `GENERATE-WITH-CLAUDE.md §10` region-census update and manifest schema notes. Migration kinds
   per `migrations/_TEMPLATE.md`. Suggested numbering (adjust as needed at implementation):
   M-0005 manifest-posture-field · M-0006 wave-2 generated-file set (added-template, consolidated) ·
   M-0007 brief-template wiring section (new-required-section) · M-0008 wave-2 phase-exit checklist rows
   (new-required-section, accreted tracker — M-0004 precedent) · M-0009 root-CLAUDE restructure
   (moved-section) · M-0010 phase-exit checklist v2 trio (new-required-section, posture-gated) ·
   (optional) M-0011 retrofit `[id=]` slugs into tasks-gen-authored trackers (human-gated; decide at W1-1).
3. **Manifest posture field.** Add `"posture": "production-grade" | "MVP/prototype"` to the Step-12.5
   manifest schema; bump `schemaVersion` → 2; `scaffold_upgrade.sh` `SKILL_SCHEMA` → 2 with graceful
   handling of v1 manifests (posture unknown ⇒ posture-gated upgrade content is human-gated). Needed so
   posture-gated rows (W4) can be filtered mechanically at upgrade time.
4. **Release check.** `scripts/release-check.sh` (new, repo root) accumulates subcommands as waves land:
   `pairs` (full-content identity — NOT structure-only; prose drift is the bug class), `census`
   (count `[id=]` regions across templates vs the §10 number), `migrations` (registry parses; every M file
   exists; every `introducedAtSha` resolves), `upgrade-dryrun` (W1-9), `playbook` (W3-2: rebuild concat +
   diff), `all`. Run `all` at the end of every wave.
5. **Escalation wording.** Findings raised at the phase-exit gate escalate as **Findings (category 2)**
   via orchestrator → lead → human (the reachability-auditor pattern). Reserve "Step-9 …" labels for the
   implementer's mid-slice checkpoint only.
6. **Fan-out report discipline (state lives in files).** Any phase-exit subagent writes its full report to
   `docs/audits/<phase>-<agent>.md` and returns a ≤10-line summary + CLEAR/BLOCKED verdict.

---

## WAVE 1 — foundations + consistency fixes

### W1-2 (do FIRST — eliminates a twin before W1-1 edits it) — single-source the generation procedure
- `skills/scaffold-generate/references/generate-procedure.md` → replace the whole 614-line file with a
  short pointer stub: "Canonical procedure: read `GENERATE-WITH-CLAUDE.md` at the **root of the
  scaffolding checkout you are running from** (the checkout that provides `templates/`)." Worded as a
  prose instruction keyed off the checkout path, NOT a relative include and NOT a symlink.
- `skills/scaffold-generate/SKILL.md` (~lines 26, 79): repoint the two citations to the root file directly.
- `templates/ARCHITECTURE.md` ↔ `skills/arch-finalize/references/architecture-template.md`: both stay real
  files (arch-finalize runs inside the target project; templates/ is scaffold-upgrade's merge base) —
  covered by `release-check pairs` byte-equality.

### W1-1 — sync the IMPLEMENTATION_PLAN pair + resolve the Step-4 contradiction
- Overwrite `skills/tasks-gen/references/implementation-plan-template.md` with the exact content of
  `templates/IMPLEMENTATION_PLAN.md` (restores: `[id=deliverable-map|parallelization-plan|task-entry-format|optional-demo-phase]`
  slugs, the Reading-discipline sectioned-read rule, the ~7-item Carry-forward cap, the bounded-Log
  (~10 rounds → `docs/archive/TASKS-LOG.md`) policy, Trims pruning, Decisions-tabled move-to-Log rule).
- `GENERATE-WITH-CLAUDE.md` §7 Step 4: when ANY tracker already exists (tasks-gen-authored or
  pre-existing), Step 4 does **verify/retrofit structure only** (required sections/blocks present), with
  any retrofit **proposed at the §6 plan-approval gate**, never silently applied; only when no tracker
  exists does it author from the template. (The stub means only the root file needs this edit.)
- `skills/tasks-gen/SKILL.md` §1.2: note the bundled reference is synced from canonical
  `templates/IMPLEMENTATION_PLAN.md` by the release check.
- Decide + record: optional migration M-0011 (retrofit `[id=]` slugs into existing tasks-gen-authored
  trackers; human-gated) — recommend authoring it; if skipped, document the known gap in the migration
  registry note.

### W1-10 — release-check.sh + manifest posture field (conventions 3–4 made real)
- New `scripts/release-check.sh` with `pairs` / `census` / `migrations` subcommands (+ `all`).
- `GENERATE-WITH-CLAUDE.md` Step 12.5: add `posture` field; `schemaVersion: 2`; document.
- `skills/scaffold-upgrade/scripts/scaffold_upgrade.sh`: `SKILL_SCHEMA=2`; v1-manifest grace path.
- `migrations/M-0005-manifest-posture-field.md` + registry entry (manifest-schema migration, runs first,
  asks the user for posture — never fabricate; gate: human).

### W1-9 (moved up from Wave 4) — migration/upgrade dry-run fixture
- `tests/fixtures/upgrade-dryrun/` (OUTSIDE `templates/` so it never ships): a minimal generated-project
  shape with manifest pinned at the **pre-M-0001 base SHA = `1d995d4b8c2ce11995f5174ecb69aa9ac93b40b8`**,
  seeded with: ≥1 `customized` EXAMPLE BLOCK, 1 diverged verbatim file, 1 damaged block marker, non-empty
  accreted bodies (a LESSONS entry + tracker living-section content). Untouched files must byte-match
  `scaffold_upgrade.sh substitute <baseSha>` output (assert this so the fixture can't drift).
- `tests/run-upgrade-dryrun.sh`: drives the EXISTING script subcommands only (resolve → substitute → diff
  → migrations → apply with a synthesized pre-approved plan.json → check-markers → stamp); asserts
  M-0001..M-0004 window selection, PROPOSE/conflict-marker/whole-file-degrade/accreted-leave-alone
  behaviors per the seeds; runs TWICE — second run must select nothing (`.done` journals). Document that
  prose-migration application stays model-run + human-gated (the script proves selection + mechanics).
- Wire as `release-check.sh upgrade-dryrun`. Extend the window per wave as new migrations are authored.

### W1-3 — Spec Anchor Index (both architecture templates, same commit)
- Add `## Spec Anchor Index` adjacent to Appendix A in BOTH templates: table
  `| REQ ID | Implemented by § | Summary |`; comments: orchestrator-owned, maintained same-round like
  Appendix A; **scale-down** (delete if planning produced no REQ-* IDs); a note that this index is what
  you copy FROM when a topic later earns an area-CLAUDE lookup row — do **NOT** seed the lookup table
  (it must stay near-empty per generate rules).
- `skills/arch-finalize/SKILL.md` §5: confirm wording matches (REQ→§ table).
- `skills/scaffold-upgrade/SKILL.md` §4 user-canonical row: extend "Only an appended Appendix A skeleton
  is a PROPOSE candidate" to include the Spec Anchor Index skeleton (additive, project-state-free).
- Update `docs/audit/scaffolding-drift.md` P0 #3 as resolved.

### W1-4 — tasks-gen SKILL test-scenario reframe (user-approved direction)
- `skills/tasks-gen/SKILL.md`:
  - frontmatter description: replace "and happy/edge/error/ integration test scenarios" with
    "and acceptance bullets pinning the spec-implied edge/error behaviors the architecture names".
  - §2 Tasks bullet: delete the test-scenarios sub-bullet; add the acceptance-bullet rule; add an explicit
    layering note: *test design is authored by the orchestrator at brief time (the RED outline) and
    reviewed at Step 2.5 — do not pre-write test designs in the plan.*
  - §1 tools line (~40): "when writing test scenarios" → "when pinning library/API behaviors in
    acceptance bullets".
- `docs/audit/scaffolding-drift.md` P0 #4: record the skill-side resolution.

### W1-5 — close-out deadlock fixes (orchestrate-end + team-end) [includes gap G-2]
- `templates/.claude/commands/orchestrate-end.md` Steps 7–8 + Forbidden — three-way:
  (a) single-operator → confirm with the user, then optionally author the next brief;
  (b) team, user-on-demand → verify push from the `git push` exit status, ack the LEAD via SendMessage,
  idle (next brief only on lead-relayed direction);
  (c) team, auto-cycle → verify push mechanically, ack the lead, author **NO** brief, expect
  shutdown_request (the successor authors the next brief after /orchestrate-start).
- `templates/.claude/commands/team-end.md` Step 0 (the file currently contradicts itself — frontmatter
  allows auto-cycle, Step 0 forbids it): user-on-demand keeps the explicit-go gate; auto-cycle (lead
  ctx ≥ ACTION, or full-team cycle requiring lead teardown) treats the mechanical trigger as the go and
  surfaces a notification, not a blocking question. **Step 1's all-teammates-closed gate is untouched.**
  Reword the Forbidden bullet to name both triggers (match root CLAUDE.md "Close-out gating").
- Propagation note in both commit messages: these are placeholder-only-kind files — untouched projects get
  the fix as a clean auto-apply on next `/scaffold-upgrade`; advise `--check`.
- NOTE for W3-1: orchestrate-end's three-way statement becomes the **canonical close-out spec** that the
  slimmed root CLAUDE.md points at.

### W1-6 — MCP tool allowlists (5 files)
- **Verify first** (one scratch test): an allowlisted-but-unconnected MCP tool name is silently ignored by
  the current Claude Code. (It is per current behavior; confirm.) Only if it errors, fall back to a
  generation-time substitution — still no EXAMPLE BLOCKs in frontmatter (HTML-comment markers are invalid
  YAML and would break registration).
- Append MCP names **verbatim and unconditionally** to: the `tools:` line of all four
  `templates/.claude/agents/*.md` and the `allowed-tools:` line of `templates/.claude/commands/wired.md`
  (e.g. the `mcp__codegraph__*` set: codegraph_context, codegraph_search, codegraph_callers,
  codegraph_callees, codegraph_trace, codegraph_impact, codegraph_explore, codegraph_node,
  codegraph_files; and `mcp__context7__*`: resolve-library-id, query-docs — use server-prefix form if the
  harness accepts it).
- Add a prefer-MCP-with-grep-fallback paragraph to each body using the existing "if present … no-op when
  absent" phrasing (root CLAUDE.md §"Code intelligence & docs" / orchestrator-briefing "External MCP tools").
- Files stay verbatim/placeholder-only kind — no census change, no manifest change.
- When W2-6 creates `arch-drift-auditor.md`, it is born with this same pattern. Update any "all four
  agents" phrasing to five at that point.

### W1-7 — archive frozen-snapshot banners
- Prepend to both `docs/archive/DEEP_AGENTIC_ARCHITECTURE_PLANNING_PLAYBOOK.md` and
  `docs/archive/START_DEEP_ARCHITECTURE_PLANNING_SESSION_PROMPT.md`: a blockquote banner — frozen
  pre-build-posture snapshot, do not edit, live copy at `skills/arch-draft/references/…`.
- `docs/audit/scaffolding-drift.md` item 6: resolved.

### W1-8 — skill description trims
- Trim frontmatter `description:` of `skills/{layer-docs,learn-site,eval-triage,scaffold-upgrade}/SKILL.md`
  to ≤700 chars each. MUST retain: the host note ("host-neutral, Codex or Claude" vs "Runs on Claude
  Code"), the chain-position cue ("after /layer-docs", "after /tasks-gen"), the discriminative clause vs
  the nearest sibling (layer-docs↔learn-site, eval-triage↔bug-hunt, scaffold-upgrade↔scaffold-generate),
  and the quoted trigger phrases. Move operational detail into the SKILL body intro.
- Honest saving: ~500 tokens/session machine-wide (state it as such; do not claim 800).

---

## WAVE 2 — the drift spine

### W2-0 (gap G-1) — PRD→REQ head-end
- `skills/arch-draft/references/architecture-planning-playbook.md` Phase 6 (§10): the Source column
  requires a **PRD citation (section/quote)** for every `explicit` requirement; `inferred` /
  `user-confirmed` tagged as such. (Playbook still monolithic at this point — fine; W3-2 carries it through.)
- `skills/arch-finalize/SKILL.md` §2 dimension 1: emit a **persisted PRD→REQ coverage table** to
  `docs/gap-audits/` (every PRD must-have → REQ ID, or an explicit out-of-scope tag) and present uncovered
  rows at the §4 human gate. `req-coverage` (W2-2 `spec-lint reqs`) reads this table as its head when present.

### W2-1 — REQ traceability, derived not stored
- **No mandatory per-task `Implements: REQ-*` line** (it would be a third drifting copy). REQ→task
  coverage derives from the task's §-marker (W2-2) + the Spec Anchor Index (W1-3). Document an OPTIONAL
  `Implements: REQ-x` override in the task-entry comment of BOTH tracker templates, only for when one §
  maps to multiple REQs and a task covers a strict subset.
- `templates/docs/tdd-brief-template.md` traceability block: one line noting REQ IDs derive from the cited
  §s (explicit REQ list only when overriding). (Lands with W2-2's single format-block edit.)
- `skills/arch-finalize/SKILL.md`: add an explicit **draft→final anchor-remap step** — emit a one-table
  map (e.g. draft `## 4A` → final `§2.5`) and update `DIAGRAM_PLAN.md` "Spec anchors" entries and
  `DECISIONS.md` "Related Architecture Anchors" entries at finalization (these currently dangle silently).

### W2-2 — ONE `spec-lint.sh` (consolidates brief-lint + spec tags + req coverage)
- New `templates/scripts/spec-lint.sh` — establishes the **project-local scripts** surface
  (generated into `<project>/scripts/`; add a §7 generation step + `generatedFiles` row, kind
  placeholder-only). One shared anchor-extraction function. Subcommands:
  - `brief <path>`: every cited §X exists in `{{ARCH_DOC}}` (grep `^## §` headings, NOT the index);
    Task ID(s) exist unticked in the tracker (accept multiple for bundles); brief anchors ⊆ the phase's
    `Spec anchors:` (prefix-aware: §4.3 ⊂ §4) OR an explicit "widens phase scope because…" line; the
    Wiring/entry-point section present (accept "none — wiring lands in <slice-id>"); handles both `§X.Y`
    and `#named-anchor` notations; LESSONS refs excluded; **advisory** count of acceptance bullets vs
    RED-outline entries (G-5); **warn-only** REQ-IDs-line presence. Output: ONE line on PASS.
  - `tests <phase>`: each anchor on the phase's `Spec anchors:` line has ≥1 test carrying a `spec(§X)`
    tag (grep the test tree — no per-commit attribution); per-anchor **waivers**
    (`§X (non-TDD: eval-fixture)` / `covered-by: <evidence>`); benchmark/REQ-NF anchors are a named
    waiver class (W4-3); out-of-set tags are FLAGGED advisory (a Step-9 item), never a failure;
    track-scoped in multi-track.
  - `reqs`: warn-only REQ coverage per W2-1 (graceful on: no REQ IDs; missing Spec Anchor Index — report
    "re-run /arch-finalize to add it").
- **Run discipline:** orchestrator runs `spec-lint brief` pre-dispatch (the mandatory gate); the
  implementer's `/tdd` Step 0 re-runs ONLY if the brief file's mtime/hash postdates the dispatch (one
  bash conditional, silent otherwise).
- `templates/docs/tdd-brief-template.md` — ONE edit to the canonical format block: add the
  `## Wiring / entry point (Step 7.5)` section (currently only in the worked example) + the W2-1 REQ
  derivation note. → migration M-0007 (new-required-section).
- `templates/.claude/commands/tdd.md`: Step 0 conditional re-lint; Step 2: RED tests carry `spec(§X)`
  per the brief's "Why" lines.
- `templates/.claude/commands/orchestrate-end.md` Step 3 — new-task anchor rule: newly added
  `### <phase-id>.N` headings must carry `(implements §X; origin: <slice>)` **or**
  `(ops — no contract anchor)` and sit under a phase whose anchors cover §X; HEADING-level check only
  (the `- [ ]` lines under tasks are field lines, never checked individually).
- `templates/docs/orchestrator-briefing.md`: the Step-9 "Future TODO — belongs to a phase" row gains the
  anchor-or-escalate rule (no covering anchor ⇒ contract gap ⇒ Architecture-doc note + escalation, never a
  silent task add); responsibility 2 mentions the pre-dispatch lint.
- BOTH tracker templates: the spec-anchor convention paragraph gains the new-task marker rule. The
  spec-coverage checklist ROW lands in W2-6's coordinated checklist edit, not here.
- Migrations: spec-lint.sh rides M-0006 (the consolidated wave-2 added-template set).

### W2-3 — session-end §2.5 fix + seam-scoped snapshot tests (user-approved scope)
- `templates/.claude/commands/session-end.md` §2.5: drop "in the same set of commits". Single-track →
  check the **uncommitted working tree** for the paired `{{ARCH_DOC}}` edit (the orchestrator wrote it hot
  in the same checkout); multi-track → pure memory check ("confirm every model field change was flagged at
  Step 9; list any that were not" — the edit lives in the integration checkout and is invisible here).
- `templates/docs/tdd-brief-template.md` "Cross-doc invariant impact" (+2 lines, same commit as W2-2's
  block edit if convenient): any NEW/extended-tagged slice touching a **§2.5-seam (shared-contract)
  Appendix-A model** must include the schema-snapshot test (model field-name set == checked-in snapshot,
  annotated `spec(§X)`) in its RED outline — implementer authors it in the same /tdd cycle; Step 2.5
  reviews it like any test.
- `skills/tasks-gen/SKILL.md`: note the seam-model snapshot requirement on cross-doc-tagged tasks; when
  seam models exist, tasks-gen seeds ONE Decisions-tabled entry: "full snapshot coverage (all Appendix-A
  models) — revisit off accumulated /phase-exit verdicts." (Judgment call: this is deliberate generated
  state with the user's approval — keep it to exactly one entry.)
- Cross-link: W2-6's arch-drift-auditor treats an anchor covered by a green snapshot as verified-by-test
  (cite + skip); a FAILING snapshot IS the finding (no re-derivation).

### W2-4 — hooks suite
- New `templates/.claude/settings.json` (PreToolUse wiring) + `templates/scripts/guards/`:
  - `git-guard.sh`: deny `git add -A` / `git add .` (all roles); deny `git push` when the session's
    `~/.claude/team-registry/<sid>.json` role == implementer.
  - `territory-guard.sh`: deny implementer Edit/Write to the orchestrator-territory paths; **no-op when no
    registry entry exists** (solo/generation sessions unaffected); deny message restates "flag it at
    Step 9 — the orchestrator writes it" and names the canonical list location.
  - `secrets-guard.sh`: `gitleaks protect --staged` when installed; warn-only regex fallback; ship a
    seeded `.gitleaksignore` template + document the fingerprint-ignore flow (TDD fixtures are FP-heavy).
  - **NO commit-requires-fresh-preflight gate** (would deadlock the documented session-end flow).
- **Territory list single-sourcing:** canonical human statement = `templates/area-CLAUDE.md` "must NOT
  touch" list, annotated "(mechanically enforced by a PreToolUse hook when generated)". scaffold-generate
  derives the guard's concrete path list from manifest values (TASK_TRACKER, ARCH_DOC, per-area
  LESSONS/CLAUDE.md) — recorded in the manifest. Trim `session-end.md` (line ~69 + §2.6 restatement) and
  the `tdd-brief-template.md` blockquote to pointers at that list. KEEP the point-of-action one-liners in
  `tdd.md` Step 10/Forbidden (they shape behavior before the hook fires).
- `GENERATE-WITH-CLAUDE.md`: reword the Step-13-area "Do NOT add any hook config" (~line 449) to scope it
  to context monitoring; add the settings.json+guards generation step (merge-don't-replace into any
  existing `.claude/settings.json`; manifest registration). The gitleaks default-on question rides W4-7's
  grouped gate-pack.
- Migrations: rides M-0006 (consolidated added-template, mode-aware, human-gated).

### W2-5 (gap G-5) — Step-2.5 quality backstop
- `templates/.claude/commands/tdd.md` Step 2.5: the write-up maps **each brief acceptance bullet → a
  covering test** (or an explicit "not-tested-because" note).
- `templates/docs/orchestrator-briefing.md` responsibility 5: `APPROVED.` means per-acceptance-bullet
  coverage was confirmed.
- (The advisory bullets-vs-tests count already lives in `spec-lint brief`, W2-2.)

### W2-6 — /phase-exit + arch-drift-auditor + the coordinated checklist edit
- **The coordinated checklist edit (BOTH tracker templates, one commit):** add machinery rows to the
  canonical "Phase exit checklist (template)" block — `Reachability audit clean per touched area
  (reachability-auditor)`, `Arch-drift audit clean over the phase's Spec anchors (arch-drift-auditor)`,
  `Spec coverage: every phase anchor has a tagged test or waiver (spec-lint tests <phase>)`. → migration
  M-0008 (new-required-section on the accreted tracker; M-0004 precedent). The W4 trio (audit/security/
  perf rows) lands later as one commit + M-0010.
- New `templates/.claude/commands/phase-exit.md` (orchestrator-side): strictly a **row→executor mapper**
  over the checklist AS WRITTEN in the generated `{{TASK_TRACKER}}` — never hardcodes rows. Executors:
  preflight per touched area; the two auditor fan-outs + security-reviewer when
  `{{SECURITY_REVIEW_POLICY}} = phase-boundary` (ONE message, parallel); script rows via Bash;
  "Commits pushed" row is VERIFY-only (push stays at /orchestrate-end). Per-row tick recorded in the
  tracker **as each row passes** (mid-gate auto-cycle resumes from the last ticked row); final
  CLEAR/BLOCKED verdict appended to the Log. Fan-out reports → `docs/audits/<phase>-<agent>.md`,
  ≤10-line summaries back. Guidance: dispatch /phase-exit at the START of a round, not appended to the
  end of one. `allowed-tools: Read, Grep, Bash, Agent, Edit` (Edit for the tracker ticks).
- New `templates/.claude/agents/arch-drift-auditor.md`: reads ONLY the phase's cited `Spec anchors:`
  sections of `{{ARCH_DOC}}` (targeted reads, never whole); diffs the contract's stated behavior/models
  against shipped code; a green snapshot test ⇒ verified-by-test (cite, skip); a failing snapshot IS the
  finding; mismatches route as Architecture-doc-note or **Finding**; read-only; born with the W1-6
  allowlist pattern (MCP names unconditional + fallback paragraph); model/effort tier: sonnet/xhigh
  (match reachability-auditor).
- Phase-boundary scope clause (pulled forward from W4-2): `templates/CLAUDE.md` reviewer-policy section —
  at `phase-boundary` the review surface is the **phase's accumulated branch diff + crossed trust
  boundaries** (for later phases of a track this over-approximates to the accumulated track diff — state
  it); add the matching relaxation line to `security-reviewer.md` ("when dispatched at a phase boundary,
  the surface is the phase diff, not a slice diff") and fix `agents/README.md` line ~29.
- `templates/.claude/agents/README.md`: add arch-drift-auditor to the inventory + the workflow diagram;
  counts become five.
- `templates/docs/orchestrator-briefing.md` + `orchestrate-end.md`: phase ticks happen only after a CLEAR
  /phase-exit verdict (or an explicitly waived row).
- Update `docs/audit/scaffolding-drift.md`: the "phase-exit has no executor" theme resolved.
- Migrations: phase-exit.md + arch-drift-auditor.md ride M-0006 (added-template; both modes — the
  orchestrator role exists in single-operator too); checklist rows are M-0008.

### W2-7 (gap G-4) — lessons / forbidden-pattern enforcement
- `templates/docs/orchestrator-briefing.md` Step-9 Convention-candidate row: every routed lesson records
  an enforcement line — `pin: <test ref>` | `pattern: <grep/ast-grep expr>` |
  `accepted: not mechanically enforceable`.
- `templates/area-CLAUDE.md` `[id=forbidden-patterns]` block: add a small machine-readable fenced
  sub-block (one grep/ast-grep pattern per line) inside the existing region.
- `templates/.claude/commands/preflight.md`: a **warn-level** (non-blocking) step grepping the staged diff
  against the pattern block; absent block ⇒ silent skip.
- Upgrade path: rides the existing region machinery (illustrative-block update auto-eligible; customized
  blocks PROPOSE). No new migration kind needed; note in the M-0006 doc.

---

## WAVE 3 — token/context

### W3-1 — root CLAUDE.md slim + three-state mode pruning + comm-rules sweep (gap G-6)
- `templates/CLAUDE.md` keeps: role table, naming/track-prefix + numbered-doc rule, escalation taxonomy,
  messaging budget + per-slice SendMessage sequence, magic-word headers, slice atomicity, canonical-
  context-source (no-self-report), and a **3-line phantom defense** (it is cross-role; team-protocol's
  lead notes point AT root). Becomes pointers: Close-out gating → **/orchestrate-end (canonical,
  exists in every mode)** + `docs/team-protocol.md` for the lead's auto-cycle mechanics (team only);
  Context monitoring mechanics → team-protocol + the script; the 18-line command list → a 3-line
  role-pairing note (the harness injects per-command descriptions).
- **Three-state mode pruning** (solo / team-single-track / team-multi-track — needed because W4-5 makes
  team-single-track the recommended solo default): template-only markers around mode-specific prose in
  `CLAUDE.md`, `team-protocol.md`, `tdd.md`, `session-end.md`, `orchestrator-briefing.md` (the
  multi-track carve-out), `team-start.md`/`team-end.md` (worktree steps). Markers are **stripped at
  generation** (never survive into generated files). The 3-state value is DERIVED from existing manifest
  fields (`mode` + `tracks[]`: single-operator | team+tracks==[] | team+tracks.length>0) — **no new
  manifest field needed**; record only that pruning was applied (a boolean) if useful.
- `skills/scaffold-upgrade/scripts/scaffold_upgrade.sh`: `build_tree`/substitute must REPLAY the mode
  pruning (derived from the manifest) when rebuilding base/ours — otherwise `theirs == base` fails for
  every pruned file and auto-apply breaks; `check-markers` learns pruning markers are template-only
  (absence in generated files is correct). Ship in the same commit as the template markers.
- Inbound cross-refs updated so pointers don't go circular: `team-protocol.md` header comment/intro/item 1
  (close-out home), `orchestrator-briefing.md` line ~19, `scaffolding-reference.md` command-list line ~80.
- Pruned solo-fallback sections in team mode (and vice versa) are replaced by a ONE-line pointer to the
  scaffolding repo, not deleted outright.
- **Comm-rules sweep (one canonical home per rule):** thresholds (70/75/80) canonical in
  `check-team-context.sh` env defaults — all prose copies (root CLAUDE.md, team-protocol, briefing,
  scaffolding-reference, SCAFFOLDING-GUIDE) state "WARN/ACTION/HARD-STOP per the script's env defaults"
  without hardcoding numbers, or cite once; the auto-cycle flow canonical in team-protocol.md; taxonomy/
  budget canonical in root. Fix `check-team-context.sh` internals while there: header `$TEAM` → `$TEAM_NAME`,
  document `--brief`, fix the "last 3 entries" comment (code does `tail -n 4`), recommendation strings use
  the env values instead of hardcoded "≥ 80%/75%/70%" (drift item 29).
- Migration: M-0009 (moved-section, human-gated) for the root-CLAUDE restructure; the pruning-replay
  script change ships simultaneously so upgrades stay coherent.
- Honest claim for docs: ~800–1.2k tokens/session on the always-loaded path, ×2 cycled roles per
  auto-cycle (the lead persists).

### W3-2 — playbook split (spine + stages + generated concat artifact)
- **Pre-step (before restructuring):** land the small Wave-4 playbook additions NOW so they ride the
  split — Phase 6 REQ-NF seed examples + PRD-citation column (W2-0 already did the citation), Phase 7
  perf-budget question, Phase 14 rows for supply-chain + performance (from W4-1/W4-3).
- Split `skills/arch-draft/references/architecture-planning-playbook.md` into:
  - `references/playbook-spine.md` (~300 lines): condensed philosophy, artifact-set tables (§2),
    mode/posture selection (§3), the tagging vocabulary, a phase index (one-line goal + stop condition +
    stage-file pointer per phase), and the CROSS-CUTTING §25 micro-prompts ("Interview the User",
    "Deepen a Thin Section") — these stay in the spine; phase-bound micro-prompts (Posture-Scoped
    Inference→P8, Decision Matrix→P11, Gap Audit→P15/16) fold into their owning stages.
  - `references/stages/stage-1..N.md` (4–6 files, e.g.: intake+mechanics / users+stakeholders+flows /
    domain+requirements+constraints+scope / assumptions+research+decisions / drafting+skeletons /
    handoff+diagrams+checklist). Large embedded skeletons (the 23-section draft skeleton, ADR template)
    become copy-from sections inside their stage files.
- `skills/arch-draft/scripts/build-playbook.sh` (new): deterministic concat (spine + stages in order) →
  regenerates `references/architecture-planning-playbook.md` as a GENERATED artifact with a DO-NOT-EDIT
  banner naming the sources (keeps the existing filename so `session-kickoff-prompt.md`'s attach path
  keeps working with minimal edits).
- `skills/arch-draft/SKILL.md` §1 step 2: "Read the spine end-to-end; read each stage file just-in-time as
  the interview enters it." `session-kickoff-prompt.md`: note the attached playbook is the concatenated
  artifact.
- `release-check.sh playbook`: rebuild + fail if the committed concat differs.
- Honest claim: benefit is reduced front-load + compaction resilience + 2–3KB re-reads; phases are NOT
  skipped in any mode.

---

## WAVE 4 — production gates

### W4-6 first — the checklist v2 trio lands as ONE commit (+ M-0010)
W4-1/2/3's checklist rows are a single edit to BOTH tracker templates + one shared new-required-section
migration ("phase-exit checklist v2"), each row carrying its posture-gating marker (manifest `posture`
field from W1-10 enables mechanical filtering at upgrade).

### W4-1 — dependency/supply-chain audit
- **NOT in base /preflight** (time-varying, network-dependent, unbounded output at every session-end).
- New `{{AUDIT_CMD}}` placeholder (§10 + Batch C + manifest; null when N/A).
- Checklist row (blocking): "Dependency audit clean, or accepted-risk recorded in Decisions tabled" —
  /phase-exit executor runs `{{AUDIT_CMD}}` ONCE, emits a one-line **new-vs-baseline** summary (baseline =
  seeded ignore/accepted-risk list), full output → `docs/audits/`; a **Finding** only for new items.
- Optional report-only run at /orchestrate-end close-out (same one-line form).
- (Playbook Phase-14 supply-chain row already landed in W3-2's pre-step.)

### W4-2 — whole-system security: ONE pass at the gate
- The checklist security row's executor RESOLVES from `{{SECURITY_REVIEW_POLICY}}`:
  - `phase-boundary` → the W2-6 security-reviewer dispatch (phase-diff scope) **IS** the whole-system
    pass; the row records its verdict. No second review.
  - `off`/`invariant`/`every-slice` → the row's default tool is Claude Code's built-in `/security-review`
    (reviews the branch's pending changes = the track worktree's accumulated diff); gstack `/cso` is the
    heavier escalation when installed and the phase carries trust-boundary anchors.
- Trigger: phases containing security-/invariant-tagged tasks or trust-boundary surfaces per
  `THREAT_MODEL.md` **when it exists** (Expanded mode only), else the architecture's risk/security anchors.
- Posture-gated (production-grade default), confirmed via W4-7. Critical findings → **Findings** escalation.

### W4-3 — performance threading (4 load-bearing artifacts; /perf DEFERRED)
- (Playbook Phase 6/7/14 edits landed in W3-2's pre-step.) Budgets are interview-elicited or PRD-derived
  ONLY — never model-invented.
- `skills/arch-finalize/SKILL.md`: 15th audit dimension — "missing performance budgets / unidentified hot
  paths"; absences bucket as **question-for-human**; "no budgets — deliberate deferral" is a recordable
  answer.
- `skills/tasks-gen/SKILL.md`: under production-grade, each budgeted hot path emits ONE discrete
  benchmark task (NOT a per-task scenario class; timing assertions stay OUT of the per-slice RED/GREEN
  loop — they're flaky; the benchmark task runs at its own cadence).
- Checklist row: "Perf budgets met, or regression flagged as a Finding."
- Benchmark/REQ-NF anchors are a named waiver class in `spec-lint tests` (W2-2).
- `/perf` command: NOT shipped — documented in the optional-command list as add-reactively.

### W4-4 — integration-branch preflight after track merges
- `templates/docs/team-protocol.md` "Working tree → tracks + worktrees" rule 2 (CANONICAL statement):
  after merging a track into the integration branch, run `/preflight` **in each code area touched by the
  merge**, from the integration checkout (collapses to one invocation for single-area projects); a
  failure blocks downstream merges and escalates as a **Finding**.
- `templates/.claude/commands/team-end.md` Step 6.6: one line citing that rule (per the existing
  "per docs/team-protocol.md" citation pattern).

### W4-5 — mode-guidance re-aim (TEAM IS THE DEFAULT — user-confirmed)
- `GENERATE-WITH-CLAUDE.md` §4: recommend the **team pattern for ALL projects, including solo
  developers** (a solo dev runs **team mode (single track)** — full 3-role team, one worktree); the
  single-operator fallback is reserved for environments where the agent-teams feature is unavailable.
  State its two concrete losses verbatim: (1) the human relays every Step-2.5/Step-9 exchange by hand;
  (2) no context monitoring or auto-cycle exists in solo mode.
- `README.md` "When to use this" (~line 245): rekey "Single-operator fallback: solo dev, fits in a
  sprint…" → "Single-operator fallback: environments without the agent-teams feature."
- `SCAFFOLDING-GUIDE.md` §3 "Single-operator fallback" + §13 step 1: same framing, identical wording for
  the two losses everywhere they're stated.
- (generate-procedure.md is a stub by now — no twin edit.)

### W4-7 — the grouped "production-grade gate pack" generation question
- `GENERATE-WITH-CLAUDE.md` (Batch E or a new §5 batch): ONE AskUserQuestion presenting the
  posture-derived recommended defaults with per-item opt-out — gitleaks hook (W2-4) · dependency-audit
  row (W4-1) · whole-system security row + `{{SECURITY_REVIEW_POLICY}}` (W4-2) · perf rows (W4-3) —
  pre-marked per the chosen Build posture, each answer recorded individually in the manifest. Replaces
  four separate confirmation gates; the always-ask rule is satisfied in one round-trip.

---

## WAVE 5 — documentation refresh + close-out (user-requested)

### W5-1 — SCAFFOLDING-GUIDE.md full refresh
Update to reflect everything: §4 file inventory (+`/phase-exit`, +`arch-drift-auditor`,
+`.claude/settings.json` + `scripts/guards/`, +`scripts/spec-lint.sh`, +`docs/audits/`); §6 command table
(+`/phase-exit`); §7 (Spec Anchor Index in the arch-doc description; tracker bounded-section rules);
§8 load-bearing mechanisms (+hooks enforcement, +seam snapshot tests, +spec tags & coverage gate,
+PRD→REQ coverage table, +the executed phase-exit gate, +the three-way close-out, lessons enforcement
line); §10 subagents (five starters; arch-drift-auditor row); §11 evolve rules (new file types; the
release-check + migration conventions); §12 limits (update: lesson↔code drift now warn-grepped; phase-exit
now executed; note what is still honest-gap). §3/§13 mode framing per W4-5. Threshold numbers per the
W3-1 canonical-home rule.

### W5-2 — README.md refresh
How-it-works flow + skills table (unchanged chain, but mention the executed phase-exit gate + hooks),
Tools & plugins table (built-in /security-review at phase boundaries), Quick start (team default wording),
"What's in the box" tree (+`scripts/release-check.sh`, +`tests/`, +`docs/plans/`), "When to use" rekeyed
(W4-5). Keep claims honest per the cost ledger.

### W5-3 — housekeeping
- `docs/audit/scaffolding-drift.md`: mark resolved items with one-line resolutions (at minimum: P0 #1–#4,
  P1 #6/#7, #22 journal-path docs, #29, the phase-exit theme); leave genuinely-open ones.
- `skills/ROUTING.md`: stage-8 security row now lands inside generated machinery (note built-in
  /security-review as default tool, /cso escalation); mention /phase-exit at stage 6/7 boundary.
- Verify `GENERATE-WITH-CLAUDE.md` §10 census number matches reality (`release-check census`).

### W5-4 — final gate
Run `scripts/release-check.sh all` (pairs, census, migrations, upgrade-dryrun, playbook). Fix anything
red. Produce a final summary for the user: per-wave commit list, migration inventory, what existing
projects get via `/scaffold-upgrade`, and the honest token ledger. **Do not push** — the user reviews
the branch and pushes.

---

## Sequencing summary

W1-2 → W1-1 → W1-10 → W1-9 → W1-3..W1-8 (any order) → Wave 2 (W2-0 → W2-1/W2-2 → W2-3 → W2-4 → W2-5 →
W2-6 → W2-7) → Wave 3 (W3-1 → W3-2 incl. pre-step playbook rows) → Wave 4 (W4-6 trio commit → W4-1/2/3
details → W4-4 → W4-5 → W4-7) → Wave 5. Run `release-check all` at each wave boundary. Every
tracker/architecture template edit honors the twin-pair rule; every generated-file change ships its
migration in the same commit.
