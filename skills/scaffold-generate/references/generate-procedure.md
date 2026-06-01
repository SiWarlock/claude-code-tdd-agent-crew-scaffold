# Generate This Scaffolding For Your Project — Instructions for Claude Code

> **You are a Claude Code session bootstrapping the agent-team scaffolding for a NEW project.** The human has handed you this file plus a `templates/` directory and their **architecture document**. Your job: read the architecture doc as the primary input, interview the user for anything you can't infer or anything ambiguous, fill the templates, and write the customized scaffolding into their repo.
>
> **Read `SCAFFOLDING-GUIDE.md` first** (same directory) if you haven't. It explains *what* this scaffolding is and *why* it works. This file is the *build procedure* — it assumes you've absorbed the guide.

---

## §0 — Two non-negotiable rules

These rules govern your entire generation session. Re-read them at the start of each major step.

### Rule 1 — The architecture document is the primary input

The user provides an architecture document (typically `ARCHITECTURE.md`, but it could be `design.md`, `architecture.md`, `design-doc.md`, etc.). **You read it end-to-end before asking any interview questions.** It is the canonical source for:

- Tech stack (runtime, framework, validation lib, lint, types, test runner)
- Code areas / workspaces (the directories with their own stacks)
- Subsystem boundaries (which become `{{ARCH_DOC}}` sections)
- Domain safety invariants (which populate "Key safety rules")
- Layer dependency rules + module organization
- Deliverables (what the project must produce)
- The architecture sentence (if the doc has a load-bearing one-liner)

**Extract everything inferrable from the doc.** Only interview the user for what genuinely isn't there or what's ambiguous.

### Rule 2 — Interview interactively; do NOT fabricate

Any time you encounter ambiguity — a stack detail that could go two ways, a code-area boundary that's unclear, a safety invariant phrased loosely, a missing piece — **stop and ask the user via `AskUserQuestion`**.

**Never fabricate placeholder values.** A wrong value propagates across many files. If you can't infer it and the user hasn't said, ask. The interview is interactive back-and-forth, not a one-shot batch.

**Examples of when to ask:**
- The arch doc says "Python" but doesn't specify version → ask.
- The doc lists `api/` and `worker/` as directories but doesn't say which is the primary code area → ask.
- Two safety invariants seem to contradict each other → surface the apparent conflict; ask which is canonical.
- The phase plan in the user's existing `MVP_TASKS.md` uses `P1.x.x` IDs but the arch doc uses `M<n>.<Cat>.<NN>` — ask which is current.

When a clarification question has discrete options (e.g. "is this a single-operator project or a team-pattern project?"), use `AskUserQuestion`. For free-form answers (project tagline, deliverable list), ask conversationally.

---

## §1 — What you will produce

When you're done, the user's repo will have:

```
CLAUDE.md                       # root — global conventions + shared comm rules
<code-area>/CLAUDE.md           # area conventions (one per code area)
<code-area>/LESSONS.md          # empty lessons skeleton (one per code area)
{{TASK_TRACKER}}                # state + phase plan (skeleton, populated with their phases)
{{ARCH_DOC}}                    # design contract (THEIR architecture doc, optionally extended with cross-doc tables)
docs/
├── team-protocol.md            # lead playbook (team pattern only)
├── orchestrator-briefing.md    # workflow rulebook
├── tdd-brief-template.md       # /tdd brief format
├── scaffolding-reference.md    # project-specific map of their scaffolding
├── briefs/                     # empty — numbered /tdd briefs land here
├── sessions/                   # empty — numbered session docs land here
├── team-handoffs/              # empty — /team-end outputs land here (team pattern only)
└── runbooks/                   # empty — operational procedures
.claude/
├── commands/                   # the slash commands (12 if team pattern, 9 if single-operator; +2 optional)
└── agents/                     # README + optional starter subagents
.scaffolding/
├── manifest.json               # generator-owned provenance manifest — enables clean `/scaffold-upgrade` 3-way merges
└── README.md                   # do-not-hand-edit note (machine-owned, rewritten by upgrades)
```

PLUS user-global installs (team pattern only — performed in Step 13):

```
~/.claude/statusline-command.sh         # Status bar + heartbeat writer
~/.claude/scripts/check-team-context.sh # /context-check helper (joins registry + heartbeats)
```

Everything in `templates/` maps to one of these. The templates carry the **workflow machinery verbatim** — the 10-step `/tdd`, the Step-9 routing matrix, the commit cadence, the checkpoints, the escalation taxonomy. You do **not** redesign any of that. What you customize is the **project-specific content**: stack, code areas, conventions, phase plan, deliverables, architecture sentence, safety invariants.

---

## §2 — Your procedure at a glance

1. **Orient (§3)** — read `SCAFFOLDING-GUIDE.md`; read the user's architecture document end-to-end; inspect the repo for anything you can infer (existing package manifests, directory layout, prior `CLAUDE.md` if any).
2. **Mode choice (§4)** — ask the user: team pattern, or single-operator fallback?
3. **Interview (§5)** — interactive, back-and-forth. Ask only what you can't infer from the architecture doc + repo. Use `AskUserQuestion` for structured choices; conversational for free-form. **Clarification on ambiguity is mandatory; fabrication is forbidden.**
4. **Plan + PAUSE (§6)** — present a one-screen generation plan: mode, code areas, stack(s), phase plan, optional commands, optional subagents, the placeholder values. **Wait for approval.**
5. **Generate (§7)** — fill every template, write every file, and stamp the provenance manifest (Step 12.5).
6. **PAUSE for review (§8)** — let the user read what you wrote before anything is committed.
7. **Handoff (§9)** — tell the user the scaffolding is ready. **Do not commit unless the user asks.**

The two PAUSE points are not optional — they mirror the scaffolding's own checkpoint discipline. Don't write files before the plan is approved; don't commit before the user has reviewed.

---

## §3 — Orient: read the architecture doc

Before the interview begins, do this read pass:

1. **Read `SCAFFOLDING-GUIDE.md`** end-to-end. You should already have this from the package handoff.
2. **Locate the user's architecture document.** Usually one of:
   - `ARCHITECTURE.md` at repo root
   - `docs/ARCHITECTURE.md` / `docs/architecture.md` / `docs/design.md`
   - A path the user named in their prompt
   - If you can't find one, **ask the user where it is** — this is a hard prerequisite.
3. **Read the architecture doc end-to-end.** Extract:
   - Tech stack (per code area if multi-area)
   - Code areas / workspace directories
   - Subsystem boundaries (architecture sections)
   - Safety invariants / key rules
   - Layer / module organization rules
   - Deliverables (what the project must produce)
   - Architecture sentence (if any single load-bearing one-liner exists)
   - Any phase plan or roadmap hints
4. **Inspect the repo.** What's already there?
   - Package manifests (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `composer.json`, etc.) — pin language + version + framework.
   - Existing directory layout — pin code areas.
   - Existing `CLAUDE.md` (if the project already has scaffolding to upgrade) — note what's there.
   - Existing task tracker (`MVP_TASKS.md`, `TASKS.md`, `ROADMAP.md`) — extract phase plan + IDs.
   - Existing `LESSONS.md`, `docs/sessions/`, `docs/briefs/` — note non-empty content.
   - `.git/config` for the remote, if any.

5. **Write a one-paragraph summary** to yourself (or surface to the user) of what you found:
   - Project name + architecture sentence + 1-line description
   - Code areas with stacks
   - Subsystem boundaries identified
   - Safety invariants listed
   - Phase plan source + ID convention
   - What's missing / ambiguous (the basis for the interview)

This becomes the foundation. Now you know what to ask.

---

## §4 — Mode choice: team pattern or single-operator?

Before the substantive interview, ask the user via `AskUserQuestion`:

**Question:** Which mode do you want for this project?

**Options:**
- **Team pattern** — 3 roles (team lead + orchestrator + implementer-per-area), direct teammate comms, escalation taxonomy. Recommended for: multi-week projects, multi-area projects, projects with safety/correctness criticality, parallel work streams. Generates `/team-start`, `/team-end`, `docs/team-protocol.md`, `docs/team-handoffs/`.
- **Single-operator fallback** — 2 sessions, the human is the bridge. Recommended for: solo dev, one-week project, single code area, no parallel tracks. Skips `/team-start`, `/team-end`, `docs/team-protocol.md` — those concepts collapse into the human.

The user's answer determines several downstream generation choices (which slash commands to write, whether to write `team-protocol.md`, how to phrase comm rules in root `CLAUDE.md`).

If the user picks team pattern, follow up with: "Is this a solo team-lead session, or will parallel team-lead sessions run in this repo (e.g. a frontend track + a backend track)?" If parallel, get the **track name** for the lead's spawn (e.g. `frontend`, `backend`).

---

## §5 — The interview (interactive, batched, clarification-mandatory)

Batch the questions. Use `AskUserQuestion` for structured choices, free-form prose for the rest. Don't interrogate one question at a time — but DO stop and ask the moment you hit ambiguity.

**Discipline:** before each batch, restate what you've inferred from the architecture doc + repo so the user can correct you. Ask only what you can't infer.

### Batch A — Project identity

From the architecture doc you should have most of this. Confirm:
- **Project name** and a **one-line description** (the tagline).
- **Repo root directory name** (for path examples in docs).
- **Architecture sentence** — does the project have a single load-bearing one-line posture? If the arch doc has one, quote it back. If not, ask.
- **Git remote** pushes go to (if a remote exists; many projects start local). Default note: "no remote yet — push when one's set up."
- **AI-assist trailer** text (default: `Assisted-by: Claude Code`).

### Batch B — Code areas

This is critical and must be unambiguous before generation.

- **How many code areas?** A code area is a directory with its own stack + its own implementer session (e.g. `app/` Python backend + `web/` React frontend = 2 areas).
- For each: **directory name** (with trailing slash), **human name** (e.g. "the backend API", "the React frontend"), **stack one-liner**.

**If the architecture doc doesn't make code areas obvious, ask the user explicitly.** Don't infer from directory listings alone — `tests/` and `scripts/` aren't code areas; only directories with their own stack + implementer session count.

### Batch C — Stack & commands (per code area)

For each code area:
- **Runtime** (Python 3.x, Node 22, Go 1.x, Rust …)
- **Package manager** (uv, pnpm, npm, cargo, poetry, …)
- **Framework** (FastAPI, React+Vite, Next.js, Hardhat, …)
- **Validation/schema lib** (Pydantic v2, Zod, …)
- **Lint tool** (ruff, ESLint, golangci-lint, …)
- **Type checker** (mypy --strict, tsc --noEmit, …)
- **Test runner** (pytest, vitest, go test, …)
- **Standard commands** — install deps, run dev server, run tests, lint, format-check, type-check.
- **Test classes/markers** for `/run-tests` (e.g. `unit`, `integration`, `e2e`).

Most of this should be inferrable from package manifests. Confirm rather than ask cold.

### Batch D — Workflow

- **Task tracker filename** — default `MVP_TASKS.md`. (Rename only with care — referenced across many files.)
- **Phase IDs** — how phases are labelled. Examples: `W3.M / W3.F / W3.D` (work-stream.MVP/Final/Deferred), `P1 / P2 / P3` (generic), `M1.C.01 / M2.A.03` (Milestone.Category.NN). Check if the user's existing task tracker has an ID convention; otherwise propose one.
- **Phase plan** — the actual phases. From the arch doc + any existing task tracker, extract or propose; let the user confirm.
- **Milestones / deadlines** — if any.
- **Who is the user?** — role, expertise, working preferences. Populates the briefing's "Who the user is" section so future orchestrator sessions calibrate tone correctly. If you can't tell from the doc, ask explicitly.

### Batch E — Architecture & domain

- **Deliverables** — what the project must produce (running app, deployed service, docs, reports, deliverable artifacts). Populates the `{{TASK_TRACKER}}` deliverable map.
- **Forbidden patterns** — 3–5 domain-specific "don't do X, do Y because Z" rules. Extract from the arch doc; ask the user for additions if the doc is sparse.
- **Key safety rules / load-bearing invariants** — domain-specific invariants stated explicitly (authorization, data-handling, isolation boundaries, solvency invariants, settlement rules, whatever applies). **If the arch doc has these, quote them verbatim back to the user — don't paraphrase.** If it doesn't, ask whether the project has any.
- **Layer dependency rule + module organization** — the directory layout + the import-direction DAG. Extract from the arch doc; ask if unclear.
- **`{{ARCH_DOC}}` sections** — the subsystem boundaries the architecture doc covers. Use the arch doc's existing section list; offer to extend if it's a skeleton.
- **Optional commands:**
  - Include `/eval`? (only for projects with an eval/test-suite class worth a dedicated command).
  - Include `/trace`? (only for observability-heavy projects with structured traces).
  - If unsure, **omit** — they're easy to add later.
- **Optional starter subagents** (team-pattern projects benefit most):
  - `code-quality-reviewer` — Step 7→8 parallel review. **Default yes** for any non-trivial project.
  - `security-reviewer` — Step 7→8 parallel review, mandatory on invariant-touching slices. **Default yes** for projects with safety invariants; default no otherwise.
  - `reachability-auditor` — phase-exit gate audit. **Default yes** — universal value.
  - `brief-drafter` — orchestrator's brief-skeleton tool. **Default yes for definition file; integration deferred until quality trial.** (See `agents/README.md` for the trial protocol.)

---

## §6 — Plan and pause

After the interview, present a compact **generation plan** and **wait for approval**:

- **Mode:** team pattern (track: `<track>` if parallel) OR single-operator fallback.
- **Project identity:** name, repo dirname, architecture sentence (or "none").
- **Code areas:** N areas — `<dir>` (`<name>`, `<stack one-liner>`) …
- **Phase IDs + the phase list** going into `{{TASK_TRACKER}}`.
- **Optional commands included:** `/eval`? `/trace`? `/wired` (standard, always).
- **Optional starter subagents included:** which of the 4.
- **Filled values for every `{{PLACEHOLDER}}`** — a short table.
- **EXAMPLE BLOCKs you'll rewrite** — one-line summary of what each becomes.
- **Provenance manifest** — note that `.scaffolding/manifest.json` will be stamped at the end (Step 12.5): it records the scaffolding commit, your filled placeholder values, and the file/EXAMPLE-BLOCK ledger so future `/scaffold-upgrade` runs are clean 3-way merges, not hand-diffs.

**Do not write any files until the user approves this plan.** If the user changes their mind on mode or other foundational choices, re-do the plan.

---

## §7 — Generation procedure

Write the files in **dependency order** — later files reference earlier ones.

> **Manifest bookkeeping (build the ledger as you go).** As you write each file below, keep a running record for the manifest you stamp in **Step 12.5** — it must be complete by then. For every file you write, note a `generatedFiles[]` row `{dest, template, kind, area?}`, where `kind` is:
> - `placeholder-only` — only `{{TOKENS}}` vary; e.g. most `.claude/commands/*` (`tdd.md`, `preflight.md`, `session-start.md`, `check-arch.md`, …) and a single-area `run-tests.md`.
> - `mixed` — machinery **plus** `EXAMPLE BLOCK` regions: root `CLAUDE.md`, area `CLAUDE.md`, `orchestrator-briefing.md`, `team-protocol.md`, `tdd-brief-template.md`, `scaffolding-reference.md`, `agents/README.md`, `security-reviewer.md`, `eval.md`, `trace.md`, multi-area `run-tests.md`.
> - `accreted` — living bodies that grow through real work: every `LESSONS.md`, and `{{TASK_TRACKER}}` (its living sections).
> - `user-canonical` — the user's `{{ARCH_DOC}}` (out of scope for upgrades; only Appendix A is ever touched).
> - `verbatim` — pure machinery with no varying placeholders (rare; use only if a file genuinely has none).
>
> And for every `EXAMPLE BLOCK [id=<slug>]` region in a file you write, note an `exampleBlocks[]` row `{file, id, status}` — `status: "customized"` if you replaced the illustrative default with the project's real content, `"illustrative"` if you left the template's example in place. The `[id=<slug>]` is the stable id carried in both the opening and closing `EXAMPLE BLOCK` comment (see §10 for the full id map).

### Step 1 — Root `CLAUDE.md`

From `templates/CLAUDE.md`. Fill identity placeholders, the project-structure tree (reflect the user's actual code areas), the tech-stack table, the cross-cutting conventions. Keep the **Team coordination — shared rules** section verbatim — it's the workflow machinery shared by all roles. If **single-operator mode**: trim the lead-specific lines (track-prefix is irrelevant, escalation taxonomy collapses to "raise with yourself"); note the fallback explicitly.

Keep it **short** — area-specific rules go in the area file.

### Step 2 — Area `CLAUDE.md` (one per code area)

From `templates/area-CLAUDE.md`, written to `<code-area>/CLAUDE.md`. For a multi-area project, generate one per area, each with its own stack + launch protocol. Fill the stack table and standard commands; **leave the lookup table, cross-doc invariants table, forbidden patterns, and lessons index near-empty** — 1–2 illustrative rows max, with a "populate as the project accretes" note. These fill in over the project's life; pre-filling them invents state.

### Step 3 — Area `LESSONS.md` (one per code area)

From `templates/area-LESSONS.md`, written to `<code-area>/LESSONS.md`. This is just the header + the lesson-format block + "lessons start at §1." **Do not invent lessons.** It's empty by design.

### Step 4 — `{{TASK_TRACKER}}`

From `templates/MVP_TASKS.md`. Fill the phase note, session protocol, deadlines, the deliverable map, and the **phase sections** with the user's actual phase plan (task entries as dense checkbox bullets — *not* pre-written briefs). "Currently in progress" starts as "Bootstrap session." Everything else (Carry-forward, Decisions tabled, Log, Trims) starts **empty**.

### Step 5 — `{{ARCH_DOC}}`

Two paths depending on what the user gave you:

- **If the user's arch doc is the canonical source:** preserve it as-is. **Do NOT overwrite the user's architecture doc.** Instead, ensure **Appendix A — Model / contract inventory** exists at the end (per `templates/ARCHITECTURE.md`) — append it if missing, leave the user's existing prose untouched. This appendix is the canonical home for the cross-doc invariants the area `CLAUDE.md` table mirrors.
- **If the user only has a skeleton / outline:** extend it from `templates/ARCHITECTURE.md` — section headings from the user's Batch-E answer, each with a 1–2 sentence stub. **Do not write the architecture content** — it accretes as decisions land. If there's an architecture sentence, place it in the executive summary stub.

### Step 6 — `docs/team-protocol.md` (TEAM PATTERN ONLY)

From `templates/docs/team-protocol.md`. Fill identity placeholders. Keep the lead playbook content verbatim — that's the workflow machinery. **Skip this file entirely in single-operator mode.**

### Step 7 — `docs/orchestrator-briefing.md`

From `templates/docs/orchestrator-briefing.md`. Fill "Who the user is," the project-context paragraph, the document-read-order, and the project-specific conventions list. **Keep the Step-9 routing matrix, messaging budget table, commit cadence, and checkpoint rules verbatim.** In single-operator mode, the "messaging budget" still applies but the recipient is "the user (acting as bridge)" rather than the orchestrator teammate — note this contextually.

### Step 8 — `docs/tdd-brief-template.md`

From `templates/docs/tdd-brief-template.md`. Mostly verbatim. The "Common pitfalls" section: keep the *general* pitfalls (don't-bundle-safety-critical, every-brief-has-Step-2.5-question, acceptance-criteria-as-behaviors, no-`/session-start`-in-briefs); the project-specific ones are EXAMPLE BLOCKs — keep labelled as illustrative or swap for the user's own recurring pitfalls as they emerge. Same for the worked example.

### Step 9 — `docs/scaffolding-reference.md`

From `templates/docs/scaffolding-reference.md`. Project-specific map. Fill the file inventory, the command table, the conventions. It's the in-repo companion to `SCAFFOLDING-GUIDE.md`.

### Step 10 — Slash commands (`.claude/commands/`)

From `templates/.claude/commands/`. Generation order:

**Team pattern:**
- `team-start` → `team-end` → `orchestrate-start` → `orchestrate-end` → `session-start` → `session-end` → `tdd` → `preflight` → `run-tests` → `check-arch` → `wired`
- Then optionally: `eval` / `trace`

**Single-operator:**
- `orchestrate-start` → `orchestrate-end` → `session-start` → `session-end` → `tdd` → `preflight` → `run-tests` → `check-arch` → `wired`
- Then optionally: `eval` / `trace`
- Skip: `team-start`, `team-end`

For each:
- **Highly portable** (`tdd`, `session-start`, `session-end`, `orchestrate-start`, `orchestrate-end`, `check-arch`, `wired`, `team-start`, `team-end`, `context-check`) — fill command/path placeholders, keep procedures verbatim.
- **`preflight`, `run-tests`** are cwd-aware in the template. **If the project has one code area, delete the mode-detection and any second-mode block** — leave a single linear gate. If 2 areas, fill both modes. If 3+ areas, expand the case statement to cover each area, repeating the per-area block.
- **`context-check`** — generate ONLY in team-pattern mode. Skip for single-operator-fallback.
- **`eval`, `trace`** — include only if the user opted in (Batch E). Otherwise don't write them.

### Step 11 — `.claude/agents/`

Always write `templates/.claude/agents/README.md` with the updated inventory.

For each of the 4 starter subagents the user opted into, write its definition file from `templates/.claude/agents/<name>.md`. The starter subagents are highly portable — fill area / language placeholders where applicable; keep the scope, protocol, forbidden-patterns, and output sections verbatim.

If the user opted out of all 4, the directory contains only `README.md` (the original "empty inventory" stance is preserved).

### Step 12 — Empty directories

Create empty directories (a `.gitkeep` is fine):
- `docs/briefs/`
- `docs/sessions/`
- `docs/runbooks/`
- `docs/team-handoffs/` (team pattern only)

The first brief / session / handoff lands in the first real working round, not at bootstrap.

### Step 12.5 — Stamp the provenance manifest (`.scaffolding/`)

Write **`.scaffolding/manifest.json`** and a short **`.scaffolding/README.md`** (from `templates/.scaffolding/README.md`). This is **additive and non-interactive** — it records decisions already made during the interview plus the files you just wrote. Its purpose: give `/scaffold-upgrade` a recoverable common ancestor so future scaffolding updates are clean **3-way merges** instead of hand-diffs. **Do this before the §8 review PAUSE** so the manifest is part of what the user reviews.

Assemble it from the ledger you built in §7 plus the foundational choices:

```json
{
  "schemaVersion": 1,
  "scaffoldingRepo": "<remote URL or local path of the scaffolding checkout>",
  "generatedFromSha": "<full 40-char SHA — `git -C <scaffolding-checkout> rev-parse HEAD`>",
  "generatedFromRef": "<branch or tag that SHA was on — advisory>",
  "generatorModel": "<which model ran generation — advisory>",
  "generatedAt": "<ISO-8601 timestamp>",
  "lastUpgradedFromSha": null,
  "lastUpgradedAt": null,

  "mode": "team | single-operator",
  "track": "<track name, or null>",
  "optionalCommands": ["eval", "trace"],
  "optionalSubagents": ["code-quality-reviewer", "security-reviewer", "reachability-auditor", "brief-drafter"],

  "placeholders": { "PROJECT_NAME": "…", "ARCH_DOC": "ARCHITECTURE.md", "TASK_TRACKER": "MVP_TASKS.md", "AI_TRAILER": "…", "…": "…" },
  "codeAreas": [
    { "CODE_AREA": "app/", "CODE_AREA_NAME": "backend", "CODE_AREA_BASENAME": "app",
      "RUNTIME": "Python 3.12", "PKG_MANAGER": "uv", "TEST_CMD": "uv run pytest",
      "TYPECHECK_CMD": "uv run mypy app", "BUILD_CMD": null }
  ],

  "generatedFiles": [
    { "dest": "CLAUDE.md", "template": "templates/CLAUDE.md", "kind": "mixed" },
    { "dest": "app/CLAUDE.md", "template": "templates/area-CLAUDE.md", "kind": "mixed", "area": "app/" },
    { "dest": "app/LESSONS.md", "template": "templates/area-LESSONS.md", "kind": "accreted", "area": "app/" },
    { "dest": ".claude/commands/tdd.md", "template": "templates/.claude/commands/tdd.md", "kind": "placeholder-only" }
  ],
  "exampleBlocks": [
    { "file": "CLAUDE.md", "id": "tech-stack", "status": "customized" },
    { "file": "CLAUDE.md", "id": "key-safety-rules", "status": "customized" },
    { "file": "app/CLAUDE.md", "id": "forbidden-patterns", "status": "illustrative" }
  ]
}
```

Rules:
- **`generatedFromSha`** is the full 40-char HEAD of the **scaffolding checkout** you generate from (not the target project): `git -C <scaffolding-checkout> rev-parse HEAD`. If the templates were handed over outside a git checkout and no SHA is resolvable, record `"generatedFromSha": null` plus `"shaUnknown": true` and a short `"note"` — `/scaffold-upgrade` falls back to a verbatim-machinery fingerprint.
- **`placeholders` / `codeAreas` are exactly the values you substituted** — every resolved token, verbatim. `codeAreas` is an array (one entry per area; a 2nd+ area maps to the `{{CODE_AREA_2}}`… suffix set); `BUILD_CMD` may be `null`.
- **`generatedFiles[]` / `exampleBlocks[]`** are the ledger you built incrementally in §7. Include **every** file you wrote — accreted and user-canonical files too, so the upgrade knows they exist and leaves them alone.
- This file is **machine-owned** — never hand-edited — and **committed** (it lives in git for the upgrade's archaeology). Validate it parses: `jq . .scaffolding/manifest.json`.
- **No interview here.** If you find you're missing a value the manifest needs, you fabricated or skipped it earlier — stop and resolve it (Rule 2); don't invent one now.

### Step 13 — Install user-global context-monitoring scripts (TEAM PATTERN ONLY)

The team-mode context monitoring + auto-cycle (per `SCAFFOLDING-GUIDE.md §8` "Context monitoring + auto-cycle") requires two user-global bash scripts. These live in `~/.claude/`, not in the project repo, because they're shared across all the user's projects that use this scaffolding.

**Skip this step entirely in single-operator-fallback mode** — no context-monitoring system exists in solo mode.

**Scripts to install:**

1. **`~/.claude/statusline-command.sh`** — renders the status bar + writes the heartbeat (conditional on team-registry entry existing for the session).
2. **`~/.claude/scripts/check-team-context.sh`** — the join + threshold-tier helper that `/context-check` invokes.

**Handle three scenarios:**

#### Scenario A — User has no existing `~/.claude/statusline-command.sh`

Install fresh. Copy from template:

```bash
mkdir -p ~/.claude/scripts
cp templates/scripts/statusline-command.sh ~/.claude/statusline-command.sh
cp templates/scripts/check-team-context.sh ~/.claude/scripts/check-team-context.sh
chmod +x ~/.claude/statusline-command.sh ~/.claude/scripts/check-team-context.sh
```

Then add to the user's `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /Users/<USER>/.claude/statusline-command.sh"
  }
}
```

Replace `<USER>` with the actual username.

#### Scenario B — User has an existing custom `~/.claude/statusline-command.sh`

**Do NOT overwrite.** The user's existing script likely has custom formatting they want to keep. Two sub-options:

- **(B1) Merge the HEARTBEAT BLOCK into the user's existing script.** Show the user the marked-off block in `templates/scripts/statusline-command.sh` (between `▼ HEARTBEAT BLOCK` and `▲ END HEARTBEAT BLOCK`), and ask them to paste it near the top of their existing script (right after they parse `$input`). Verify their script preserves the `input=$(cat)` line — the heartbeat block depends on `$input` being captured.

- **(B2) Use the template script as-is.** If the user is OK swapping their custom status line for ours, back up theirs first (`mv ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.bak`), then copy the template in. They can re-merge their formatting later.

**Always:** install the helper script:
```bash
mkdir -p ~/.claude/scripts
cp templates/scripts/check-team-context.sh ~/.claude/scripts/check-team-context.sh
chmod +x ~/.claude/scripts/check-team-context.sh
```

#### Scenario C — User wants Claude to do it

If the user asks "you handle it" — use `Read` + `Edit` to do scenario B1 surgically (read their script, locate the `input=$(cat)` line, insert the HEARTBEAT BLOCK after it). Verify by re-reading the result.

**Verification step:**

After install, ask the user to confirm:
1. Start a new Claude Code session (or check this one's status line) — the status bar should still render normally.
2. Run `~/.claude/scripts/check-team-context.sh` from a terminal. With no team active, output should be: `No team registry entries found. Are any team sessions active?`
3. If the user runs `/team-start` from this scaffolding, the spawn prompts will write team-registry entries for each teammate; then `/context-check <team>` should show live ctx_pct.

**Settings.json — what to change and what NOT to change:**

The settings file is `~/.claude/settings.json` (USER-GLOBAL, NOT the project's `.claude/settings.json`). The context-monitoring system is implemented via the status line script + the spawn-prompt registry-write — **not via Claude Code hooks**. Do NOT add any hook config (no `Stop`, `SessionStart`, `UserPromptSubmit`, etc. hooks are required or used by this system).

What you DO change in `~/.claude/settings.json`:

1. **`statusLine.command`** — point at the installed script. If the user already has a `statusLine` set (scenario B), it's already pointing at their script; just leave it. If you installed fresh (scenario A), set it now.
2. **Optional: `env.CLAUDE_TEAM_CTX_*`** — only if customizing thresholds. Defaults (70/75/80) are baked into the helper script and work without env-var setup.

What you do NOT change:

- **Hooks** — none needed. The system runs entirely through status-line + slash-commands + spawn-prompt-driven Bash.
- **Permissions, env, plugins, theme, etc.** — leave untouched unless the user asks.
- **The project's `.claude/settings.json`** — this is a USER-GLOBAL feature; don't touch project-local settings.

**Merge, don't replace.** If `~/.claude/settings.json` already exists (it almost always does), READ it first, then add only the missing keys. Use `Read` + `Edit`, never `Write` — overwriting destroys the user's existing config (plugins, themes, hooks, MCP servers, etc.).

**Threshold env vars (optional install-time configuration):**

The defaults (`WARN=70`, `ACTION=75`, `HARD=80`) are conservative. To customize, add to `~/.claude/settings.json` `env` block (MERGE into existing `env`, don't replace):

```json
{
  "env": {
    "CLAUDE_TEAM_CTX_WARN": "70",
    "CLAUDE_TEAM_CTX_ACTION": "75",
    "CLAUDE_TEAM_CTX_HARD": "80"
  }
}
```

Ask the user only if they have a strong preference; default values are fine for most projects.

---

## §8 — After generation: PAUSE for review

**Stop. Tell the user what you wrote.** Summarize:
- Files created (count + paths).
- Mode chosen (team pattern + track / single-operator).
- Optional commands + subagents included.
- Anything that diverged from the user's first answers during generation (e.g. you discovered a third code area while writing area-CLAUDE.md).

**Let the user review before any commit.** If they want changes, iterate.

---

## §9 — Handoff

Once the user has reviewed:

1. **Tell the user the scaffolding is live.** Suggest:
   - The first slice can start with `/team-start <track>` (team pattern) or `/orchestrate-start` (single-operator), which authors the first `/tdd` brief into `docs/briefs/001-...`.
   - In team-pattern mode: the lead spawns the orchestrator + first implementer via the templates in `/team-start.md`.
2. **Do NOT commit.** Leave the bootstrap commit to the user. If the user explicitly asks you to commit, use one round commit:
   ```
   chore(scaffolding): bootstrap agent-team scaffolding

   <one paragraph: what landed, which optional commands were included,
   how many code areas, single-operator-fallback-or-team-pattern>

   {{AI_TRAILER}}
   ```

---

## §10 — Placeholder manifest

Every `{{PLACEHOLDER}}` the templates use. Confirm a value for each during the interview.

### Identity & repo

| Placeholder | Meaning | Example |
|---|---|---|
| `{{PROJECT_NAME}}` | Full project name | `Apex Logistics` / `Aurora API` |
| `{{PROJECT_TAGLINE}}` | One-line description | `Real-time route optimization service` |
| `{{ARCHITECTURE_SENTENCE}}` | The load-bearing one-liner (optional — omit lines that use it if N/A) | `The dispatcher is the single source of truth; workers are stateless; jobs are idempotent.` |
| `{{REPO_DIRNAME}}` | Repo root directory name | `apex-logistics` |
| `{{GIT_REMOTE}}` | Remote pushes go to (or "none configured") | `origin` / `the project fork` / `none configured` |
| `{{AI_TRAILER}}` | Commit trailer for AI-assisted commits | `Assisted-by: Claude Code` / `Co-Authored-By: Claude <noreply@anthropic.com>` |

### Workflow file names (defaults shown — rename only with care; they're referenced across many files)

| Placeholder | Meaning | Default |
|---|---|---|
| `{{TASK_TRACKER}}` | The state + phase-plan file | `MVP_TASKS.md` |
| `{{ARCH_DOC}}` | The design-contract file | `ARCHITECTURE.md` |
| `{{PHASE_IDS}}` | How phases are labelled | `W3.M / W3.F / W3.D` or `P1 / P2 / P3` or `M1.C.01 / M2.A.03` |

### Team pattern only

| Placeholder | Meaning | Example |
|---|---|---|
| `{{TRACK_NAME}}` | The track this team-lead session covers (if parallel teams run) | `frontend` / `backend` (omit for solo team) |

### Code area (repeat the area-scoped rows per code area)

| Placeholder | Meaning | Example |
|---|---|---|
| `{{CODE_AREA}}` | Code-area directory (with trailing slash) | `app/`, `web/`, `src/` |
| `{{CODE_AREA_NAME}}` | Human name for the area | `backend`, `the React frontend` |
| `{{CODE_AREA_BASENAME}}` | Bare directory name, no slash — used for `cwd` matching in `/preflight` + `/run-tests` | `app`, `web` |
| `{{RUNTIME}}` | Language runtime + version | `Python 3.12`, `Node 22 LTS` |
| `{{PKG_MANAGER}}` | Dependency manager | `uv`, `pnpm` |
| `{{FRAMEWORK}}` | Primary framework (if any) | `FastAPI`, `React 19 + Vite` |
| `{{VALIDATION_LIB}}` | Runtime validation / schema lib | `Pydantic v2`, `Zod` |
| `{{LINT}}` | Linter | `ruff`, `ESLint` |
| `{{TYPECHECKER}}` | Static type checker | `mypy --strict`, `tsc --noEmit` |
| `{{TEST_RUNNER}}` | Test runner | `pytest`, `Vitest` |
| `{{INSTALL_CMD}}` | Install dependencies | `uv sync`, `pnpm install` |
| `{{DEV_CMD}}` | Run dev server | `uv run uvicorn app.main:app --reload`, `pnpm dev` |
| `{{TEST_CMD}}` | Run the test suite | `uv run pytest`, `pnpm test:run` |
| `{{TEST_CMD_SINGLE_FILE}}` | Run one test file (used in `/tdd` Steps 3 & 5) | `uv run pytest <path> -v`, `pnpm test:run <path>` |
| `{{TEST_CMD_UNIT}}` / `{{TEST_CMD_INTEGRATION}}` / `{{TEST_CMD_ALL}}` | `/run-tests` mapping commands | per project |
| `{{LINT_CMD}}` | Run the linter | `uv run ruff check .`, `pnpm lint` |
| `{{FORMAT_CHECK_CMD}}` | Check formatting | `uv run ruff format --check .`, `pnpm format --check` |
| `{{TYPECHECK_CMD}}` | Run the type checker | `uv run mypy app`, `pnpm typecheck` |
| `{{BUILD_CMD}}` | Build (if applicable — e.g. frontend production build) | `pnpm build`, `cargo build --release` |
| `{{TEST_CLASSES}}` | `/run-tests` argument values (the `argument-hint`) | `unit\|integration\|all` |

> `{{CODE_AREA}}` **includes its trailing slash** — templates use it as a path prefix (`{{CODE_AREA}}CLAUDE.md` → `app/CLAUDE.md`). `{{CODE_AREA_BASENAME}}` is the bare name for `cwd` matching.

### N-area projects (>2 areas)

For 3+ areas, expand placeholders by suffix: `{{CODE_AREA_2}}` / `{{CODE_AREA_3}}` / `{{CODE_AREA_4}}` …, each with its full set of area-scoped rows (`{{CODE_AREA_2_NAME}}`, `{{INSTALL_CMD_2}}`, `{{TEST_CMD_2}}`, etc.). For 1-area projects, **delete** the `_2`+ blocks entirely from `/preflight` and `/run-tests` rather than filling them — those commands collapse to a single linear gate.

### EXAMPLE BLOCKs (rewrite wholesale, don't substitute a value)

Each `EXAMPLE BLOCK` region carries a stable **`[id=<slug>]`** in both its opening (`<!-- ▼ EXAMPLE BLOCK [id=<slug>]: … ▼ -->`) and closing (`<!-- ▲ END EXAMPLE BLOCK [id=<slug>] ▲ -->`) marker. The slug is the manifest's `exampleBlocks[].id`. Rewrite each block's **content** for the project (or leave the illustrative default and record it as `illustrative`); **never alter the marker line or its `[id=`** — `/scaffold-upgrade` keys per-region merges on it. The 24 regions across 12 files:

| File | EXAMPLE BLOCK ids |
|---|---|
| `CLAUDE.md` | `project-structure` · `tech-stack` · `strict-typing-posture` · `tdd-scope` · `key-safety-rules` |
| `<code-area>/CLAUDE.md` (`area-CLAUDE.md`) | `area-stack` · `forbidden-patterns` · `module-layout` · `area-subagent-candidates` |
| `docs/orchestrator-briefing.md` | `who-the-user-is` · `project-context` · `project-conventions` |
| `{{TASK_TRACKER}}` (`MVP_TASKS.md`) | `deliverable-map` · `task-entry-format` |
| `docs/tdd-brief-template.md` | `tdd-brief-worked-example` · `project-specific-pitfalls` |
| `docs/scaffolding-reference.md` | `inventory-extension` · `instance-conventions` |
| `docs/team-protocol.md` | `code-areas` |
| `.claude/agents/README.md` | `starter-subagent-inventory` |
| `.claude/agents/security-reviewer.md` | `safety-invariant-cross-checks` |
| `.claude/commands/run-tests.md` | `test-class-discipline-notes` |
| `.claude/commands/eval.md` | `eval-body` |
| `.claude/commands/trace.md` | `trace-body` |

---

## §11 — Hard rules (do NOT)

- **Don't redesign the workflow.** The 3-role pattern (or single-operator fallback), the `/tdd` steps, the routing matrix, the commit cadence, the checkpoints, the escalation taxonomy — these are the *point* of the scaffolding. Fill placeholders; keep the machinery verbatim.
- **Don't fabricate placeholder values or arch-doc content.** If you can't infer from the architecture doc or repo, **ask the user**. A wrong placeholder propagates across many files. Phrase the question crisply via `AskUserQuestion` if it has discrete options; conversationally otherwise.
- **Don't overwrite the user's architecture document.** Extend it minimally (Appendix A if missing). The user's prose is canonical.
- **Don't inject project STATE into scaffolding files.** "Phase 1 is done" / "currently building X" belongs in `{{TASK_TRACKER}}`, never in a slash command or the briefing. Scaffolding describes *how the workflow runs*, not where the project is.
- **Don't pre-build subagents the user didn't opt into.** Those that aren't included stay un-generated; the directory just has `README.md`.
- **Don't invent lessons, decisions, or carry-forward items.** Those files start empty and accrete through real work.
- **Don't skip the interview or guess.** Even one fabricated value can cascade.
- **Don't skip the two PAUSE points** (after the plan, before the commit). They mirror the scaffolding's own checkpoint discipline — practice what you're installing.
- **Don't commit unless the user explicitly asks.** The user reviews and commits themselves.
- **Don't `git add -A`** even when the user asks for a commit. Stage scaffolding files explicitly.
