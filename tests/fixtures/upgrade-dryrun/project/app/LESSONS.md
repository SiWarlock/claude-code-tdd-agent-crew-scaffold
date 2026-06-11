# LESSONS.md — FixtureTracker (backend)

> Full prose for every lesson logged during work in `app/`. The compact index lives in `app/CLAUDE.md` "Lessons logged" table.
>
> **Lesson numbers are stable IDs.** New lessons get the next sequential number. Numbers may be referenced from code comments, commit messages, and cross-references between lessons. **Don't reorder; don't reuse a deleted number's slot.**
>
> **Lessons start at §1.** Each code area has its own lesson sequence — lessons don't carry across code areas.

---

## Lesson format

```markdown
## <a id="N"></a>N. <Short topic> — <one-line rule>

**Date:** YYYY-MM-DD.
**Source slice:** <slice-id or commit hash>.

<2-5 paragraphs explaining: what was discovered, why it matters, how to
apply the rule, what edge cases are still open. Cite file:line references
where applicable.>

**Rule:** <one-sentence summary, same as the heading subtitle>.
```

---

## <a id="1"></a>1. Event-hash dedup — compute the hash before normalization, not after

**Date:** 2026-06-02.
**Source slice:** P0.2.

The ingestion endpoint deduplicates upstream events by a SHA-256 of the payload. The first
implementation hashed the *normalized* payload, so two byte-different events that normalized
identically collided and the second was silently dropped as a duplicate even when its metadata
differed. Hash the raw bytes (`request.body()`), then normalize.

**Rule:** compute the dedup hash on the raw payload bytes, never on the normalized form.
