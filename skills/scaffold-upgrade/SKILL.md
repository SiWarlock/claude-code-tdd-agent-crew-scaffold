---
name: scaffold-upgrade
description: >-
  Bring an already-generated, already-customized project's agent-team scaffolding up to date with the
  current templates via a provenance-manifest 3-way merge — WITHOUT clobbering placeholder values,
  customized EXAMPLE BLOCK regions, or accreted state (LESSONS.md, IMPLEMENTATION_PLAN.md living sections). Runs on
  Claude Code from a scaffolding-repo checkout pointed at the target project; never vendored into projects.
  A bundled bash+jq script does the deterministic git/substitution/merge work; this skill adjudicates
  classification edges, drafts the conflicts git can't, runs structural migrations, and drives two human
  gates. Invoke when the user says "upgrade the scaffolding", "update this project's scaffolding",
  "scaffold-upgrade", "check the scaffolding for drift", or after pulling new scaffolding templates.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Task
---

# scaffold-upgrade — keep a project's scaffolding current via 3-way merge

The counterpart to `scaffold-generate`. Where generate writes the harness fresh, **upgrade** re-derives it
against a recoverable common ancestor and merges only what changed upstream, **never clobbering** what the
project customized. It keeps an already-generated project's slash commands, layered `CLAUDE.md`, briefing
docs, and machinery current as the scaffolding templates evolve.

**You run from a scaffolding-repo checkout, pointed at the target project (its repo root is the cwd).** You
are **not** a team-role command, you do **not** run inside `/tdd`, and you write **no** project STATE. The
skill is **never vendored into projects** — always run it from the current scaffolding checkout so the
upgrade logic itself never goes stale inside a project.

**Prime directive — project files are user-owned.** There is no "re-render over the top." The ONLY files
written without explicit human confirmation are `verbatim`/`placeholder-only` files that are **provably
untouched** (`theirs == base`). Everything the project customized is **PROPOSE-ONLY**. Lower base
confidence ⇒ MORE gating, never more auto-apply.

---

## 0. Read the bundled spec first

`references/upgrade-spec.md` is the **canonical buildable spec** — read it fully before acting. Deeper
detail lives in the bundled siblings: `references/upgrade-mechanism.md` (manifest schema + retro-stamping
R1/R2/R3 + the per-file EXAMPLE-BLOCK map), `references/upgrade-skill.md` (full phase + migration
mechanics, the `registry.json`/commit shapes), `references/upgrade-priorart.md` (copier/cruft/projen/gstack
prior art). These are bundled so the skill is self-contained — do **not** depend on `workflow-analysis/`.

---

## 1. Inputs, args, and the bundled script

**Two inputs:**
1. **The target project** — the cwd (its repo root), which must contain `.scaffolding/manifest.json` (stamped
   by `scaffold-generate` Step 12.5). No manifest → the **LEGACY** path (§7).
2. **A scaffolding checkout** at the version to upgrade *to* (defaults to that checkout's `HEAD`). Passed in
   by path, so a moved/renamed remote is irrelevant.

**Args:** `/scaffold-upgrade [--check] [--from <sha>] [--to <ref>] [--auto]`
- `--check` — drift-detection only (the `cruft check` analog). Runs PRECHECK→DRY-RUN, reports "N commits /
  M files behind," exits before any mutation. **Safe in CI.**
- `--from <sha>` — override the base SHA (escape hatch when the manifest SHA is wrong/missing).
- `--to <ref>` — upgrade to a tag/branch/SHA rather than scaffolding `HEAD`.
- `--auto` — let the AUTO-APPLY group write without PAUSE 1, **for provably-untouched verbatim/placeholder
  files only**; PROPOSE + migrations still gate. **Off by default.**

**The bundled script** `scripts/scaffold_upgrade.sh` (bash + jq + git — no new deps; matches the existing
`check-team-context.sh`/statusline toolchain) does the deterministic work via self-contained subcommands:
`resolve` · `substitute <ref> <out-dir>` · `diff` · `migrations` · `apply <plan.json>` · `stamp <to>`.
**Invoke it via Bash; never reimplement its mechanical work by hand.** It produces facts and performs the
human-approved writes — it makes **no judgment calls**.

**Script ↔ model split:** the SCRIPT does `resolve`/`substitute`/`diff`/`migration-select`/`apply`/`stamp`.
The MODEL (you) adjudicates classification edges, **resolves the conflicts git can't** (reading the
customized content + the upstream change + the original intent to draft a merge — the one thing a skill
beats a CLI at), runs prose migrations, presents the dry-run, drives the two gates, confirms recovered
legacy values (never fabricating), and authors the commit.

**Tools (use when available):** when reading the project's files to classify edges or draft a conflict resolution, prefer a code-intelligence MCP (e.g. CodeGraph) over `grep`+read loops where it helps. Optional — no-op if absent.

---

## 2. The 3-way merge in one breath

```
base   = OLD templates @ <base sha>,  re-substituted with the manifest's stored placeholder values
ours   = NEW templates @ <to ref>,    re-substituted with the SAME stored values
theirs = the project's files on disk
```

Reusing the **identical** placeholder set on both sides is what makes each diff reflect a **template**
change, not a **value** change. `base = --from ?? lastUpgradedFromSha ?? generatedFromSha`; `to = --to ??
scaffolding HEAD`. Where `theirs == base` (the project never touched a file), `ours` wins automatically.
Where the project customized, the diff is bounded and reviewed — never blind-overwritten.

---

## 3. The phase ladder

```
PRECHECK    (report-only)     resolve base/to · idempotency short-circuit · clean-tree gate · upgrade branch
   │  (no manifest → §7 LEGACY: retro-stamp, or heuristic-fingerprint base + force PROPOSE)
DIFF        (SCRIPT)          rebuild base+ours by re-substitution · 3 diffs/file · template-set delta → plan.json
CLASSIFY    (SCRIPT+MODEL)    default policy per file & per mixed-region; model adjudicates edges
MIGRATE-SEL (SCRIPT)          topological window (base,to] · idempotency pre-checks → ordered migration list
DRY-RUN     (MODEL)           report grouped by KIND + HIGH/MED/LOW risk;  --check EXITS here
══ PAUSE 1 ══                 plan-approval — approve all / selectively / inspect / abort  [--auto skips ONLY auto-apply]
APPLY       (SCRIPT+MODEL)    write files · inline <<<<<<< conflict markers · run migrations (journaled, idempotent)
══ PAUSE 2 ══                 pre-commit review — show diff; BLOCK commit on any unresolved marker
STAMP+COMMIT(SCRIPT+MODEL)    advance lastUpgradedFromSha · refresh ledgers · append upgrade-log · one explicit-add commit
DONE                          "What's New" CHANGELOG summary; the human pushes
```

**PRECHECK gates (all mutation-free except branch/stash):** if the manifest `schemaVersion` is newer than
this skill understands → **STOP**, tell the user to update the skill. If the working tree is dirty on
scaffolding-managed paths (`generatedFiles[]` or `.scaffolding/`) → **STOP**, ask to commit/stash (dirty
*project source* paths are fine and untouched). Create an upgrade branch `scaffolding-upgrade/<base8>..<to8>`;
never run on the default branch. Short-circuit "already up to date" if `base == to`, or if
`lastUpgradedFromSha == to` with no scaffolding-file drift.

---

## 4. The five file kinds → merge policy

| `kind` | Examples | Merge rule |
|---|---|---|
| `verbatim` | `tdd.md` 10 steps, Step-9 routing, escalation taxonomy, commit cadence | **AUTO-APPLY iff `theirs == base`** → take `ours`. Else **PROPOSE** with a loud "you diverged from verbatim machinery" flag. |
| `placeholder-only` | `preflight.md`, `wired.md`, single-area `run-tests.md` | **AUTO-APPLY iff `theirs == base`** (provably untouched). A clean-but-diverged 3-way ⇒ **PROPOSE** (low risk, `propose-clean`); a conflict ⇒ PROPOSE (resolve). |
| `mixed` | `CLAUDE.md`, `area-CLAUDE.md`, `orchestrator-briefing.md` | **Per-region split** (§5): machinery + `illustrative` blocks → auto-eligible; `customized` blocks → PROPOSE-ONLY, never clobber. |
| `accreted` | `LESSONS.md`, `IMPLEMENTATION_PLAN.md` living sections, area tables | **LEAVE ALONE.** Body never touched. Only skeleton/format changes are PROPOSE suggestions; body rewrites only via an explicit `accreted-format` migration. |
| `user-canonical` | the user's `{{ARCH_DOC}}` | Out of scope. Only an appended **Appendix A** or **Spec Anchor Index** skeleton (both additive + project-state-free) is a PROPOSE candidate. |

> **The prime directive governs.** Where a bundled reference phrases a per-kind rule more permissively (e.g.
> "placeholder-only auto-applies on any clean 3-way"), the stricter rule here wins: **nothing customized is
> ever written without confirmation.** Auto-apply requires `theirs == base`; a clean 3-way on a diverged file
> is a low-risk *proposal*, not a silent write. (`scaffold_upgrade.sh` enforces this in its policy defaults.)

---

## 5. mixed-file regions + migrations

**Region split (mixed files).** Regions are delimited by the stable `<!-- ▼ EXAMPLE BLOCK [id=<slug>] … -->`
/ `<!-- ▲ END EXAMPLE BLOCK [id=<slug>] ▲ -->` markers. Outside-block text is machinery (treated like
`verbatim`/`placeholder-only`). Per region: `exampleBlocks[id].status == "illustrative"` → AUTO-APPLY-eligible
(still upstream's); `status == "customized"` → PROPOSE-ONLY, conflict surfaced **only** if the upstream
block's *structure* changed (markers moved, block split/renamed/retired). **Marker-drift rule:** if region
parsing of `theirs` can't locate a block's boundaries (the user damaged/renamed/deleted a marker), the file
degrades to **whole-file PROPOSE** — never silently mis-merge; surface "couldn't locate block boundaries in
your copy — review the whole file."

**Migrations** (for structural change a content-diff can't express). Registry travels with the templates:
`migrations/registry.json` + one `M-NNNN-*.md` each. Selection = topological window `base < introducedAtSha
<= to` in commit order; a crossed migration never re-fires. **Idempotent** (idempotencyKey checked first),
**journaled** (a `.scaffolding/.migrations/<id>.done` touchfile marks completion so an interrupted upgrade resumes), **append-only** (a buggy migration is fixed
by a NEW one at a later SHA, never edited in place), per-migration failure non-fatal. Seven kinds:
`renamed-placeholder`, `moved-section`, `new-required-section`, `renamed-template`, `deleted-template`
(**PROPOSE-only, never auto-delete**), `added-template` (mode/optional-filtered), `accreted-format` (**the
only path allowed to rewrite accreted bodies** — human-gated, idempotent, sampled before/after). Full
handler table: `references/upgrade-skill.md §6`.

**New REQUIRED placeholder upstream:** during `ours` substitution, any `{{TOKEN}}` with no manifest value →
**STOP and ask the user** (never leave an unresolved `{{TOKEN}}`, never fabricate — generate Rule 2); write
the new value back to the manifest. **Manifest schema older than the skill:** a manifest-schema migration
runs **first**, before any file work.

---

## 6. The two PAUSE gates (not overridable)

Mirror the scaffolding's own discipline (`GENERATE-WITH-CLAUDE §6` plan-approval, §8 pre-commit; `/tdd`
Step 2.5). A "work without stopping" / "don't ask questions" instruction scopes to *clarifying* questions
and does **not** override these gates — surface the conflict instead of skipping.

- **PAUSE 1 (after DRY-RUN, before ANY write):** present findings grouped by KIND + risk tier (HIGH =
  touches a key-safety-rules block / the escalation taxonomy / a placeholder inside verbatim machinery / any
  accreted-body migration; MED = customized-block reshapes, non-clean placeholder merges, removed/renamed
  templates; LOW = clean auto-applies, illustrative updates, additive files). `AskUserQuestion`: approve all
  / approve selectively / inspect a file / abort. `--auto` skips PAUSE 1 **only** for the provably-untouched
  auto-apply group. **Abort = `git checkout -` ; `git branch -D` — manifest untouched, zero residue.**
- **PAUSE 2 (after APPLY, before commit):** show the diff. Before allowing commit, the script greps every
  written file for `^<<<<<<<` / `^>>>>>>>`; **any hit hard-blocks the commit.** No commit without explicit
  approval. Refuse to commit while any conflict marker remains.

---

## 7. Legacy / unstamped projects (no manifest)

**Preferred — retro-stamp, then upgrade normally** (`references/upgrade-mechanism.md §3`):
- **R1** recover placeholder values + `mode` by reverse-reading generated files (mode from
  `team-protocol.md` presence; placeholders from `CLAUDE.md` H1, filenames, per-area stack tables + resolved
  command bodies). **Confirm recovered values with the user; never fabricate.**
- **R2** recover `generatedFromSha`, in priority order: (A) **ask the user**; (B) git-history date-bound
  (project bootstrap-commit date → newest scaffolding commit at/before it); (C) verbatim-machinery
  fingerprint (un-substitute placeholders, match against the small set of commits where machinery changed).
  Record a `baseConfidence` marker: `exact | git-history-inferred | fingerprint | none`.
- **R3** write + commit a `retroStamped: true` manifest. From here it upgrades like a fresh project.

**Fallback — no base SHA recoverable:** set the merge base to the **oldest** scaffolding commit whose
verbatim machinery still matches (deliberately over-reports machinery diffs — safe, noisier), and **force
EVERY file to PROPOSE** (no auto-apply without a trustworthy base). Accreted state is still left alone.

---

## 8. Stamp + commit

Only after PAUSE-2 approval + a clean (marker-free) tree, the script rewrites the manifest:
`generatedFromSha` **unchanged** (archaeology anchor); `lastUpgradedFromSha = <to>` (the new merge base for
the next upgrade — the crucial field); `lastUpgradedAt` set; `generatedFiles`/`exampleBlocks`/`placeholders`
refreshed (renames mapped, deletions reconciled); `schemaVersion` bumped only if a migration changed the
manifest shape. Append one `.scaffolding/upgrade-log.jsonl` record `{from,to,at,applied,proposed,migrations,
skipped}`. Commit is **its own commit on the upgrade branch, NEVER `git add -A`** — stage explicitly every
written scaffolding file + `.scaffolding/manifest.json` + the upgrade-log. **The human pushes, not the skill.**

Commit message:
```
chore(scaffolding): upgrade <base8> → <to8>

Auto-applied: <verbatim/placeholder files>.
Proposed+accepted: <customized files re-merged>.
Migrations run: <ids + titles>.
Left untouched: accreted state (LESSONS.md, IMPLEMENTATION_PLAN.md living sections), ARCHITECTURE.md.
Skipped/deferred: <list>.

{{AI_TRAILER}}
```
(`{{AI_TRAILER}}` resolves from the project's manifest `placeholders`.)

---

## 9. Hard rules (forbidden)

- **Never re-render over the top.** No blind overwrite of any customized or accreted file. Propose; don't clobber.
- **Never auto-delete a template's file** (`deleted-template` is PROPOSE-only) — a project may depend on it.
- **Never touch accreted bodies** (`LESSONS.md`, `IMPLEMENTATION_PLAN.md` living sections) except via an explicit,
  human-gated `accreted-format` migration. **Never touch `{{ARCH_DOC}}`** beyond an appended Appendix A skeleton.
- **Never fabricate a placeholder** — an unresolved `{{TOKEN}}` STOPS and asks; recovered legacy values are confirmed.
- **Never auto-apply without a trustworthy base** — lower `baseConfidence` ⇒ more gating, never more auto-apply.
- **Never commit with a conflict marker present**, never `git add -A`, never push. The two PAUSE gates are not overridable.
- **Never reimplement the script's deterministic work by hand**, and never hand-edit `.scaffolding/manifest.json`.

---

## 10. Output & handoff

> **Scaffolding upgrade `<base8>` → `<to8>`** on branch `scaffolding-upgrade/<base8>..<to8>`. Auto-applied
> `<A>` provably-untouched files; re-merged `<P>` customized files (you approved); ran `<M>` migrations; left
> accreted state + `{{ARCH_DOC}}` untouched. Manifest re-stamped (`lastUpgradedFromSha` advanced). A
> "What's New" summary is above. **Next:** review the branch, then **push it yourself** and open a PR — I do
> not push. Re-run `/scaffold-upgrade --check` any time to detect future drift.

Then stop.
