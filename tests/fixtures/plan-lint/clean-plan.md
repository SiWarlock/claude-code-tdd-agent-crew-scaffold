# IMPLEMENTATION_PLAN.md — plan-lint CLEAN fixture

Post-2026-07-19 plan-doc standard. Living sections are bounded; history is
archived (never inlined); every task carries one state line + a Spec anchor.
This fixture is the positive control for tests/run-plan-lint.sh — it must lint
clean (0 violations, 0 warnings) or the lint has regressed.

## Currently in progress

- Phase 1 landing: 1.3 (typed store) is the next slice.
- Blocking: none.

## Carry-forward

- Dedup-hash rule (LESSONS §1) cited in every ingestion-touching brief. (origin: 2026-06-02 1.2)

## Phase 1 — ingestion spine

**Spec anchors:** ARCHITECTURE.md §2, §3.1
**Goal:** upstream events land deduplicated in a typed store.

### 1.1 Intake endpoint skeleton

- [x] DONE `abc1234` 2026-06-05 — intake endpoint skeleton landed.
**Spec:** ARCHITECTURE.md §3.1
**Files:** app/main.py (NEW)

### 1.2 Event-hash dedup

- [~] PARTIAL — dedup landed; remaining: backfill dedup over pre-existing rows.
**Spec:** ARCHITECTURE.md §3.1
**Files:** app/ingest.py (NEW)

### 1.3 Typed store

- [ ] OPEN — typed asyncpg store + strict Pydantic models.
**Spec:** ARCHITECTURE.md §3.1
**Files:** app/store.py (NEW), app/models.py (NEW)

## Phase 2 — read API

**Spec anchors:** ARCHITECTURE.md §3.2
**Goal:** consumers can query stored events; one path may leave the box.

### 2.1 List endpoint

- [ ] OPEN — filtered list endpoint with typed responses.
**Spec:** ARCHITECTURE.md §3.2
**Files:** app/read.py (NEW)

### 2.2 Cloud egress connector

- [ ] OWNER-GATED §ARM-egress — real outbound connector; built dormant until armed.
**Spec:** ARCHITECTURE.md §5

## Owner gates & arming ledgers

### §ARM-egress — first real external egress

Arming this ledger authorizes the first real outbound write from 2.2. Owner-gated;
stays closed until the owner confirms per crossing.

## Log

History is archived — see docs/archive/IMPLEMENTATION_LOG.md for the full round log.
