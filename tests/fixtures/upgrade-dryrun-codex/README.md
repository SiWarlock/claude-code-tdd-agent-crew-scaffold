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
| `.agents/skills/check-arch/SKILL.md` | placeholder-only | **untouched** | provably-untouched; harness byte-compares a fresh `substitute <baseSha>` so the fixture can't silently drift from templates-at-base — AND proves the `[codex]` HOST frontmatter region (`name:`, no `allowed-tools`) + host-token resolution |
| `.agents/skills/tdd/SKILL.md` | placeholder-only | +1 line | customized placeholder-only file → **leave-alone** (no upstream change between base and target), never auto-overwritten |
| `app/AGENTS.md` | mixed | `END EXAMPLE BLOCK [id=module-layout]` removed | damaged region marker, seeded to exercise **whole-file-propose** degradation — **currently pinned to its actual behavior (upstreamChanged=false → skip) instead, see "Known limitation" below** |
| `AGENTS.md` | mixed | substitute output | per-region split; `tech-stack` + `key-safety-rules` customized → never auto-eligible; HOST-split project-structure tree resolves to the Codex layout; **also currently exercises the real upstream-Codex-template-change scenario** (see below) |
| `IMPLEMENTATION_PLAN.md` | accreted | substitute output | leave-alone, byte-identical end-to-end |
| `app/LESSONS.md` | accreted | substitute output | leave-alone, byte-identical end-to-end |
| `.codex/config.toml` | verbatim | substitute output | the Codex `[mcp_servers]` + `[[hooks.PreToolUse]]` config (no Claude analog) |

## What it proves (host layer)

- `resolve` reports `host = "codex"`, `schemaVersion = 3`, `mode = "single-operator"`.
- `substitute <baseSha>` reproduces the frozen project byte-for-byte → **HOST-region pruning emits the Codex
  `name:` frontmatter** and the **host-derived tokens resolve** (`AGENTS.md`, `.agents/skills/`,
  `.codex/config.toml`, `~/.codex`).
- The rebuilt `ours` tree carries **no `▼ HOST [` markers** (host pruning ran) and the SKILL.md files carry
  **Codex frontmatter** (`name:`), not Claude (`allowed-tools:`).
- Migration window is **empty** — every registry migration (incl. M-0013, `introducedAtSha` = the schema-v3
  engine commit) predates this Codex base, so a fresh Codex project inherits no legacy Claude-era migration
  (SHA-window host isolation).
- **The upstream-Codex-template-change scenario is live and asserted:** `templates/CLAUDE.md` genuinely
  differs between this fixture's pinned base and the target ref (real commits landed there since the base
  pin), so `AGENTS.md` resolves `upstreamChanged=true` / `baseEqualsTheirs=true` / `policy=mixed-regions` for
  real — pinned exactly by `tests/run-upgrade-dryrun.sh`, not merely asserted-to-not-fire.
- `apply` (writes list derived DYNAMICALLY from `policy=="auto-apply"` entries in `plan.json` — not hardcoded,
  since which file(s), if any, are auto-apply-eligible depends on what changed upstream between this fixture's
  base and the target ref, and that set shifts over time) and `check-markers`
  now both run for host=codex, exercising the real Codex dest-path write mechanics and — most importantly —
  the Codex-specific `▼ HOST [` marker-leak guard in `cmd_check_markers`, which previously had zero coverage.

## Known limitation — whole-file-propose degradation is seeded but not currently triggered

`app/AGENTS.md`'s damaged `END EXAMPLE BLOCK [id=module-layout]` marker was seeded to exercise whole-file-propose
degradation (as the Claude fixture's analogous `app/CLAUDE.md` seed does), but that code path only evaluates
when `upstreamChanged=true` for the dest — and `templates/area-CLAUDE.md` itself has not changed between this
fixture's base pin and the current target ref. So today this resolves to `upstreamChanged=false` / `policy=skip`
instead. `tests/run-upgrade-dryrun.sh` pins that actual value (so a real regression is still caught) rather than
asserting the originally-intended-but-currently-unreachable degradation path. To properly exercise
whole-file-propose for Codex, re-pin this fixture's base SHA to predate a real historical change to
`templates/area-CLAUDE.md` (mirroring exactly how the Claude fixture's base SHA was chosen), or introduce one.

## NOT proven here (covered elsewhere)

The `auto-apply` and `propose-conflict` policies for a genuinely-eligible dest need an upstream template
change in the `(base, to]` window for that SPECIFIC dest; this fixture's placeholder-only Codex files
(the SKILL.md pair) haven't had such a change land, so those two policies aren't exercised for them here
(the mixed-regions AGENTS.md case above exercises a *different* upstream-change scenario instead). Both
policies are **host-agnostic** (the merge runs on already-built trees) and are exercised end-to-end by the
Claude fixture. The `hosts` migration filter is unit-tested directly in `tests/run-upgrade-dryrun.sh`. No
fixture yet exercises upgrading a project with the EXPERIMENTAL team overlay opted in
(`codex_team_experimental: true`) — only the solo-core path is proven.

## Re-authoring

To regenerate from templates-at-base (e.g. after a templates change at that SHA), re-run
`scaffold_upgrade.sh substitute 1d7744b41d7bea37b575c9810ffa2b53c2c05c61 <out> --work <work>` with a
host=codex manifest, then re-apply the seed table above.
