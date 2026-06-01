# Provenance Stamping & Clean Upgrades — Design

> **Problem.** When the scaffolding repo is updated and a project that was generated from an OLDER
> commit pulls the new templates, there is today no clean way to bring its scaffolding up to date
> WITHOUT clobbering its `{{PLACEHOLDER}}` substitutions, its rewritten EXAMPLE BLOCK regions, and its
> accreted state (`LESSONS.md`, `MVP_TASKS.md` living sections, the area-`CLAUDE.md` lookup +
> invariants tables). Before `/scaffold-upgrade`, the only path was hand-diffing generated files against
> current templates — error-prone and unbounded; `SCAFFOLDING-GUIDE.md §11` now documents this skill instead.
>
> **Solution.** Stamp a small, machine-readable **provenance manifest** into every generated project at
> bootstrap. The manifest records exactly what a future upgrade needs to reconstruct the **base**
> (the templates at the generation SHA, re-substituted with the recorded values) and run a true
> **3-way merge**: `base` (old templates @ recorded SHA, substituted) → `theirs` (the project's current
> files) ← `ours` (new templates @ HEAD, substituted with the same recorded values). Where the project
> never touched a file (verbatim machinery), `ours` wins automatically. Where the project customized
> (EXAMPLE BLOCKs, accreted state), the diff is bounded and reviewable instead of a blind overwrite.

The manifest turns "diff every generated file against every current template by hand" into
"regenerate the base deterministically, then 3-way merge." That is the whole point of provenance
stamping: it makes the *base* of the merge recoverable.

---

## 1 — Manifest path + format

**Path (hidden, in-repo, committed):**

```
.scaffolding/manifest.json          # the machine-readable provenance record (single source of truth)
.scaffolding/README.md              # 6-line human note: what this dir is, do-not-hand-edit, how upgrades use it
```

Rationale for the choices:

- **Hidden directory `.scaffolding/`** (not a dotfile at root) — keeps the project root clean, groups the
  manifest with any future upgrade artifacts (e.g. a saved merge-conflict log), and is unambiguous about
  ownership. A single hidden *file* (`.scaffolding-manifest.json`) would also work but a directory leaves
  room for the companion README and a future `upgrade-log.jsonl`.
- **JSON, not YAML/TOML** — the generator already shells `jq` for the team-registry writes (Step 13), so
  JSON is the lowest-friction machine format already in the toolchain. An upgrade session reads it with one
  `jq` call; no new parser dependency.
- **Committed, not gitignored** — provenance must travel with the repo. It rides the bootstrap commit
  (and is updated by each upgrade), so `git log .scaffolding/manifest.json` is itself an upgrade history.
- **`schemaVersion` field first** — so a future manifest-format change is itself upgradeable.

### 1.1 — Manifest schema

```jsonc
{
  "schemaVersion": 1,

  // ── provenance: where this generation came from ──────────────────────────
  "scaffoldingRepo": "git@github.com:<owner>/claude-code-tdd-agent-crew-scaffolding.git",
  "generatedFromSha": "0a595e0fc911a3c011f9adc2d3d441d86c29155c",  // FULL 40-char SHA of the scaffolding repo HEAD at generation time
  "generatedFromRef": "ce-integration",                            // branch/tag the SHA was on, advisory only
  "generatedAt": "2026-05-28T00:00:00Z",
  "generatorModel": "claude-opus-4-8",                             // advisory: which model ran the generation
  "lastUpgradedFromSha": null,                                     // set by upgrade runs; null at bootstrap
  "lastUpgradedAt": null,

  // ── mode + track (drives which files exist) ──────────────────────────────
  "mode": "team",                  // "team" | "single-operator"
  "track": "backend",              // string | null  (null = solo team or single-operator)
  "optionalCommands": ["wired", "eval"],          // which of /eval, /trace were generated (/wired is standard)
  "optionalSubagents": ["code-quality-reviewer", "reachability-auditor"],  // which of the 4 starters were generated

  // ── resolved placeholder values (the §10 manifest, filled) ───────────────
  "placeholders": {
    "PROJECT_NAME": "Apex Logistics",
    "PROJECT_TAGLINE": "Real-time route optimization service",
    "ARCHITECTURE_SENTENCE": "The dispatcher is the single source of truth; workers are stateless.",
    "REPO_DIRNAME": "apex-logistics",
    "GIT_REMOTE": "origin",
    "AI_TRAILER": "Assisted-by: Claude Code",
    "TASK_TRACKER": "MVP_TASKS.md",
    "ARCH_DOC": "ARCHITECTURE.md",
    "PHASE_IDS": "M1.C.01 / M2.A.03",
    "TRACK_NAME": "backend"
  },

  // ── per-code-area placeholder sets (1..N) ────────────────────────────────
  "codeAreas": [
    {
      "CODE_AREA": "app/",
      "CODE_AREA_NAME": "backend API",
      "CODE_AREA_BASENAME": "app",
      "RUNTIME": "Python 3.12",
      "PKG_MANAGER": "uv",
      "FRAMEWORK": "FastAPI",
      "VALIDATION_LIB": "Pydantic v2",
      "LINT": "ruff",
      "TYPECHECKER": "mypy --strict",
      "TEST_RUNNER": "pytest",
      "INSTALL_CMD": "uv sync",
      "DEV_CMD": "uv run uvicorn app.main:app --reload",
      "TEST_CMD": "uv run pytest",
      "TEST_CMD_SINGLE_FILE": "uv run pytest <path> -v",
      "TEST_CMD_UNIT": "uv run pytest -m unit",
      "TEST_CMD_INTEGRATION": "uv run pytest -m integration",
      "TEST_CMD_ALL": "uv run pytest",
      "LINT_CMD": "uv run ruff check .",
      "FORMAT_CHECK_CMD": "uv run ruff format --check .",
      "TYPECHECK_CMD": "uv run mypy app",
      "BUILD_CMD": null,
      "TEST_CLASSES": "unit|integration|all"
    }
    // ... one object per code area; the 2nd+ map to {{CODE_AREA_2_*}} etc.
  ],

  // ── generated-files ledger: dest path ← template source ──────────────────
  // Every file the generator wrote, and which template it came from. This is
  // the spine of the 3-way merge: it says which template to re-substitute to
  // rebuild each file's base. `kind` tells the merge how aggressive to be.
  "generatedFiles": [
    { "dest": "CLAUDE.md",                         "template": "templates/CLAUDE.md",                         "kind": "mixed" },
    { "dest": "app/CLAUDE.md",                      "template": "templates/area-CLAUDE.md",                    "kind": "mixed",   "area": "app/" },
    { "dest": "app/LESSONS.md",                     "template": "templates/area-LESSONS.md",                   "kind": "accreted" },
    { "dest": "MVP_TASKS.md",                       "template": "templates/MVP_TASKS.md",                      "kind": "accreted" },
    { "dest": "ARCHITECTURE.md",                    "template": "templates/ARCHITECTURE.md",                   "kind": "user-canonical" },
    { "dest": "docs/team-protocol.md",              "template": "templates/docs/team-protocol.md",             "kind": "mixed" },
    { "dest": "docs/orchestrator-briefing.md",      "template": "templates/docs/orchestrator-briefing.md",     "kind": "mixed" },
    { "dest": "docs/tdd-brief-template.md",         "template": "templates/docs/tdd-brief-template.md",        "kind": "mixed" },
    { "dest": "docs/scaffolding-reference.md",      "template": "templates/docs/scaffolding-reference.md",     "kind": "mixed" },
    { "dest": ".claude/commands/tdd.md",            "template": "templates/.claude/commands/tdd.md",           "kind": "verbatim" },
    { "dest": ".claude/commands/preflight.md",      "template": "templates/.claude/commands/preflight.md",     "kind": "placeholder-only" },
    { "dest": ".claude/commands/run-tests.md",      "template": "templates/.claude/commands/run-tests.md",     "kind": "mixed" }
    // ... one row per file actually written (commands, agents, etc.)
  ],

  // ── EXAMPLE-BLOCK customization ledger ───────────────────────────────────
  // For every EXAMPLE BLOCK region in every generated file, record whether the
  // project REPLACED it with its own content (`customized`) or LEFT it as the
  // illustrative default (`illustrative`). The 3-way merge uses this to decide
  // per-region: a still-illustrative block can take upstream improvements; a
  // customized block is project content and is left alone (conflict surfaced only
  // if the upstream block's *structure/markers* changed).
  "exampleBlocks": [
    { "file": "CLAUDE.md",                "id": "project-structure",        "status": "customized" },
    { "file": "CLAUDE.md",                "id": "tech-stack",               "status": "customized" },
    { "file": "CLAUDE.md",                "id": "strict-typing-posture",    "status": "customized" },
    { "file": "CLAUDE.md",                "id": "tdd-scope",                "status": "customized" },
    { "file": "CLAUDE.md",                "id": "key-safety-rules",         "status": "customized" },
    { "file": "app/CLAUDE.md",            "id": "area-stack",               "status": "customized" },
    { "file": "app/CLAUDE.md",            "id": "forbidden-patterns",       "status": "customized" },
    { "file": "app/CLAUDE.md",            "id": "module-layout",            "status": "customized" },
    { "file": "app/CLAUDE.md",            "id": "area-subagent-candidates", "status": "illustrative" },
    { "file": "docs/orchestrator-briefing.md", "id": "who-the-user-is",     "status": "customized" },
    { "file": "docs/orchestrator-briefing.md", "id": "project-context",     "status": "customized" },
    { "file": "docs/orchestrator-briefing.md", "id": "project-conventions", "status": "customized" },
    { "file": "docs/tdd-brief-template.md",    "id": "tdd-brief-worked-example",   "status": "illustrative" },
    { "file": "docs/tdd-brief-template.md",    "id": "project-specific-pitfalls",  "status": "illustrative" }
    // ... one row per EXAMPLE BLOCK region in each generated file
  ]
}
```

### 1.2 — The five file `kind`s (drive merge aggressiveness)

The `kind` field maps directly onto the five template KINDS the problem statement names. It is the
single most load-bearing field for a clean merge — it tells the upgrade session how to treat each file.

| `kind` | Template kind | Merge rule |
|---|---|---|
| `verbatim` | (a) VERBATIM machinery — `/tdd` 10 steps, Step-9 routing, commit cadence, escalation taxonomy | If the project file == base (re-substituted old template), upstream wins outright — take `ours` wholesale. If it differs, the project hand-edited machinery (rare, discouraged): surface as a conflict for human review. |
| `placeholder-only` | (b) only `{{PLACEHOLDER}}` substitution, no EXAMPLE BLOCKs (e.g. `/preflight`, single-area `/run-tests`) | Re-substitute new template with recorded placeholders → that is `ours`. 3-way merge against the project file; non-placeholder regions should match base, so changes apply cleanly. |
| `mixed` | (b)+(c) — placeholders AND EXAMPLE BLOCKs (`CLAUDE.md`, `area-CLAUDE.md`, the briefing) | Per-region 3-way merge driven by the `exampleBlocks` ledger: machinery + still-illustrative blocks take upstream; `customized` blocks are kept as project content. |
| `accreted` | (d) ACCRETED-STATE files — `LESSONS.md`, `MVP_TASKS.md` living sections, area-`CLAUDE.md` tables | **Never overwrite.** Only the *skeleton/format* regions (header, lesson-format block, section headings) are merge candidates; the accreted body is untouched. Upstream skeleton changes are surfaced as a suggested patch, never auto-applied. |
| `user-canonical` | the user's own `{{ARCH_DOC}}` | Out of scope for upgrades. Only the appended **Appendix A** skeleton is a candidate; the user's prose is never touched. |

---

## 2 — Concrete additions to GENERATE-WITH-CLAUDE.md

The manifest is written by the generator. It needs (a) a new generation step that writes it, and (b)
small bookkeeping so the data is captured as it is produced. All additions below are additive — nothing
in the existing 13-step order changes semantically.

### 2.1 — New **Step 12.5 — Stamp the provenance manifest** (between Step 12 and Step 13)

Insert into §7, after "Step 12 — Empty directories" and before "Step 13":

> ### Step 12.5 — Stamp the provenance manifest (`.scaffolding/manifest.json`)
>
> Write `.scaffolding/manifest.json` recording the provenance of this generation so future scaffolding
> upgrades are clean 3-way merges instead of blind hand-diffs. Also write a 6-line `.scaffolding/README.md`
> stating: this directory is generator-owned, the manifest must not be hand-edited (it is rewritten by
> upgrade runs), and pointing to `SCAFFOLDING-GUIDE.md §11` for the upgrade procedure.
>
> Capture, at minimum:
> 1. **`generatedFromSha`** — the FULL scaffolding-repo commit SHA you generated from. Get it with
>    `git -C <path-to-scaffolding-repo> rev-parse HEAD`. If you cannot resolve a SHA (the templates were
>    handed to you outside a git checkout), record `null` and add a `"shaUnknown": true` flag plus a
>    `"note"` — the upgrade path then falls back to the verbatim-machinery fingerprint (§3).
> 2. **`scaffoldingRepo`** + **`generatedFromRef`** — the remote URL and the branch/tag the SHA was on.
> 3. **`mode`** + **`track`** + **`optionalCommands`** + **`optionalSubagents`** — exactly the foundational
>    choices from §4 and Batch E. These determine which files exist; an upgrade must not try to merge a
>    file the project legitimately never had (e.g. `team-protocol.md` in single-operator mode).
> 4. **`placeholders`** + **`codeAreas[]`** — every resolved `{{PLACEHOLDER}}` value from the §10 manifest,
>    exactly as you substituted them. This is what lets the upgrade session re-substitute BOTH the old
>    templates (to rebuild the merge base) and the new templates (to build `ours`).
> 5. **`generatedFiles[]`** — one row per file you actually wrote in Steps 1–12, each with its `dest`
>    path, the `template` it came from, and its `kind` (`verbatim` | `placeholder-only` | `mixed` |
>    `accreted` | `user-canonical`). **Build this list incrementally as you write each file** — do not
>    reconstruct it from memory at the end.
> 6. **`exampleBlocks[]`** — one row per EXAMPLE BLOCK region in each generated file, with `status` =
>    `customized` (you replaced it with project content) or `illustrative` (you left the labelled default).
>    You know this at write time: when §6/§7 told you to "rewrite wholesale," that block is `customized`;
>    when you kept it "labelled as illustrative," it is `illustrative`.
>
> Use `jq -n` (or write the JSON directly) — JSON, not prose. Validate it parses (`jq . .scaffolding/manifest.json`)
> before moving on. **This step does not require user interaction**; it records decisions already made.

### 2.2 — Bookkeeping hooks in earlier steps (one line each)

So Step 12.5 has the data, add a single closing instruction to a few existing steps:

- **§6 (Plan and pause)** — add a final bullet: *"Note for yourself that the approved plan (mode, track,
  optional commands, optional subagents, every placeholder value, and which EXAMPLE BLOCKs you will
  rewrite vs. keep illustrative) is exactly the data the Step-12.5 manifest will record — keep it
  structured as you go."*
- **§7 Steps 1, 2, 6, 7, 8, 9, 10, 11** — add a trailing sentence to each: *"Append a `generatedFiles[]`
  row (dest, template, kind) and, for any EXAMPLE BLOCK you touched, an `exampleBlocks[]` row
  (file, id, status) to your running manifest data."* (One sentence; the work is just keeping a list.)
- **§10 (Placeholder manifest)** — add a closing note: *"Every value you resolve here is recorded
  verbatim in `.scaffolding/manifest.json` at Step 12.5. The placeholder table and the manifest's
  `placeholders` + `codeAreas[]` are the same data in two forms — keep them consistent."*

### 2.3 — Stable EXAMPLE-BLOCK ids (one-time template change, enables `id` matching)

The manifest's `exampleBlocks[].id` must be stable across template revisions or the merge cannot match a
project's customized block to the corresponding upstream block. Today the markers are free-text
(`<!-- ▼ EXAMPLE BLOCK: project structure — ... ▼ -->`). Add a short stable slug to each marker, e.g.:

```
<!-- ▼ EXAMPLE BLOCK [id=project-structure]: project structure — extend the tree ... ▼ -->
...
<!-- ▲ END EXAMPLE BLOCK [id=project-structure] ▲ -->
```

This is a non-breaking template edit (the slug is inside the existing comment). **Verified against the
current templates: there are exactly 24 EXAMPLE BLOCK regions across 12 template files** — CLAUDE.md×5,
area-CLAUDE.md×4, orchestrator-briefing.md×3, MVP_TASKS.md×2, tdd-brief-template.md×2,
scaffolding-reference.md×2, and one each in security-reviewer.md, README.md, run-tests.md, eval.md,
trace.md, team-protocol.md. Slugging all 24 once gives every region a durable identity. Add a note to
`GENERATE-WITH-CLAUDE.md §10` EXAMPLE-BLOCK list that the slug is the manifest `id`.

**Two marker forms exist in the templates today — slug both.** Some regions are *paired* (an opening
`<!-- ▼ EXAMPLE BLOCK: … ▼ -->` and a separate closing `<!-- ▲ END EXAMPLE BLOCK ▲ -->`); others are
*single-line self-closing* (`<!-- ▼ EXAMPLE BLOCK: … ▲ -->`, no separate END line — e.g. MVP_TASKS.md:53
deliverable map, area-CLAUDE.md:152 area-subagent-candidates, scaffolding-reference.md:61, the
tdd-brief-template.md project-pitfalls block, the README.md inventory block, the run-tests.md notes
block). For the *paired* form, put `[id=<slug>]` in BOTH the open and close markers (so a region boundary
is unambiguous when the upgrade parser walks the file). For the *single-line* form, put `[id=<slug>]` in
the one marker. Recommend a **side fix while slugging**: normalize the single-line regions to the paired
form so every EXAMPLE BLOCK has an explicit machine-detectable start AND end — this makes the per-region
3-way merge in §4 step 3 (`mixed` files) reliable rather than dependent on heuristic region inference.

---

## 3 — Retro-stamping an existing (manifest-less) project

A project generated before this mechanism existed has no `.scaffolding/manifest.json`. It must be
best-effort retro-stamped before its first clean upgrade. This is a **one-time** procedure, ideally a new
slash-command-less recipe in `SCAFFOLDING-GUIDE.md §11` ("Retro-stamping a pre-manifest project"), run by
a fresh Claude Code session pointed at both the project and the current scaffolding checkout.

### Step R1 — Recover the placeholder values + mode (always possible)

These are sitting in the generated files; reverse them out:

- **mode** — `docs/team-protocol.md` exists ⇒ `team`; absent ⇒ `single-operator`. Confirm against whether
  `/team-start` / `/team-end` / `/context-check` commands exist.
- **track** — read `{{TRACK_NAME}}` usage in `docs/team-protocol.md` / root `CLAUDE.md` comm rules; if no
  track prefix appears, `null`.
- **placeholders** — `PROJECT_NAME` from root `CLAUDE.md` H1; `TASK_TRACKER` / `ARCH_DOC` from the actual
  filenames present; per-area stack values from each `<area>/CLAUDE.md` stack table and the `/preflight`
  / `/run-tests` / `/tdd` command bodies (they carry `{{TEST_CMD}}`, `{{LINT_CMD}}`, etc. resolved).
- **optionalCommands / optionalSubagents** — list what is actually present in `.claude/commands/` and
  `.claude/agents/`.
- **generatedFiles / exampleBlocks** — enumerate the present files; map each to its template by name
  (`app/CLAUDE.md` ← `templates/area-CLAUDE.md`, etc.) and classify `kind`. For EXAMPLE BLOCK status:
  read each region in the project file; if it still matches the template's illustrative text, mark
  `illustrative`, else `customized`.

### Step R2 — Recover `generatedFromSha` — three strategies, in priority order

**Strategy A — Ask the user (preferred, cheapest).** `AskUserQuestion`: *"Which scaffolding commit did you
generate this project from?"* If they pulled the scaffolding repo and generated from a known checkout,
they may have it in shell history, a note, or the bootstrap-commit date. Record it; done.

**Strategy B — Detect from git history (date-bounded).** The project's bootstrap commit
(`git log --diff-filter=A -- CLAUDE.md` / first commit touching `.claude/commands/tdd.md`) gives a
**timestamp**. In the scaffolding repo, `git log --until="<bootstrap-date>" -1 --format=%H` yields the
scaffolding commit that was HEAD on or before that date — a strong candidate for `generatedFromSha`.
Record it as `generatedFromSha` with `"shaConfidence": "git-history-inferred"`.

**Strategy C — Verbatim-machinery fingerprint (most robust, no external info).** The `kind: verbatim` files
are byte-identical across all projects generated from the same scaffolding commit (only placeholders
differ, and those are known from R1). So:

1. Take the project's verbatim files (`tdd.md`, the Step-9 routing block in `orchestrator-briefing.md`,
   the escalation taxonomy in root `CLAUDE.md`, commit cadence) and **un-substitute** the recovered
   placeholders to recover the template form.
2. For each candidate scaffolding commit, check out `templates/.claude/commands/tdd.md` (etc.) and compare.
   `git -C <scaffolding> log --format=%H -- templates/.claude/commands/tdd.md` enumerates only the commits
   where the verbatim machinery actually changed — a small set. The newest commit whose verbatim files
   match the project's (modulo placeholders) is the generation SHA, or the closest lower bound.
3. Record `generatedFromSha` = that match with `"shaConfidence": "fingerprint-matched"`.

Strategies B and C reinforce each other: B narrows the candidate set by date; C confirms by content. If
none of the three resolves a SHA, record `generatedFromSha: null`, `"shaUnknown": true`, and set the merge
base to the **oldest scaffolding commit whose verbatim machinery still matches** — the upgrade then over-
reports machinery diffs (safe; just noisier review) rather than silently skipping a real change.

### Step R3 — Write the manifest + commit

Write `.scaffolding/manifest.json` with everything recovered, plus the confidence markers, plus
`"retroStamped": true` and `"retroStampedAt"`. Commit on its own:
`chore(scaffolding): retro-stamp provenance manifest`. From here, the project upgrades like a freshly
generated one.

---

## 4 — How an upgrade run uses the manifest (the payoff)

Not requested as a deliverable, but stated so the manifest fields are justified end-to-end. A future
`/upgrade-scaffolding` recipe (or a guide §11 procedure) does:

1. Read `.scaffolding/manifest.json`. Resolve `base` = templates @ `generatedFromSha`, `ours` = templates @
   current HEAD.
2. For each `generatedFiles[]` row: re-substitute `base` template and `ours` template with the manifest's
   `placeholders` + the matching `codeAreas[]` set → two concrete files. `theirs` = the project's current file.
3. Run a 3-way merge governed by `kind` (§1.2) and, for `mixed` files, the `exampleBlocks[]` ledger:
   - `verbatim` / `placeholder-only`: take `ours` where `theirs == base`; conflict otherwise.
   - `mixed`: machinery + `illustrative` blocks → `ours`; `customized` blocks → kept; surface a conflict only
     if a customized block's surrounding markers changed upstream.
   - `accreted` / `user-canonical`: skeleton-only suggestions; body untouched.
4. New files in `ours` not in `generatedFiles[]` (e.g. a brand-new slash command added upstream) are
   offered as **additions**, filtered by `mode`/`optionalCommands` so single-operator projects are not
   handed `team-start.md`.
5. On success, update `lastUpgradedFromSha` / `lastUpgradedAt` (and refresh `generatedFiles` /
   `exampleBlocks` for any newly added files), then commit. `git log .scaffolding/manifest.json` is the
   upgrade audit trail.

---

## 5 — Summary of deliverables

| Deliverable | Specification |
|---|---|
| Manifest path | `.scaffolding/manifest.json` (committed) + `.scaffolding/README.md` (do-not-edit note) |
| Format | JSON with `schemaVersion`, written via `jq`/direct, validated with `jq .` |
| Fields | provenance (SHA/ref/repo/timestamps) · mode+track+optional commands/subagents · resolved `placeholders` + per-area `codeAreas[]` · `generatedFiles[]` (dest←template, `kind`) · `exampleBlocks[]` (file, id, customized/illustrative) |
| Generator change | New **Step 12.5** writes it; one-line bookkeeping hooks added to §6, §7 Steps 1/2/6/7/8/9/10/11, §10; one-time stable-slug edit to the 24 EXAMPLE BLOCK markers across 12 template files |
| Retro-stamping | R1 reverse placeholders+mode from generated files · R2 recover SHA via ask → git-history-date → verbatim-fingerprint (priority order, with confidence markers) · R3 write + commit `retroStamped: true` manifest |
