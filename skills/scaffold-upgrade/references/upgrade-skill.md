# The `/scaffold-upgrade` Skill — Flow Design

> **What this designs.** The runtime flow of the `/scaffold-upgrade` SKILL: the prompt-driven procedure
> a fresh Claude Code session executes to bring an already-customized project's scaffolding up to date
> with the current `templates/` tree **without clobbering** its `{{PLACEHOLDER}}` substitutions, its
> rewritten `EXAMPLE BLOCK` regions, or its accreted state (`LESSONS.md`, `MVP_TASKS.md` living sections,
> the area-`CLAUDE.md` lookup + invariants tables).
>
> **What it assumes (designed elsewhere, not re-specified here).**
> - The **provenance manifest** `.scaffolding/manifest.json` exists — `schemaVersion`, `generatedFromSha`,
>   `scaffoldingRepo`/`generatedFromRef`, `mode`/`track`/`optionalCommands`/`optionalSubagents`, resolved
>   `placeholders` + per-area `codeAreas[]`, the `generatedFiles[]` ledger (`dest ← template`, `kind`), and
>   the `exampleBlocks[]` ledger (`file`, `id`, `customized`|`illustrative`). Format, stamping (Step 12.5),
>   and **retro-stamping** of pre-manifest projects are specified in `upgrade-mechanism.md`.
> - The **prior-art canon** (copier/cruft 3-way merge; projen marker; gstack migrations + journal/done-markers)
>   is distilled in `upgrade-priorart.md`. This doc applies that canon as a *Claude SKILL* flow.
>
> **The one-sentence shape.** `base` = old templates @ `generatedFromSha`, re-substituted with the manifest's
> stored values → `ours` = new templates @ HEAD, re-substituted with the *same* values → `theirs` = the
> project's files on disk. A deterministic bundled **script** rebuilds `base`/`ours`, runs the per-file
> 3-way merge governed by `kind`, and emits a machine-readable plan; the **model** classifies anything the
> script can't decide, resolves the conflicts git can't, runs the migration registry, presents the dry-run,
> and gates on the two PAUSE points the scaffolding already mandates.

---

## §0 — Invocation, identity, and the prime directive

`/scaffold-upgrade [--check] [--from <sha>] [--to <ref>] [--auto]` — a SKILL (a prompt Claude executes),
**not** a CLI. It is run by a **fresh, standalone Claude Code session** pointed at:

1. the **target project** (cwd = project repo root, the one carrying `.scaffolding/manifest.json`), and
2. a **checkout of the scaffolding repo** at the version to upgrade *to* (path passed in `args` or
   auto-located; defaults to the scaffolding repo's HEAD).

**This is not a team-role command.** It does not run inside `/tdd`, is not dispatched by the orchestrator,
and writes no project STATE. It is closest in spirit to `GENERATE-WITH-CLAUDE.md` — a generation-class
procedure — but it *re-generates against an existing base* instead of generating from scratch.

**Prime directive (the projen/cookiecutter lesson inverted):** the project's files are **user-owned**, not
upstream-managed. There is **no "re-render over the top."** The only files this skill ever writes without
explicit human confirmation are `kind: verbatim` and `kind: placeholder-only` files that are *provably
untouched by the project* (`theirs == base`). Everything the project customized is PROPOSE-ONLY.

**Args:**
- `--check` — drift-detection only (the `cruft check` analog). Runs §1–§4, prints "you are N commits / M
  changed files behind," exits before any mutation. Safe in CI.
- `--from <sha>` / `--to <ref>` — override the manifest's `generatedFromSha` (base) and the scaffolding HEAD
  (target). `--from` is the escape hatch when the manifest SHA is wrong; `--to` lets you upgrade to a tag
  rather than HEAD.
- `--auto` — permit the AUTO-APPLY phase to write without the first PAUSE *for verbatim/placeholder files only*;
  PROPOSE and migration phases still gate. Off by default. Mirrors gstack's "Always" policy but scoped to the
  one phase that is mechanically safe.

---

## §1 — Phase 0: PRECHECK — resolve the two anchors, refuse on ambiguity

Before any diffing, establish a clean, reconstructable base. This phase is **report-only**; it mutates nothing.

**Step 1.1 — Read the manifest.** `jq . .scaffolding/manifest.json`. If it doesn't exist or doesn't parse →
**LEGACY branch** (§8). If `schemaVersion` is newer than this skill understands → stop and tell the user to
upgrade the skill first (the manifest is self-versioning by design). Capture `generatedFromSha`, `mode`,
`track`, `optionalCommands`, `optionalSubagents`, `placeholders`, `codeAreas[]`, `generatedFiles[]`,
`exampleBlocks[]`.

**Step 1.2 — Resolve `base` (old) and `to` (new) refs.**
- `base` = `--from` if given, else `generatedFromSha`. Verify it resolves in the scaffolding checkout
  (`git -C <scaffolding> cat-file -e <sha>^{commit}`). If it does not resolve (shallow clone, or the SHA is
  from a since-rebased branch) → fetch with history (`git -C <scaffolding> fetch --unshallow` or
  `fetch origin <sha>`); if still unresolvable, fall back to the **verbatim-fingerprint base recovery** in
  §8.2 and mark `baseConfidence: "fingerprint"`. (Prior art: cruft #181 — a 3-way merge needs the *real
  blobs* of the old baseline; a shallow clone silently corrupts the merge.)
- `to` = `--to` if given, else `git -C <scaffolding> rev-parse HEAD`.

**Step 1.3 — Idempotency short-circuit.** If `base == to` (the project is already at the target version) →
report "already up to date at `<sha>`," update nothing, exit 0. Also short-circuit if `manifest.lastUpgradedFromSha == to`
*and* the working tree shows no scaffolding-file drift — re-running the skill on an already-upgraded project is a no-op.

**Step 1.4 — Working-tree cleanliness gate.** The 3-way merge and any `.bak`/restore-on-failure step need a
clean baseline. Run `git -C <project> status --porcelain`. If the working tree is dirty **on scaffolding-managed
paths** (anything in `generatedFiles[]` or `.scaffolding/`), STOP and ask the user to commit or stash first —
an upgrade must start from a committed state so `git diff`/restore is meaningful and the upgrade lands as its
own reviewable commit. (Borrowed from gstack: `git stash` before, restore on failure.) Dirty *non-scaffolding*
paths (the project's own source) are fine and untouched.

**Step 1.5 — Branch.** Create an upgrade branch `scaffolding-upgrade/<base8>..<to8>` so the entire upgrade is
reviewable as one PR and trivially abandonable (`git checkout -; git branch -D ...`). Never run the upgrade
directly on the default branch.

---

## §2 — Phase 1: DIFF — compute the true upstream change set (script-produced)

**The script does this; the model reads the output.** The goal is to separate *real upstream template changes*
(`base → ours`) from *project customizations* (`base → theirs`), so the model never has to eyeball whole files.

The bundled helper script `scaffold_upgrade.sh diff` (see §10) does, per `generatedFiles[]` row, **deterministically**:

1. **Rebuild `base`** — `git -C <scaffolding> show <base>:<template>` → the raw old template → run the
   manifest's recorded `placeholders` + matching `codeAreas[]` substitution → a concrete old file. Substitution
   is the *same deterministic token replacement the generator used*, applied in a temp dir (`$TMP/base/<dest>`).
2. **Rebuild `ours`** — `git -C <scaffolding> show <to>:<template>` → raw new template → substitute with the
   **same** stored values → `$TMP/ours/<dest>`. (Reusing the identical placeholder set is what makes the diff
   reflect *template* change, not value change.)
3. **`theirs`** = the project file on disk (`<project>/<dest>`).
4. Emit three machine diffs per file: `base↔ours` (the upstream change — what the skill *wants* to bring in),
   `base↔theirs` (the project's customization — what must be *preserved*), and a dry git 3-way
   (`git merge-file --diff3 -p theirs base ours`) whose exit code says clean (0) vs. conflicted (≠0).

Output: `$TMP/plan.json` — one record per file with `{dest, template, kind, baseEqualsTheirs, upstreamChanged,
mergeClean, conflictHunks, area}`. Plus a **template-set delta**: templates present in `to` but not in `base`
(`addedTemplates[]`), templates removed (`removedTemplates[]`), and templates whose path moved
(`renamedTemplates[]`, detected via `git -C <scaffolding> diff --find-renames --name-status <base> <to> -- templates/`).

**Why the script and not the model:** this is pure mechanical git + string substitution + `merge-file`. It is
deterministic, fast, auditable, and re-runnable. The prior art is explicit (`upgrade-priorart.md`, "What to
AVOID"): *do not reinvent the diff/merge engine in skill prose.* Lean on git; reserve the model for judgment.

---

## §3 — Phase 2: CLASSIFY + assign upgrade policy (script proposes from `kind`; model adjudicates edges)

Every file in `plan.json` is assigned a **policy** keyed off its `kind` (§1.2 of `upgrade-mechanism.md`) and
the diff facts. The script computes the *default* policy; the model overrides only on the listed edge cases.

| `kind` | What it is (real examples) | Default policy | When the model intervenes |
|---|---|---|---|
| **`verbatim`** | `tdd.md` (the 10 steps, Step-2.5/7.5 checkpoints, Forbidden section, Step-10 commit rules), the Step-9 routing matrix + commit-cadence table in `orchestrator-briefing.md`, the escalation taxonomy + slice-atomicity rules in root `CLAUDE.md`. Comment headers literally say "keep VERBATIM." | **AUTO-APPLY** iff `baseEqualsTheirs` (project never hand-edited it) → take `ours` wholesale (it is the project's placeholders re-substituted into the new machinery). | If `!baseEqualsTheirs`: the project hand-edited machinery (rare, discouraged). Demote to **PROPOSE** with a loud "you diverged from VERBATIM machinery here" flag; show the project's edit vs. the new upstream so the human decides whether to keep their fork or adopt upstream. |
| **`placeholder-only`** | `preflight.md`, single-area `run-tests.md`, `wired.md`, `check-arch.md`, `session-start.md` — substitution only, no EXAMPLE BLOCKs. | **AUTO-APPLY** if `mergeClean` (placeholder regions match base, so the upstream change applies cleanly with the project's values re-substituted). | If `!mergeClean`: a placeholder region drifted (e.g. the project hand-tuned a `{{TEST_CMD}}` away from the manifest value). Demote to **PROPOSE**; offer to also update the manifest's stored value if the project's on-disk value is the new truth. |
| **`mixed`** | `CLAUDE.md`, `area-CLAUDE.md`, `orchestrator-briefing.md`, `tdd-brief-template.md`, `scaffolding-reference.md` — VERBATIM machinery **and** `{{PLACEHOLDER}}`s **and** `EXAMPLE BLOCK` regions in one file. | **Per-region split** (§3.1). Machinery + `illustrative` blocks → AUTO-APPLY-eligible; `customized` blocks → **PROPOSE-ONLY**. | The model owns the region split when the script can't cleanly delimit a region (markers moved/renamed upstream — see §3.1). |
| **`accreted`** | `area-LESSONS.md` (empty-by-design, accretes via Step-9), `MVP_TASKS.md` living sections (Currently-in-progress, Carry-forward, Log, Decisions tabled, phase checkboxes), area-`CLAUDE.md` lookup + cross-doc-invariants tables. | **LEAVE ALONE.** Body is never touched. Only the **skeleton/format** regions (header blockquote, the lesson-format code block, fixed section *headings*) are merge candidates, and only as a **PROPOSE** suggestion — never auto-applied. | The model decides whether a skeleton change is cosmetic (skip) or a **structural format migration** that the accreted body must conform to → routes it to the **migration registry** (§6), which is the *only* path that may rewrite accreted content, and only via an explicit human-gated, idempotent migration. |
| **`user-canonical`** | the user's `{{ARCH_DOC}}` (their own architecture doc). | **OUT OF SCOPE.** Never touched. Only the appended **Appendix A — Model/contract inventory** skeleton is a candidate, PROPOSE-ONLY. | The model never proposes a change to the user's prose; at most it suggests adding the Appendix A scaffold if absent. |

### §3.1 — `mixed`-file region split (the heart of "separate upstream change from project customization")

A `mixed` file is decomposed into **regions** by stable `EXAMPLE BLOCK [id=...]` markers (the slugged markers
from `upgrade-mechanism.md §2.3`). Everything *outside* a marked block is **machinery/placeholder region**;
everything *inside* is an **example-block region** whose ownership is recorded in `exampleBlocks[]`.

For each region the policy is:

- **Machinery/placeholder region (outside any block):** treated exactly like a `verbatim`/`placeholder-only`
  file — AUTO-APPLY-eligible if that region is unchanged in `theirs` vs `base`; PROPOSE if the project edited it.
- **`exampleBlocks[id].status == "illustrative"`** (project kept the labelled default): the project does *not*
  own this content → if upstream improved the illustrative text, **AUTO-APPLY-eligible** (it's still upstream's).
- **`exampleBlocks[id].status == "customized"`** (project rewrote it with its own forbidden-patterns / safety
  rules / layer DAG / worked example): **PROPOSE-ONLY, never clobber.** The project's content is canonical.
  Surface a conflict **only** if the upstream block's *surrounding structure changed* — the markers moved, the
  block was split/merged, a new required sub-section appeared inside it, or the block was renamed/retired
  upstream. In that case the model presents: "your customized `[id=forbidden-patterns]` content (preserved)
  vs. upstream's new block *shape* — do you want to re-fit your content into the new shape?" That re-fit is a
  judgment call (model + human), not a mechanical merge.

**Marker-drift handling (model judgment):** if a block's `id` exists in `theirs` but the upstream block was
**renamed** (`[id=key-safety-rules]` → `[id=domain-invariants]`) or **removed**, the script flags `markerDrift`
and the model maps old→new using the migration registry's `renamedExampleBlock` / `removedExampleBlock` entries
(§6). Without a registry entry, the model treats a vanished customized block as **KEEP-AS-IS + report** (never
silently drop project content) and asks the human.

**Output of Phase 2:** the script writes `policy` onto each `plan.json` record; the model reads the whole plan
and overrides per the "when the model intervenes" column, recording each override with a one-line reason. The
result is the **classified plan** that drives the dry-run.

---

## §4 — Phase 3: DRY-RUN report FIRST (model-presented, grouped by KIND + risk)

**Nothing has been written yet.** The model presents a single-screen-first, drill-down-on-request report —
the analog of `copier --pretend` / `cruft diff`, and the discipline equivalent of `GENERATE-WITH-CLAUDE.md §6`'s
"present a compact plan and wait." Structure:

```
Scaffolding upgrade: <base8> → <to8>   (<N> upstream commits, <M> template files changed)
Base confidence: exact | git-history-inferred | fingerprint        Mode: team (track: backend)

AUTO-APPLY  (verbatim machinery + placeholder re-substitution, project provably untouched)
  ✓ .claude/commands/tdd.md            verbatim       Step-9 routing reworded; commit-cadence row added
  ✓ .claude/commands/preflight.md      placeholder    new format-check gate; {{TEST_CMD}} re-substituted
  ✓ CLAUDE.md  (machinery regions)     mixed/verbatim escalation taxonomy: 4th category clarified

PROPOSE  (you customized this — review the upstream change; nothing applied without your OK)
  ⚠ CLAUDE.md  [id=key-safety-rules]   mixed/example  upstream restructured the block shape; your 3 rules preserved
  ⚠ docs/orchestrator-briefing.md [id=project-context]  your content kept; upstream added a "Who the user is" sub-heading
  ⚠ .claude/commands/run-tests.md      placeholder*   you hand-edited {{TEST_CMD_INTEGRATION}}; upstream also changed it → conflict

LEAVE ALONE  (accreted state — body untouched)
  – app/LESSONS.md                     accreted       (12 lessons; skeleton unchanged)
  – MVP_TASKS.md                       accreted       (living sections untouched; format unchanged)
  – ARCHITECTURE.md                    user-canonical (not touched)

MIGRATIONS  (structural changes a content-diff can't express — human-gated, §6)
  ! M-0007  rename placeholder {{TEST_RUNNER}} → {{TEST_FRAMEWORK}}   affects 4 files
  ! M-0011  new required section "Rollback protocol" in orchestrator-briefing.md

ADDED upstream (offered as new files, filtered by your mode/optional set)
  + .claude/commands/triage.md         new command    (team mode — eligible)
  – .claude/commands/team-sync.md      new command    (SKIPPED: single-operator project)   [shown only if filtered]

RISK SUMMARY:  3 auto-apply · 3 propose · 2 migrations · 1 new file
HIGH-RISK flags: M-0007 touches a placeholder referenced in tdd.md (verbatim); 1 customized safety-rules block reshaped.
```

**Risk tiers** the model assigns (and surfaces):
- **HIGH** — anything touching a `key-safety-rules` block, the escalation taxonomy, a placeholder used inside a
  `verbatim` machinery file, or any `accreted` body-rewriting migration. These get individual call-outs.
- **MEDIUM** — `customized` example-block reshapes, `!mergeClean` placeholder conflicts, removed/renamed templates.
- **LOW** — clean verbatim/placeholder auto-applies, illustrative-block updates, additive new files.

**`--check` exits here** with a behind-by count and exit 1 if anything would change (CI-friendly).

---

## §5 — The two PAUSE gates (mirroring the scaffolding's own discipline)

The scaffolding installs a two-PAUSE discipline (`GENERATE-WITH-CLAUDE.md §2`: plan-approval, then pre-commit
review) and a two-checkpoint `/tdd` discipline (Step-2.5, Step-9). The upgrade skill **practices what it
installs** — it has exactly two human-review gates, and they are not overridable by any "work without stopping"
instruction (same rule as `/tdd` Step 2.5).

### PAUSE 1 — after the dry-run, before ANY write (the plan-approval gate)

Present the §4 report. Wait. The human can:
- **Approve all** — proceed to apply AUTO-APPLY + all approved PROPOSE items + run migrations.
- **Approve selectively** — `AskUserQuestion` (or free-form) per PROPOSE item and per migration: apply / skip /
  defer. Skipped items are recorded so a re-run re-offers them (idempotent, not lost).
- **Inspect** — ask to see any file's `base↔ours` / `base↔theirs` / 3-way diff (the script already computed them).
- **Abort** — `git checkout -; git branch -D scaffolding-upgrade/...`; manifest untouched; zero residue.

With `--auto`, PAUSE 1 is *skipped for the AUTO-APPLY group only* (verbatim/placeholder, provably untouched —
mechanically safe). PROPOSE items and migrations **always** stop here regardless of `--auto`.

### Apply (between the gates)

Write in dependency order (same order as `GENERATE-WITH-CLAUDE.md §7`, since later files reference earlier
names). Per file:
- AUTO-APPLY → write `ours` (verbatim) or the clean 3-way result (placeholder/mixed-machinery).
- PROPOSE-approved → for clean merges, write the 3-way result; for conflicts, write the file **with git-style
  `<<<<<<< / ======= / >>>>>>>` inline conflict markers** (copier's `inline` default — the one format every
  dev and Claude already resolve), then the model proposes a resolution in-session for the human to accept.
  This is the single place a SKILL beats a CLI: it can read both sides + intent and draft the merge.
- `accreted` / `user-canonical` → not written (unless a §6 migration explicitly handles it).
- Each written file gets a one-line entry in an in-memory apply-log (for the commit body + the upgrade-log).

Migrations run interleaved per §6 (pre-migrations before the file apply, post-migrations after — copier's
stage ordering).

### PAUSE 2 — after writing, before the commit (the pre-commit review gate)

Mirror `GENERATE-WITH-CLAUDE.md §8`. Stop. Tell the human exactly what changed on disk:
- Files written (count + paths), grouped by AUTO-APPLY / PROPOSE / migration-touched.
- Any files left with **unresolved conflict markers** (these BLOCK the commit — the human resolves or aborts).
- Anything that diverged from PAUSE-1's plan (e.g. a migration discovered a third affected file).
- `git -C <project> diff` is available for the human to read the full change.

**Do not commit until the human approves** (same posture as the generator's "don't commit unless the user
asks"). Then §7 records the new SHA and commits.

---

## §6 — The migration registry (gstack-style) for structural changes

Content diffs handle text. They **cannot** express: a renamed placeholder, a moved/renamed section, a new
*required* section, a renamed/deleted/added template file, or a format migration of accreted state. These are
**migrations** — the copier `_migrations` / gstack `migrations/v*.sh` analog, adapted to this template tree.

### §6.1 — Where migrations live + how they're keyed

Migrations live **in the scaffolding repo** (they travel with the templates that necessitate them):

```
templates/../migrations/                       # sibling to templates/, shipped in the scaffolding repo
  registry.json                                # ordered index: id, title, appliesFromSha→toSha window, kind, gate, idempotencyKey
  M-0007-rename-test-runner-placeholder.md     # one file per migration: detect / pre / transform / post / verify, in prose + bash blocks
  M-0011-add-rollback-protocol-section.md
```

`registry.json` row shape (read by the script, executed by the model):

```jsonc
{
  "id": "M-0007",
  "title": "Rename placeholder {{TEST_RUNNER}} → {{TEST_FRAMEWORK}}",
  "introducedAtSha": "<scaffolding commit that introduced it>",
  "kind": "renamed-placeholder",     // renamed-placeholder | moved-section | new-required-section
                                     // | renamed-template | deleted-template | added-template | accreted-format
  "appliesWhen": "base < introducedAtSha <= to",   // version-window gate (copier PEP440 analog, by SHA topology)
  "gate": "human",                   // human | auto   (structural/accreted-touching => human; pure-additive => auto-eligible)
  "idempotencyKey": "placeholder:TEST_RUNNER->TEST_FRAMEWORK",
  "touches": ["manifest.placeholders", ".claude/commands/tdd.md", "app/CLAUDE.md", "MVP_TASKS.md"]
}
```

**Selection (the gstack `sort -V` analog):** the script walks `registry.json`, selects every migration whose
`introducedAtSha` is in the topological window `(base, to]` (i.e. introduced *after* the project's base and
*at or before* the target), in commit order. Only those fire. A migration already crossed in a prior upgrade
is not in the window, so it never re-fires.

### §6.2 — The seven structural change kinds + their handlers

| Migration kind | Example | Handler does (script + model) |
|---|---|---|
| **renamed-placeholder** | `{{TEST_RUNNER}}` → `{{TEST_FRAMEWORK}}` | Rewrite the manifest's `placeholders` key (preserving the value); re-key any `codeAreas[]` entry. The substitution then resolves the new token automatically in `base`/`ours` rebuilds. Touched files re-merge with the renamed token. **Idempotent:** if the manifest already has the new key, skip. |
| **moved-section** | the "Push posture" section relocated within `CLAUDE.md` | A pure-text move is usually absorbed by the 3-way merge. The migration exists for the case where the project *customized* the section: the model re-anchors the project's customized content to the new location, preserving it. Human-gated. |
| **new-required-section** | a new mandatory "Rollback protocol" heading in `orchestrator-briefing.md` | Insert the new section's *skeleton* from the new template at the correct anchor, with its EXAMPLE-BLOCK markers, marked for the project to fill. Never fabricate the content (same rule as generation). Human-gated; the model shows where it lands. |
| **renamed-template** | `templates/.claude/commands/run-tests.md` → `.../test.md` (and command renamed) | `git mv` the project's corresponding file; update the `generatedFiles[]` ledger `dest`+`template`; grep-and-update cross-references (the renamed command's name inside other command bodies + `area-CLAUDE.md` slash-command list + briefing "Tools"). This is exactly the "renaming caveat" ripple `SCAFFOLDING-GUIDE.md §11` warns about — the migration automates the grep-and-update. Human-gated (it touches references in machinery). |
| **deleted-template** | a retired slash command | Propose deleting the project's file + its references. **Never auto-delete** — a project may depend on it. PROPOSE-ONLY; if kept, record a `divergence` note in the manifest so future upgrades don't re-offer the deletion. |
| **added-template** | a brand-new slash command / subagent upstream | Offer as an addition, **filtered by `mode`/`optionalCommands`/`optionalSubagents`** so a single-operator project is never handed `team-start.md` and an opted-out subagent isn't installed. Substitute placeholders, write, append to `generatedFiles[]`. Auto-eligible (purely additive) unless it introduces a new required placeholder (then it asks). |
| **accreted-format** | the `LESSONS.md` lesson-format block gains a required `**Slice:**` line; the cross-doc-invariants table gains a column | **The only path allowed to rewrite accreted bodies**, and only via an explicit, human-gated, idempotent transform: the migration ships a deterministic rewriter (e.g. "for each existing lesson, insert a `**Slice:** unknown` line if absent") run by the script, with a per-item `idempotencyKey` so re-running is a no-op. The model shows a before/after sample of one item and gates on approval before applying across the body. If the transform can't be made deterministic, it degrades to a PROPOSE checklist the human applies. |

### §6.3 — Idempotency + journaling (inherited from gstack `v1.27.0.0`)

- Every migration is **re-runnable**. The `idempotencyKey` is checked first; if the change is already present
  (placeholder already renamed, section already inserted, format line already added), the migration is a no-op.
- Multi-step migrations write a **journal + done-markers** under `.scaffolding/.migrations/<id>/`: each step
  appends its name on success; re-entry resumes from the first un-done step; a `<id>.done` touchfile
  short-circuits the whole migration. This makes an *interrupted upgrade* (model ran out of context, human
  closed the session) resume cleanly instead of double-applying.
- **Migrations are append-only history.** A buggy shipped migration is *never edited in place* (the gstack
  gotcha: done-markers make an in-place fix a silent no-op on projects that already ran the buggy version).
  The fix is a **new** migration at a later SHA that patches what the broken one missed.
- **Per-migration failure is non-fatal** (gstack posture): a migration that errors is isolated, reported in
  the PAUSE-2 summary as "M-0011 had errors (non-fatal) — review manually," and does not abort the rest of
  the upgrade. The journal records the failure so it isn't marked done.

---

## §7 — Idempotency of the whole run + recording the new base SHA

**Idempotency of the skill (not just migrations):** the whole `/scaffold-upgrade` run is a function of
`(base, to, manifest, project-tree)`. Re-running after a successful upgrade short-circuits at §1.3 (`base == to`
or `lastUpgradedFromSha == to` with a clean tree). Re-running after a *partial* upgrade (aborted at a gate,
or context-exhausted mid-apply) is safe because:
- nothing was committed (the upgrade lands as one commit at the very end),
- migration journals resume rather than re-apply,
- the AUTO-APPLY phase is `theirs == base` gated, which becomes false once applied (so a re-run won't
  re-touch an already-updated file), and conflict-marker files are detected and re-offered, not re-merged blindly.

**Recording the new SHA (the merge anchor advance — copier/cruft's defining final step):** *only after PAUSE-2
approval and a clean commit*, the skill rewrites the manifest:

```jsonc
{
  "generatedFromSha":   "<unchanged — the original generation anchor, kept for archaeology>",
  "lastUpgradedFromSha": "<to>",          // ← the new merge base for the NEXT upgrade
  "lastUpgradedAt":      "<ISO8601 now>",
  "generatedFiles":      [ /* refreshed: added/renamed/deleted files reconciled */ ],
  "exampleBlocks":       [ /* refreshed: new blocks added, renamed ids mapped, removed ones dropped */ ],
  "placeholders":        { /* refreshed if a renamed-placeholder migration ran */ }
  // schemaVersion bumped only if an accreted-format/manifest migration changed the manifest shape
}
```

The crucial field is **`lastUpgradedFromSha`** — the next upgrade's `base` is `lastUpgradedFromSha ?? generatedFromSha`.
Without advancing it, the next upgrade would recompute the diff from the *original* generation SHA and re-offer
everything already applied. (This is copier `_commit` / cruft `commit` advancing — the non-negotiable "update
the provenance ref so the next update has a fresh anchor." Prior art, `upgrade-priorart.md` §"THE Canonical
Pattern" invariant 5.)

**The commit** (its own commit on the upgrade branch, never `git add -A`):

```
chore(scaffolding): upgrade <base8> → <to8>

Auto-applied: <list of verbatim/placeholder files>.
Proposed+accepted: <list of customized files re-merged>.
Migrations run: M-0007 (rename TEST_RUNNER), M-0011 (add Rollback protocol).
Left untouched: accreted state (LESSONS.md, MVP_TASKS.md living sections), ARCHITECTURE.md.
Skipped/deferred: <list>.

{{AI_TRAILER}}
```

Stage explicitly: every written scaffolding file + `.scaffolding/manifest.json` + `.scaffolding/upgrade-log.jsonl`
(append one record per run: `{from, to, at, applied, proposed, migrations, skipped}` — `git log` of the manifest
plus this log is the upgrade audit trail). **The human pushes**, not the skill.

**Failure recovery:** if the apply phase errors after writing some files, restore from the pre-upgrade commit
(`git -C <project> checkout -- <written paths>` or `git reset --hard <pre-upgrade-commit>` on the upgrade
branch) — the working-tree-clean gate (§1.4) guarantees this restores to a known-good state. Tell the human,
leave the branch for inspection. (gstack's `.bak` + restore-on-failure, expressed via git since we branched.)

---

## §8 — LEGACY fallback for unstamped projects (no manifest)

A project generated before the manifest mechanism existed has no `.scaffolding/manifest.json`. The skill
**does not refuse** — it offers a best-effort path. Two routes; the model picks based on what it can recover.

**§8.1 — Preferred: retro-stamp, then upgrade normally.** The cleanest legacy path is to *manufacture* the
manifest, then run the normal flow. Retro-stamping is fully specified in `upgrade-mechanism.md §3` (R1 recover
placeholders + mode by reverse-reading the generated files; R2 recover `generatedFromSha` via
ask-user → git-history-date-bound → verbatim-fingerprint; R3 write + commit a `retroStamped: true` manifest).
The upgrade skill **invokes that procedure inline** when it finds no manifest and the user agrees to stamp.
Once stamped (even with `baseConfidence: "fingerprint"`), §1–§7 run unchanged. **This is the recommended path**
— it makes the project upgrade like a freshly-generated one and leaves a durable anchor for all future upgrades.

**§8.2 — Heuristic fallback: upgrade without a recoverable base SHA (the truly-unknown case).** When even the
verbatim-fingerprint can't pin a base SHA (heavily hand-edited machinery, ancient/forked templates), reconstruct
a *conservative* base by **content fingerprinting**, not by SHA:

1. **Recover placeholder values heuristically** (R1): `PROJECT_NAME` from root `CLAUDE.md` H1; `TASK_TRACKER`/`ARCH_DOC`
   from the filenames actually present; per-area stack values from each `<area>/CLAUDE.md` stack table and the
   resolved `{{TEST_CMD}}`/`{{LINT_CMD}}`/etc. sitting in `preflight.md`/`run-tests.md`/`tdd.md`. Mark each
   recovered value `confidence: low|med|high` and **confirm the load-bearing ones with the user** (a wrong
   placeholder propagates — same rule as generation, `GENERATE-WITH-CLAUDE.md` Rule 2: never fabricate).
2. **Reverse-classify each present file** to a `kind` by matching it to a current template by path/name
   (`app/CLAUDE.md` ← `templates/area-CLAUDE.md`, etc.).
3. **Set the merge base to the *oldest* scaffolding commit whose verbatim machinery still matches the project's**
   (modulo recovered placeholders). Using the *oldest* match (not newest) deliberately **over-reports** machinery
   diffs: the skill shows the human *more* potential changes rather than silently skipping a real one. Noisier
   review, but safe — the failure mode is "you reviewed an extra hunk," not "you missed a fix."
4. **Force everything into the PROPOSE tier.** With a low-confidence base, *no* file is AUTO-APPLY — even
   verbatim files are presented as proposals, because "provably untouched" can't be proven without a trustworthy
   base. Accreted state is still LEFT ALONE; user-canonical still untouched. The two PAUSE gates still apply.
5. **On success, write a real manifest** (`retroStamped: true`, `baseConfidence: "fingerprint"` or `"none"`),
   so the *next* upgrade is clean. The legacy path is a one-time tax that converts the project to the stamped path.

**Hard rule for the legacy path:** lower confidence ⇒ *more* human gating and *less* auto-apply, never the
reverse. A project with no provenance gets the most conservative, most-reviewed upgrade — it never gets a
silent overwrite. (This is the cookiecutter-overwrite anti-pattern the whole design exists to avoid.)

---

## §9 — Helper script vs. model — the deterministic/judgment split

The prior art is emphatic (`upgrade-priorart.md` "What to AVOID"): **do not reinvent the diff/merge engine in
skill prose**; lean on git; reserve the model for the conflicts git can't resolve. The split:

### What the bundled SCRIPT does (deterministic, re-runnable, auditable) — `scaffold_upgrade.sh`

A single bundled bash script (lives in the scaffolding repo alongside the skill; the skill calls its
subcommands). Each invocation is self-contained (no cross-call shell state — the SKILL constraint):

- `scaffold_upgrade.sh resolve` — read+validate the manifest (`jq`), resolve `base`/`to` refs, verify they
  exist (and are not shallow), check the working-tree-clean gate, emit `precheck.json`.
- `scaffold_upgrade.sh substitute <ref> <out-dir>` — for every `generatedFiles[]` row, `git show <ref>:<template>`
  → apply the manifest's deterministic placeholder substitution → write the concrete file. Used to build both
  `base` (at `<base>`) and `ours` (at `<to>`).
- `scaffold_upgrade.sh diff` — produce the per-file `base↔ours`, `base↔theirs`, and `git merge-file --diff3`
  3-way; compute `baseEqualsTheirs`, `upstreamChanged`, `mergeClean`, `conflictHunks`; detect the template-set
  delta (`addedTemplates`/`removedTemplates`/`renamedTemplates` via `git diff --find-renames`); split `mixed`
  files into regions by the `[id=...]` markers; emit `plan.json` with a default `policy` per `kind`.
- `scaffold_upgrade.sh migrations` — read `migrations/registry.json`, select the topological window
  `(base, to]`, emit the ordered migration list + each one's `idempotencyKey` pre-check result (already-applied?).
- `scaffold_upgrade.sh apply <plan.json>` — execute the *mechanical* writes: AUTO-APPLY files, clean 3-way
  results, and conflict-marked files. (It writes; it does not *decide* — the plan it's handed already encodes
  the human's PAUSE-1 selections.)
- `scaffold_upgrade.sh stamp <to>` — rewrite the manifest's `lastUpgradedFromSha`/`lastUpgradedAt` + reconcile
  `generatedFiles`/`exampleBlocks`/`placeholders`; append the `upgrade-log.jsonl` record; validate (`jq .`).

The script **produces facts and performs the human-approved mechanical writes.** It makes **no judgment call**
and **never decides what to apply** — it is handed a plan that already encodes the decisions.

### What the MODEL does (judgment, presentation, the conflicts git can't resolve)

- **Adjudicate classification edges** (§3 "when the model intervenes"): demote hand-edited verbatim to PROPOSE,
  decide whether an accreted skeleton change is cosmetic vs. a format migration, map drifted/renamed EXAMPLE-BLOCK
  ids when the registry is silent.
- **Resolve the conflicts git can't** — read the project's customized content *and* the upstream change *and*
  the original intent, and draft a merge (the one thing a SKILL does better than a CLI). Especially: re-fitting a
  `customized` safety-rules / forbidden-patterns / layer-DAG block into an upstream block whose *shape* changed.
- **Run the structural migrations** that need prose understanding (re-anchoring a moved customized section,
  placing a new-required-section skeleton at the right anchor, the grep-and-update reference ripple of a renamed
  template, sampling+approving an accreted-format transform).
- **Present** the dry-run grouped by KIND + risk, assign risk tiers, call out HIGH-risk items individually.
- **Drive the two PAUSE gates** via `AskUserQuestion` / free-form, honor selective approve/skip/defer, and never
  override the gates on a "work without stopping" instruction (same rule as `/tdd` Step 2.5).
- **Confirm recovered values** in the legacy path (never fabricate a placeholder — `GENERATE-WITH-CLAUDE.md` Rule 2).
- **Author the commit message** and the PAUSE-2 change summary; refuse to commit while conflict markers remain.

---

## §10 — End-to-end flow (the phase ladder)

```
PRECHECK (§1, report-only)        → resolve base/to · idempotency short-circuit · clean-tree gate · branch
   │  (no manifest? → §8 LEGACY: retro-stamp or heuristic-fingerprint base; force PROPOSE tier)
   ▼
DIFF (§2, SCRIPT)                 → rebuild base+ours by re-substitution · 3 diffs/file · template-set delta → plan.json
   ▼
CLASSIFY (§3, SCRIPT proposes / MODEL adjudicates) → policy per file & per mixed-region · model overrides edges
   ▼
MIGRATIONS-SELECT (§6, SCRIPT)    → topological window (base,to] · idempotency pre-checks → ordered migration list
   ▼
DRY-RUN (§4, MODEL)               → report grouped by KIND + risk; --check exits here
   ▼
══ PAUSE 1 (§5) ══  plan-approval gate — approve all / selectively / inspect / abort   [--auto skips ONLY auto-apply group]
   ▼
APPLY (§5 + §6, SCRIPT mechanical / MODEL conflicts+migrations) → write files · inline conflict markers · run migrations (journaled, idempotent)
   ▼
══ PAUSE 2 (§5) ══  pre-commit review gate — show diff; BLOCK on unresolved markers; no commit without approval
   ▼
STAMP + COMMIT (§7, SCRIPT+MODEL) → advance lastUpgradedFromSha · refresh ledgers · append upgrade-log · one explicit-add commit
   ▼
DONE                              → "What's New" CHANGELOG summary; human pushes
```

## §11 — Summary of deliverables

| Deliverable | Specification |
|---|---|
| Skill identity | `/scaffold-upgrade [--check] [--from <sha>] [--to <ref>] [--auto]`; fresh standalone session; project-owned files, never re-render-over-the-top |
| Phases | PRECHECK · DIFF · CLASSIFY · MIGRATIONS-SELECT · DRY-RUN · **PAUSE 1** · APPLY · **PAUSE 2** · STAMP+COMMIT (§10) |
| Base/target resolution | base = `--from` ?? `lastUpgradedFromSha` ?? `generatedFromSha`; to = `--to` ?? HEAD; clean-tree gate; upgrade branch; idempotent short-circuit on `base==to` (§1) |
| Diff | SCRIPT rebuilds `base`/`ours` by re-substituting stored placeholders into old/new templates; emits per-file 3 diffs + template-set delta (§2) |
| Classification + policy | per `kind`: verbatim/placeholder→AUTO-APPLY iff provably-untouched; mixed→per-region split (machinery+illustrative auto / customized PROPOSE-ONLY); accreted→LEAVE ALONE (skeleton-only suggestions); user-canonical→untouched (§3) |
| Dry-run | report-only, grouped by KIND + HIGH/MED/LOW risk, drill-down on the script's pre-computed diffs; `--check` exits here (§4) |
| Review gates | two PAUSEs mirroring the scaffolding's own discipline (plan-approval, pre-commit); not overridable; selective approve/skip/defer; abort = zero residue (§5) |
| Migration registry | `migrations/registry.json` + `M-NNNN-*.md` in the scaffolding repo; SHA-window-gated selection; 7 structural kinds; idempotent + journaled + append-only + non-fatal (gstack pattern) (§6) |
| Idempotency + SHA recording | whole-run idempotent (short-circuit + journals + `theirs==base` gating); advance `lastUpgradedFromSha` only after PAUSE-2 + clean commit; refresh ledgers; append `upgrade-log.jsonl` (§7) |
| Legacy fallback | retro-stamp-then-upgrade (preferred) OR heuristic fingerprint base + force-PROPOSE-tier + confirm recovered values; lower confidence ⇒ more gating, never auto-apply; write a real manifest on success (§8) |
| Script vs. model | SCRIPT = deterministic resolve/substitute/diff/migration-select/mechanical-apply/stamp; MODEL = classify edges, resolve conflicts git can't, run prose migrations, present, gate, author commit (§9) |
```
