# M-0008 — Add the Wiring/entry-point section (+ REQ note, seam-snapshot rule) to the brief template's format block

> `docs/tdd-brief-template.md`'s canonical **format block** gained three things the worked example
> already showed but the format never required: the `## Wiring / entry point (Step 7.5)` section
> (now a `spec-lint brief` failure when missing), the REQ-IDs-derive-from-§s comment, and the
> §2.5-seam schema-snapshot rule in "Cross-doc invariant impact".

## Registry entry (in `registry.json` `migrations[]`)

```json
{
  "id": "M-0008",
  "title": "Brief template format block: Wiring/entry-point section + REQ derivation note + seam-snapshot rule",
  "introducedAtSha": "<set by the follow-up wiring commit — the W2-2 commit>",
  "kind": "new-required-section",
  "appliesWhen": "base < introducedAtSha <= to",
  "gate": "human",
  "idempotencyKey": "section:tdd-brief-template:wiring-entry-point",
  "touches": ["docs/tdd-brief-template.md"]
}
```

## What changed upstream, and why

`templates/docs/tdd-brief-template.md` (kind `mixed`) — the changes sit in the **machinery** part of the
file (the format block), so a project that never touched the file absorbs them via the plain 3-way merge.
This migration exists for projects that **customized** the format block: the merge may conflict or the
section may need re-anchoring inside their custom format.

## Handler steps

1. **Idempotency pre-check:** if the project's `docs/tdd-brief-template.md` format block already contains
   `## Wiring / entry point`, journal `.done` and stop.
2. Insert the three pieces from the new template at their anchors (after Acceptance criteria; inside the
   traceability block; at the end of Cross-doc invariant impact), copied verbatim — show the diff, apply
   on approval. Never reflow the project's own prose.
3. Journal `.scaffolding/.migrations/M-0008.done`.

## Idempotency & journal

The `## Wiring / entry point` heading is the idempotency probe; `.done` short-circuits.

## Risk & gating

**LOW** (template prose, no state), but human-gated per the new-required-section rule — the model shows
where it lands.
