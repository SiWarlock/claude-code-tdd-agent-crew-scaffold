# Scaffolding drift & inconsistency findings

> Captured 2026-06-05 from a full end-to-end read of every file in the repo (orientation pass).
> These are **documentation drift, naming inconsistencies, count mismatches, and stale-tense design docs** — mostly non-breaking, but each is a maintenance hazard or a source of confusion / token waste. Line numbers are approximate (from cluster digests); verify before acting. Grouped by priority, then by file.
>
> This is a backlog for a later deeper-dive cleanup pass, NOT the context-optimization work itself (that is tracked separately).

---

## P0 — Load-bearing or merge-affecting

1. **scaffold-upgrade base-resolution drift.** `references/upgrade-skill.md §1.2` (PRECHECK) resolves `base = --from ?? generatedFromSha` (omits `lastUpgradedFromSha`), but `§7`, the `§11` deliverables table, and `references/upgrade-mechanism.md §4` say `base = --from ?? lastUpgradedFromSha ?? generatedFromSha`. Taken literally, §1.2 would make a *second* upgrade recompute from the original generation SHA and re-offer everything already applied. The shipped `scripts/scaffold_upgrade.sh` (`cmd_resolve`) **correctly** uses `lastUpgradedFromSha ?? generatedFromSha` — so the §1.2 prose is the stale copy. **Fix:** correct §1.2.

2. **placeholder-only merge-rule contradiction.** `references/upgrade-spec.md §2.2` says placeholder-only files "AUTO-APPLY if 3-way clean"; `SKILL.md §4` requires `theirs == base` and demotes a clean-but-diverged 3-way to a PROPOSE. `SKILL.md`'s "prime directive governs" note resolves it (stricter wins), and the script enforces the strict rule. **Fix:** reword the spec line so it doesn't read as a license to auto-apply diverged files.

3. **`Spec Anchor Index` prescribed but missing from the template.** `arch-finalize/SKILL.md §1/§5` require the finalized `ARCHITECTURE.md` to carry a "Spec Anchor Index," and `tasks-gen` reads it — but `arch-finalize/references/architecture-template.md` (and `templates/ARCHITECTURE.md`) have **no Spec Anchor Index section** in the skeleton (only `§<N>` anchors + Appendix A). **Fix:** add the section to both templates, or drop the requirement. **RESOLVED 2026-06 (W1-3):** the section (REQ → implementing § table, adjacent to Appendix A, scale-down comment) now ships in both templates; pair identity enforced by `scripts/release-check.sh pairs`.

4. **tasks-gen test-scenario drift.** `tasks-gen/SKILL.md §2` mandates every task carry happy/edge/error/integration **test scenarios** (which "become the Step-2.5 test designs"), but the `references/implementation-plan-template.md` task `EXAMPLE BLOCK [id=task-entry-format]` shows only acceptance behaviors + `Files:` + `Cross-doc invariant:` — no test-scenario scaffold. An author following the template literally omits what the skill requires. **Fix:** add the test-scenario bullets to the template block (or reconcile the skill).

5. **Migration registry is empty + dormant.** `migrations/registry.json` `migrations[]` is `[]`; the entire structural-migration path (`scaffold_upgrade.sh migrations`, the 7 kinds, journaling) has **never executed**. First real migration exercises this code for the first time. **Action:** flag for a deliberate test/dry-run before relying on it.

---

## P1 — Duplication (token cost + drift risk)

6. **The 1831-line playbook + 86-line kickoff prompt are byte-identical in two places.** `docs/archive/DEEP_AGENTIC_ARCHITECTURE_PLANNING_PLAYBOOK.md` == `skills/arch-draft/references/architecture-planning-playbook.md`; `docs/archive/START_..._PROMPT.md` == `skills/arch-draft/references/session-kickoff-prompt.md` (confirmed via `diff`). The archive copies are reference-only, but editing one without the other silently diverges. **Fix:** delete the archive copies (the `archive/README.md` already records provenance), or add a "this is a frozen snapshot; live copy at …" banner.

7. **`GENERATE-WITH-CLAUDE.md` (root) vs `skills/scaffold-generate/references/generate-procedure.md`.** The skill says its reference "IS GENERATE-WITH-CLAUDE.md." Two near-identical ~596-line generation procedures. **Action:** confirm whether they are duplicates and, if so, make one canonical and have the other point to it (or symlink).

8. **Shared team-comm rules restated across ≥4 files.** The role table, escalation taxonomy, messaging budget, and thresholds (70/75/80) appear in `templates/CLAUDE.md`, `templates/docs/team-protocol.md`, `templates/docs/orchestrator-briefing.md`, and `templates/docs/scaffolding-reference.md`. Only the env-var *names* are factored out; the prose numbers are copied. Changing a default means editing ≥3 prose copies. (The Step-9 routing matrix is the one thing done right — canonical in `orchestrator-briefing.md`, others point to it.) **Fix:** pick one canonical home per rule; others point. (Overlaps with the context-optimization work.)

9. **Lesson stable-ID rule stated in 3 places** (`templates/CLAUDE.md`, `templates/area-CLAUDE.md`, `templates/area-LESSONS.md`) with slightly different wording.

10. **Cross-doc-invariant discipline duplicated** across `templates/ARCHITECTURE.md` leading comment, `templates/area-CLAUDE.md` session-end protocol, and `area-CLAUDE.md` "Cross-doc invariants" section.

11. **Magic-words reply protocol (`APPROVED.`/`TWEAK:`/`ADD:`) defined in both** `templates/.claude/commands/tdd.md` Step 2.5 and `templates/CLAUDE.md` "Inter-teammate messaging." Intentional, but must stay in sync.

12. **scaffold-upgrade design docs restate each other.** `upgrade-mechanism.md` and `upgrade-skill.md` both contain the 3-way-merge framing, the five kinds, and retro-stamping; `upgrade-spec.md` consolidates all three. Edits must touch multiple files.

---

## P2 — Naming / count / tense inconsistencies

13. **Planning-mode middle name:** `arch-draft/SKILL.md` calls it **"Default"**; `session-kickoff-prompt.md` and the playbook `§3` call it **"Standard."** A user pasting the kickoff prompt asks for a mode the SKILL table doesn't name.

14. **Draft artifact name:** `arch-draft/SKILL.md` mandates emitting `ARCHITECTURE_DRAFT.md`; the kickoff prompt's Goal list + playbook `§1.3` call it `ARCHITECTURE.md` (while the rest of the playbook also uses `ARCHITECTURE.md`). Downstream skills key off the name.

15. **Questioning cadence:** `arch-draft/SKILL.md §0` says "one topic per question"; kickoff prompt + playbook say "focused batches." Softer guidance in the human-paste artifact.

16. **ROUTING.md stage numbers:** header prose calls `IMPLEMENTATION_PLAN.md` "stage 5" but the happy-path table puts tasks-gen at stage 4, scaffold at stage 5. Footer says "16-stage" but there's an extra unnumbered sub-row.

17. **Command-count framing:** `GENERATE-WITH-CLAUDE.md §1` / `scaffold-generate` say "12 team / 9 single-operator; +2 optional," but the ordered Step-10 list names 11 + context-check implicitly. Arithmetic is loose across §1/§4/Step-10.

18. **Subagent starter count:** README says an "opt-in starter set of **four**" and "opted out of all four," but only **3 are Active** — `brief-drafter` ships Deferred (definition-only, quality-trial-gated). A clean bootstrap wires up 3.

19. **`/tdd` "10 steps" is really 13 stops** (Step 0, 2.5, 7.5). Nomenclature throughout says "10-step."

20. **bug-hunt mode names:** front-matter "in-build/incident," body "Build/Incident," procedure "Mode A/Mode B."

21. **scaffold-upgrade count slips:** `upgrade-spec.md §2.2` heading "the four file kinds" lists five; `§4` "three added rules (#3, #11, #13, #15)" lists four; `SKILL.md §4` correctly says "five."

22. **scaffold-upgrade migration-journal path:** `SKILL.md §5` = `.scaffolding/.migrations/<id>.done` (touchfile); `upgrade-spec.md §3` / `upgrade-skill.md §6.3` = `.scaffolding/.migrations/<id>/` (directory). The script (`cmd_migrations`) uses the **touchfile** form `.scaffolding/.migrations/<id>.done`. **Fix:** make the docs match the script.

23. **scaffold-upgrade skill name:** `upgrade-mechanism.md §4` refers to a future `/upgrade-scaffolding`; everything else is `/scaffold-upgrade`.

24. **scaffold-upgrade design docs read as forward-looking but the work is done.** `upgrade-mechanism.md`/`upgrade-skill.md` describe Step 12.5 + the "24 slugged EXAMPLE BLOCK markers" as changes "to be made," yet the templates already carry `[id=…]` slugs and Step 12.5 exists. **Fix:** update tense, or fold into the spec and archive the design docs.

25. **`renamedExampleBlock` / `removedExampleBlock`** referenced in `upgrade-skill.md §3.1` but not listed among the 7 migration kinds in `§6.2` — an implied 8th concern with no kind row.

26. **learn-site serve command:** `SKILL.md §6` = bare `python3 -m http.server`; playbook = `python3 -m http.server -d docs/learn-site 8000`.

27. **Phase-naming in the playbook:** kickoff + §0 say "Phase 0: Intake and Planning Mode Selection," but actual `§4` heading is "Phase 0 — Intake and Initial Read" with Mode Selection as a separate `§3`. Also Phase N = Section N+4 offset throughout.

28. **Two Phase-0 intake lists:** standalone prompt lists 13 items; playbook `§4` lists 14 (splits risk into technical/product/demo).

---

## P3 — Smaller flags

29. **`templates/scripts/check-team-context.sh`:** header USAGE says auto-detect uses `$TEAM` but code reads `$TEAM_NAME`; `--brief` is implemented but undocumented in the header; comment says "last 3 entries" but code does `tail -n 4`; human-mode recommendation strings hardcode "≥ 80% / 75% / 70%" though thresholds are env-configurable; status-bar color ladder (70/90) differs from monitoring ladder (70/75/80).

30. **`templates/.claude/commands/team-start.md`** Cycle protocol references "Step 6 of this command," but the file has no Step 6 (ends at Step 5).

31. **`{{TEST_CMD_SINGLE_FILE}}`** is used in `tdd.md` but omitted from that file's TEMPLATE NOTE fill-list (which lists only `{{TEST_CMD}}`/`{{TYPECHECK_CMD}}`/`{{LINT_CMD}}`).

32. **`wired.md` TEMPLATE NOTE** says "Fill placeholders" but the file has no `{{…}}` placeholders.

33. **`run-tests.md`** embeds `{{TEST_CLASSES}}` inside YAML frontmatter (generator must substitute in frontmatter, not just body); is the only command with no "Forbidden" section; allowed-tools is `Bash` only (no `Read`), unlike siblings.

34. **arch-finalize `allowed-tools`** (and bug-hunt, tasks-gen) omit `mcp__*` tools though their bodies recommend CodeGraph/Context7 — works only because MCP is granted ambiently.

35. **README subagent "file shape" skeleton** shows `tools: Read, Edit, Write` + `model: sonnet`, but all 4 shipped definitions are read-only (`Read, Grep, Bash`) and 3/4 are `model: opus`. `effort: xhigh` is in all 4 frontmatters but absent from the skeleton.

36. **agents README workflow diagram** lists the Step 7→8 reviewer fan-out *then* Step 7.5 reachability *then* Step 8 — non-monotonic step order; could misread fan-out vs reachability ordering.

37. **`code-quality-reviewer` "don't double-cover" vs both-mandatory.** It defers safety-invariant slices to `security-reviewer`, yet on invariant-touching slices **both** are mandatory; the real boundary is "security covers safety axes, code-quality covers the rest," not "only one runs."

38. **eval-triage:** `"Diagnosis patterns (corrected)"` has a vestigial "(corrected)"; taxonomy D has a `"no/var wrong tool call"` typo; the playbook file is the one uncommitted (`M`) file in the tree; interview-framing ("reads as senior") leaks throughout.

39. **layer-docs:** `lastRun` field appears only in the playbook's state-file schema (not SKILL.md), role vs `generatedAt` under-specified; no schemaVersion-mismatch behavior defined.

40. **Manifest schema:** the Step 12.5 example omits the `shaUnknown`/`note` keys (described only in prose); `generatorModel`/`generatedFromRef`/`lastUpgradedAt` appear in the schema example but not in `scaffold-generate/SKILL.md §4`'s field list.

---

## Notes for the deeper dive

- Several of these (P1 #6–#12, #8 especially) overlap directly with the **context/token-optimization** effort: de-duplicating restated rules both removes drift risk *and* cuts tokens loaded into every session.
- The "design doc tense" issues (#24) suggest a one-time pass to retire `upgrade-mechanism.md`/`upgrade-skill.md` into the spec now that the feature is built, leaving `upgrade-spec.md` + `SKILL.md` + the script as the canonical trio.
- Nothing here is a correctness bug in shipped behavior; the bash scripts and the SKILL operational instructions are internally consistent — the drift is between **design/reference prose** and the **operational truth**.

## Update 2026-06-07 — task-tracker rename + build-posture axis + optional demo

- **`MVP_TASKS.md` → `IMPLEMENTATION_PLAN.md`** (the `{{TASK_TRACKER}}` default flipped). The rename swept the
  **duplicated surface** flagged in P1 #7 (`GENERATE-WITH-CLAUDE.md` ≡ `generate-procedure.md`) and the
  near-duplicate tracker templates (P1 / template pair) — both kept byte/structure-in-sync, **not de-duped**
  (the de-dupe refactor in #7 is still open). A new **`renamed-template` migration `M-0003`** propagates the
  rename to already-generated projects (`introducedAtSha` still **PENDING** — must be wired to the shipping
  commit, the same two-step `a939bd0` used for M-0001/M-0002).
- **Optional Demo phase** added one EXAMPLE BLOCK (`optional-demo-phase`) to the tracker template → the
  authoritative §10 census in `GENERATE-WITH-CLAUDE.md` is now **25 regions** (was 24), and the present-tense
  census in `upgrade-mechanism.md` was bumped to 25 / `IMPLEMENTATION_PLAN.md×3`. The **historical** "one-time
  edit added `[id=]` slugs to **24** markers" statements (`upgrade-spec.md`, `upgrade-mechanism.md §change-summary`)
  are intentionally **left at 24** — they describe a completed past action, not the current count. (New drift
  surface; resolve when #24 retires those design docs.)
- **Build posture** is a new, always-confirmed axis threaded arch-draft → handoff → `ARCHITECTURE.md` exec
  summary → arch-finalize gap audit → tasks-gen. Recorded as a fill-in stub (`<production-grade | MVP/prototype>`),
  **not** a `{{PLACEHOLDER}}` — so no manifest/§10 placeholder-manifest change was needed.
