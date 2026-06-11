#!/usr/bin/env bash
# build-playbook.sh — deterministic concat of the arch-draft playbook sources:
#   references/playbook-spine.md + references/stages/stage-{1..6}-*.md (lexical order)
# into the GENERATED artifact references/architecture-planning-playbook.md (original filename kept so
# session-kickoff-prompt.md's attach path stays valid).
#
#   build-playbook.sh            # rebuild the artifact in place
#   build-playbook.sh --stdout   # emit to stdout (release-check.sh playbook diffs against the artifact)
#
# Edit the SOURCES, never the artifact — release-check fails when the committed concat is stale.

set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"   # skill root (skills/arch-draft)

SPINE="references/playbook-spine.md"
ARTIFACT="references/architecture-planning-playbook.md"
[ -f "$SPINE" ] || { echo "build-playbook: missing $SPINE" >&2; exit 1; }

emit() {
  cat <<'BANNER'
<!--
  GENERATED FILE — DO NOT EDIT. Rebuilt by skills/arch-draft/scripts/build-playbook.sh from:
    references/playbook-spine.md + references/stages/stage-{1..6}-*.md
  Edit those sources, then re-run the build script (release-check.sh playbook fails on a stale concat).
  This concatenated artifact keeps the original filename so session-kickoff-prompt.md's attach path
  stays valid: attach THIS file to the Brain-1 session; inside the skill, read the spine end-to-end
  and each stage just-in-time.
-->

BANNER
  cat "$SPINE"
  local f
  for f in references/stages/stage-*.md; do
    printf '\n'
    cat "$f"
  done
}

if [ "${1:-}" = "--stdout" ]; then
  emit
else
  emit > "$ARTIFACT"
  printf 'rebuilt %s (%s lines)\n' "$ARTIFACT" "$(wc -l < "$ARTIFACT" | tr -d ' ')" >&2
fi
