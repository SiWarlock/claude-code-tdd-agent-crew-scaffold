#!/usr/bin/env bash
# scaffold_upgrade.sh — the deterministic engine behind the /scaffold-upgrade skill.
#
# It produces FACTS and performs HUMAN-APPROVED mechanical writes. It makes no judgment calls:
# the model (the skill) decides what to apply, resolves conflicts git can't, and drives the gates.
#
# Toolchain: bash + jq + git only (no new deps; bash 3.2-compatible — no associative arrays).
# Each subcommand is self-contained; cross-call state travels through files in the --work dir.
#
# Subcommands:
#   resolve       resolve base/to, validate manifest, clean-tree gate            → <work>/precheck.json
#   substitute    REF OUTDIR — rebuild a substituted template tree at a ref       (debug / building base|ours)
#   diff          build base+ours, 3-way merge every file, split mixed regions   → <work>/plan.json
#   migrations    select the (base,to] migration window from registry.json       → <work>/migrations.json
#   apply         PLAN — copy auto-apply (ours) + write merged (markers) files    (mechanical writes only)
#   stamp         TO   — advance lastUpgradedFromSha, append upgrade-log          (manifest finalize)
#   check-markers grep written files for unresolved conflict markers; nonzero if any
#
# Usage:
#   scaffold_upgrade.sh resolve  --project DIR --scaffold DIR [--base SHA] [--to REF] [--work DIR]
#   scaffold_upgrade.sh substitute REF OUTDIR --work DIR
#   scaffold_upgrade.sh diff       --work DIR
#   scaffold_upgrade.sh migrations --work DIR
#   scaffold_upgrade.sh apply      PLAN_JSON  --work DIR
#   scaffold_upgrade.sh stamp      TO --work DIR [--record JSON]
#   scaffold_upgrade.sh check-markers --work DIR
#
# The skill knows the schema version it understands; bump SKILL_SCHEMA when the manifest shape changes.
# Schema history: v2 added `posture` ("production-grade" | "MVP/prototype"). v3 added `host`
# ("claude" | "codex") — the generation target. A v1/v2 manifest is still accepted; its `host`
# surfaces as "claude" (the historical default) so existing Claude projects render byte-identically.
# A v1 manifest's posture surfaces as "unknown" in precheck.json, and posture-gated upgrade content
# (e.g. production-grade checklist rows) must then be HUMAN-gated, never auto-applied.

set -euo pipefail

SKILL_SCHEMA=3
SELF="scaffold_upgrade.sh"

die()  { printf '%s: error: %s\n' "$SELF" "$*" >&2; exit 1; }
warn() { printf '%s: %s\n' "$SELF" "$*" >&2; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }

need git; need jq

# ---- shared arg parsing -------------------------------------------------------------------------
PROJECT="" ; SCAFFOLD="" ; BASE="" ; TO="" ; WORK="" ; RECORD=""
POS=()
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --project)  PROJECT="${2:?}"; shift 2 ;;
      --scaffold) SCAFFOLD="${2:?}"; shift 2 ;;
      --base)     BASE="${2:?}"; shift 2 ;;
      --to)       TO="${2:?}"; shift 2 ;;
      --work)     WORK="${2:?}"; shift 2 ;;
      --record)   RECORD="${2:?}"; shift 2 ;;
      --*)        die "unknown option: $1" ;;
      *)          POS+=("$1"); shift ;;
    esac
  done
}

# Read a value from precheck.json (written by `resolve`); used by later self-contained subcommands.
pc() { jq -r "$1" "$WORK/precheck.json"; }

manifest_path() { printf '%s/.scaffolding/manifest.json' "$1"; }

# ---- substitution (pure bash; preserves trailing newlines; literal, glob-safe replacement) -------
# Emit the effective TOKEN<TAB>VALUE map for a generatedFiles row (global placeholders, overlaid with
# the matching codeAreas entry when the row is area-scoped). Null values are skipped, not substituted.
# ---- host token map (host-derived placeholder values) -------------------------------------------
# A small set of placeholders whose value is DERIVED from the manifest's `host` field rather than
# interviewed — they name host-specific layout facts (memory filename, hooks-config file, commands
# home, user-global dir, project-dir env var, host name). Templates carry these {{TOKENS}} only at
# load-bearing spots (cross-doc pointers, hook-wiring lines, the `cd "${{{PROJECT_DIR_ENV}}}"` in
# secrets-guard). Emitted at LOWEST precedence (see emit_map_for_area) so a real placeholder of the
# same name would still win. host defaults to "claude", so a manifest without a host field renders
# byte-identically to the historical Claude layout.
normalize_host() {  # $1 = raw host value (possibly "", "null", garbage) -> stdout "claude" | "codex", never anything else
  case "$1" in
    codex) printf 'codex\n' ;;
    *)     printf 'claude\n' ;;
  esac
}

resolve_host_from_manifest() {  # $1 = manifest path -> stdout "claude" | "codex" (normalized; single source of truth)
  normalize_host "$(jq -r '.host // "claude"' "$1" 2>/dev/null)"
}

host_token_map() {  # $1 = host -> stdout TSV (TOKEN<TAB>VALUE)
  case "$1" in
    codex)
      printf '%s\t%s\n' ROOT_MEMORY     "AGENTS.md"
      printf '%s\t%s\n' AREA_MEMORY     "AGENTS.md"
      printf '%s\t%s\n' HOOKS_CONFIG    ".codex/config.toml"
      printf '%s\t%s\n' COMMANDS_HOME   ".agents/skills/"
      printf '%s\t%s\n' USER_GLOBAL_DIR "~/.codex"
      printf '%s\t%s\n' PROJECT_DIR_ENV "CODEX_PROJECT_DIR"
      printf '%s\t%s\n' HOST_NAME       "Codex CLI"
      ;;
    *)  # claude (historical default)
      printf '%s\t%s\n' ROOT_MEMORY     "CLAUDE.md"
      printf '%s\t%s\n' AREA_MEMORY     "CLAUDE.md"
      printf '%s\t%s\n' HOOKS_CONFIG    ".claude/settings.json"
      printf '%s\t%s\n' COMMANDS_HOME   ".claude/commands/"
      printf '%s\t%s\n' USER_GLOBAL_DIR "~/.claude"
      printf '%s\t%s\n' PROJECT_DIR_ENV "CLAUDE_PROJECT_DIR"
      printf '%s\t%s\n' HOST_NAME       "Claude Code"
      ;;
  esac
}

emit_map_for_area() {  # $1 = manifest, $2 = area ("" for none) -> stdout TSV
  # Area-scoped values are emitted FIRST so that, with substitute_stream's first-match-wins semantics, an
  # area override beats the global default for the same token (e.g. a per-area TEST_CMD). The area's own
  # CODE_AREA value also fills {{CODE_AREA}} for that area's files, so it is kept (it doubles as the area id).
  # Host-derived tokens are emitted LAST (lowest precedence) so a real placeholder still wins on collision.
  local manifest="$1" area="$2"
  if [ -n "$area" ]; then
    jq -r --arg a "$area" \
      '.codeAreas[]? | select(.CODE_AREA==$a) | to_entries[] | select(.value != null) | [.key, (.value|tostring)] | @tsv' \
      "$manifest"
  fi
  jq -r '.placeholders | to_entries[] | select(.value != null) | [.key, (.value|tostring)] | @tsv' "$manifest"
  host_token_map "$(resolve_host_from_manifest "$manifest")"
}

substitute_stream() {  # $1 = map TSV file; reads stdin, writes substituted content to stdout
  local mapfile="$1" content key val pat
  content=$(cat; printf 'x'); content=${content%x}   # capture stdin, keep trailing newlines
  while IFS=$'\t' read -r key val || [ -n "$key" ]; do
    [ -n "$key" ] || continue
    pat="{{${key}}}"
    content=${content//"$pat"/"$val"}                # quoted => literal, glob-safe
  done < "$mapfile"
  printf '%s' "$content"
}

# ---- mode pruning (template-only MODE markers) ---------------------------------------------------
# Templates may carry mode-pruning regions:
#   <!-- ▼ MODE [solo|team-single-track|team-multi-track] pointer: <one-line text, or `delete`> ▼ -->
#   ...content kept only when the project's derived state is in the [list]...
#   <!-- ▲ END MODE ▲ -->
# Generation strips the marker LINES (content kept bare when the state matches; otherwise the whole
# region is replaced by the pointer line, or nothing for `delete`). These markers are TEMPLATE-ONLY —
# they never survive into generated files — so base/ours rebuilds MUST replay the same pruning or
# `theirs == base` would fail for every pruned file. No nesting.

# The project's 3-state mode, DERIVED from existing manifest fields (no new field):
#   single-operator => solo · team + tracks==[] => team-single-track · team + tracks>0 => team-multi-track
derive_mode_state() {  # $1 = manifest -> stdout state
  jq -r 'if .mode == "single-operator" then "solo"
         elif ((.tracks // []) | length) > 0 then "team-multi-track"
         else "team-single-track" end' "$1"
}

prune_stream() {  # $1 = state; stdin -> stdout with MODE regions resolved
  awk -v state="$1" '
    BEGIN { inblock = 0; keep = 1; down = "\xe2\x96\xbc"; up = "\xe2\x96\xb2" }
    index($0, down " MODE [") {
      inblock = 1
      modes = $0; sub(/^.*MODE \[/, "", modes); sub(/\].*$/, "", modes)
      keep = (index("|" modes "|", "|" state "|") > 0)
      if (!keep && index($0, "pointer: ") > 0) {
        ptr = substr($0, index($0, "pointer: ") + 9)
        p = index(ptr, down); if (p > 0) ptr = substr(ptr, 1, p - 1)
        gsub(/[ \t]+$/, "", ptr)
        if (ptr != "delete" && ptr != "") print ptr
      }
      next
    }
    index($0, "END MODE") && index($0, up) { inblock = 0; keep = 1; next }
    inblock && !keep { next }
    { print }
  '
}

host_prune_stream() {  # $1 = host; stdin -> stdout with HOST regions resolved
  # Mirror of prune_stream over HOST markers: <!-- ▼ HOST [claude|codex] ▼ --> ... <!-- ▲ END HOST ▲ -->.
  # A region whose bracket list excludes the active host is dropped; if that opener carries a
  # "pointer: <text>", the pointer line is emitted in its place (same convention as MODE).
  # host defaults upstream to "claude", so a template with no HOST markers is passed through verbatim.
  awk -v state="$1" '
    BEGIN { inblock = 0; keep = 1; down = "\xe2\x96\xbc"; up = "\xe2\x96\xb2" }
    index($0, down " HOST [") {
      inblock = 1
      modes = $0; sub(/^.*HOST \[/, "", modes); sub(/\].*$/, "", modes)
      keep = (index("|" modes "|", "|" state "|") > 0)
      if (!keep && index($0, "pointer: ") > 0) {
        ptr = substr($0, index($0, "pointer: ") + 9)
        p = index(ptr, down); if (p > 0) ptr = substr(ptr, 1, p - 1)
        gsub(/[ \t]+$/, "", ptr)
        if (ptr != "delete" && ptr != "") print ptr
      }
      next
    }
    index($0, "END HOST") && index($0, up) { inblock = 0; keep = 1; next }
    inblock && !keep { next }
    { print }
  '
}

# Build a fully substituted template tree at REF into OUTDIR (one file per generatedFiles row).
# Substitution AND mode pruning are both replayed so the tree matches what generation produced.
# Records any template missing at REF into <work>/missing-<tag>.txt (tag = base|ours|<ref>).
build_tree() {  # $1 = manifest, $2 = scaffold dir, $3 = ref, $4 = outdir, $5 = tag
  local manifest="$1" scaffold="$2" ref="$3" outdir="$4" tag="$5"
  local rows dest template area mapf miss state host
  miss="$WORK/missing-$tag.txt"; : > "$miss"
  mkdir -p "$outdir"
  state=$(derive_mode_state "$manifest")
  host=$(resolve_host_from_manifest "$manifest")
  rows=$(jq -c '.generatedFiles[]?' "$manifest")
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    dest=$(printf '%s' "$row" | jq -r '.dest')
    template=$(printf '%s' "$row" | jq -r '.template')
    area=$(printf '%s' "$row" | jq -r '.area // ""')
    # Only verbatim/placeholder-only/mixed get rebuilt; accreted + user-canonical are never re-derived.
    local kind; kind=$(printf '%s' "$row" | jq -r '.kind')
    case "$kind" in accreted|user-canonical) continue ;; esac
    if ! git -C "$scaffold" cat-file -e "$ref:$template" 2>/dev/null; then
      printf '%s\t%s\n' "$dest" "$template" >> "$miss"
      continue
    fi
    mapf="$WORK/.map.tmp"; emit_map_for_area "$manifest" "$area" > "$mapf"
    mkdir -p "$outdir/$(dirname "$dest")"
    git -C "$scaffold" show "$ref:$template" | substitute_stream "$mapf" | prune_stream "$state" | host_prune_stream "$host" > "$outdir/$dest"
  done <<EOF
$rows
EOF
}

# ---- resolve ------------------------------------------------------------------------------------
cmd_resolve() {
  [ -n "$PROJECT" ]  || die "resolve needs --project"
  [ -n "$SCAFFOLD" ] || die "resolve needs --scaffold"
  WORK="${WORK:-$PROJECT/.scaffolding/.upgrade-work}"
  mkdir -p "$WORK"
  git -C "$PROJECT" rev-parse --git-dir >/dev/null 2>&1 || die "project is not a git repository: $PROJECT (scaffold-upgrade needs git for the clean-tree gate + the upgrade branch/commit)"
  local manifest; manifest=$(manifest_path "$PROJECT")
  if [ ! -f "$manifest" ]; then
    jq -n --arg p "$PROJECT" '{legacy:true, projectDir:$p, reason:"no .scaffolding/manifest.json"}' > "$WORK/precheck.json"
    cat "$WORK/precheck.json"; return 0
  fi
  jq -e . "$manifest" >/dev/null 2>&1 || die "manifest is not valid JSON: $manifest"

  local schema; schema=$(jq -r '.schemaVersion // 0' "$manifest")
  if [ "$schema" -gt "$SKILL_SCHEMA" ]; then
    die "manifest schemaVersion ($schema) is newer than this skill understands ($SKILL_SCHEMA) — update the skill."
  fi

  # base = --base ?? lastUpgradedFromSha ?? generatedFromSha
  local mbase
  mbase=$(jq -r '.lastUpgradedFromSha // .generatedFromSha // ""' "$manifest")
  [ -n "$BASE" ] || BASE="$mbase"
  local sha_unknown=false base_conf="exact"
  if [ -z "$BASE" ] || [ "$BASE" = "null" ]; then sha_unknown=true; base_conf="none"; BASE=""; fi

  # to = --to ?? HEAD, resolved to a full sha in the scaffold checkout
  local to_ref="${TO:-HEAD}" to_sha=""
  to_sha=$(git -C "$SCAFFOLD" rev-parse --verify "${to_ref}^{commit}" 2>/dev/null || true)
  [ -n "$to_sha" ] || die "cannot resolve --to '$to_ref' in scaffold checkout $SCAFFOLD"

  local shallow base_exists=true
  shallow=$(git -C "$SCAFFOLD" rev-parse --is-shallow-repository 2>/dev/null || echo false)
  if [ -n "$BASE" ] && ! git -C "$SCAFFOLD" cat-file -e "${BASE}^{commit}" 2>/dev/null; then
    base_exists=false; base_conf="none"
  fi

  # clean-tree gate: dirty paths among generatedFiles dests or .scaffolding/
  local dirty; dirty=$(
    git -C "$PROJECT" status --porcelain 2>/dev/null | while IFS= read -r line; do
      p="${line:3}"                                   # strip the 2-char status + 1 space
      case "$p" in *" -> "*) p="${p##* -> }" ;; esac   # rename: take the post-arrow (new) path
      p="${p%\"}"; p="${p#\"}"                         # unquote if porcelain quoted a special path
      case "$p" in .scaffolding/*) echo "$p"; continue ;; esac
      jq -e --arg p "$p" '.generatedFiles[]? | select(.dest==$p)' "$manifest" >/dev/null 2>&1 && echo "$p" || true
    done | sort -u
  )

  local already=false
  if [ -n "$BASE" ] && [ "$BASE" = "$to_sha" ]; then already=true; fi

  jq -n \
    --arg project "$PROJECT" --arg scaffold "$SCAFFOLD" --arg manifest "$manifest" \
    --arg base "$BASE" --arg baseConf "$base_conf" --arg to "$to_sha" --arg toRef "$to_ref" \
    --argjson schema "$schema" --argjson shaUnknown "$sha_unknown" \
    --argjson baseExists "$base_exists" --argjson already "$already" \
    --arg shallow "$shallow" --arg mode "$(jq -r '.mode // ""' "$manifest")" \
    --arg posture "$(jq -r '.posture // ""' "$manifest")" \
    --arg host "$(resolve_host_from_manifest "$manifest")" \
    --arg dirty "$dirty" '
    { legacy:false, projectDir:$project, scaffoldDir:$scaffold, manifestPath:$manifest,
      schemaVersion:$schema, base:$base, baseConfidence:$baseConf, baseExists:$baseExists,
      to:$to, toRef:$toRef, shaUnknown:$shaUnknown, shallow:($shallow=="true"),
      alreadyUpToDate:$already, mode:$mode, host:$host,
      posture:(if $posture=="" then "unknown" else $posture end),
      dirtyScaffoldPaths:($dirty|split("\n")|map(select(length>0))),
      cleanTree:(($dirty|split("\n")|map(select(length>0))|length)==0) }' > "$WORK/precheck.json"
  cat "$WORK/precheck.json"
}

# ---- substitute (standalone) --------------------------------------------------------------------
cmd_substitute() {
  [ "${#POS[@]}" -ge 2 ] || die "substitute needs: REF OUTDIR"
  [ -n "$WORK" ] || die "substitute needs --work (with a precheck.json)"
  local ref="${POS[0]}" outdir="${POS[1]}"
  local manifest scaffold; manifest=$(pc '.manifestPath'); scaffold=$(pc '.scaffoldDir')
  build_tree "$manifest" "$scaffold" "$ref" "$outdir" "$(printf '%s' "$ref" | tr '/:' '__')"
  printf 'substituted tree at %s -> %s\n' "$ref" "$outdir" >&2
}

# ---- diff: build base+ours, 3-way merge, region-split mixed -> plan.json ------------------------
extract_region() {  # $1 = file, $2 = id ; prints inner content (between open and close markers)
  awk -v id="$2" '
    index($0, "EXAMPLE BLOCK [id=" id "]") && index($0,"\xe2\x96\xbc EXAMPLE BLOCK") {g=1; next}
    index($0, "END EXAMPLE BLOCK [id=" id "]") {g=0}
    g {print}
  ' "$1" 2>/dev/null
}
has_region() {  # file id -> 0 if both open and close markers present
  grep -Fq "EXAMPLE BLOCK [id=$2]" "$1" 2>/dev/null && grep -Fq "END EXAMPLE BLOCK [id=$2]" "$1" 2>/dev/null
}

cmd_diff() {
  [ -n "$WORK" ] || die "diff needs --work"
  local manifest scaffold project base to
  manifest=$(pc '.manifestPath'); scaffold=$(pc '.scaffoldDir'); project=$(pc '.projectDir')
  base=$(pc '.base'); to=$(pc '.to')
  [ -n "$base" ] || die "no base SHA in precheck (legacy/fingerprint path is model-driven; pass --base)"
  local bdir="$WORK/base" odir="$WORK/ours" mdir="$WORK/merged"
  rm -rf "$bdir" "$odir" "$mdir"; mkdir -p "$bdir" "$odir" "$mdir"
  build_tree "$manifest" "$scaffold" "$base" "$bdir" "base"
  build_tree "$manifest" "$scaffold" "$to"   "$odir" "ours"

  local entries="$WORK/.plan-entries.jsonl"; : > "$entries"
  local rows; rows=$(jq -c '.generatedFiles[]?' "$manifest")
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    local dest template kind area
    dest=$(printf '%s' "$row" | jq -r '.dest')
    template=$(printf '%s' "$row" | jq -r '.template')
    kind=$(printf '%s' "$row" | jq -r '.kind')
    area=$(printf '%s' "$row" | jq -r '.area // ""')
    local bf="$bdir/$dest" of="$odir/$dest" tf="$project/$dest" mf="$mdir/$dest"

    # accreted / user-canonical: never re-derived; just flag presence for the model.
    case "$kind" in
      accreted)       printf '%s\n' "$(jq -nc --arg d "$dest" --arg k "$kind" '{dest:$d,kind:$k,policy:"leave-alone"}')" >> "$entries"; continue ;;
      user-canonical) printf '%s\n' "$(jq -nc --arg d "$dest" --arg k "$kind" '{dest:$d,kind:$k,policy:"skip"}')" >> "$entries"; continue ;;
    esac

    local pb=false po=false pt=false
    [ -f "$bf" ] && pb=true; [ -f "$of" ] && po=true; [ -f "$tf" ] && pt=true

    # template removed upstream
    if [ "$pb" = true ] && [ "$po" = false ]; then
      printf '%s\n' "$(jq -nc --arg d "$dest" --arg k "$kind" '{dest:$d,kind:$k,policy:"deleted-template",note:"template removed upstream — PROPOSE delete, never auto-delete"}')" >> "$entries"; continue
    fi
    # template added since base (in ledger but absent at base)
    if [ "$pb" = false ] && [ "$po" = true ]; then
      printf '%s\n' "$(jq -nc --arg d "$dest" --arg k "$kind" '{dest:$d,kind:$k,policy:"added",note:"present at to, absent at base"}')" >> "$entries"; continue
    fi

    local baseEqualsTheirs=false upstreamChanged=false mergeClean=false conflicts=0
    [ "$pb" = true ] && [ "$pt" = true ] && cmp -s "$bf" "$tf" && baseEqualsTheirs=true
    [ "$pb" = true ] && [ "$po" = true ] && { cmp -s "$bf" "$of" || upstreamChanged=true; }
    if [ "$pt" = true ] && [ "$pb" = true ] && [ "$po" = true ]; then
      mkdir -p "$(dirname "$mf")"
      set +e; git merge-file -p --diff3 -L 'theirs (your file)' -L 'base (last upgrade)' -L 'ours (upstream)' "$tf" "$bf" "$of" > "$mf" 2>/dev/null; conflicts=$?; set -e
      [ "$conflicts" -eq 0 ] && mergeClean=true
      [ "$conflicts" -ge 255 ] && { conflicts=-1; mergeClean=false; }
    fi

    # default policy by kind
    local policy="skip" regions_json="[]" wholeFilePropose=false
    if [ "$upstreamChanged" = false ]; then
      policy="skip"
    else
      case "$kind" in
        verbatim)
          if [ "$baseEqualsTheirs" = true ]; then policy="auto-apply"; else policy="propose-diverged"; fi ;;
        placeholder-only)
          # Prime directive: auto-apply ONLY when provably untouched. A clean-but-diverged 3-way is a
          # low-risk PROPOSE (human-approved), never a silent write; a conflicted one is a PROPOSE too.
          if [ "$baseEqualsTheirs" = true ]; then policy="auto-apply"
          elif [ "$mergeClean" = true ]; then policy="propose-clean"
          else policy="propose-conflict"; fi ;;
        mixed)
          policy="mixed-regions"
          # build per-region facts
          local ids rj="[]" id
          ids=$(jq -r --arg f "$dest" '.exampleBlocks[]? | select(.file==$f) | .id' "$manifest")
          while IFS= read -r id; do
            [ -n "$id" ] || continue
            local status rOpenT="present" rEq=false rUp=false
            status=$(jq -r --arg f "$dest" --arg i "$id" '.exampleBlocks[]? | select(.file==$f and .id==$i) | .status' "$manifest")
            if ! has_region "$tf" "$id"; then rOpenT="missing"; wholeFilePropose=true; fi
            if [ "$rOpenT" = present ] && [ "$pb" = true ]; then
              [ "$(extract_region "$bf" "$id")" = "$(extract_region "$tf" "$id")" ] && rEq=true
            fi
            [ "$pb" = true ] && [ "$po" = true ] && { [ "$(extract_region "$bf" "$id")" = "$(extract_region "$of" "$id")" ] || rUp=true; }
            rj=$(printf '%s' "$rj" | jq -c --arg id "$id" --arg st "$status" --arg ot "$rOpenT" \
                   --argjson eq "$rEq" --argjson up "$rUp" \
                   '. + [{id:$id, status:$st, theirsMarker:$ot, baseEqualsTheirs:$eq, upstreamChanged:$up,
                          policy: (if $ot=="missing" then "whole-file-propose"
                                   elif ($up|not) then "skip"
                                   elif $st=="illustrative" then "auto-eligible"
                                   else "propose" end)}]')
          done <<RIDS
$ids
RIDS
          regions_json="$rj" ;;
      esac
    fi

    printf '%s\n' "$(jq -nc \
      --arg d "$dest" --arg t "$template" --arg k "$kind" --arg a "$area" --arg p "$policy" \
      --argjson be "$baseEqualsTheirs" --argjson uc "$upstreamChanged" --argjson mc "$mergeClean" \
      --argjson cf "$conflicts" --argjson wp "$wholeFilePropose" --argjson rg "$regions_json" '
      { dest:$d, template:$t, kind:$k, area:(if $a=="" then null else $a end), policy:$p,
        baseEqualsTheirs:$be, upstreamChanged:$uc, mergeClean:$mc, conflicts:$cf,
        wholeFilePropose:$wp, regions:$rg }')" >> "$entries"
  done <<EOF
$rows
EOF

  # template-set delta between base and to (added / removed / renamed under templates/)
  local added removed renamed
  added=$(git -C "$scaffold" diff --name-status --diff-filter=A "$base" "$to" -- templates/ 2>/dev/null | awk '{print $2}' | jq -R . | jq -s . || echo '[]')
  removed=$(git -C "$scaffold" diff --name-status --diff-filter=D "$base" "$to" -- templates/ 2>/dev/null | awk '{print $2}' | jq -R . | jq -s . || echo '[]')
  renamed=$(git -C "$scaffold" diff --name-status --find-renames --diff-filter=R "$base" "$to" -- templates/ 2>/dev/null \
            | awk -F'\t' '{print $2"\t"$3}' | jq -R 'split("\t")|{from:.[0],to:.[1]}' | jq -s . || echo '[]')

  jq -s --argjson added "${added:-[]}" --argjson removed "${removed:-[]}" --argjson renamed "${renamed:-[]}" \
     --arg base "$base" --arg to "$to" \
     '{base:$base, to:$to, files:., templateSetDelta:{added:$added, removed:$removed, renamed:$renamed}}' \
     "$entries" > "$WORK/plan.json"
  cat "$WORK/plan.json"
}

# ---- migrations: select the (base,to] window from registry.json ---------------------------------
cmd_migrations() {
  [ -n "$WORK" ] || die "migrations needs --work"
  local scaffold base to host; scaffold=$(pc '.scaffoldDir'); base=$(pc '.base'); to=$(pc '.to')
  host=$(normalize_host "$(pc '.host')")   # precheck.json's host is already normalized (cmd_resolve); this is defense-in-depth
  local reg; reg=$(git -C "$scaffold" show "$to:migrations/registry.json" 2>/dev/null || echo '{"migrations":[]}')
  local ids; ids=$(printf '%s' "$reg" | jq -r '.migrations[]? | select(.introducedAtSha != null) | (.introducedAtSha + "\t" + .id)')
  local selected="[]" line isha mid
  while IFS=$'\t' read -r isha mid; do
    [ -n "$isha" ] || continue
    # window: base < introducedAtSha <= to  (topological via ancestry). Distinguish a clean ancestry
    # answer (rc 0/1) from an UNRESOLVABLE sha (rc>=128, e.g. shallow clone / rebased) — never silently
    # treat an unresolvable migration sha as out-of-window.
    local upper=false lower=true rc
    set +e; git -C "$scaffold" merge-base --is-ancestor "$isha" "$to" 2>/dev/null; rc=$?; set -e
    if [ "$rc" -eq 0 ]; then upper=true
    elif [ "$rc" -ge 128 ]; then warn "migration $mid: introducedAtSha $isha unresolvable in scaffold (shallow clone / rebased?) — skipping; unshallow or pass --to a ref that contains it"; continue
    fi
    if [ -n "$base" ]; then
      # lower bound: introducedAtSha must NOT be an ancestor of base (i.e. base < isha)
      set +e; git -C "$scaffold" merge-base --is-ancestor "$isha" "$base" 2>/dev/null; rc=$?; set -e
      if [ "$rc" -eq 0 ]; then lower=false
      elif [ "$rc" -ge 128 ]; then warn "migration $mid: introducedAtSha $isha unresolvable against base — skipping"; continue
      fi
    fi
    if [ "$upper" = true ] && [ "$lower" = true ]; then
      local entry; entry=$(printf '%s' "$reg" | jq -c --arg id "$mid" '.migrations[] | select(.id==$id)')
      # host filter: a migration may declare a `hosts` array naming the host(s) it applies to.
      # Absent ⇒ applies to all hosts (back-compat: the 12 historical migrations carry no `hosts`).
      # Present ⇒ select only when the manifest's active host is listed.
      local hostok; hostok=$(printf '%s' "$entry" | jq -r --arg h "$host" '
        if (.hosts|type)=="array" then (if (.hosts|index($h))!=null then "yes" else "no" end) else "yes" end' 2>/dev/null)
      if [ "$hostok" != "yes" ]; then continue; fi
      # idempotency pre-check: a journal touchfile under .scaffolding/.migrations/<id>.done
      local done=false; [ -f "$(pc '.projectDir')/.scaffolding/.migrations/$mid.done" ] && done=true
      selected=$(printf '%s' "$selected" | jq -c --argjson e "$entry" --argjson d "$done" '. + [($e + {alreadyApplied:$d})]')
    fi
  done <<EOF
$ids
EOF
  # Ordering follows registry.json declaration order — the registry is append-only and MUST be authored in
  # topological / commit order (newest last), so declaration order == apply order.
  jq -n --argjson sel "$selected" '{window:{base:"'"$base"'",to:"'"$to"'"}, migrations:$sel}' > "$WORK/migrations.json"
  cat "$WORK/migrations.json"
}

# ---- apply: mechanical writes only (plan already encodes the human's PAUSE-1 decisions) ----------
# Expects a plan with a "writes" array: [{dest, source}] where source ∈ "ours" | "merged".
cmd_apply() {
  [ "${#POS[@]}" -ge 1 ] || die "apply needs: PLAN_JSON"
  [ -n "$WORK" ] || die "apply needs --work"
  local plan="${POS[0]}" project; project=$(pc '.projectDir')
  jq -e . "$plan" >/dev/null 2>&1 || die "apply plan is not valid JSON: $plan"
  local n=0
  jq -c '.writes[]?' "$plan" | while IFS= read -r w; do
    local dest source src
    dest=$(printf '%s' "$w" | jq -r '.dest')
    source=$(printf '%s' "$w" | jq -r '.source')   # ours | merged
    case "$source" in
      ours)   src="$WORK/ours/$dest" ;;
      merged) src="$WORK/merged/$dest" ;;
      *)      warn "skip $dest: unknown source '$source'"; continue ;;
    esac
    [ -f "$src" ] || { warn "skip $dest: missing $src"; continue; }
    mkdir -p "$project/$(dirname "$dest")"
    cp "$src" "$project/$dest"
    printf '  applied (%s): %s\n' "$source" "$dest" >&2
    n=$((n+1))
  done
  printf 'apply complete\n' >&2
}

# ---- check-markers: hard pre-commit guard -------------------------------------------------------
cmd_check_markers() {
  [ -n "$WORK" ] || die "check-markers needs --work"
  local project manifest; project=$(pc '.projectDir'); manifest=$(pc '.manifestPath')
  local hits=0 mode_hits=0 host_hits=0 dest
  while IFS= read -r dest; do
    [ -n "$dest" ] || continue
    if [ -f "$project/$dest" ] && grep -nE '^(<<<<<<<|\|\|\|\|\|\|\||=======|>>>>>>>)' "$project/$dest" >/dev/null 2>&1; then
      warn "UNRESOLVED conflict markers in: $dest"
      hits=$((hits+1))
    fi
    # MODE pruning markers are TEMPLATE-ONLY — their ABSENCE in generated files is correct (unlike
    # EXAMPLE BLOCK markers); their PRESENCE means an upgrade write leaked an unpruned template.
    if [ -f "$project/$dest" ] && grep -q '▼ MODE \[' "$project/$dest" 2>/dev/null; then
      warn "TEMPLATE-ONLY MODE marker leaked into: $dest (a write skipped mode pruning)"
      mode_hits=$((mode_hits+1))
    fi
    # HOST pruning markers are likewise TEMPLATE-ONLY — their presence means a write skipped host pruning.
    if [ -f "$project/$dest" ] && grep -q '▼ HOST \[' "$project/$dest" 2>/dev/null; then
      warn "TEMPLATE-ONLY HOST marker leaked into: $dest (a write skipped host pruning)"
      host_hits=$((host_hits+1))
    fi
  done < <(jq -r '.generatedFiles[]?.dest' "$manifest")
  if [ "$hits" -gt 0 ]; then die "$hits file(s) still contain conflict markers — resolve before commit (PAUSE 2)"; fi
  if [ "$mode_hits" -gt 0 ]; then die "$mode_hits file(s) contain template-only MODE markers — re-apply from a pruned tree"; fi
  if [ "$host_hits" -gt 0 ]; then die "$host_hits file(s) contain template-only HOST markers — re-apply from a pruned tree"; fi
  printf 'no conflict markers found\n' >&2
}

# ---- stamp: finalize the manifest + append the upgrade-log --------------------------------------
cmd_stamp() {
  [ "${#POS[@]}" -ge 1 ] || die "stamp needs: TO"
  [ -n "$WORK" ] || die "stamp needs --work"
  local to="${POS[0]}" project manifest; project=$(pc '.projectDir'); manifest=$(pc '.manifestPath')
  local now; now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp="$WORK/.manifest.new"
  jq --arg to "$to" --arg now "$now" \
     '.lastUpgradedFromSha=$to | .lastUpgradedAt=$now' "$manifest" > "$tmp"
  jq -e . "$tmp" >/dev/null 2>&1 || die "stamped manifest failed to validate"
  mv "$tmp" "$manifest"
  # append upgrade-log record (use --record JSON if provided, else a minimal one)
  local log="$project/.scaffolding/upgrade-log.jsonl" rec
  mkdir -p "$(dirname "$log")"
  if [ -n "$RECORD" ] && [ -f "$RECORD" ]; then rec=$(jq -c '.' "$RECORD"); else
    rec=$(jq -nc --arg to "$to" --arg now "$now" '{to:$to, at:$now}'); fi
  printf '%s\n' "$rec" >> "$log"
  printf 'manifest stamped: lastUpgradedFromSha=%s\n' "$to" >&2
}

# ---- dispatch -----------------------------------------------------------------------------------
[ $# -ge 1 ] || die "usage: $SELF <resolve|substitute|diff|migrations|apply|stamp|check-markers> [opts]"
SUB="$1"; shift
parse_args "$@"
case "$SUB" in
  resolve)       cmd_resolve ;;
  substitute)    cmd_substitute ;;
  diff)          cmd_diff ;;
  migrations)    cmd_migrations ;;
  apply)         cmd_apply ;;
  stamp)         cmd_stamp ;;
  check-markers) cmd_check_markers ;;
  *) die "unknown subcommand: $SUB" ;;
esac
