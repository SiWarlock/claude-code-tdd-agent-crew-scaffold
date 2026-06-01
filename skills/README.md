# cc-crew skills — the planning chain

Custom skills that run the cross-model **planning front** of the cc-crew workflow, upstream of the
agent-team implementation engine. They live in the scaffolding repo and are run from this checkout
(not vendored into each project). See `workflow-analysis/synthesis/workflow-overview.md` for the full
design and `workflow-analysis/flow.html` for the visual.

```
PRD ──▶ arch-draft ──▶ arch-finalize ──▶ tasks-gen ──▶ scaffold-generate ──▶ /tdd engine
        (GPT-5.5/Codex)   (Claude)         (Claude)        (Claude)            (Claude)
        Brain 1           Brain 2          Brain 2         Brain 2
```

| Skill | Runs on | What it does | Status |
|---|---|---|---|
| **`arch-draft`** | **GPT-5.5 / Codex** (Brain 1; host-neutral) | PRD → architecture rough draft + supporting artifacts via the Deep Architecture Planning Playbook (interview-gated, never codes) → `docs/planning/` | ✅ built |
| **`arch-finalize`** | Claude Code (Brain 2) | gap-audit + adversarial scrutiny of the draft → binding `ARCHITECTURE.md` | ✅ built |
| **`tasks-gen`** | Claude Code | finalized `ARCHITECTURE.md` → spec-anchored `MVP_TASKS.md` | ✅ built |
| **`scaffold-generate`** | Claude Code | personalize the agent-team harness from `ARCHITECTURE.md` + `MVP_TASKS.md` + planning artifacts; stamp `.scaffolding/manifest.json` | ✅ built |
| **`scaffold-upgrade`** | Claude Code | keep an already-generated project's scaffolding current via a provenance-manifest **3-way merge** (propose-don't-clobber); bundled `scaffold_upgrade.sh` + `migrations/` registry | ✅ built |

`scaffold-upgrade` (keep a project's scaffolding current via a provenance-manifest 3-way merge) is
**built** — `SKILL.md` + bundled `references/` (the consolidated spec + design detail) +
`scripts/scaffold_upgrade.sh` (bash+jq+git, smoke-tested) + the repo-root `migrations/` registry. It is
**run from this checkout, never vendored** into projects, so the upgrade logic never goes stale. Its read-only
path (`--check` / dry-run) is safe to dogfood. The lifecycle map for composing gstack/CE inserts around all
these skills is **`ROUTING.md`**.

## Standalone skills (not in the chain)

| Skill | Runs on | What it does | Status |
|---|---|---|---|
| **`bug-hunt`** | **Codex or Claude** (host-neutral) | on-demand **root-cause debugging** — reproduce-with-a-failing-test (strong default) → localize → root cause → fix via the TDD loop → verify → opt-in compound into a lesson + forbidden-pattern. Two modes (in-build / incident). | ✅ built |

`bug-hunt` is **not a lifecycle stage** — invoke it whenever a bug surfaces, in any session or repo. It uses
the project's `/tdd`, `/wired`, and `LESSONS.md` / forbidden-patterns when present, and degrades gracefully
elsewhere.

## Why the cross-model split
`arch-draft` runs on **GPT-5.5 via Codex** and `arch-finalize` runs on **Claude** on purpose: two
independent models over the architecture (one drafts, the other adversarially finalizes) catch more than
one model reviewing its own work twice. The handoff is **file-based** — `arch-draft` writes
`docs/planning/*`; `arch-finalize` reads them. `arch-finalize` can optionally bring GPT back as a
cross-model reviewer (gstack `/codex`).

## Install

**`arch-draft` → both Codex and Claude.** It's Brain 1 on GPT-5.5/Codex, but it's authored host-neutral,
so install it in **both** skills dirs and run the draft on whichever lane you're in (e.g. the Codex lane in
Conductor, or Claude directly):
```bash
mkdir -p ~/.codex/skills ~/.claude/skills
ln -snf "$PWD/skills/arch-draft" ~/.codex/skills/arch-draft    # Codex / GPT-5.5 lane
ln -snf "$PWD/skills/arch-draft" ~/.claude/skills/arch-draft   # Claude lane
```
(Host-neutral: it asks questions via whatever question tool the host provides, falling back to plain
numbered prompts.)

**`arch-finalize`, `tasks-gen`, `scaffold-generate`, `scaffold-upgrade` → Claude Code:**
```bash
ln -snf "$PWD/skills/arch-finalize"     ~/.claude/skills/arch-finalize
ln -snf "$PWD/skills/tasks-gen"         ~/.claude/skills/tasks-gen
ln -snf "$PWD/skills/scaffold-generate" ~/.claude/skills/scaffold-generate
ln -snf "$PWD/skills/scaffold-upgrade"  ~/.claude/skills/scaffold-upgrade
```

**`bug-hunt` → both Codex and Claude** (host-neutral, standalone — usable in any session, any repo):
```bash
ln -snf "$PWD/skills/bug-hunt" ~/.codex/skills/bug-hunt
ln -snf "$PWD/skills/bug-hunt" ~/.claude/skills/bug-hunt
```

**Notes.**
- **Symlinks, not copies** — they stay live against this checkout (and `scaffold-upgrade` keeps running *from
  the checkout*, never vendored into a project).
- **Restart the host session** after linking — Claude Code / Codex discover skills at session start, so newly
  linked skills won't appear as slash commands until the next session.
- **Conductor** reads global + project configs, so this global install surfaces the skills in **both** its
  Claude and Codex lanes — exactly what the two-brain planning front needs (`arch-draft` on the Codex lane,
  `arch-finalize` / `tasks-gen` / `scaffold-generate` on the Claude lane).
- **Managing skills with a central manager** (a tool that symlinks from a central store): register all
  six there, and make sure **`arch-draft` AND `bug-hunt` are exposed to BOTH** `~/.codex/skills/` and
  `~/.claude/skills/` (they're host-neutral) — most managers default to the Claude dir only.
- Eventually these become a packaged `cc-crew` plugin; for now, run them from this checkout.

## Artifacts & flow
- `arch-draft` writes everything to **`docs/planning/`** (mode-dependent set; see the skill), including
  `ARCHITECTURE_DRAFT.md` and `CLAUDE_CODE_HANDOFF.md`.
- `arch-finalize` reads all of `docs/planning/*` + the PRD → writes the binding **`ARCHITECTURE.md`** at
  the repo root.
- `tasks-gen` reads `ARCHITECTURE.md` → writes **`MVP_TASKS.md`** at the repo root.
- The three 🔒 artifacts `ARCHITECTURE.md`, `MVP_TASKS.md`, and the `/tdd` ordering stay owned by these
  skills — composed plugins (gstack/CE) feed-into or review around them, never author them.
