# learn-site — playbook

The depth behind `SKILL.md`: site structure, the plain/deep content model, the interactivity catalog, the
stack decision matrix, the content schema, the zero-build React-via-CDN pattern, and serving/verifying. The
north star: someone who has never seen the project can learn how it works — fast in Plain English, deeply when
they want it.

---

## Site information architecture

Derive the structure from the layers; scale it to the project.

- **Home / Overview** — what the project is (one plain paragraph), the **layer map** (interactive), and the
  **"how it fits together"** walkthrough. The landing experience should let someone grasp the whole in two
  minutes, then drill in.
- **One page (or section) per layer** — title, a Plain/Deep toggle, the layer's role, components, flow,
  connections. Mirrors a `docs/layers/NN-*.md`.
- **"How it all works together"** — a single end-to-end walkthrough (follow a request/job/command across the
  layers), ideally steppable.
- **Glossary** — the project's terms, each with a plain definition.
- Small project → collapse to one page with anchored sections. Platform → multi-page with a persistent nav.

---

## The plain / deep content model (the core idea)

Every topic carries two registers, toggleable in the UI:
- **Plain English** — sourced from the layer doc's **executive summary**. No jargon; analogies welcome; "what
  and why," not "how." A non-engineer (or a tired engineer) should follow it.
- **Deeper Dive** — sourced from the doc's **depth sections**. Real mechanics, `path:line` references,
  data shapes, trade-offs, gotchas.

A global "Explain like I'm…" toggle (Plain ⇄ Deep) plus per-topic overrides works well. Default to Plain on
first load; remember the choice (localStorage).

---

## Interactivity catalog (pick what teaches THIS system)

- **Clickable layer map** — an SVG/CSS diagram of the layers; click a layer → load its explanation; arrows
  show dependency/flow direction. The single highest-value interaction.
- **Interactive, trace-able diagrams** — pan/zoom node-graphs with a "trace a flow" highlighter, clickable
  nodes (→ detail + a jump to the layer doc), a minimap, and a legend. The skill **always** builds two
  (**Architecture / runtime data flow** + **Infrastructure**) and proposes more. This is the feature that
  escalates the site to the **full React app** tier (it uses `@xyflow/react`). Full recipe in the
  **"Interactive diagrams"** section below — read it before building any.
- **Request / data-flow walkthrough** — a stepper that moves a "unit of work" (an HTTP request, a CLI
  command, a job) through the layers one hop at a time, narrating each, highlighting the active layer on the
  map. Turns the overview's spine into something you *watch*.
- **Expandable depth** — progressive disclosure: summary visible, details on demand (so the page isn't a wall).
- **Search** — client-side filter over the content model (titles, plain text, terms).
- **Glossary tooltips** — hover/tap a term anywhere → its plain definition.
- **Dark mode**, **copyable code refs**, **"jump to file" links** (to the repo path).
- **Optional checks** — a couple of "can you trace where X happens?" self-quizzes, only if it suits the
  audience.

Skip anything that doesn't aid understanding. Motion should clarify (highlight the active layer), never decorate.

---

## Stack decision matrix

| Need | Stack | Why |
|------|-------|-----|
| Tabs/toggles, clickable static map, search, dark mode | **Static HTML/JS/CSS** (default) | Zero build, opens by double-click, portable forever. Vanilla JS handles all of this. |
| Linked live views, a stateful request simulator, many interacting widgets | **React via CDN** (zero-build) | Component state without a toolchain — one `index.html`, no `npm`. |
| Large, many routes/components, you'll keep extending it, want a real build | **Full React app (Vite)** | Worth a build step only at real size/statefulness. |
| **Interactive, trace-able architecture/infra diagrams** (pan/zoom, trace-a-flow, minimap) | **Full React app (Vite)** | Uses `@xyflow/react` (React Flow v12) — needs a bundler. **Interactive diagrams are the usual reason to go past static.** |

Bias to the simplest that delivers the needed interactivity. Most projects are well served by **static**; a
"follow the request" simulator with linked highlighting is the usual reason to reach for **React-via-CDN**.
**Interactive diagrams (always built — see below) are the usual reason to go all the way to the full React
app:** they pull in `@xyflow/react`, which needs a build. Add `@xyflow/react` (plus `react`, `react-dom`,
`vite`, `@vitejs/plugin-react`, `typescript`) to `package.json` when you take this tier.

---

## Content schema — `docs/learn-site/content.json`

```json
{
  "project": { "name": "", "tagline": "", "summary_plain": "", "stack": [] },
  "layers": [
    {
      "id": "api",
      "name": "API Layer",
      "order": 1,
      "plain": "<from the layer doc's executive summary>",
      "deep":  "<from the depth sections; may include short markdown>",
      "components": [ { "name": "", "what": "", "ref": "path/to/file:line" } ],
      "depends_on": ["domain"],
      "used_by": ["ui"],
      "connects": "<how it hands off to neighbors>"
    }
  ],
  "flow": [
    { "step": 1, "layer": "ui", "plain": "", "deep": "" }
  ],
  "glossary": [ { "term": "", "plain": "" } ],

  "architecture":   { "id": "architecture",   "name": "Architecture",   "nodes": [], "edges": [], "flows": [] },
  "infrastructure": { "id": "infrastructure", "name": "Infrastructure", "nodes": [], "edges": [], "flows": [] },
  "diagrams": [ /* opted-in extras — each a full Diagram with its own id + name */ ]
}
```

Keep `plain`/`deep` faithful to the source docs (preserve meaning and `path:line` anchors). The pages render
from this file, so updating the docs → regenerating `content.json` → site stays in sync. The three diagram
keys (`architecture`, `infrastructure`, `diagrams[]`) are present **only when the site is the full React-app
tier**; their schema + sourcing rules are in the **"Interactive diagrams"** section below.

---

## Zero-build React-via-CDN pattern (when chosen)

A single `index.html` with no toolchain:

```html
<!doctype html><html><head><meta charset="utf-8">
  <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <link rel="stylesheet" href="assets/styles.css">
</head><body><div id="root"></div>
  <script type="text/babel">
    function App() {
      const [content, setContent] = React.useState(null);
      const [deep, setDeep] = React.useState(false);
      React.useEffect(() => { fetch('content.json').then(r => r.json()).then(setContent); }, []);
      if (!content) return <p>Loading…</p>;
      // …render the layer map, the active layer's plain/deep view, the flow stepper…
    }
    ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
  </script>
</body></html>
```

Note: CDN React needs to be **served** (a `fetch` of `content.json` won't run from `file://` in some
browsers) — use `python3 -m http.server`. The pure-static build can avoid `fetch` (inline the data) so it
opens straight from `file://`; prefer that when "double-click to open" matters.

---

## Interactive diagrams (always built at the React-app tier)

When the site is the **full React-app** tier, it **always** ships two comprehensive, full-scope,
interactive diagrams, and proposes more (§propose-diagrams). Every diagram is the same component: a
pan/zoom node-graph with **clickable nodes that open an info panel**, **animated flowing data-flow
edges**, **trace-a-flow** highlighting, a **minimap**, and a **legend**. Start from the pattern in
`templates/` and **adapt it to mesh with the site you're generating** — its theme tokens, router,
content model, and naming. The **mechanics** (the gotchas below) are what you must preserve; the
diagram's nodes/edges/flows are entirely **this** project's data. Don't re-derive the React Flow
wiring from scratch — each gotcha below is a real bug the pattern already solves.

Library: **`@xyflow/react`** (React Flow v12). Including diagrams is the usual reason the site escalates
past static (see the stack matrix). Add `@xyflow/react` to `package.json`.

### The two always-on diagrams (full-scope, not simplified)

1. **Architecture / runtime data flow** — *every* component and how a **request**, a **write**, and the
   **async work** move through the system: clients → frontend/host → API → services → domain/DB, the
   cross-cutting **authorization/audit**, the **async pipeline** (publish → queue → worker → external), and
   **batch jobs** — all connected with directional data-flow edges. Flows trace real named operations.
2. **Infrastructure** — the **deployed topology**: DNS/CDN/edge → load balancer → compute (pods/functions)
   → data store → messaging/queues → secrets/identity → external services → CI/CD deploy. Flows trace a
   page load, the async pipeline, and a deploy.

Both are **comprehensive** — show the whole system, not a tidy subset. Right-sizing applies to *which extra
diagrams* you build and to tiny projects (a small CLI lib may get just one architecture diagram), not to
amputating the two core ones.

### §propose-diagrams — the additional-diagrams gate

After the two core diagrams are decided, **propose extras and let the user choose** (a blocking-question
gate, same mechanic as the stack gate). Derive candidates from **this project's real components / layers /
flows** AND from **`docs/planning/DIAGRAM_PLAN.md` if it exists** (read it — it often lists the exact
diagrams reviewers want, each with the question it answers). Present **~3–5** candidates, each with a
one-line *"what it shows,"* **recommend the strongest**, and build **only** the ones the user picks.

Candidate types to weigh (pick those that fit the project — never pad):

- **Data model / ERD** — entities + relationships + key constraints (nodes = tables, edges = FKs).
- **A key lifecycle / state machine** — states as nodes, transitions as edges (e.g. `DRAFT → LOCKED → …`).
- **An auth / IDOR / audit flow** — who-can-touch-what + the denial paths; trust boundaries.
- **A subsystem deep-dive** — e.g. an async outbox/retry pipeline, a federation host↔remote contract, a
  read-model / CQRS refresh.
- **A request sequence** — one operation end-to-end across the layers.
- **The deploy / CI-CD pipeline** — build → test gates → image → infra → rollout → smoke.
- …whatever the project's docs / `DIAGRAM_PLAN.md` surface as high-value for **this** system.

(`DIAGRAM_PLAN.md` drives **both** the core arch/infra content **and** this proposal list.)

### Data model (data-driven — store in `content.json`, render from it, never hardcode in JSX)

```ts
Diagram     = { id, name, nodes: DiagramNode[], edges: DiagramEdge[], flows: DiagramFlow[] }
DiagramNode = { id, label, sub?, kind, detail, x, y, layer? }   // x/y = layout coords
DiagramEdge = { id, source, target, label?, kind, flows: string[] } // flows = traces incl. this edge
DiagramFlow = { id, name, desc }                                    // a named path to highlight
```

On `Content`: `architecture: Diagram`, `infrastructure: Diagram`, `diagrams: Diagram[]` (the opted-in
extras). Full TypeScript in `templates/diagram-types.ts`; a complete worked example in
`templates/content.diagram-example.json` (generic placeholder — replace every node/edge/flow).

### `kind` taxonomy + palette (drives colour)

Each `kind` gets a stable accent colour via a per-kind `--k` CSS var, reused for the node left-border, the
legend dot, the detail-panel chip, and the minimap rect. (Defined in `templates/diagram.css` /
`DiagramView`'s `KIND_COLOR`.)

| kind | colour | kind | colour | kind | colour |
|------|--------|------|--------|------|--------|
| `client` | `#64748b` | `service` | `#7c3aed` | `edge` | `#0284c7` |
| `frontend` | `#6366f1` | `data` | `#d97706` | `storage` | `#ca8a04` |
| `api` | `#0891b2` | `async` | `#9333ea` | `compute` | `#2563eb` |
| `authz` | `#e11d48` | `worker` | `#16a34a` | `messaging` | `#9333ea` |
| `job` | `#b45309` | `external` | `#6b7280` | `security` | `#dc2626` |
|  |  |  |  | `cicd` | `#db2777` |

### Faithful sourcing (never invent components)

- **Nodes** = the layer docs' **components** + the overview. Set `layer` on **every** node that maps to a
  documented layer, so a click links to that layer's page (`Open <layer> →`).
- **Edges** = the documented **data flow** / "how it works" sections + **`ARCHITECTURE.md`**. Edge `kind`
  reflects the relationship (`request`, `call`, `write`, `read`, `authz`, `publish`, `async`, `external`,
  `tls`, `deploy`, …); `async`/`publish` edges animate even with no flow selected.
- **Flows** = **real named operations** (e.g. "lock a plan", "manager read", "calendar sync", "a deploy").
- Lay nodes out **top-down** (`x`/`y`): clients at small `y`, data/infra at large `y`; spread `x` so the
  async branch and the authz/audit sidecar read clearly.

### Integrity check (run before building — a dangling ref silently breaks a trace)

Assert that **every** edge `source`/`target` resolves to a node `id`, and **every** entry in each edge's
`flows[]` resolves to a `flow id`. Fail loudly. Run the shipped checker:

```bash
node templates/check-diagrams.mjs docs/learn-site/content.json
```

### The `DiagramView` recipe — MUST-DO / common failure modes

`templates/DiagramView.tsx` is the renderer pattern — adapt it to the generated site (imports, theme
tokens, labels, naming) and feed it the project's data. These points are **load-bearing** — keep them
exactly however you adapt the rest; each is a bug that actually bit the prototype:

- **MiniMap goes EMPTY unless you use `useNodesState`/`useEdgesState` AND pass
  `onNodesChange`/`onEdgesChange` to `<ReactFlow>`.** A plain controlled `nodes` prop with no change
  handler stops React Flow from propagating **measured node sizes**, so the minimap can't draw them. (Bonus:
  the change handlers make nodes draggable.)
- **Custom node = a `<div>` with exactly ONE target `<Handle position={Top}>` + ONE source
  `<Handle position={Bottom}>`** (unambiguous routing). Style by kind via a `dgn-<kind>` class that sets
  `--k`; show a bold label + a small mono `sub`; clickable. Hide the handles with CSS (keep them in the DOM).
- **Edges**: `type: 'smoothstep'`; `animated` when (a) part of the actively-traced flow, or (b) intrinsically
  async (`kind` `async`/`publish`). Per-edge `style = { stroke, strokeWidth, opacity }` — traced → indigo,
  thicker, opacity 1; non-traced while a flow is selected → opacity ~0.12.
  `markerEnd: { type: MarkerType.ArrowClosed, color }` matching the stroke.
- **Trace-a-flow** = a row of pills (one per flow + a "Show all"). Selecting a flow computes its edge-id set
  + the node-ids those edges touch; **animate + accent** those edges, **dim** everything else, and show the
  flow's `desc`. Re-tint via a **`useEffect` on the selected flow** that updates node `data` (dim/active) and
  rebuilds edges — so **measured sizes + drag positions survive** the re-tint.
- **Node click → a detail panel** (kind chip + label + `sub` + `detail` text + an `Open <layer> →` button
  when `layer` is set, navigating to that layer's page). **Pane click closes it.**
- **MiniMap `nodeColor` = the node's kind colour (THEME-INDEPENDENT).** Theme its *background* via CSS
  (`--xy-minimap-background-color-default: var(--bg-elev)`), **not** a JS `style` prop.
- **THEME GOTCHA: do NOT read `document.documentElement.dataset.theme` during render to theme React Flow.**
  On first paint the attribute isn't set yet → a white→dark flash + miscolour. Theme the React-Flow chrome
  with **CSS** (`[data-theme]` selectors / the `--xy-*` vars); any JS-set colour must be theme-independent
  (the kind colours, a neutral mask `rgba(127,127,127,0.16)`, a neutral dot/background colour).
- **Canvas needs an EXPLICIT height** (e.g. `74vh`, `min-height ~460px`) — React Flow renders nothing in a
  0-height box. `fitView` on mount. Add `<Background>`, `<Controls showInteractive={false} />`, `<MiniMap>`.
  Hide the attribution (`proOptions={{ hideAttribution: true }}` + `.react-flow__attribution { display:none }`).

### Wiring

- **Routes (hash):** `/architecture`, `/infrastructure`, and `/diagram/<id>` for each opted-in extra. Branch
  in `App` on these; look the extra up by id in `content.diagrams`.
- **Sidebar: a single "Diagrams" row with a dropdown** that lists every built diagram (Architecture,
  Infrastructure, then each extra) and navigates to its route — e.g.:

  ```tsx
  const allDiagrams = [content.architecture, content.infrastructure, ...content.diagrams];
  // a collapsible nav group:
  <div className="nav-group">
    <button className="nav-item" onClick={() => setOpen((o) => !o)}>
      Diagrams <span className="pill">{allDiagrams.length}</span>
    </button>
    {open && allDiagrams.map((d) => (
      <button key={d.id} className={cls(isActive(d))}
        onClick={() => go(d.id === 'architecture' || d.id === 'infrastructure'
          ? `/${d.id}` : `/diagram/${d.id}`)}>
        {d.name}
      </button>
    ))}
  </div>
  ```

- **Overview CTAs** for the two core diagrams ("🗺 Architecture map — trace the data flow", "☁
  Infrastructure map — the topology"). Keep everything else on the site unchanged.
- **Thin per-diagram wrapper** (~12 lines) — pass the diagram + an eyebrow/title/tagline to `DiagramView`:

  ```tsx
  export function ArchitectureDiagram() {
    return <DiagramView diagram={content.architecture}
      eyebrow="Architecture" title="How it's wired — runtime data flow"
      tagline="Every component and how a request, a write, and the async work move through the system.
               Pick a flow to trace it; click any box for detail and a jump to its layer." />;
  }
  ```
  For opted-in extras, a generic route component can render `DiagramView` with the diagram's own `name` as
  the title.

### Verify (the diagrams specifically)

After serving, confirm on **each** diagram: it **renders** (boxes + edges visible), the **minimap is
populated** (not empty), **trace-a-flow animates** a path and dims the rest, a **node click opens its
detail panel** and the **`Open <layer> →` link navigates** to that layer's page, the legend + pan/zoom +
minimap work, and there are no console errors. (Also run the integrity checker above.)

**Pattern files (self-contained, in this skill):** `templates/DiagramView.tsx` (the renderer pattern +
the gotchas), `templates/diagram-types.ts` (the schema), `templates/diagram.css` (the `.dg-*` / `--k`
rules + CSS-only theming), `templates/content.diagram-example.json` (the data shape), and
`templates/check-diagrams.mjs` (the integrity check). They are a starting point — **adapt them to mesh
with the site you're generating**, and fill them with **this project's** nodes/edges/flows.

---

## Accessibility & readability

- Semantic HTML, keyboard-navigable controls, visible focus, sufficient contrast (check both themes).
- Readable measure (~60–80 chars), generous line-height, a clear type scale.
- Respects `prefers-color-scheme`; remembers the Plain/Deep choice.
- Works without JavaScript at least to the extent of showing the plain content (progressive enhancement) when
  feasible.

---

## Serving & verifying

- Serve: `python3 -m http.server -d docs/learn-site 8000` → open `http://localhost:8000`.
- Verify: pages load; nav/links resolve; **Plain/Deep toggle** flips content on every topic; clickable map
  loads the right layer; the flow stepper advances and highlights; search filters; dark mode toggles; no
  console errors.
- **If diagrams were built:** on each diagram — it renders, the **minimap is populated**, **trace-a-flow
  animates** a path (and dims the rest), a **node click opens its detail panel** + the **layer link
  navigates**; the Diagrams dropdown reaches every diagram. Run `node templates/check-diagrams.mjs
  docs/learn-site/content.json` first. (Full list in the "Interactive diagrams" section.)
- Faithfulness: spot-check site text against the layer docs; fix any drift in `content.json`, not by editing
  rendered output.
- Tell the user exactly how to open it (double-click `index.html`, or the `http.server` command).
