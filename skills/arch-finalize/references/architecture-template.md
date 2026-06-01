<!--
  TEMPLATE: {{ARCH_DOC}} → write to repo root.
  This is the project's DESIGN CONTRACT. At bootstrap it is a SKELETON — section
  headings with 1-2 sentence stubs. Do NOT write the architecture; it accretes as
  decisions land. Fill the section list from the user's Batch-E answer. Keep
  Appendix A — it is the canonical home for the cross-doc invariant model
  inventory that the area CLAUDE.md table points at. Delete this comment.

  HOW THIS DOC IS USED (carry this discipline into the project):
   - Loaded ON DEMAND, never whole. Sessions reach it via the area CLAUDE.md
     lookup table + `/check-arch <topic>`, which read only the cited section.
   - It is a CONTRACT. Typed models that mirror a section are listed in the area
     CLAUDE.md cross-doc invariants table; a field change requires an edit to the
     matching section in the same round of commits.
   - Orchestrator territory. The implementer never edits it directly — they flag
     a cross-doc change at /tdd Step 9; the orchestrator writes it hot.
   - Phases in {{TASK_TRACKER}} cite their `{{ARCH_DOC}}` sections as "spec anchors."
-->

# {{ARCH_DOC}} — {{PROJECT_NAME}}

## Executive summary

<~300-500 words: what the system is, the core design posture, the major
subsystems and how they relate.>

> {{ARCHITECTURE_SENTENCE}}
>
> _(If the project has a load-bearing one-line posture, restate it here. Otherwise delete.)_

## §1 — Goals & non-goals

**Goals:** <what the system must do.>

**Non-goals:** <what it explicitly does not try to do.>

## §2 — System overview

<High-level diagram + the end-to-end flow. One screen.>

## §3 — <Subsystem / boundary A>

<Stub. Expands as decisions land.>

## §4 — <Subsystem / boundary B>

<Stub.>

<!-- One section per major subsystem boundary. Add as the architecture is decided.
     The section list comes from the user's Batch-E answer. -->

## §<N> — Cross-cutting concerns

<Observability, security, error handling, configuration — whatever cuts across
subsystems.>

## §<N+1> — Open questions

<Architectural decisions not yet made. Resolved entries move into their section;
new ones get added as they surface.>

---

## Appendix A — Model / contract inventory

The canonical home for every typed model that is a **cross-doc invariant** — mirrored in the area `CLAUDE.md` cross-doc invariants table. A field change on any model here requires an edit to this appendix (and the model's `§` section) in the same round of commits.

| Model | Section | Fields (summary) |
|---|---|---|
| <model> | §X | <field list> |

<!-- Starts empty (or with the first contract model). Grows as contract models land. -->
