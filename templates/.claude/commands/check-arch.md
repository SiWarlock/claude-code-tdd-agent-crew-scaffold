<!-- ▼ HOST [claude] ▼ -->
---
description: Look up a topic in the architecture lookup table and read only that section. Usage: /check-arch <topic>
allowed-tools: Read, Grep
argument-hint: "<topic>"
---
<!-- ▲ END HOST ▲ -->
<!-- ▼ HOST [codex] ▼ -->
---
name: check-arch
description: Look up a topic in the architecture lookup table and read only that section. Usage: /check-arch <topic>
argument-hint: "<topic>"
---
<!-- ▲ END HOST ▲ -->

Look up a topic in the area `{{AREA_MEMORY}}` lookup table and read **only that section** of the cited file (`Read` with `offset`/`limit`). Context-efficiency primitive.

Argument: `$ARGUMENTS` — the topic to look up.

## Procedure

1. Read the lookup table in `{{CODE_AREA}}{{AREA_MEMORY}}` (top section, near "Lookup table — where to find canonical info").

2. Find the row matching `$ARGUMENTS`. Match flexibly — partial keyword match, case-insensitive.

3. If a match is found:
   - Read only the cited section of the cited file (use `Read` with `offset` + `limit` to read just that section).
   - Report the section content + its file:section reference.

4. If no match is found:
   - Fall back to `grep` across `{{ARCH_DOC}}` for the topic keyword.
   - Report the best matches with file:line references.
   - **Recommend adding a row to the lookup table** if the topic will recur.

## Output format

```
Topic: <argument>
Source: <file>:§<section>

<section content — abbreviated to ~50 lines max; cite further reads if needed>
```

If fallback grep was used:

```
Topic: <argument> (no lookup-table match)
Grep matches:
- <file>:<line> — <snippet>

Recommendation: add a row to the {{CODE_AREA}}{{AREA_MEMORY}} lookup table:
| <topic> | <file> | §<section> |
```

## Forbidden in this command

- **Loading the entire `{{ARCH_DOC}}`.** The whole point is targeted reads.
- **Inferring sections beyond what the lookup table or grep surfaces.** If a topic isn't documented, say so; don't fabricate.
