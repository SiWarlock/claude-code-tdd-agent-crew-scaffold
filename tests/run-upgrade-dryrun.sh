#!/usr/bin/env bash
# run-upgrade-dryrun.sh — drives a full /scaffold-upgrade mechanical pass against the frozen fixture at
# tests/fixtures/upgrade-dryrun/ (a minimal generated project pinned at the pre-M-0001 base SHA).
#
# It exercises ONLY the existing scaffold_upgrade.sh subcommands (resolve → substitute → diff →
# migrations → apply → check-markers → stamp) — it never reimplements the script's deterministic work.
# What it proves: SHA-window migration selection + journaling, auto-apply vs PROPOSE policies,
# per-region split, marker-drift whole-file degradation, accreted leave-alone, conflict-marker
# emission + the check-markers block, stamping, and second-run idempotency.
#
# What it deliberately does NOT prove: the APPLICATION of prose migrations (M-NNNN handler steps) and
# per-region merges — those are model-run and human-gated by design; the harness synthesizes their
# outcomes (.done journals, a pre-approved writes plan) exactly as a human-approved run would.
#
# Wired as `scripts/release-check.sh upgrade-dryrun`.

set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO/skills/scaffold-upgrade/scripts/scaffold_upgrade.sh"
FIX="$REPO/tests/fixtures/upgrade-dryrun/project"
BASE=1d995d4b8c2ce11995f5174ecb69aa9ac93b40b8

FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=1; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/upgrade-dryrun.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
PROJ="$TMP/proj"; WORK="$TMP/work"
mkdir -p "$PROJ"
cp -R "$FIX/." "$PROJ/"
git -C "$PROJ" init -q
git -C "$PROJ" -c user.email=dryrun@fixture -c user.name=dryrun add -A
git -C "$PROJ" -c user.email=dryrun@fixture -c user.name=dryrun commit -qm "fixture seed"

jqp() { jq -r "$1" "$2"; }

# ---- 1. resolve ----------------------------------------------------------------------------------
"$SCRIPT" resolve --project "$PROJ" --scaffold "$REPO" --work "$WORK" > /dev/null
PC="$WORK/precheck.json"
[ "$(jqp '.legacy' "$PC")" = "false" ]            && ok "resolve: manifest path (not legacy)" || bad "resolve: legacy unexpectedly true"
[ "$(jqp '.base' "$PC")" = "$BASE" ]              && ok "resolve: base = pinned pre-M-0001 SHA" || bad "resolve: base $(jqp '.base' "$PC") != $BASE"
[ "$(jqp '.schemaVersion' "$PC")" = "1" ]         && ok "resolve: schemaVersion 1 accepted"     || bad "resolve: schemaVersion $(jqp '.schemaVersion' "$PC")"
[ "$(jqp '.posture' "$PC")" = "unknown" ]         && ok "resolve: v1 grace — posture 'unknown'" || bad "resolve: posture $(jqp '.posture' "$PC") (expected unknown)"
[ "$(jqp '.cleanTree' "$PC")" = "true" ]          && ok "resolve: clean tree"                   || bad "resolve: tree not clean"
[ "$(jqp '.alreadyUpToDate' "$PC")" = "false" ]   && ok "resolve: upgrade pending"              || bad "resolve: alreadyUpToDate on run 1"
TO=$(jqp '.to' "$PC")

# ---- 2. substitute @ base — fixture-drift guard --------------------------------------------------
"$SCRIPT" substitute "$BASE" "$TMP/sub-base" --work "$WORK" 2>/dev/null
if cmp -s "$TMP/sub-base/.claude/commands/check-arch.md" "$FIX/.claude/commands/check-arch.md"; then
  ok "fixture-drift guard: untouched check-arch.md byte-matches substitute($BASE)"
else
  bad "fixture-drift guard: check-arch.md no longer matches substitute output — fixture drifted from templates-at-base"
fi
DIVERGED_LINES=$(diff "$TMP/sub-base/.claude/commands/tdd.md" "$FIX/.claude/commands/tdd.md" | grep -c '^>' || true)
[ "$DIVERGED_LINES" = "1" ] && ok "fixture-drift guard: tdd.md diverges by exactly the one seeded line" \
                            || bad "fixture-drift guard: tdd.md divergence is $DIVERGED_LINES lines (expected 1)"

# ---- 3. diff → plan.json -------------------------------------------------------------------------
"$SCRIPT" diff --work "$WORK" > /dev/null
PLAN="$WORK/plan.json"
e() { jq -r --arg d "$1" '.files[] | select(.dest==$d)'"$2" "$PLAN"; }

[ "$(e 'MVP_TASKS.md' '.policy')" = "leave-alone" ]   && ok "diff: accreted tracker → leave-alone" || bad "diff: MVP_TASKS.md policy $(e 'MVP_TASKS.md' '.policy')"
[ "$(e 'app/LESSONS.md' '.policy')" = "leave-alone" ] && ok "diff: accreted LESSONS → leave-alone" || bad "diff: app/LESSONS.md policy $(e 'app/LESSONS.md' '.policy')"

# diverged placeholder-only file: the seeded line collides with an upstream edit → conflict, PROPOSE
[ "$(e '.claude/commands/tdd.md' '.policy')" = "propose-conflict" ] \
  && ok "diff: diverged tdd.md → propose-conflict (never auto-apply)" \
  || bad "diff: tdd.md policy $(e '.claude/commands/tdd.md' '.policy') (expected propose-conflict)"
[ "$(e '.claude/commands/tdd.md' '.conflicts')" -ge 1 ] \
  && ok "diff: tdd.md merge reports >=1 conflict" || bad "diff: tdd.md conflicts $(e '.claude/commands/tdd.md' '.conflicts')"

# untouched placeholder-only file: provably untouched → auto-apply iff upstream changed, else skip
CA_BET=$(e '.claude/commands/check-arch.md' '.baseEqualsTheirs')
CA_UC=$(e '.claude/commands/check-arch.md' '.upstreamChanged')
CA_POL=$(e '.claude/commands/check-arch.md' '.policy')
[ "$CA_BET" = "true" ] && ok "diff: check-arch.md provably untouched" || bad "diff: check-arch.md baseEqualsTheirs=$CA_BET"
if [ "$CA_UC" = "true" ]; then EXPECT=auto-apply; else EXPECT=skip; fi
[ "$CA_POL" = "$EXPECT" ] && ok "diff: untouched check-arch.md → $EXPECT" || bad "diff: check-arch.md policy $CA_POL (expected $EXPECT)"

# mixed file with damaged marker → whole-file degradation
[ "$(e 'app/CLAUDE.md' '.wholeFilePropose')" = "true" ] \
  && ok "diff: damaged module-layout marker → whole-file-propose degradation" \
  || bad "diff: app/CLAUDE.md wholeFilePropose=$(e 'app/CLAUDE.md' '.wholeFilePropose')"
[ "$(e 'app/CLAUDE.md' '.regions | map(select(.id=="module-layout"))[0].theirsMarker')" = "missing" ] \
  && ok "diff: module-layout region marker reported missing" || bad "diff: module-layout marker not reported missing"

# mixed file per-region split: a CUSTOMIZED region must never be auto-eligible
TS_POL=$(e 'CLAUDE.md' '.regions | map(select(.id=="tech-stack"))[0].policy')
case "$TS_POL" in propose|skip) ok "diff: customized tech-stack region → $TS_POL (never auto-eligible)" ;;
  *) bad "diff: customized tech-stack region policy '$TS_POL'" ;; esac
PS_POL=$(e 'CLAUDE.md' '.regions | map(select(.id=="project-structure"))[0].policy')
case "$PS_POL" in auto-eligible|skip) ok "diff: illustrative project-structure region → $PS_POL" ;;
  *) bad "diff: illustrative project-structure region policy '$PS_POL'" ;; esac

# ---- 4. migrations — window selection + journal idempotency --------------------------------------
"$SCRIPT" migrations --work "$WORK" > /dev/null
MIG="$WORK/migrations.json"
SELECTED=$(jq -r '.migrations[].id' "$MIG" | sort)
REGISTRY=$(git -C "$REPO" show "$TO:migrations/registry.json" | jq -r '.migrations[].id' | sort)
for id in M-0001 M-0002 M-0003 M-0004; do
  echo "$SELECTED" | grep -qx "$id" && ok "migrations: $id selected (in (base,to] window)" || bad "migrations: $id NOT selected"
done
[ "$SELECTED" = "$REGISTRY" ] \
  && ok "migrations: selection == full registry (base predates every migration)" \
  || bad "migrations: selection/registry mismatch: $(comm -3 <(echo "$SELECTED") <(echo "$REGISTRY") | tr '\n' ' ')"
[ "$(jq -r '[.migrations[].alreadyApplied] | any' "$MIG")" = "false" ] \
  && ok "migrations: none pre-applied on run 1" || bad "migrations: alreadyApplied set on run 1"

# Synthesize the journals a human-gated, model-run application would leave (prose application itself
# is out of mechanical scope by design), then re-select: everything must report alreadyApplied.
mkdir -p "$PROJ/.scaffolding/.migrations"
jq -r '.migrations[].id' "$MIG" | while read -r id; do touch "$PROJ/.scaffolding/.migrations/$id.done"; done
"$SCRIPT" migrations --work "$WORK" > /dev/null
[ "$(jq -r '[.migrations[].alreadyApplied] | all' "$MIG")" = "true" ] \
  && ok "migrations: re-select after .done journals → nothing left to do" \
  || bad "migrations: journaled migrations still report unapplied"

# ---- 5. apply — pre-approved plan (auto-applies from ours; the conflicted file from merged) -------
cp "$PROJ/MVP_TASKS.md" "$TMP/tracker.before"; cp "$PROJ/app/LESSONS.md" "$TMP/lessons.before"
jq '{writes: ([.files[] | select(.policy=="auto-apply") | {dest, source:"ours"}]
            + [{dest:".claude/commands/tdd.md", source:"merged"}])}' "$PLAN" > "$TMP/apply-plan.json"
"$SCRIPT" apply "$TMP/apply-plan.json" --work "$WORK" 2>/dev/null
grep -q '^<<<<<<<' "$PROJ/.claude/commands/tdd.md" \
  && ok "apply: merged tdd.md carries conflict markers (diff3 emission)" \
  || bad "apply: expected conflict markers in applied tdd.md"
cmp -s "$PROJ/MVP_TASKS.md" "$TMP/tracker.before"  && ok "apply: accreted tracker untouched end-to-end" || bad "apply: tracker was modified"
cmp -s "$PROJ/app/LESSONS.md" "$TMP/lessons.before" && ok "apply: accreted LESSONS untouched end-to-end" || bad "apply: LESSONS was modified"

# ---- 6. check-markers must BLOCK, then pass after resolution --------------------------------------
if "$SCRIPT" check-markers --work "$WORK" >/dev/null 2>&1; then
  bad "check-markers: did NOT block on unresolved conflict markers"
else
  ok "check-markers: blocks while conflict markers present"
fi
cp "$WORK/ours/.claude/commands/tdd.md" "$PROJ/.claude/commands/tdd.md"   # human resolves (takes upstream)
"$SCRIPT" check-markers --work "$WORK" >/dev/null 2>&1 \
  && ok "check-markers: clean after resolution" || bad "check-markers: still failing after resolution"

# ---- 7. stamp -------------------------------------------------------------------------------------
"$SCRIPT" stamp "$TO" --work "$WORK" >/dev/null 2>&1
[ "$(jq -r '.lastUpgradedFromSha' "$PROJ/.scaffolding/manifest.json")" = "$TO" ] \
  && ok "stamp: lastUpgradedFromSha = $TO" || bad "stamp: manifest not stamped"
[ -s "$PROJ/.scaffolding/upgrade-log.jsonl" ] && ok "stamp: upgrade-log appended" || bad "stamp: no upgrade-log"

# ---- 8. run 2 — full idempotency -------------------------------------------------------------------
git -C "$PROJ" -c user.email=dryrun@fixture -c user.name=dryrun add -A
git -C "$PROJ" -c user.email=dryrun@fixture -c user.name=dryrun commit -qm "upgrade applied"
"$SCRIPT" resolve --project "$PROJ" --scaffold "$REPO" --work "$WORK" > /dev/null
[ "$(jqp '.alreadyUpToDate' "$PC")" = "true" ] \
  && ok "run 2: resolve reports already up to date (base == to)" || bad "run 2: not up-to-date after stamp"
"$SCRIPT" migrations --work "$WORK" > /dev/null
[ "$(jq -r '.migrations | length' "$MIG")" = "0" ] \
  && ok "run 2: migration window empty — second run selects nothing" || bad "run 2: migrations still selected"

if [ "$FAIL" -ne 0 ]; then printf 'upgrade-dryrun: \033[31mFAILED\033[0m\n'; exit 1; fi
printf 'upgrade-dryrun: \033[32mOK\033[0m\n'
