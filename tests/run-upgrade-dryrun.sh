#!/usr/bin/env bash
# run-upgrade-dryrun.sh — drives a full /scaffold-upgrade mechanical pass against the frozen fixtures:
#   • tests/fixtures/upgrade-dryrun/        (host = claude — the original, pinned pre-M-0001)
#   • tests/fixtures/upgrade-dryrun-codex/  (host = codex  — the Codex host-axis sibling, pinned at Phase B)
#
# It exercises ONLY the existing scaffold_upgrade.sh subcommands (resolve → substitute → diff →
# migrations → apply → check-markers → stamp) — it never reimplements the script's deterministic work.
# What the Claude pass proves: SHA-window migration selection + journaling, auto-apply vs PROPOSE policies,
# per-region split, marker-drift whole-file degradation, accreted leave-alone, conflict-marker emission +
# the check-markers block, stamping, and second-run idempotency.
# What the Codex pass proves (the host layer): resolve reports host=codex/schema-v3/single-operator;
# `substitute` reproduces the frozen Codex project byte-for-byte (HOST-region pruning emits the Codex
# `name:` frontmatter + host-derived tokens resolve to AGENTS.md/skills/config.toml/~/.codex); no `▼ HOST [`
# marker leaks; accreted files leave-alone; a customized placeholder-only file is never auto-overwritten;
# the migration window is host/SHA-isolated (empty for a fresh Codex project). The auto-apply / conflict /
# whole-file-propose policies are HOST-AGNOSTIC (the merge runs on already-built trees) and are proven by
# the Claude pass; they additionally fire for Codex once an upstream Codex-template change lands in the
# window. A focused unit test covers the per-migration `hosts` filter directly.
#
# Wired as `scripts/release-check.sh upgrade-dryrun`.

set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO/skills/scaffold-upgrade/scripts/scaffold_upgrade.sh"

FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=1; }
gitq() { git -C "$1" -c user.email=dryrun@fixture -c user.name=dryrun "${@:2}"; }

# ==================================================================================================
# Claude fixture (host = claude) — the original mechanical pass, unchanged.
# ==================================================================================================
claude_fixture() {
  printf '\n— claude fixture —\n'
  local FIX="$REPO/tests/fixtures/upgrade-dryrun/project"
  local BASE=1d995d4b8c2ce11995f5174ecb69aa9ac93b40b8
  local TMP; TMP=$(mktemp -d "${TMPDIR:-/tmp}/upgrade-dryrun.XXXXXX")
  local PROJ="$TMP/proj" WORK="$TMP/work"
  mkdir -p "$PROJ"; cp -R "$FIX/." "$PROJ/"
  git -C "$PROJ" init -q; gitq "$PROJ" add -A; gitq "$PROJ" commit -qm "fixture seed"
  local jqp; jqp() { jq -r "$1" "$2"; }

  # ---- 1. resolve --------------------------------------------------------------------------------
  "$SCRIPT" resolve --project "$PROJ" --scaffold "$REPO" --work "$WORK" > /dev/null
  local PC="$WORK/precheck.json"
  [ "$(jqp '.legacy' "$PC")" = "false" ]            && ok "resolve: manifest path (not legacy)" || bad "resolve: legacy unexpectedly true"
  [ "$(jqp '.base' "$PC")" = "$BASE" ]              && ok "resolve: base = pinned pre-M-0001 SHA" || bad "resolve: base $(jqp '.base' "$PC") != $BASE"
  [ "$(jqp '.schemaVersion' "$PC")" = "1" ]         && ok "resolve: schemaVersion 1 accepted"     || bad "resolve: schemaVersion $(jqp '.schemaVersion' "$PC")"
  [ "$(jqp '.host' "$PC")" = "claude" ]             && ok "resolve: host defaults to claude (v1 manifest)" || bad "resolve: host $(jqp '.host' "$PC") (expected claude)"
  [ "$(jqp '.posture' "$PC")" = "unknown" ]         && ok "resolve: v1 grace — posture 'unknown'" || bad "resolve: posture $(jqp '.posture' "$PC") (expected unknown)"
  [ "$(jqp '.cleanTree' "$PC")" = "true" ]          && ok "resolve: clean tree"                   || bad "resolve: tree not clean"
  [ "$(jqp '.alreadyUpToDate' "$PC")" = "false" ]   && ok "resolve: upgrade pending"              || bad "resolve: alreadyUpToDate on run 1"
  local TO; TO=$(jqp '.to' "$PC")

  # ---- 2. substitute @ base — fixture-drift guard ------------------------------------------------
  "$SCRIPT" substitute "$BASE" "$TMP/sub-base" --work "$WORK" 2>/dev/null
  if cmp -s "$TMP/sub-base/.claude/commands/check-arch.md" "$FIX/.claude/commands/check-arch.md"; then
    ok "fixture-drift guard: untouched check-arch.md byte-matches substitute($BASE)"
  else
    bad "fixture-drift guard: check-arch.md no longer matches substitute output — fixture drifted from templates-at-base"
  fi
  local DIVERGED_LINES; DIVERGED_LINES=$(diff "$TMP/sub-base/.claude/commands/tdd.md" "$FIX/.claude/commands/tdd.md" | grep -c '^>' || true)
  [ "$DIVERGED_LINES" = "1" ] && ok "fixture-drift guard: tdd.md diverges by exactly the one seeded line" \
                              || bad "fixture-drift guard: tdd.md divergence is $DIVERGED_LINES lines (expected 1)"

  # ---- 3. diff → plan.json -----------------------------------------------------------------------
  "$SCRIPT" diff --work "$WORK" > /dev/null
  local PLAN="$WORK/plan.json"
  e() { jq -r --arg d "$1" '.files[] | select(.dest==$d)'"$2" "$PLAN"; }

  [ "$(e 'MVP_TASKS.md' '.policy')" = "leave-alone" ]   && ok "diff: accreted tracker → leave-alone" || bad "diff: MVP_TASKS.md policy $(e 'MVP_TASKS.md' '.policy')"
  [ "$(e 'app/LESSONS.md' '.policy')" = "leave-alone" ] && ok "diff: accreted LESSONS → leave-alone" || bad "diff: app/LESSONS.md policy $(e 'app/LESSONS.md' '.policy')"

  [ "$(e '.claude/commands/tdd.md' '.policy')" = "propose-conflict" ] \
    && ok "diff: diverged tdd.md → propose-conflict (never auto-apply)" \
    || bad "diff: tdd.md policy $(e '.claude/commands/tdd.md' '.policy') (expected propose-conflict)"
  [ "$(e '.claude/commands/tdd.md' '.conflicts')" -ge 1 ] \
    && ok "diff: tdd.md merge reports >=1 conflict" || bad "diff: tdd.md conflicts $(e '.claude/commands/tdd.md' '.conflicts')"

  local CA_BET CA_UC CA_POL EXPECT
  CA_BET=$(e '.claude/commands/check-arch.md' '.baseEqualsTheirs')
  CA_UC=$(e '.claude/commands/check-arch.md' '.upstreamChanged')
  CA_POL=$(e '.claude/commands/check-arch.md' '.policy')
  [ "$CA_BET" = "true" ] && ok "diff: check-arch.md provably untouched" || bad "diff: check-arch.md baseEqualsTheirs=$CA_BET"
  if [ "$CA_UC" = "true" ]; then EXPECT=auto-apply; else EXPECT=skip; fi
  [ "$CA_POL" = "$EXPECT" ] && ok "diff: untouched check-arch.md → $EXPECT" || bad "diff: check-arch.md policy $CA_POL (expected $EXPECT)"

  [ "$(e 'app/CLAUDE.md' '.wholeFilePropose')" = "true" ] \
    && ok "diff: damaged module-layout marker → whole-file-propose degradation" \
    || bad "diff: app/CLAUDE.md wholeFilePropose=$(e 'app/CLAUDE.md' '.wholeFilePropose')"
  [ "$(e 'app/CLAUDE.md' '.regions | map(select(.id=="module-layout"))[0].theirsMarker')" = "missing" ] \
    && ok "diff: module-layout region marker reported missing" || bad "diff: module-layout marker not reported missing"

  local TS_POL PS_POL
  TS_POL=$(e 'CLAUDE.md' '.regions | map(select(.id=="tech-stack"))[0].policy')
  case "$TS_POL" in propose|skip) ok "diff: customized tech-stack region → $TS_POL (never auto-eligible)" ;;
    *) bad "diff: customized tech-stack region policy '$TS_POL'" ;; esac
  PS_POL=$(e 'CLAUDE.md' '.regions | map(select(.id=="project-structure"))[0].policy')
  case "$PS_POL" in auto-eligible|skip) ok "diff: illustrative project-structure region → $PS_POL" ;;
    *) bad "diff: illustrative project-structure region policy '$PS_POL'" ;; esac

  if grep -rq '▼ MODE \[' "$WORK/ours" 2>/dev/null; then
    bad "mode pruning NOT replayed: template-only MODE markers leaked into the rebuilt ours tree"
  else
    ok "mode pruning replayed: no MODE markers in the rebuilt ours tree"
  fi

  # ---- 4. migrations -----------------------------------------------------------------------------
  "$SCRIPT" migrations --work "$WORK" > /dev/null
  local MIG="$WORK/migrations.json" SELECTED REGISTRY
  SELECTED=$(jq -r '.migrations[].id' "$MIG" | sort)
  REGISTRY=$(git -C "$REPO" show "$TO:migrations/registry.json" | jq -r '.migrations[].id' | sort)
  local id
  for id in M-0001 M-0002 M-0003 M-0004; do
    echo "$SELECTED" | grep -qx "$id" && ok "migrations: $id selected (in (base,to] window)" || bad "migrations: $id NOT selected"
  done
  [ "$SELECTED" = "$REGISTRY" ] \
    && ok "migrations: selection == full registry (base predates every migration)" \
    || bad "migrations: selection/registry mismatch: $(comm -3 <(echo "$SELECTED") <(echo "$REGISTRY") | tr '\n' ' ')"
  [ "$(jq -r '[.migrations[].alreadyApplied] | any' "$MIG")" = "false" ] \
    && ok "migrations: none pre-applied on run 1" || bad "migrations: alreadyApplied set on run 1"

  mkdir -p "$PROJ/.scaffolding/.migrations"
  jq -r '.migrations[].id' "$MIG" | while read -r id; do touch "$PROJ/.scaffolding/.migrations/$id.done"; done
  "$SCRIPT" migrations --work "$WORK" > /dev/null
  [ "$(jq -r '[.migrations[].alreadyApplied] | all' "$MIG")" = "true" ] \
    && ok "migrations: re-select after .done journals → nothing left to do" \
    || bad "migrations: journaled migrations still report unapplied"

  # ---- 5. apply ----------------------------------------------------------------------------------
  cp "$PROJ/MVP_TASKS.md" "$TMP/tracker.before"; cp "$PROJ/app/LESSONS.md" "$TMP/lessons.before"
  jq '{writes: ([.files[] | select(.policy=="auto-apply") | {dest, source:"ours"}]
              + [{dest:".claude/commands/tdd.md", source:"merged"}])}' "$PLAN" > "$TMP/apply-plan.json"
  "$SCRIPT" apply "$TMP/apply-plan.json" --work "$WORK" 2>/dev/null
  grep -q '^<<<<<<<' "$PROJ/.claude/commands/tdd.md" \
    && ok "apply: merged tdd.md carries conflict markers (diff3 emission)" \
    || bad "apply: expected conflict markers in applied tdd.md"
  cmp -s "$PROJ/MVP_TASKS.md" "$TMP/tracker.before"  && ok "apply: accreted tracker untouched end-to-end" || bad "apply: tracker was modified"
  cmp -s "$PROJ/app/LESSONS.md" "$TMP/lessons.before" && ok "apply: accreted LESSONS untouched end-to-end" || bad "apply: LESSONS was modified"

  # ---- 6. check-markers --------------------------------------------------------------------------
  if "$SCRIPT" check-markers --work "$WORK" >/dev/null 2>&1; then
    bad "check-markers: did NOT block on unresolved conflict markers"
  else
    ok "check-markers: blocks while conflict markers present"
  fi
  cp "$WORK/ours/.claude/commands/tdd.md" "$PROJ/.claude/commands/tdd.md"
  "$SCRIPT" check-markers --work "$WORK" >/dev/null 2>&1 \
    && ok "check-markers: clean after resolution" || bad "check-markers: still failing after resolution"

  # ---- 7. stamp ----------------------------------------------------------------------------------
  "$SCRIPT" stamp "$TO" --work "$WORK" >/dev/null 2>&1
  [ "$(jq -r '.lastUpgradedFromSha' "$PROJ/.scaffolding/manifest.json")" = "$TO" ] \
    && ok "stamp: lastUpgradedFromSha = $TO" || bad "stamp: manifest not stamped"
  [ -s "$PROJ/.scaffolding/upgrade-log.jsonl" ] && ok "stamp: upgrade-log appended" || bad "stamp: no upgrade-log"

  # ---- 8. run 2 — idempotency --------------------------------------------------------------------
  gitq "$PROJ" add -A; gitq "$PROJ" commit -qm "upgrade applied"
  "$SCRIPT" resolve --project "$PROJ" --scaffold "$REPO" --work "$WORK" > /dev/null
  [ "$(jqp '.alreadyUpToDate' "$PC")" = "true" ] \
    && ok "run 2: resolve reports already up to date (base == to)" || bad "run 2: not up-to-date after stamp"
  "$SCRIPT" migrations --work "$WORK" > /dev/null
  [ "$(jq -r '.migrations | length' "$MIG")" = "0" ] \
    && ok "run 2: migration window empty — second run selects nothing" || bad "run 2: migrations still selected"
  rm -rf "$TMP"
}

# ==================================================================================================
# Codex fixture (host = codex) — proves the host axis end-to-end (generation + the host-specific layer).
# ==================================================================================================
codex_fixture() {
  printf '\n— codex fixture —\n'
  local FIX="$REPO/tests/fixtures/upgrade-dryrun-codex/project"
  local BASE=1d7744b41d7bea37b575c9810ffa2b53c2c05c61
  local TMP; TMP=$(mktemp -d "${TMPDIR:-/tmp}/upgrade-dryrun-codex.XXXXXX")
  local PROJ="$TMP/proj" WORK="$TMP/work"
  mkdir -p "$PROJ"; cp -R "$FIX/." "$PROJ/"
  git -C "$PROJ" init -q; gitq "$PROJ" add -A; gitq "$PROJ" commit -qm "codex fixture seed"
  local jqp; jqp() { jq -r "$1" "$2"; }

  # ---- 1. resolve — host=codex / schema v3 / single-operator -------------------------------------
  "$SCRIPT" resolve --project "$PROJ" --scaffold "$REPO" --work "$WORK" > /dev/null
  local PC="$WORK/precheck.json"
  [ "$(jqp '.host' "$PC")" = "codex" ]              && ok "resolve: host = codex"                 || bad "resolve: host $(jqp '.host' "$PC") (expected codex)"
  [ "$(jqp '.schemaVersion' "$PC")" = "3" ]         && ok "resolve: schemaVersion 3"              || bad "resolve: schemaVersion $(jqp '.schemaVersion' "$PC") (expected 3)"
  [ "$(jqp '.mode' "$PC")" = "single-operator" ]    && ok "resolve: mode single-operator (Codex solo core)" || bad "resolve: mode $(jqp '.mode' "$PC")"
  [ "$(jqp '.base' "$PC")" = "$BASE" ]              && ok "resolve: base = pinned Phase-B SHA"    || bad "resolve: base $(jqp '.base' "$PC")"
  local TO; TO=$(jqp '.to' "$PC")

  # ---- 2. substitute @ base — the KEY host-axis proof (HOST pruning + token resolution) ----------
  "$SCRIPT" substitute "$BASE" "$TMP/sub-base" --work "$WORK" 2>/dev/null
  # untouched files must byte-match a fresh substitute — proves the [codex] frontmatter region + tokens
  cmp -s "$TMP/sub-base/skills/check-arch/SKILL.md" "$FIX/skills/check-arch/SKILL.md" \
    && ok "fixture-drift guard: untouched check-arch SKILL.md byte-matches substitute($BASE)" \
    || bad "fixture-drift guard: check-arch SKILL.md drifted from templates-at-base (host pruning/token change?)"
  cmp -s "$TMP/sub-base/AGENTS.md" "$FIX/AGENTS.md" \
    && ok "fixture-drift guard: AGENTS.md (HOST-split tree + tokens) byte-matches substitute($BASE)" \
    || bad "fixture-drift guard: AGENTS.md drifted from templates-at-base"
  local DIVERGED; DIVERGED=$(diff "$TMP/sub-base/skills/tdd/SKILL.md" "$FIX/skills/tdd/SKILL.md" | grep -c '^>' || true)
  [ "$DIVERGED" -ge 1 ] && ok "fixture-drift guard: tdd SKILL.md diverges by the seeded customization" \
                        || bad "fixture-drift guard: tdd SKILL.md shows no seed (expected >=1 added line)"
  # the substitute output must be Codex-shaped, not Claude-shaped
  head -6 "$TMP/sub-base/skills/tdd/SKILL.md" | grep -q '^name: tdd$' \
    && ok "substitute: tdd SKILL.md carries Codex frontmatter (name: tdd)" || bad "substitute: tdd SKILL.md missing 'name:' frontmatter"
  head -6 "$TMP/sub-base/skills/tdd/SKILL.md" | grep -q 'allowed-tools' \
    && bad "substitute: Claude 'allowed-tools' leaked into the Codex SKILL.md" || ok "substitute: no Claude 'allowed-tools' in the Codex SKILL.md"
  grep -q 'AGENTS.md' "$TMP/sub-base/AGENTS.md" && grep -q 'config.toml' "$TMP/sub-base/AGENTS.md" \
    && ok "substitute: AGENTS.md resolves the Codex layout (AGENTS.md + config.toml)" || bad "substitute: AGENTS.md did not resolve the Codex layout"

  # ---- 3. diff → host-specific policies ----------------------------------------------------------
  "$SCRIPT" diff --work "$WORK" > /dev/null
  local PLAN="$WORK/plan.json"
  e() { jq -r --arg d "$1" '.files[] | select(.dest==$d)'"$2" "$PLAN"; }
  # no HOST markers may survive into the rebuilt ours tree (template-only; their presence is a leak)
  if grep -rq '▼ HOST \[' "$WORK/ours" 2>/dev/null; then
    bad "host pruning NOT replayed: template-only HOST markers leaked into the rebuilt ours tree"
  else
    ok "host pruning replayed: no HOST markers in the rebuilt ours tree"
  fi
  # the rebuilt SKILL.md must be Codex-shaped
  grep -q '^name: tdd$' "$WORK/ours/skills/tdd/SKILL.md" \
    && ok "diff: rebuilt ours tdd SKILL.md carries Codex frontmatter" || bad "diff: rebuilt ours tdd SKILL.md not Codex-shaped"
  # untouched placeholder-only file is provably untouched
  [ "$(e 'skills/check-arch/SKILL.md' '.baseEqualsTheirs')" = "true" ] \
    && ok "diff: check-arch SKILL.md provably untouched" || bad "diff: check-arch SKILL.md baseEqualsTheirs=$(e 'skills/check-arch/SKILL.md' '.baseEqualsTheirs')"
  # a CUSTOMIZED placeholder-only file is NEVER auto-applied (the core safety invariant)
  case "$(e 'skills/tdd/SKILL.md' '.policy')" in
    auto-apply) bad "diff: customized tdd SKILL.md would be auto-overwritten (policy auto-apply)" ;;
    *)          ok "diff: customized tdd SKILL.md not auto-applied (policy $(e 'skills/tdd/SKILL.md' '.policy'))" ;;
  esac
  # accreted living content is left alone
  [ "$(e 'IMPLEMENTATION_PLAN.md' '.policy')" = "leave-alone" ] \
    && ok "diff: accreted IMPLEMENTATION_PLAN.md → leave-alone" || bad "diff: IMPLEMENTATION_PLAN.md policy $(e 'IMPLEMENTATION_PLAN.md' '.policy')"
  [ "$(e 'app/LESSONS.md' '.policy')" = "leave-alone" ] \
    && ok "diff: accreted app/LESSONS.md → leave-alone" || bad "diff: app/LESSONS.md policy $(e 'app/LESSONS.md' '.policy')"

  # ---- 4. migrations — host/SHA isolation (fresh Codex inherits no legacy migration) -------------
  "$SCRIPT" migrations --work "$WORK" > /dev/null
  local MIG="$WORK/migrations.json"
  [ "$(jq -r '.migrations | length' "$MIG")" = "0" ] \
    && ok "migrations: window empty — a fresh Codex project inherits no legacy/Claude-era migration" \
    || bad "migrations: expected empty window, got $(jq -r '[.migrations[].id]|join(",")' "$MIG")"
  jq -e '[.migrations[].id] | index("M-0013") | not' "$MIG" >/dev/null \
    && ok "migrations: M-0013 (host-field backfill) not selected — base post-dates it" || bad "migrations: M-0013 unexpectedly selected"

  # ---- 5. stamp + idempotency --------------------------------------------------------------------
  "$SCRIPT" stamp "$TO" --work "$WORK" >/dev/null 2>&1
  [ "$(jq -r '.lastUpgradedFromSha' "$PROJ/.scaffolding/manifest.json")" = "$TO" ] \
    && ok "stamp: lastUpgradedFromSha = $TO" || bad "stamp: manifest not stamped"
  [ "$(jq -r '.host' "$PROJ/.scaffolding/manifest.json")" = "codex" ] \
    && ok "stamp: host preserved (codex)" || bad "stamp: host not preserved after stamp"
  gitq "$PROJ" add -A; gitq "$PROJ" commit -qm "codex upgrade applied"
  "$SCRIPT" resolve --project "$PROJ" --scaffold "$REPO" --work "$WORK" > /dev/null
  [ "$(jqp '.alreadyUpToDate' "$PC")" = "true" ] \
    && ok "run 2: resolve reports already up to date" || bad "run 2: not up-to-date after stamp"
  rm -rf "$TMP"
}

# ==================================================================================================
# Unit test — the per-migration `hosts` filter (engine: cmd_migrations) ----------------------------
# Verifies the filter expression directly: absent => all hosts; present => select iff host listed.
# ==================================================================================================
hosts_filter_unit() {
  printf '\n— hosts-filter unit —\n'
  local h e want got
  # (host, entry-json, expected-selected)
  check() {
    h="$1"; e="$2"; want="$3"
    got=$(printf '%s' "$e" | jq -r --arg h "$h" '
      if (.hosts|type)=="array" then (if (.hosts|index($h))!=null then "yes" else "no" end) else "yes" end')
    [ "$got" = "$want" ] && ok "hosts-filter: host=$h $e → $got" || bad "hosts-filter: host=$h $e → $got (expected $want)"
  }
  check codex '{"id":"X"}'                         yes   # absent hosts => all hosts
  check codex '{"id":"X","hosts":["codex"]}'       yes   # listed
  check codex '{"id":"X","hosts":["claude"]}'      no    # excluded
  check claude '{"id":"X","hosts":["claude"]}'     yes
  check claude '{"id":"X","hosts":["codex"]}'      no
  check codex '{"id":"X","hosts":["claude","codex"]}' yes
}

claude_fixture
codex_fixture
hosts_filter_unit

if [ "$FAIL" -ne 0 ]; then printf '\nupgrade-dryrun: \033[31mFAILED\033[0m\n'; exit 1; fi
printf '\nupgrade-dryrun: \033[32mOK\033[0m\n'
