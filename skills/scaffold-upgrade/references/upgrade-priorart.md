# Prior Art: Updating an Already-Generated Project When Its Source Template Changes

**Question:** When you scaffold a project from a template, then the template improves, how do you pull
those improvements into the already-generated project *without* clobbering the user's local edits?

This brief surveys the five established tools (copier, cruft, cookiecutter, projen, Yeoman), distills the
canonical pattern they converged on, summarizes how gstack does Claude-native self-upgrade + migrations,
and states what to **borrow** and **avoid** for a Claude Code *skill* (not a standalone CLI).

---

## 1. The five tools

### copier (`copier update`) — the gold standard

- **Provenance stored:** `.copier-answers.yml` committed in the generated project. Records the template
  source, the template version/commit it was last rendered from (`_commit`), the template path
  (`_src_path`), and **every answer** the user gave. The docs are emphatic: *never hand-edit this file* —
  doing so makes Copier believe a different answer set produced the current tree, corrupting the merge.
- **Merge algorithm (true 3-way):**
  1. Regenerate a *fresh* project from the **old** template version + recorded answers.
  2. Regenerate a fresh project from the **new** template version + answers.
  3. Diff "old-fresh → current-on-disk" to capture the **user's** local changes.
  4. Lay down the new template output, then **re-apply the user diff** on top.
  This is the same shape as a `git merge`: a common ancestor (old-fresh render), "theirs" (new template),
  "ours" (user's working tree).
- **Conflict handling:** `--conflict inline` (default) writes Git-style `<<<<<<< >>>>>>>` markers directly
  into the file. `--conflict rej` writes a sidecar `.rej` per conflicting file. Internally it leans on Git
  machinery so the working tree ends up in a normal "resolve the conflicts" state.
- **Migrations:** first-class. `_migrations:` in `copier.yml` is a list of commands, each optionally
  version-gated. Semantics: a migration runs only when **new_version >= declared_version > old_version**
  (so it fires exactly once, when you cross that version boundary). Each runs in a `before`/`after` stage
  and receives `$STAGE`, `$VERSION_FROM`, `$VERSION_TO`, `$VERSION_CURRENT` (plus PEP440-normalized
  variants) as both env vars and Jinja vars. The answers file is **reloaded after migrations** so a
  migration can rewrite stored answers (e.g. rename a question key).

### cruft — copier's pattern, retrofitted onto cookiecutter

- **Provenance stored:** `.cruft.json` in the project. Fields: `template` (repo URL), `commit` (the exact
  git hash last synced to), `checkout` (branch/tag, optional), `context` (the full cookiecutter answer
  dict), and `skip` (files/glob patterns never to touch during update).
- **Merge algorithm:** same conceptual 3-way as copier — render the template at the **recorded old commit**,
  render it at the **latest commit**, produce a patch between the two, and apply that patch onto the
  project. Difference is the *application* path.
- **Conflict handling (the weak spot):** cruft first tries `git apply --3way` (real 3-way merge using Git
  blobs). When the user has diverged too far for a clean 3-way, it **falls back to `git apply --reject`**,
  which scatters `*.rej` reject files the user must hand-resolve. There is no inline-marker option; this is
  a long-standing complaint (open issues #49, #206) and the main reason teams pick copier over cruft.
- **Other commands:** `cruft check` (exit 1 if drifted from template HEAD — great for CI), `cruft diff`
  (git-diff-style view of project vs template), `cruft link` (retrofit `.cruft.json` onto a project that
  was created with plain cookiecutter), and `--variables-to-update` to bump stored answers.
- **Migrations:** **none** as a first-class concept. cruft is purely a file-diff syncer. State-shape
  migration is left to the template author / user.

### cookiecutter — generation only, no update story

- **Provenance stored:** a *replay* file under `~/.cookiecutter_replay/<template>.json` capturing the
  **inputs** (answers) for a generation, plus optional `--replay` / `--replay-file`.
- **Update support:** **none.** Replay only re-runs the prompts with the same answers to regenerate from
  scratch; there is no diff/merge against an existing tree, no stored template commit, no per-project
  provenance committed alongside the code. Updating an existing project is explicitly out of scope —
  that gap is exactly what cruft (and copier) exist to fill.

### projen — eliminate the merge entirely (regenerate from code)

- **Source of truth:** a `.projenrc.ts` / `.projenrc.js` / `.projenrc.py` **program**, not an answers
  file. You don't store "answers"; you store *code* that, when run (`npx projen`), synthesizes all managed
  config files (`package.json`, `tsconfig.json`, CI YAML, `.gitignore`, etc.).
- **Update model:** there is no 3-way merge because there is no divergence to merge. Every managed file is
  **fully overwritten** on each synthesis. Files carry a marker header — the magic string
  `~~ Generated by projen` (exposed as `FileBase.PROJEN_MARKER`) — and projen's contract is "do not edit
  these by hand; edit `.projenrc` and re-run." Manual edits to a managed file are silently clobbered next
  synth.
- **Escape hatch:** `SampleFile` (and friends) are generated **only if absent**, then become user-owned and
  are never touched again. `marker: false` opts a file out of the managed marker. This cleanly partitions
  the tree into *machine-owned* (regenerate, never merge) and *human-owned* (write-once, then hands-off).
- **"Migration":** upgrading the projen library + re-running synth *is* the upgrade. Behavior changes ship
  as new projen versions; the user's `.projenrc` is the stable contract.

### Yeoman — per-file conflict prompts, no real 3-way

- **Provenance stored:** `.yo-rc.json` marks the project root and stores per-generator config/answers so
  sub-generators and re-runs share state. It is config storage, not a template-commit pin.
- **Update model:** generators write into an in-memory file system (**mem-fs**), shared across composed
  generators, then commit to disk at the end. On commit, any write that would **overwrite an existing,
  differing file** triggers the **conflict resolver**, which prompts the user per file: overwrite / skip /
  diff / etc.
- **Conflict handling:** interactive, per-file, **two-way** (incoming vs on-disk). There is no common
  ancestor and thus no true 3-way merge — the user manually adjudicates each clash. Good UX for
  interactive runs, poor for unattended fleet updates.
- **Migrations:** no built-in versioned migration framework; a generator can do arbitrary work on re-run,
  but there's no "run X once when crossing version N" primitive.

| Tool | Provenance | Merge approach | Conflicts | Migrations |
|------|-----------|----------------|-----------|------------|
| **copier** | `.copier-answers.yml` (src, `_commit`, answers) | True 3-way: render old + new, re-apply user diff | Inline `<<<` markers (default) or `.rej` | First-class, version-gated, before/after stages |
| **cruft** | `.cruft.json` (template, commit, context, skip) | 3-way patch: render old commit → new commit, apply diff | `git apply --3way`, falls back to `*.rej` | None |
| **cookiecutter** | replay JSON (inputs only) | None — regenerate from scratch | N/A | None |
| **projen** | `.projenrc` *code* | None — regenerate, fully overwrite managed files | None (managed files clobbered; samples write-once) | New library version + re-synth |
| **Yeoman** | `.yo-rc.json` (per-generator config) | Two-way per-file via mem-fs | Interactive prompt per file (overwrite/skip/diff) | None |

---

## 2. THE canonical pattern (what they share)

Strip away the surface differences and four of the five (all except plain cookiecutter, which is the
counter-example proving the point) converge on the same skeleton:

> **Stored provenance + a template reference (version/commit) + re-render-and-3-way-merge.**

Concretely, the canonical update is:

1. **Pin provenance in the generated project.** A committed, machine-owned file records the template
   source, the exact template version/commit it was last synced to, and the answers/config that produced
   the current tree (`.copier-answers.yml`, `.cruft.json`). This is the linchpin: it gives the merge its
   **common ancestor**.
2. **Re-render the common ancestor.** Using the *old* recorded version + the *recorded answers*, regenerate
   what the template *would have* produced before the user touched anything. This synthetic "base" is what
   makes a true 3-way possible without ever having stored a snapshot.
3. **Render the new target.** Same answers, new template version.
4. **3-way merge** base / target / working-tree, leaving Git-style conflict markers (or `.rej`) for the
   human where local edits collide with template edits.
5. **Run version-gated migrations** for state that file-diffing can't express (renamed answer keys, moved
   directories, format changes) — fired exactly once when crossing the version that introduced them.
6. **Advance the pin.** Rewrite the stored commit/version so the project is now the ancestor for next time.

projen is the same idea taken to its logical extreme: make the **template itself executable and the source
of truth**, mark every generated file machine-owned, and **regenerate instead of merging**. No merge is
needed because the user is contractually forbidden from editing managed files; user-owned files are
write-once. cookiecutter is the null case: no pin, no merge, generation only.

The deepest lesson across all five: **the hard part isn't the diff, it's establishing a trustworthy common
ancestor.** copier/cruft buy it by re-rendering from a pinned commit + frozen answers. projen sidesteps it
by declaring most of the tree non-user-editable. Everyone needs a clean line between *machine-owned* (safe
to overwrite/merge) and *human-owned* (never touch).

---

## 3. How gstack does it today (Claude-native self-upgrade + migrations)

Source: `gstack/gstack-upgrade/SKILL.md` and `gstack/gstack-upgrade/migrations/`.

gstack is a *toolkit* (a set of Claude Code skills), and its upgrade target is **the toolkit install
itself**, not a user-scaffolded project. That is a different problem from copier/cruft (which update a
*generated project*), and the design reflects it.

**The skill is the upgrader — there is no CLI binary doing the merge.** `gstack-upgrade/SKILL.md` is a
prompt that *instructs Claude* to perform the upgrade step by step using `Bash`/`Read`/`Write`/
`AskUserQuestion`. The "algorithm" is natural-language steps Claude executes, not compiled code.

Mechanism (from SKILL.md):
- **Detect install type** (Step 2): `global-git`, `local-git`, `vendored`, `vendored-global` — by probing
  for `.git` dirs at known paths. The whole flow branches on this.
- **Upgrade by install type** (Step 4):
  - *Git installs:* `git stash` → `git fetch` → `git reset --hard origin/main` → `./setup`. If the stash
    saved work, warn the user to `git stash pop`. So the toolkit's "merge" is just **git reset to upstream**
    — no 3-way; user edits to the toolkit are stashed aside, not merged.
  - *Vendored installs:* clone fresh into a temp dir, `mv` the old install to `.bak`, swap in the new tree,
    run `./setup`, delete `.bak`. **Backup-and-replace with rollback**, not merge.
- **Auto-upgrade + snooze policy** (Step 1): config-driven (`auto_upgrade`), with escalating-backoff snooze
  state in `~/.gstack/update-snoozed` (24h → 48h → 1 week) and a "never ask again" kill switch
  (`update_check false`). On auto-upgrade failure it **restores from `.bak`** and tells the user to retry.
- **Version pin + "what's new":** the `VERSION` file holds the installed version (the provenance pin);
  `~/.gstack/just-upgraded-from` records the prior version; `CHANGELOG.md` between old and new versions is
  summarized back to the user. `~/.gstack/last-update-check` is the update-check cache.

**Migrations** (`gstack-upgrade/migrations/`, run at Step 4.75, *after* `./setup`):
- Files are `v{VERSION}.sh` (present today: `v0.15.2.0`, `v0.16.2.0`, `v1.0.0.0`, `v1.1.3.0`, `v1.17.0.0`,
  `v1.27.0.0`, `v1.37.0.0`, `v1.38.1.0`, `v1.40.0.0`). The runner finds them with
  `find ... -name 'v*.sh' | sort -V` and runs each whose version is **strictly newer than the old installed
  version** — i.e. `OLD_VERSION < m_ver` via `sort -V`. Same "run once when crossing the boundary"
  semantics as copier's `new >= declared > old`.
- Migrations exist precisely for **state that `./setup` can't express**: stale config, orphaned files,
  directory-structure changes, renamed skills. This is gstack's analogue of copier's migrations.
- They are **idempotent bash scripts**, and the discipline is visible and strong:
  - *Ownership guards* — `v1.1.3.0.sh` only removes a stale `/checkpoint` install if the path *resolves
    inside* `~/.claude/skills/gstack/` (symlink-canonicalized via `realpath` with a `python3` fallback). A
    user's own same-named skill (regular file, or symlink pointing elsewhere) is preserved. This is the
    machine-owned vs human-owned line, enforced at runtime.
  - *Done-markers + retry* — `v1.40.0.0.sh` writes `~/.gstack/.migrations/v1.40.0.0.done` **only when every
    repair succeeded or was provably unnecessary**; on any partial failure (missing `jq`, corrupt JSON, failed
    append) it sets `incomplete=1`, skips the marker, and the runner retries next upgrade. Each individual
    edit is also guarded on "not already present," so re-running is a no-op even without the marker.
  - *Never push for the user* — migrations patch local federated-artifacts files (`.brain-allowlist`,
    `.brain-privacy-map.json`, `.gitattributes`) but explicitly refuse to `git commit`/`push`; the user
    controls when changes ship.
- **Notable:** the artifacts repo uses git's own `merge=union` driver via `.gitattributes` (the v1.40.0.0
  migration appends `merge=union` rules) — gstack leans on **git's native merge machinery** for its
  append-only state files rather than reinventing a 3-way merge. That's a direct echo of the canonical
  pattern: when you can, delegate the merge to git.

**Summary of the gstack model:** version-pinned (`VERSION`), Claude-driven (the SKILL is the script),
replace-and-rollback for the toolkit itself (no 3-way on toolkit files — git reset / backup-swap), and a
**robust idempotent version-gated migration framework** for on-disk state, with ownership guards and
done-markers as its safety rails.

---

## 4. What to BORROW (for a Claude Code skill, not a CLI)

1. **Pin provenance in the generated project, committed.** The single highest-leverage idea. A
   machine-owned file (e.g. `.gstack-scaffold.json`) recording: template/skill source, the **version/commit
   last synced**, and the **answers/config** that produced the tree. Without the pin there is no common
   ancestor and no honest merge — you're reduced to cookiecutter (regenerate-only) or Yeoman (per-file
   guessing).
2. **Re-render the common ancestor, then 3-way merge — but let git do the merge.** copier/cruft both
   ultimately stand on git. A skill can: render base (old version + answers) into a temp dir, render target
   (new version + answers), and use `git merge-file` / `git apply --3way` / a throwaway git tree to produce
   inline `<<<<<<<` markers. **Prefer inline markers over `.rej`** (copier's default, cruft's pain point) —
   markers live where the dev is already looking and resolve like any merge conflict.
3. **Version-gated, idempotent migrations — keep gstack's exact discipline.** It is already excellent and
   maps 1:1 onto copier's model: `v{VERSION}.sh`, run when `old < v <= new` (`sort -V`), done-markers that
   only write on full success, "not already present" guards on every edit, ownership guards before any
   destructive op. Keep all of it. This is gstack's clearest competitive advantage over cruft (which has
   *no* migrations).
4. **A hard machine-owned vs human-owned partition (projen's insight).** Mark scaffold-managed files
   explicitly (a `Generated by gstack — edit the template, not this file` marker, à la `PROJEN_MARKER`) and
   give users a write-once `sample`-style tier for files they're meant to own. Regenerate the managed tier
   freely; never touch the human tier after first write. This shrinks the merge surface dramatically — the
   only files that *need* 3-way are the genuinely-shared ones.
5. **`skip` / drift-check / dry-run.** Borrow cruft's `skip` globs (per-project opt-out) and `cruft check`
   (drift detection, CI-friendly, exit 1 when behind). A skill should be able to *show the diff and ask*
   before writing — which is natural for a Claude skill via `AskUserQuestion`.
6. **Backup + rollback + reload-after-migrate.** gstack's `.bak`-and-restore on failed `./setup` is the
   right default for any destructive step. And copier's "reload the answers file after migrations" matters
   if a migration renames an answer key — re-read provenance after migrating.
7. **Let the SKILL be the upgrader (gstack's own choice).** Natural-language steps + `Bash`/`Read`/`Write`/
   `AskUserQuestion` is the right substrate. It gives interactive conflict adjudication (Yeoman's one good
   idea) *for free* via the model, and it can summarize the changelog and explain conflicts in prose, which
   no CLI can.

## 5. What to AVOID

1. **Don't ship `.rej` files as the conflict UX.** cruft's reject-file fallback is its single most-hated
   trait (issues #49, #206). A scattered `*.rej` next to an unchanged source file is a worse dev experience
   than inline markers. If 3-way fails, surface conflicts inline or let Claude walk the user through them —
   never leave silent `.rej` litter.
2. **Don't let users hand-edit the provenance file.** copier's warning is real: an edited answers/pin file
   silently corrupts the common ancestor and produces a garbage merge. Make it machine-owned, marker-headed,
   and ideally re-derivable.
3. **Don't silently overwrite user-edited shared files (the projen trap, when misapplied).** projen's
   clobber-everything model is *correct only because* managed files are contractually off-limits. If you
   adopt "regenerate and overwrite" without a rock-solid machine-vs-human partition, you will eat someone's
   local changes. Either merge (with provenance) or partition (with markers) — never blind-overwrite a file
   a user might legitimately own.
4. **Don't rely on per-file interactive prompts as the *only* path (Yeoman's limit).** Fine for a human at a
   terminal, useless for unattended/fleet updates and painful at scale. A skill should support a
   non-interactive "merge and leave markers" mode too, so it works inside `/ship`, CI, or a batch sweep.
5. **Don't reinvent the merge engine.** Both copier and cruft — and gstack's `merge=union` choice — delegate
   to git. A bespoke line-level merger in bash/JS is a bug farm. Render into temp trees and call git.
6. **Don't conflate "update the toolkit" with "update a scaffolded project."** gstack's current
   `git reset --hard origin/main` + backup-swap is right for **the toolkit install** (which the user
   shouldn't be editing). It is the *wrong* model for **a project the user actively develops in** — that one
   needs the copier-style provenance + 3-way merge. Keep the two flows distinct; don't let the toolkit's
   reset-to-upstream pattern leak into project scaffolding.
7. **Don't drop migrations to match cruft.** cruft proves file-diffing alone is insufficient for
   state-shape changes (renamed answers, moved dirs). gstack already has the better answer; preserve it.

---

## Sources

- [Copier — Updating a project](https://copier.readthedocs.io/en/stable/updating/)
- [Copier — Migrations & tasks (configuring)](https://copier.readthedocs.io/en/stable/configuring/#migrations)
- [cruft — docs](https://cruft.github.io/cruft/)
- [cruft — GitHub README](https://github.com/cruft/cruft)
- [cruft issue #206 — cookiecutter.diff vs *.rej files](https://github.com/cruft/cruft/issues/206)
- [cruft issue #49 — improve rejection fallback](https://github.com/timothycrosley/cruft/issues/49)
- [Cruft vs Copier — automating template updates at scale (Blenddata)](https://www.blenddata.nl/en/blogs/cruft-vs-copier-automating-template-updates-at-scale)
- [Cookiecutter — replay docs](https://cookiecutter.readthedocs.io/en/stable/advanced/replay.html)
- [The Projen Workflow](https://projen.io/docs/introduction/the-projen-workflow/)
- [projen ARCHITECTURE.md (PROJEN_MARKER, synthesis)](https://github.com/projen/projen/blob/main/ARCHITECTURE.md)
- [projen discussion #3363 — why files always regenerate](https://github.com/projen/projen/discussions/3363)
- [Yeoman — running context / file system & conflict resolution](https://yeoman.io/authoring/file-system.html)
- gstack: `gstack/gstack-upgrade/SKILL.md`, `gstack/gstack-upgrade/migrations/v1.1.3.0.sh`, `.../v1.40.0.0.sh`
