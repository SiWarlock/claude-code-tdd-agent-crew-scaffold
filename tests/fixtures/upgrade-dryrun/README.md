# upgrade-dryrun fixture

A **frozen, minimal generated project** used by `tests/run-upgrade-dryrun.sh` (wired as
`scripts/release-check.sh upgrade-dryrun`) to dry-run the whole `/scaffold-upgrade` mechanical path
against the real templates. It lives under `tests/` — **outside `templates/`** — so it never ships via
scaffold-generate and is never treated as a template by the merge.

## Shape

`project/` is pinned at **base SHA `1d995d4b8c2ce11995f5174ecb69aa9ac93b40b8`** — the last commit
*before* M-0001, so every migration in the registry is inside the `(base, to]` selection window. Its
manifest is **schema v1** (no `posture`), which exercises the v1 grace path (`posture: "unknown"` in
precheck → posture-gated content human-gated).

Files were produced by `scaffold_upgrade.sh substitute <baseSha>` itself at authoring time, then seeded:

| File | Kind | Seed | Exercises |
|---|---|---|---|
| `.claude/commands/check-arch.md` | placeholder-only | **untouched** | provably-untouched → auto-apply; the harness byte-compares it against a fresh `substitute <baseSha>` so the fixture can't silently drift from templates-at-base |
| `.claude/commands/tdd.md` | placeholder-only | line 3 (`allowed-tools:`) edited — a line upstream also changed after base | guaranteed 3-way conflict → `propose-conflict`, diff3 marker emission, `check-markers` blocking |
| `CLAUDE.md` | mixed | `tech-stack` + `key-safety-rules` regions customized | per-region split; a customized region must never be auto-eligible |
| `app/CLAUDE.md` | mixed | `END EXAMPLE BLOCK [id=module-layout]` marker line deleted | marker drift → whole-file-propose degradation |
| `MVP_TASKS.md` | accreted | real living-section content (ticked tasks, Log, Carry-forward) | leave-alone, byte-identical end-to-end; pre-M-0003 name keeps the rename migration in scope |
| `app/LESSONS.md` | accreted | one real lesson (§1) | leave-alone, byte-identical end-to-end |

## What the harness does NOT cover (by design)

Prose-migration **application** and per-region merge **adjudication** are model-run and human-gated;
the harness synthesizes their outcomes (`.scaffolding/.migrations/<id>.done` journals, a pre-approved
`writes` plan) exactly as an approved run would. The dry-run proves **selection + mechanics**, not the
gated judgment steps.

## Maintaining

- Do not regenerate `project/` casually — it is frozen at the base SHA on purpose. If the manifest's
  `generatedFiles` set must grow, regenerate the new file with
  `scaffold_upgrade.sh substitute 1d995d4b8c2ce11995f5174ecb69aa9ac93b40b8 <out> --work <work>` and
  re-apply the seed table above.
- New migrations need no fixture change: the harness asserts *selection == the full registry at HEAD*
  dynamically (the base predates everything), plus the explicit M-0001..M-0004 floor.
