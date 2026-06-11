#!/usr/bin/env bash
# release-check.sh — the scaffolding repo's release gate. Run at every wave/release boundary:
#
#   scripts/release-check.sh all
#
# Subcommands (each exits non-zero on failure):
#   pairs           bundled skill twins are byte-identical to their canonical templates
#                   (FULL-content identity, not structure-only — prose drift is the bug class),
#                   and the generate-procedure stub stays a stub
#   census          the [id=] EXAMPLE-BLOCK region count across templates/ matches the
#                   GENERATE-WITH-CLAUDE.md §10 census, and every opener has a matching closer
#   migrations      migrations/registry.json parses; every entry has its M-file and vice versa;
#                   every introducedAtSha resolves in this checkout; kinds/gates are valid
#   upgrade-dryrun  runs tests/run-upgrade-dryrun.sh when present (skips with a note otherwise)
#   playbook        rebuilds the arch-draft playbook concat and fails if the committed artifact
#                   differs (skips with a note until the build script exists)
#   all             everything above
#
# A template change that skips its twin sync or its migration must fail HERE, loudly — this is
# the fail-loud posture that keeps the template pairs and the upgrade path honest.

set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=1; }
skip() { printf '  \033[33mSKIP\033[0m %s\n' "$*"; }

# ---- pairs ---------------------------------------------------------------------------------------
# canonical<TAB>bundled-twin — add a line per new pair.
PAIRS=$(cat <<'EOF'
templates/IMPLEMENTATION_PLAN.md	skills/tasks-gen/references/implementation-plan-template.md
templates/ARCHITECTURE.md	skills/arch-finalize/references/architecture-template.md
EOF
)

cmd_pairs() {
  printf 'pairs:\n'
  while IFS=$'\t' read -r canon twin; do
    [ -n "$canon" ] || continue
    if [ ! -f "$canon" ]; then bad "$canon missing"; continue; fi
    if [ ! -f "$twin" ];  then bad "$twin missing";  continue; fi
    if cmp -s "$canon" "$twin"; then
      ok "$canon == $twin"
    else
      bad "$canon != $twin — re-sync the bundled twin (cp canonical over it) in the SAME commit as the template edit"
    fi
  done <<< "$PAIRS"

  # The generation procedure is single-sourced at the root; the skill copy must stay a pointer stub.
  local stub="skills/scaffold-generate/references/generate-procedure.md"
  if [ -f "$stub" ] && grep -q "pointer stub" "$stub" && [ "$(wc -l < "$stub")" -le 30 ]; then
    ok "$stub is a pointer stub ($(wc -l < "$stub" | tr -d ' ') lines)"
  else
    bad "$stub is no longer a pointer stub — the canonical procedure lives ONLY in GENERATE-WITH-CLAUDE.md (W1-2)"
  fi
}

# ---- census --------------------------------------------------------------------------------------
cmd_census() {
  printf 'census:\n'
  local expected
  expected=$(grep -oE 'The [0-9]+ regions across [0-9]+ files' GENERATE-WITH-CLAUDE.md | grep -oE '^The [0-9]+' | grep -oE '[0-9]+' || true)
  if [ -z "$expected" ]; then
    bad "could not parse 'The N regions across M files' from GENERATE-WITH-CLAUDE.md §10"
    return
  fi
  local openers closers
  openers=$(grep -rh '▼ EXAMPLE BLOCK \[id=' templates/ | wc -l | tr -d ' ')
  closers=$(grep -rh 'END EXAMPLE BLOCK \[id=' templates/ | wc -l | tr -d ' ')
  [ "$openers" -eq "$expected" ] \
    && ok "region count: $openers openers == §10 census ($expected)" \
    || bad "region count drift: $openers openers in templates/ but §10 says $expected — update the census + id map in the SAME commit"
  [ "$openers" -eq "$closers" ] \
    && ok "marker balance: $openers openers / $closers closers" \
    || bad "marker imbalance: $openers openers vs $closers closers"
  # id sets must match between openers and closers (multiset compare)
  local oids cids
  oids=$(grep -rho '▼ EXAMPLE BLOCK \[id=[a-z0-9-]*\]' templates/ | grep -o '\[id=[a-z0-9-]*\]' | sort)
  cids=$(grep -rho 'END EXAMPLE BLOCK \[id=[a-z0-9-]*\]' templates/ | grep -o '\[id=[a-z0-9-]*\]' | sort)
  if [ "$oids" = "$cids" ]; then
    ok "opener/closer id sets match"
  else
    bad "opener/closer id mismatch: $(diff <(echo "$oids") <(echo "$cids") | grep '^[<>]' | tr '\n' ' ')"
  fi
}

# ---- migrations ----------------------------------------------------------------------------------
cmd_migrations() {
  printf 'migrations:\n'
  local reg="migrations/registry.json"
  if ! jq -e . "$reg" >/dev/null 2>&1; then bad "$reg does not parse"; return; fi
  ok "$reg parses"

  local ids dupes
  ids=$(jq -r '.migrations[].id' "$reg")
  dupes=$(echo "$ids" | sort | uniq -d)
  [ -z "$dupes" ] && ok "migration ids unique" || bad "duplicate migration ids: $dupes"

  # every registry entry has its file; fields are valid; SHA resolves
  while IFS=$'\t' read -r id sha kind gate; do
    local f
    f=$(ls "migrations/${id}-"*.md 2>/dev/null | head -1 || true)
    [ -n "$f" ] && ok "$id has $f" || bad "$id has no migrations/${id}-*.md file"
    case "$kind" in
      renamed-placeholder|moved-section|new-required-section|renamed-template|deleted-template|added-template|accreted-format)
        ok "$id kind '$kind' valid" ;;
      *) bad "$id kind '$kind' is not one of the seven" ;;
    esac
    case "$gate" in human|auto) : ;; *) bad "$id gate '$gate' invalid (human|auto)" ;; esac
    if git cat-file -e "${sha}^{commit}" 2>/dev/null; then
      ok "$id introducedAtSha resolves (${sha:0:7})"
    else
      bad "$id introducedAtSha '$sha' does not resolve — wire the real SHA (two-step pattern) before release"
    fi
  done < <(jq -r '.migrations[] | [.id, .introducedAtSha, .kind, .gate] | @tsv' "$reg")

  # every M-file has a registry entry
  for f in migrations/M-*.md; do
    [ -e "$f" ] || continue
    local mid; mid=$(basename "$f" | grep -oE '^M-[0-9]{4}')
    echo "$ids" | grep -qx "$mid" && ok "$f registered" || bad "$f has no registry entry"
  done
}

# ---- upgrade-dryrun (wired by W1-9) ----------------------------------------------------------------
cmd_upgrade_dryrun() {
  printf 'upgrade-dryrun:\n'
  if [ -x tests/run-upgrade-dryrun.sh ]; then
    if tests/run-upgrade-dryrun.sh; then ok "upgrade dry-run clean"; else bad "upgrade dry-run failed"; fi
  else
    skip "tests/run-upgrade-dryrun.sh not present/executable"
  fi
}

# ---- playbook (wired by W3-2) ----------------------------------------------------------------------
cmd_playbook() {
  printf 'playbook:\n'
  local build="skills/arch-draft/scripts/build-playbook.sh"
  local artifact="skills/arch-draft/references/architecture-planning-playbook.md"
  if [ -x "$build" ]; then
    local tmp; tmp=$(mktemp)
    if "$build" --stdout > "$tmp" 2>/dev/null; then
      if cmp -s "$tmp" "$artifact"; then
        ok "committed playbook concat matches rebuild"
      else
        bad "playbook concat is stale — run $build and commit the regenerated artifact"
      fi
    else
      bad "$build failed"
    fi
    rm -f "$tmp"
  else
    skip "$build not present/executable"
  fi
}

usage() { sed -n '2,20p' "$0"; exit 2; }

main() {
  local sub="${1:-}"
  case "$sub" in
    pairs)          cmd_pairs ;;
    census)         cmd_census ;;
    migrations)     cmd_migrations ;;
    upgrade-dryrun) cmd_upgrade_dryrun ;;
    playbook)       cmd_playbook ;;
    all)            cmd_pairs; cmd_census; cmd_migrations; cmd_upgrade_dryrun; cmd_playbook ;;
    *)              usage ;;
  esac
  if [ "$FAIL" -ne 0 ]; then
    printf '\nrelease-check: \033[31mFAILED\033[0m — fix the items above before the wave/release lands.\n'
    exit 1
  fi
  printf '\nrelease-check: \033[32mOK\033[0m\n'
}

main "$@"
