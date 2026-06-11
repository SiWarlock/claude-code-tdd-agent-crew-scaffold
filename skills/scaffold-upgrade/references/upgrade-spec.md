# `/scaffold-upgrade` — Final Buildable Spec

> Consolidates the three design reports (`upgrade-priorart.md`, `upgrade-mechanism.md`, `upgrade-skill.md`)
> into one buildable spec, adds the adversarial edge-case pass, a concrete build plan, and the open decisions.
> Finalized in the main loop after the design workflow's research + design phases completed (the synthesize/
> critique/finalize phases were lost to a machine shutdown; this doc replaces them).

---

## 1. Design summary

**Problem.** When you push scaffolding updates and pull them into a project that was already generated and
customized, there is no clean way to bring its scaffolding up to date without clobbering its `{{PLACEHOLDER}}`
values, its rewritten `EXAMPLE BLOCK` regions, or its accreted state (`LESSONS.md`, `IMPLEMENTATION_PLAN.md` living
sections, area-`CLAUDE.md` tables). The pre-`/scaffold-upgrade` answer — *"diff your generated files against the
current templates by hand"* — failed because a project's files differ from the templates for **two mixed
reasons**: real upstream upgrades **and** the project's own customizations. You can't mechanically separate
them from two sides alone.

**Solution (the copier/cruft pattern, as a Claude skill).** Stamp a **provenance manifest** into every
generated project recording the scaffolding commit it came from + the placeholder values + a file/template
ledger. That gives the merge a recoverable **common ancestor**, turning the problem into a true **3-way merge**:

```
base   = OLD templates @ manifest.generatedFromSha, re-substituted with the stored values
ours   = NEW templates @ HEAD,                      re-substituted with the SAME stored values
theirs = the project's files on disk
```

Where `theirs == base` (the project never touched a file), `ours` wins automatically. Where the project
customized, the diff is **bounded and reviewed**, never blind-overwritten. A bundled **bash+jq script** does the
deterministic git/substitution/merge work; the **model** does classification edges, the conflicts git can't
resolve, the structural migrations, and the two human-review gates.

**Grounding (prior art).** copier (`copier update`) and cruft (`cruft update`) solve exactly this with a stored
`.copier-answers.yml`/`.cruft.json` (template ref + answers) + re-render-and-3-way-merge. projen's lesson: a hard
**machine-owned vs human-owned partition** shrinks the merge surface. gstack's lesson: **version-gated,
idempotent, journaled migrations** for state a text-diff can't express. We borrow all three; we avoid cruft's
`.rej` litter (use inline `<<<<<<<` markers) and projen's blind-overwrite (never re-render over customized files).

---

## 2. The mechanism (provenance stamping)

### 2.1 Manifest — `.scaffolding/manifest.json` (committed, machine-owned, never hand-edited)

Records, at minimum:
- **Provenance:** `schemaVersion`, `scaffoldingRepo`, `generatedFromSha` (full 40-char), `generatedFromRef`,
  `generatedAt`, `lastUpgradedFromSha` (null at bootstrap), `lastUpgradedAt`.
- **Shape-determining choices:** `mode` (team|single-operator), `track`, `optionalCommands`, `optionalSubagents`
  — so an upgrade never tries to merge a file the project legitimately never had.
- **Resolved values:** `placeholders{}` + per-area `codeAreas[]` (exactly the §10 manifest, filled) — the key
  to re-substituting both old and new templates.
- **`generatedFiles[]`:** one row per written file — `{dest, template, kind, area?}`. The spine of the merge.
- **`exampleBlocks[]`:** one row per EXAMPLE BLOCK region — `{file, id, status: customized|illustrative}`.

Companion `.scaffolding/README.md`: 6 lines — "generator-owned, do not hand-edit, rewritten by upgrades, see
SCAFFOLDING-GUIDE §11."

### 2.2 The four file `kind`s (drive merge aggressiveness)

| `kind` | Examples | Merge rule |
|---|---|---|
| `verbatim` | `tdd.md` 10 steps, Step-9 routing, escalation taxonomy, commit cadence | AUTO-APPLY iff `theirs == base` (provably untouched) → take `ours`. Else PROPOSE with a loud "you diverged from verbatim machinery" flag. |
| `placeholder-only` | `preflight.md`, `wired.md`, single-area `run-tests.md` | AUTO-APPLY iff `theirs == base` (provably untouched). A clean-but-diverged 3-way is a low-risk PROPOSE (`propose-clean`) — never a silent write; a conflict is a PROPOSE too. |
| `mixed` | `CLAUDE.md`, `area-CLAUDE.md`, `orchestrator-briefing.md` | Per-region split: machinery + `illustrative` blocks → auto-eligible; `customized` blocks → PROPOSE-ONLY, never clobber. |
| `accreted` | `LESSONS.md`, `IMPLEMENTATION_PLAN.md` living sections, area-`CLAUDE.md` tables | **LEAVE ALONE.** Body never touched. Only skeleton/format changes are PROPOSE suggestions; body rewrites only via an explicit `accreted-format` migration. |
| `user-canonical` | the user's `{{ARCH_DOC}}` | Out of scope. Only the appended Appendix A skeleton is a PROPOSE candidate. |

### 2.3 Generator changes (`GENERATE-WITH-CLAUDE.md`)
- **New Step 12.5** — stamp `.scaffolding/manifest.json` + README (additive; no interaction; records decisions
  already made). Build `generatedFiles[]`/`exampleBlocks[]` **incrementally** as each file is written.
- **One-line bookkeeping hooks** in §6 (plan), §7 steps 1/2/6/7/8/9/10/11 (append a ledger row), §10 (placeholders
  == manifest values).
- **One-time template edit:** add stable `[id=<slug>]` to all **26 EXAMPLE BLOCK markers across 12 files**, and
  normalize the single-line self-closing form to the paired open/close form so every region has a
  machine-detectable boundary. Non-breaking (slug lives inside the existing comment).

### 2.4 Retro-stamping existing (manifest-less) projects
A `SCAFFOLDING-GUIDE §11` recipe, run once per existing project by a fresh session:
- **R1 — recover values + mode** by reverse-reading generated files (mode from team-protocol.md presence;
  placeholders from `CLAUDE.md` H1, filenames, per-area stack tables + resolved `{{TEST_CMD}}` etc. in command
  bodies).
- **R2 — recover `generatedFromSha`**, in priority order: (A) ask the user; (B) git-history date-bound (project
  bootstrap commit date → newest scaffolding commit at/before it); (C) verbatim-machinery fingerprint (un-substitute
  placeholders, match against the small set of commits where machinery changed). Record a `baseConfidence` marker.
- **R3 — write + commit** `retroStamped: true` manifest. From here it upgrades like a fresh project.

---

## 3. The skill (`/scaffold-upgrade`)

**Identity.** `/scaffold-upgrade [--check] [--from <sha>] [--to <ref>] [--auto]` — a skill (a prompt Claude
executes), run from a **fresh standalone session** pointed at the project (cwd) + a scaffolding checkout. It is
**not** a team-role command, does not run inside `/tdd`, writes no project STATE. It **lives in the scaffolding
repo and is always run from the current checkout — it is NOT vendored into projects** (so the upgrade logic
itself never goes stale in a project).

**Prime directive.** Project files are **user-owned**. There is no "re-render over the top." The ONLY files
written without explicit human confirmation are `verbatim`/`placeholder-only` files that are **provably untouched**
(`theirs == base`). Everything customized is PROPOSE-ONLY.

**Phase ladder:**
```
PRECHECK   (report-only)  resolve base/to · idempotency short-circuit · clean-tree gate · upgrade branch
   │  (no manifest → LEGACY: retro-stamp, or heuristic fingerprint base + force-PROPOSE)
DIFF       (SCRIPT)        rebuild base+ours by re-substitution · 3 diffs/file · template-set delta → plan.json
CLASSIFY   (SCRIPT+MODEL)  policy per file & per mixed-region; model adjudicates edges
MIGRATE-SEL(SCRIPT)        topological window (base,to] · idempotency pre-checks → ordered migration list
DRY-RUN    (MODEL)         report grouped by KIND + HIGH/MED/LOW risk; --check exits here
══ PAUSE 1 ══              plan-approval: approve all / selectively / inspect / abort  [--auto skips ONLY auto-apply group]
APPLY      (SCRIPT+MODEL)  write files · inline <<<<<<< conflict markers · run migrations (journaled, idempotent)
══ PAUSE 2 ══              pre-commit review: show diff; BLOCK on unresolved markers; no commit without approval
STAMP+COMMIT(SCRIPT+MODEL) advance lastUpgradedFromSha · refresh ledgers · append upgrade-log · one explicit-add commit
DONE                       "What's New" CHANGELOG summary; human pushes
```

**Two PAUSE gates** mirror the scaffolding's own discipline (`GENERATE-WITH-CLAUDE §6` plan-approval, §8
pre-commit) and are **not overridable** by a "work without stopping" instruction (same rule as `/tdd` Step 2.5).
`--auto` skips PAUSE 1 *only for the provably-untouched auto-apply group*; PROPOSE + migrations always stop.

**Migration registry** (in the scaffolding repo, travels with the templates):
`migrations/registry.json` + `M-NNNN-*.md`, SHA-window-gated (`base < introducedAtSha <= to`), seven kinds —
`renamed-placeholder`, `moved-section`, `new-required-section`, `renamed-template`, `deleted-template`
(PROPOSE-only, never auto-delete), `added-template` (mode/optional-filtered), `accreted-format` (the only path
allowed to rewrite accreted bodies — human-gated, idempotent, sampled). Idempotent + journaled
(the `.scaffolding/.migrations/<id>.done` touchfile the script checks; multi-step migrations may also keep per-step markers under `.scaffolding/.migrations/<id>/`) + append-only (a buggy migration is fixed by a NEW one, never edited in place)
+ per-migration failure is non-fatal.

**Script vs model split.** `scaffold_upgrade.sh` (bash+jq) does `resolve`/`substitute`/`diff`/`migrations`/
`apply`/`stamp` — deterministic, re-runnable, makes no judgment. The model adjudicates classification edges,
resolves the conflicts git can't (drafting merges from both sides + intent — the one thing a skill beats a CLI
at), runs prose migrations, presents the dry-run, drives the gates, and authors the commit.

---

## 4. Adversarial edge-case pass

| # | Edge case | Handled? | How |
|---|---|---|---|
| 1 | **Placeholder renamed upstream** | ✅ | `renamed-placeholder` migration rewrites the manifest key (preserving value); re-keys `codeAreas[]`; idempotent. |
| 2 | **Project hand-edited "verbatim" machinery** | ✅ | `theirs != base` demotes the file from AUTO-APPLY to PROPOSE with a loud divergence flag; human decides keep-fork vs adopt-upstream. The core clobber-guard. |
| 3 | **User damaged/deleted an EXAMPLE-BLOCK marker in their copy** | ✅ *(added rule)* | If region parsing of `theirs` fails to find a block's boundaries, the file degrades to **whole-file PROPOSE** (never auto-apply); the model surfaces "couldn't locate block boundaries in your copy — review the whole file." Never silently mis-merge. |
| 4 | **Accreted state must survive a structural template change** | ✅ | `accreted` = LEAVE ALONE; only an explicit human-gated, idempotent, sampled `accreted-format` migration may touch the body. |
| 5 | **Template deleted / renamed / added upstream** | ✅ | `deleted-template` (PROPOSE, never auto-delete; record `divergence` if kept), `renamed-template` (git mv + grep-and-update reference ripple), `added-template` (mode/optional-filtered). |
| 6 | **Multi-area project, single-area template changed** | ✅ | `generatedFiles[]` rows carry `area`; one template change fans out to N area files, each 3-way-merged with that area's `codeAreas[]` set; `exampleBlocks[]` is keyed by dest path so per-area customization is tracked independently. |
| 7 | **Merge conflict in a file** | ✅ | Inline `<<<<<<< ======= >>>>>>>` markers (copier default, never `.rej`); model drafts a resolution; PAUSE 2 **blocks the commit** while any marker remains. |
| 8 | **Unstamped legacy project** | ✅ | Retro-stamp (preferred) or heuristic fingerprint base + **force every file to PROPOSE** (no auto-apply without a trustworthy base); accreted still left alone; writes a real manifest on success. |
| 9 | **Mid-build with uncommitted work** | ✅ | Clean-tree gate on scaffolding-managed paths only — stop & ask to commit/stash; dirty *project source* paths are fine and untouched. |
| 10 | **Scaffolding base SHA gone / repo moved** | ✅ | `--from` override; `fetch --unshallow`/`fetch origin <sha>`; fingerprint-base fallback with `baseConfidence` marker; scaffolding path is passed in args so a moved remote is irrelevant. |
| 11 | **New REQUIRED placeholder introduced upstream** | ✅ *(added rule)* | During `ours` substitution, any `{{TOKEN}}` with no manifest value → **STOP and ask the user** (never leave an unresolved `{{TOKEN}}` in the project, never fabricate — `GENERATE-WITH-CLAUDE` Rule 2). The new value is written back to the manifest. |
| 12 | **Stacked upgrades / skipped versions** | ✅ | Topological window `(base, to]` selects all intervening migrations in commit order; each fires exactly once. |
| 13 | **Manifest schema older than the skill** | ✅ *(added rule)* | A manifest-schema migration runs **first**, upgrading the manifest to current schema before any file work. (Skill-older-than-manifest already handled: §1.1 stops and tells the user to update the skill.) |
| 14 | **Interrupted upgrade (context exhausted / session closed mid-apply)** | ✅ | Nothing is committed until the very end; migration journals resume; AUTO-APPLY is `theirs==base`-gated (false once applied); conflict-marker files are re-detected, not re-merged. Re-running is safe. |
| 15 | **Conflict markers accidentally reach the commit** | ✅ *(added rule)* | Before STAMP+COMMIT the script greps all written files for `^<<<<<<<` / `^>>>>>>>`; any hit hard-blocks the commit at PAUSE 2. |

**Net:** the design's default posture is **propose-don't-clobber** everywhere customizations or accreted state are
involved, and **lower base-confidence ⇒ more gating, never more auto-apply.** The three added rules (#3, #11, #13,
#15) close the gaps the lost critique phase would have surfaced.

---

## 5. Build plan (ordered, concrete)

Ship incrementally so you can dogfood the safe read-only parts first.

**Phase 1 — Enablement (low-risk, unblocks everything).**
1. `templates/**` — add stable `[id=<slug>]` to all 26 EXAMPLE BLOCK markers across the 12 files; normalize
   single-line markers to paired open/close. *(One mechanical, non-breaking edit pass.)*
2. `GENERATE-WITH-CLAUDE.md` — add **Step 12.5** (stamp manifest), the §6/§7/§10 bookkeeping hooks, add
   `.scaffolding/` to the documented generated structure, and document the manifest schema.
3. `templates/.scaffolding/README.md` — the do-not-edit companion note (templated).

**Phase 2 — The read-only skill (safe to dogfood: `--check` + dry-run, no writes).**
4. `scaffold-upgrade/SKILL.md` — PRECHECK · DIFF · CLASSIFY · MIGRATE-SELECT · DRY-RUN · `--check`.
5. `scaffold-upgrade/scripts/scaffold_upgrade.sh` — `resolve` / `substitute` / `diff` / `migrations` subcommands
   (bash + jq + git; matches your existing script toolchain — no new dependency).

**Phase 3 — Apply + gates (the write path).**
6. Extend the skill with PAUSE 1 · APPLY (inline conflict markers) · PAUSE 2 · STAMP+COMMIT, and the
   `scaffold_upgrade.sh apply`/`stamp` subcommands.

**Phase 4 — Migration registry.**
7. `migrations/registry.json` (seeded empty) + `migrations/_TEMPLATE.md` + the seven-kind handlers in the skill.

**Phase 5 — Legacy + docs.**
8. `SCAFFOLDING-GUIDE.md §11` — rewrite to document the new upgrade path + the retro-stamping recipe (replacing
   the "diff by hand" admission). Add the retro-stamp flow to the skill's LEGACY branch.

---

## 6. Open decisions for the user

1. **Retro-stamp existing projects now, or stamp-on-first-upgrade?** Recommend: a one-time retro-stamp pass on
   any *actively-developed* project (cheap, gives a durable anchor); let dormant ones stamp lazily on first upgrade.
2. **`--auto` default.** Recommend: default OFF (always PAUSE 1) for the first several real upgrades; enable
   `--auto` (skip PAUSE 1 for provably-untouched verbatim/placeholder only) once you trust it.
3. **Manifest location.** Recommend `.scaffolding/manifest.json` (room for the README + journals + upgrade-log).
   Alternative: a single `.scaffolding-manifest.json` dotfile.
4. **Skill is scaffolding-repo-resident, not vendored** (recommended, above). Confirm you're OK running
   `/scaffold-upgrade` from a scaffolding checkout pointed at the project, rather than as a per-project command.
5. **Script language:** bash + jq (recommended — matches `check-team-context.sh`/`statusline`; zero new deps) vs
   a bun/TS tool like gstack. Bash keeps it dependency-free and in-toolchain.
6. **Build sequence:** the incremental Phase 1→5 above (recommended — dogfood `--check` early) vs all-at-once.

---

*Reports consolidated: `upgrade-priorart.md`, `upgrade-mechanism.md`, `upgrade-skill.md`. This file is the
canonical spec.*
