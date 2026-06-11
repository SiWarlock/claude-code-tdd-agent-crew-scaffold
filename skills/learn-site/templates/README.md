# learn-site templates — interactive diagrams

Reusable **pattern** for the **Interactive diagrams** capability (full React-app tier only). The full
recipe + all the load-bearing gotchas live in `../references/learn-site-playbook.md` → "Interactive
diagrams". Read it first.

These files are a **starting point to adapt**, not a drop-in artifact to freeze. The point is to
reproduce the *functionality* — **clickable nodes → an info panel, animated flowing edges,
trace-a-flow highlighting, a populated minimap, a legend, pan/zoom** — in a component that **meshes
with the site you're generating** (its theme tokens, router, content model, and naming). The diagram
itself and every node/edge/flow in it are **entirely the specific project's data**, derived from its
`docs/layers/` + `ARCHITECTURE.md` (+ `DIAGRAM_PLAN.md`) — never carried over from another project.

| File | Use |
|------|-----|
| `DiagramView.tsx` | The renderer pattern → `src/components/DiagramView.tsx`. **Preserve the mechanics** (the gotchas in its header); **adapt** imports, theme tokens, labels, and naming to your site. |
| `diagram-types.ts` | Merge into `src/types.ts` — `Diagram` / `DiagramNode` / `DiagramEdge` / `DiagramFlow` + the `kind` union, and the `Content` keys to add. |
| `diagram.css` | Append to `src/styles.css` — the `.dg-*` / `.dgn-*` / `.dgk-*` / `--k` rules + the CSS-only React-Flow theming. Wire its `var(--…)` tokens to the site's own theme variables. |
| `content.diagram-example.json` | The `architecture` / `infrastructure` / `diagrams[]` shape in practice. A generic placeholder — **replace every node/edge/flow** with this project's real ones. |
| `check-diagrams.mjs` | Integrity check. Run before building: `node templates/check-diagrams.mjs docs/learn-site/content.json`. Fails on any dangling edge endpoint or flow ref. |

Dependency: `@xyflow/react` (React Flow v12). The thin per-diagram wrapper is ~12 lines — see the
playbook.
