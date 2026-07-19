# IMPLEMENTATION_PLAN.md — plan-lint DEGRADED fixture

Old-format / pre-compaction plan. Deliberately violates the post-2026-07-19
contract on several axes so tests/run-plan-lint.sh can pin the lint's failure
detection (this is the NEGATIVE control — every block below is a known defect).

## Currently in progress

- Phase 1 in flight.

## Carry-forward

- ✅ Dedup rule RESOLVED in place — should have been deleted with an archive pointer.

## Phase 1 — ingestion spine

### 1.1 Intake endpoint

- [x] DONE — intake landed (no hash, no date, no Spec anchor).

### 1.2 Event-hash dedup ✅

- [x] done abc1234 2026-06-05 — dedup landed.
- [ ] OPEN — follow-up: backfill dedup over legacy rows.
**Spec:** ARCHITECTURE.md §3.1

### 1.3 Typed store

- [ ] OWNER-GATED §ARM-missing — typed store behind an undefined ledger.
**Spec:** ARCHITECTURE.md §3.1

## Log

- **2026-06-02** — P0.1+P0.2 landed (commit abc1234); suite 14 green.
- **2026-06-05** — P1.1 started; read API next.
