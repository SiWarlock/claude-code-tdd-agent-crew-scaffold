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

Bias to the simplest that delivers the needed interactivity. Most projects are well served by **static**; a
"follow the request" simulator with linked highlighting is the usual reason to reach for **React-via-CDN**.

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
  "glossary": [ { "term": "", "plain": "" } ]
}
```

Keep `plain`/`deep` faithful to the source docs (preserve meaning and `path:line` anchors). The pages render
from this file, so updating the docs → regenerating `content.json` → site stays in sync.

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
- Faithfulness: spot-check site text against the layer docs; fix any drift in `content.json`, not by editing
  rendered output.
- Tell the user exactly how to open it (double-click `index.html`, or the `http.server` command).
