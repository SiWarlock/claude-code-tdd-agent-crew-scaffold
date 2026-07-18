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

  # ---- HOST marker class (Codex host axis; template-only, stripped at build) --------------------
  # Unlike EXAMPLE BLOCK ids, HOST regions repeat the host label ([claude]/[codex]) — balance, not id set.
  local hopen hclose
  hopen=$(grep -rh '▼ HOST \[' templates/ | wc -l | tr -d ' ')
  hclose=$(grep -rh 'END HOST' templates/ | wc -l | tr -d ' ')
  [ "$hopen" -eq "$hclose" ] \
    && ok "HOST marker balance: $hopen openers / $hclose closers" \
    || bad "HOST marker imbalance: $hopen openers vs $hclose closers"
  local badlabels
  badlabels=$(grep -rho '▼ HOST \[[^]]*\]' templates/ | sed 's/.*\[//; s/\].*//' | tr '|' '\n' | sort -u | grep -vE '^(claude|codex)$' || true)
  [ -z "$badlabels" ] && ok "HOST region labels are claude|codex only" || bad "unknown HOST label(s): $(echo "$badlabels" | tr '\n' ' ')"
  # the engine's host_token_map must define all 7 host-derived tokens (so no HOST token renders unresolved)
  local SUS="skills/scaffold-upgrade/scripts/scaffold_upgrade.sh" tok miss=""
  for tok in ROOT_MEMORY AREA_MEMORY HOOKS_CONFIG COMMANDS_HOME USER_GLOBAL_DIR PROJECT_DIR_ENV HOST_NAME; do
    grep -q "printf '%s\\\\t%s\\\\n' $tok " "$SUS" || miss="$miss $tok"
  done
  [ -z "$miss" ] && ok "host_token_map defines all 7 host-derived tokens" || bad "host_token_map missing token(s):$miss"

  # value-correctness guard (not just definedness): the codex-column COMMANDS_HOME/HOOKS_CONFIG must resolve
  # under a dot-directory — Codex's real skill/config loaders never scan a bare project-root path. This is
  # the exact regression class that shipped once already; catch it here so it can't ship silently again.
  # Isolate host_token_map()'s own function body FIRST (awk, brace-scoped) before extracting its codex
  # case arm — normalize_host() also has a `codex)` arm, and a bare `/^    codex)/,/;;/` sed range across
  # the whole file can silently union the two disjoint case blocks (GNU sed range semantics don't test the
  # end pattern against the line that opened the range, so a same-line `codex) ... ;;` in normalize_host
  # doesn't close there — it re-opens at the next `;;`, then a second range opens at host_token_map's own
  # `codex)` line). Scoping to the function body first makes the codex-arm extraction unambiguous.
  local host_token_map_body codex_commands_home codex_hooks_config
  host_token_map_body=$(awk '/^host_token_map\(\) \{/{f=1} f{print} f && /^}/{exit}' "$SUS")
  codex_commands_home=$(printf '%s\n' "$host_token_map_body" | sed -n '/^    codex)/,/^      ;;/p' | grep "COMMANDS_HOME" | sed -E 's/.*COMMANDS_HOME[[:space:]]+"([^"]*)".*/\1/')
  codex_hooks_config=$(printf '%s\n' "$host_token_map_body" | sed -n '/^    codex)/,/^      ;;/p' | grep "HOOKS_CONFIG" | sed -E 's/.*HOOKS_CONFIG[[:space:]]+"([^"]*)".*/\1/')
  case "$codex_commands_home" in
    .codex/*|.agents/*) ok "codex COMMANDS_HOME is dot-directory-scoped ($codex_commands_home)" ;;
    *) bad "codex COMMANDS_HOME is bare-root ($codex_commands_home) — Codex's real skill loader never scans a bare project-root directory" ;;
  esac
  case "$codex_hooks_config" in
    .codex/*) ok "codex HOOKS_CONFIG is under .codex/ ($codex_hooks_config)" ;;
    *) bad "codex HOOKS_CONFIG is not under .codex/ ($codex_hooks_config) — a bare-root config.toml only loads under a weak, trust-gated fallback" ;;
  esac
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

  # optional per-migration `hosts` filter (schema v3): values must be claude|codex
  # Guard with `select((.hosts|type)=="array")` before `.hosts[]` — jq halts the WHOLE pipeline on the
  # first runtime type error (e.g. a non-array `hosts` field on an earlier entry), which would silently
  # skip label-validation for every entry after it. The type guard means a malformed entry is skipped here
  # (never fatal to this check) while badhostsarr below independently reports the type problem itself.
  local badhosts
  badhosts=$(jq -r '.migrations[] | select(.hosts) | select((.hosts|type)=="array") | .hosts[]' "$reg" 2>/dev/null | sort -u | grep -vE '^(claude|codex)$' || true)
  [ -z "$badhosts" ] && ok "migration 'hosts' values are claude|codex only" || bad "invalid migration 'hosts' value(s): $(echo "$badhosts" | tr '\n' ' ')"
  local badhostsarr
  badhostsarr=$(jq -r '.migrations[] | select(has("hosts")) | select((.hosts|type)!="array") | .id' "$reg" 2>/dev/null || true)
  [ -z "$badhostsarr" ] && ok "migration 'hosts' fields are arrays" || bad "migration 'hosts' not an array: $badhostsarr"
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
