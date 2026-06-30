# upgrade-dryrun-codex fixture

A **frozen, minimal generated _Codex_ project** used by `tests/run-upgrade-dryrun.sh` (wired as
`scripts/release-check.sh upgrade-dryrun`) to dry-run the whole `/scaffold-upgrade` mechanical path for
**host = codex**. It is the Codex sibling of `tests/fixtures/upgrade-dryrun/` (host = claude). Like that one
it lives under `tests/` — **outside `templates/`** — so it never ships via scaffold-generate and is never
treated as a template to merge.

## Shape

`project/` is pinned at **base SHA `1d7744b41d7bea37b575c9810ffa2b53c2c05c61`** — the commit that first
host-tagged the templates (Phase B of the Codex host axis). Its manifest is **schema v3** with
`"host": "codex"` and `"mode": "single-operator"` (the Codex solo core). Files were produced by
`scaffold_upgrade.sh substitute <baseSha>` itself at authoring time (host=codex), then seeded:

| File | Kind | Seed | Exercises |
|---|---|---|---|
| `skills/check-arch/SKILL.md` | placeholder-only | **untouched** | provably-untouched; harness byte-compares a fresh `substitute <baseSha>` so the fixture can't silently drift from templates-at-base — AND proves the `[codex]` HOST frontmatter region (`name:`, no `allowed-tools`) + host-token resolution |
| `skills/tdd/SKILL.md` | placeholder-only | +1 line | customized placeholder-only file → **leave-alone** (no upstream change between base and HEAD), never auto-overwritten |
| `app/AGENTS.md` | mixed | `END EXAMPLE BLOCK [id=module-layout]` removed | damaged region marker → **whole-file-propose** degradation |
| `AGENTS.md` | mixed | substitute output | per-region split; `tech-stack` + `key-safety-rules` customized → never auto-eligible; HOST-split project-structure tree resolves to the Codex layout |
| `IMPLEMENTATION_PLAN.md` | accreted | substitute output | leave-alone, byte-identical end-to-end |
| `app/LESSONS.md` | accreted | substitute output | leave-alone, byte-identical end-to-end |
| `config.toml` | verbatim | substitute output | the Codex `[mcp_servers]` + `[[hooks.PreToolUse]]` config (no Claude analog) |

## What it proves (host layer)

- `resolve` reports `host = "codex"`, `schemaVersion = 3`, `mode = "single-operator"`.
- `substitute <baseSha>` reproduces the frozen project byte-for-byte → **HOST-region pruning emits the Codex
  `name:` frontmatter** and the **host-derived tokens resolve** (`AGENTS.md`, `skills/`, `config.toml`, `~/.codex`).
- The rebuilt `ours` tree carries **no `▼ HOST [` markers** (host pruning ran) and the SKILL.md files carry
  **Codex frontmatter** (`name:`), not Claude (`allowed-tools:`).
- Migration window is **empty** — every registry migration (incl. M-0013, `introducedAtSha` = the schema-v3
  engine commit) predates this Codex base, so a fresh Codex project inherits no legacy Claude-era migration
  (SHA-window host isolation).

## NOT proven here (covered elsewhere)

The `auto-apply` and `propose-conflict` policies need an upstream template change in the `(base, to]` window;
between this base and HEAD no Codex-emitted template changed, so those policies don't fire here. They are
**host-agnostic** (the merge runs on already-built trees) and are exercised by the Claude fixture; the Codex
fixture additionally exercises them once an upstream Codex-template change lands in the window. The `hosts`
migration filter is unit-tested directly in `tests/run-upgrade-dryrun.sh`.

## Re-authoring

To regenerate from templates-at-base (e.g. after a templates change at that SHA), re-run
`scaffold_upgrade.sh substitute 1d7744b41d7bea37b575c9810ffa2b53c2c05c61 <out> --work <work>` with a
host=codex manifest, then re-apply the seed table above.
