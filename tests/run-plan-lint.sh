#!/usr/bin/env bash
# run-plan-lint.sh — unit test for the plan-format lint (templates/scripts/plan-lint.sh),
# the gate /orchestrate-end Step-6.5 runs against IMPLEMENTATION_PLAN.md.
#
# Fixtures:
#   • tests/fixtures/plan-lint/clean-plan.md            positive control — new-standard plan, must lint 0/0
#   • tests/fixtures/plan-lint/degraded-plan.md         negative control — a spread of known-defect blocks
#   • tests/fixtures/upgrade-dryrun/project/MVP_TASKS.md the frozen pre-migration tracker (old format)
#
# Rendering note (why we don't run templates/scripts/plan-lint.sh directly):
#   The TEMPLATE default is  PLAN="${1:-{{TASK_TRACKER}}}"  — the {{TASK_TRACKER}} token is still
#   present. Run un-rendered, bash brace-matching ends the ${1:-…} expansion at the FIRST '}', so an
#   explicit file arg comes back with a stray "}}" appended (arg -> "arg}}") and the lint reports the
#   wrong path. scaffold-generate SUBSTITUTES the token first, producing  ${1:-IMPLEMENTATION_PLAN.md}
#   — the clean form /orchestrate-end actually invokes. So we render the template the same way
#   (substitute the token) into a temp copy and run THAT with an explicit arg. We never modify the
#   template on disk.
#
# Wired for direct invocation:  tests/run-plan-lint.sh
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
FIX="$REPO/tests/fixtures/plan-lint"

FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; FAIL=1; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/plan-lint.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# Render the template as scaffold-generate would (token -> generated default), then invoke with an
# explicit arg — mirroring the generated scripts/plan-lint.sh that /orchestrate-end Step-6.5 runs.
LINT="$TMP/plan-lint.rendered.sh"
sed 's/{{TASK_TRACKER}}/IMPLEMENTATION_PLAN.md/g' "$REPO/templates/scripts/plan-lint.sh" > "$LINT"
grep -q '{{' "$LINT" \
  && bad "render: {{…}} token still present in rendered lint (substitution failed)" \
  || ok  "render: token substituted — rendered default is clean, explicit-arg invocation is unambiguous"

# run_lint FILE -> sets OUT (combined stdout+stderr) + RC (exit code), without tripping set -e.
run_lint() { OUT=$(bash "$LINT" "$1" 2>&1) && RC=0 || RC=$?; }
# has PATTERN -> true iff the last run's output contains PATTERN (fixed string).
has() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# ==================================================================================================
# CLEAN — a plan written to the post-2026-07-19 standard lints with zero findings.
# ==================================================================================================
clean_case() {
  printf '\n— clean fixture —\n'
  run_lint "$FIX/clean-plan.md"
  [ "$RC" -eq 0 ] && ok "clean: exit 0" || bad "clean: exit $RC (expected 0) — $OUT"
  has 'plan-lint: 0 violation(s), 0 warning(s)' \
    && ok "clean: 0 violations, 0 warnings" || bad "clean: not 0/0 — $OUT"
}

# ==================================================================================================
# DEGRADED (existing fixture) — the frozen old-format tracker must be rejected. The task-mandated
# case: assert EXIT 1 + the missing-IMPLEMENTATION_LOG.md-pointer class. NOTE: this fixture's inline
# Log line is NOT bold-dated, so the lint's inline-history detector (which only matches `- **20YY-…`)
# does not fire here — only the pointer class does. The bold-dated inline-history class is covered by
# the rich degraded fixture below.
# ==================================================================================================
degraded_existing_case() {
  printf '\n— degraded fixture (existing MVP_TASKS.md, old format) —\n'
  run_lint "$REPO/tests/fixtures/upgrade-dryrun/project/MVP_TASKS.md"
  [ "$RC" -eq 1 ] && ok "degraded(existing): exit 1" || bad "degraded(existing): exit $RC (expected 1) — $OUT"
  has 'Log section lacks the docs/archive/IMPLEMENTATION_LOG.md pointer' \
    && ok "degraded(existing): missing IMPLEMENTATION_LOG.md pointer flagged" \
    || bad "degraded(existing): pointer violation not flagged — $OUT"
}

# ==================================================================================================
# DEGRADED (rich) — a compact plan that violates the contract on several axes at once; assert EXIT 1
# and that a spread of distinct violation classes each fire (the lint's real detection surface).
# ==================================================================================================
degraded_rich_case() {
  printf '\n— degraded fixture (rich negative control) —\n'
  run_lint "$FIX/degraded-plan.md"
  [ "$RC" -eq 1 ] && ok "degraded(rich): exit 1" || bad "degraded(rich): exit $RC (expected 1) — $OUT"
  has 'inline history entry in the Log section' \
    && ok "degraded(rich): inline-history-in-Log flagged" || bad "degraded(rich): inline-history not flagged — $OUT"
  has 'Log section lacks the docs/archive/IMPLEMENTATION_LOG.md pointer' \
    && ok "degraded(rich): missing IMPLEMENTATION_LOG.md pointer flagged" || bad "degraded(rich): pointer not flagged — $OUT"
  has 'DONE line missing' \
    && ok "degraded(rich): DONE line without hash/ISO-date flagged" || bad "degraded(rich): DONE-missing not flagged — $OUT"
  has '2 checkbox lines' \
    && ok "degraded(rich): multi-checkbox task flagged" || bad "degraded(rich): multi-checkbox not flagged — $OUT"
  has 'missing **Spec:** anchor' \
    && ok "degraded(rich): task without Spec anchor flagged" || bad "degraded(rich): missing-anchor not flagged — $OUT"
  has 'carries a state token' \
    && ok "degraded(rich): state token in task heading flagged" || bad "degraded(rich): heading-state-token not flagged — $OUT"
  has 'resolved item annotated in place in Carry-forward' \
    && ok "degraded(rich): resolved-in-place Carry-forward item flagged" || bad "degraded(rich): cf-resolved not flagged — $OUT"
  has 'OWNER-GATED pointer §ARM-missing has no ledger definition' \
    && ok "degraded(rich): OWNER-GATED pointer to undefined ledger flagged" || bad "degraded(rich): undefined-gate not flagged — $OUT"
}

clean_case
degraded_existing_case
degraded_rich_case

if [ "$FAIL" -ne 0 ]; then printf '\nrun-plan-lint: \033[31mFAILED\033[0m\n'; exit 1; fi
printf '\nrun-plan-lint: \033[32mOK\033[0m\n'
