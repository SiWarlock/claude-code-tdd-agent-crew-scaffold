---
name: learn-site
description: >-
  Build an interactive educational WEBSITE that teaches how a project works — sourced from docs/layers/ (the
  /layer-docs output) plus the real code. The site explains the whole system and each layer and how they fit
  together, and every topic offers a PLAIN-ENGLISH view and a DEEPER-DIVE view you can toggle. Interactivity
  and depth scale to the project (a CLI library and a web platform get different sites). Defaults to plain,
  ZERO-BUILD static HTML/JS/CSS (double-click index.html to open); escalates to a zero-build React-via-CDN
  page, or a full React app, only when richer interactivity genuinely aids learning — with your sign-off.
  At the full-React-app tier it also builds interactive, trace-able diagrams (React Flow): always a
  full-scope Architecture/runtime-data-flow diagram and an Infrastructure diagram, plus any extras you opt
  into. Content is generated data-first (a content model derived from the layer docs) so it stays faithful and
  maintainable. Writes to docs/learn-site/ and serves it locally to verify. Runs on Claude Code, from inside
  the target project, AFTER /layer-docs. Invoke when the user says "learn-site", "build the learning site",
  "make the educational website", "turn the layer docs into a site", or wants an interactive explainer of the
  project.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# learn-site — an interactive learning site built from the layer docs

A **standalone, on-demand** skill that turns a project's `docs/layers/` set (from **`/layer-docs`**) into an
**interactive educational website** — a genuine learning tool for understanding *what was built and how it
works*, for you and for anyone else. It explains the system as a whole, each **layer** on its own, and **how
it all fits together**, and gives every topic a **Plain-English** view and a **Deeper-Dive** view. It runs on
**Claude Code**, from **inside the target project**, and writes to **`docs/learn-site/`**.

**Right-sized, not flashy.** Interactivity and depth are chosen to fit the project — a clickable layer map and
a "follow a request through the system" walkthrough teach more than animation for its own sake. It defaults to
**plain, zero-build static HTML/JS/CSS** so the result opens with a double-click and survives forever;
it escalates to a **zero-build React-via-CDN** page, or a **full React app**, only when the interactivity
earns it — and only with your sign-off.

**Faithful and maintainable.** Content is **derived from the layer docs** (and the code), not re-invented; the
site is **data-driven** (a `content.json` model the pages render) so it stays consistent with the docs and is
easy to regenerate.

Depth — site structure, the plain/deep content model, the interactivity catalog, the stack decision matrix,
the zero-build React-via-CDN pattern, the content schema, and the **Interactive diagrams** recipe (the
trace-able Architecture/Infrastructure node-graphs, with all the load-bearing gotchas) — is in
**`references/learn-site-playbook.md`**; an adaptable pattern + helpers live in **`templates/`**. Read the playbook first.

---

## 0. Asking the user questions (host-neutral — read first)

This skill has two gates — a scope/stack gate (§3) and a propose-diagrams gate (§3b). Ask via:
1. A blocking question tool — `AskUserQuestion` (Claude Code), `request_user_input` / `ask_user` (Codex / other).
2. Else **plain text** — print the question + options, then **stop and wait**.

Discipline: one topic per check-in · recommend an option + **why** · **never invent** an explanation the
docs/code don't support — pull it from `docs/layers/` or mark it and ask.

---

## 1. Require and read the source docs

> *Goal: stand on the layer docs; don't re-derive the architecture.*

1. **Check `docs/layers/`** exists with `OVERVIEW.md` + per-layer docs. If it's **missing or thin**, stop and
   recommend running **`/layer-docs` first** — this skill builds *from* that set, it doesn't replace it.
2. **Read the whole set** — the overview and every layer doc — plus the architecture/planning docs for extra
   context and any diagrams worth recreating. The layer docs' **executive summaries become the Plain-English
   views**; the depth sections become the **Deeper-Dive views**.
3. **Also read `ARCHITECTURE.md` and `docs/planning/DIAGRAM_PLAN.md` if they exist** — they drive the
   interactive diagrams (§3b/§5): `ARCHITECTURE.md` + the layer docs' "how it works" sections supply the
   nodes/edges; `DIAGRAM_PLAN.md` (when present) often names the exact diagrams reviewers want and drives
   both the core arch/infra content **and** the additional-diagram proposal.

⏸ **Check-in:** confirm the doc set you'll build from (and flag any gaps).

## 2. Plan the site

> *Goal: design a learning experience shaped to this specific project.*

1. **Information architecture** from the layers: a **Home / Overview** (what it is + the layer map + the
   "how it fits together" walkthrough), **one page/section per layer**, a **"How it all works together"**
   flow, and a **Glossary**. (Adapt: a small library may be one page with sections; a platform may need more.)
2. **Pick the interactivity** that teaches *this* system (see the playbook catalog): a **clickable layer map**
   (click a layer → its explanation), a **request/data-flow walkthrough** (step through how work crosses the
   layers), **expandable depth**, **search**, **dark mode**. Choose what aids learning; skip the rest.
3. **Right-size depth** to the project and audience.

## 3. ⏸ Choose the stack + scope (gate)

> *Goal: agree on how heavy to build before building.*

Recommend by the interactivity the content actually needs (matrix in the playbook):
- **Static HTML/JS/CSS (default)** — zero build, opens by double-click, fully portable. Handles tabs/toggles,
  a clickable SVG/CSS map, search, dark mode via vanilla JS.
- **React via CDN (zero-build)** — a single `index.html` pulling React + Babel from a CDN; component state
  for richer interactions (a live request simulator, linked views) with **no toolchain**.
- **Full React app (Vite)** — only when the site is large/stateful enough to warrant components + a build.

> **Interactive diagrams ⇒ full React app.** The interactive, trace-able **Architecture** + **Infrastructure**
> diagrams (§3b/§5) use **`@xyflow/react`** (React Flow v12), which needs a bundler — so **building diagrams is
> the usual reason to choose the full React-app tier**. Note this in the recommendation, and add `@xyflow/react`
> as a dependency. (A tiny CLI lib with no real topology can skip diagrams and stay static; anything platform-
> shaped should take the React-app tier and get the full set.)

State the recommendation + why, list the scope (pages, interactions, **diagrams**), and **pause for sign-off**
before building.

## 3b. ⏸ Propose additional diagrams (gate)

> *Goal: build the right diagrams for THIS system — always the two core ones, plus what the user opts into.*
>
> *(Only when the stack is the full React-app tier; a static/CDN site has no interactive diagrams.)*

1. **Always build two** comprehensive, full-scope diagrams (no opt-out): an **Architecture / runtime
   data-flow** diagram and an **Infrastructure** diagram. (See the playbook for what "full-scope" means.)
2. **Propose ~3–5 additional candidates** and let the user choose, via the blocking-question tool (same
   pattern as the §3 stack gate). Derive candidates from the project's **real components / layers / flows**
   AND from **`docs/planning/DIAGRAM_PLAN.md`** if it exists. Each candidate gets a one-line *"what it
   shows."* **Recommend the strongest**; build **only** the ones the user picks. Candidate types: data
   model / ERD · a lifecycle / state machine · an auth / IDOR / audit flow · a subsystem deep-dive (async
   outbox, federation host↔remote, read-model/CQRS) · a request sequence · the deploy / CI-CD pipeline · …
   whatever the docs / `DIAGRAM_PLAN.md` flag as high-value here. **Never** propose a diagram the docs
   don't support.

State the two core diagrams + your recommended extras + why, and **pause for the user's picks** before building.

## 4. Generate the content model

> *Goal: separate content from presentation so the site stays faithful and editable.*

Write **`docs/learn-site/content.json`** (schema in the playbook): the project meta, the layer map + flow, and
per topic a **`plain`** field (from the layer doc's executive summary) and a **`deep`** field (from the depth
sections), plus code references, glossary terms, and the inter-layer connections. Derive it from the docs —
don't paraphrase loosely; preserve the docs' meaning and their `path:line` anchors.

**Diagrams (React-app tier only):** add the `architecture` + `infrastructure` diagrams (always) and a
`diagrams[]` array for the extras the user picked in §3b. Each is a `Diagram` (`{ id, name, nodes, edges,
flows }` — schema + `kind` taxonomy in the playbook). **Source faithfully:** nodes = the layer docs'
components + the overview (set each node's `layer` to its layer id); edges = the documented data flow /
"how it works" + `ARCHITECTURE.md`; flows = real named operations. **Never invent** a component or edge.
Then run the **integrity check** — every edge `source`/`target` must resolve to a node id and every
`flows[]` entry to a flow id — and fix any failure before building:
`node templates/check-diagrams.mjs docs/learn-site/content.json`.

## 5. Build the site

> *Goal: render the content model into the chosen stack.*

Scaffold under **`docs/learn-site/`**: `index.html`, `assets/styles.css`, `assets/app.js` (and `content.json`).
Implement the planned pages and interactions from the content model. Every topic shows a **Plain / Deep
toggle**. Keep it accessible and readable (the playbook has the patterns and the zero-build React-via-CDN
snippet). Do **not** hardcode content into markup — render it from `content.json` so it stays in sync.

**Diagrams (React-app tier):** start from the pattern files and **adapt them to mesh with the site you're
generating** (imports, theme tokens, labels, naming) — `templates/DiagramView.tsx` →
`src/components/DiagramView.tsx`; merge `templates/diagram-types.ts` into `src/types.ts`; append
`templates/diagram.css` to `src/styles.css`. **Preserve the mechanics, never the project-specifics:** the
goal is to reproduce the *functionality* — clickable nodes → an info panel, animated flowing edges,
trace-a-flow, a populated minimap, legend, pan/zoom — while the nodes/edges/flows are entirely **this**
project's data. Then wire it: a thin wrapper per core diagram; hash routes `/architecture`,
`/infrastructure`, and `/diagram/<id>` for each extra (branch in `App`); a **single "Diagrams" sidebar row
with a dropdown** listing every built diagram (Architecture, Infrastructure, then the extras) → its route;
and Overview CTAs for the two core ones. Render every diagram from `content.json`. The load-bearing recipe +
all the failure modes to keep intact (the `useNodesState`/`onNodesChange` measurement bug → empty minimap,
the theme-read flash, the explicit canvas height, theme-independent minimap colors, one-target/one-source
handles, the trace-a-flow re-tint `useEffect`) are in the playbook's **"Interactive diagrams"** section.

## 6. Serve and verify

> *Goal: prove it actually works before declaring done.*

1. **Serve it:** `python3 -m http.server` (or open `index.html` directly for the pure-static build) and load
   the site. If browser tools are available, smoke-test; otherwise fetch pages and check they render.
2. **Check:** pages load, nav/links resolve, the **Plain/Deep toggle** works on each topic, the clickable map
   + walkthrough behave, search returns hits, no console errors.
3. **Diagrams (if built):** on **each** diagram — it **renders** (boxes + edges), the **minimap is
   populated** (not empty), **trace-a-flow animates** a path and dims the rest, a **node click opens its
   detail panel** and the **`Open <layer> →` link navigates** to that layer's page; the Diagrams dropdown
   reaches every diagram. (Run the integrity checker first.)
4. **Faithfulness pass:** spot-check that what the site says matches the layer docs (and thus the code).

⏸ **Check-in:** show the user how to open/serve it; confirm it meets the learning goal.

---

## Hard rules (forbidden)

- **Content comes from `docs/layers/` (+ code)** — **never invent** explanations; if the docs don't cover
  something, say so or go read the code, don't fabricate.
- **Every topic gets BOTH a Plain-English and a Deeper-Dive view** — that dual register is the point.
- **Default to zero-build static**; escalate to React-via-CDN or a React app only when interactivity
  genuinely aids learning, and only with the user's sign-off (§3).
- **Data-driven** — render from `content.json`; don't bake content into HTML/JSX so the docs and site can't
  drift. **This includes diagrams** — nodes/edges/flows live in `content.json`, never hardcoded in JSX.
- **Diagrams (React-app tier): always build the two core ones** (full-scope Architecture + Infrastructure)
  and propose the rest (§3b). **Reproduce the functionality, adapt the component to the site:** start from
  the `templates/` pattern and **preserve the load-bearing mechanics** (the gotchas), but mesh it with the
  generated site (theme, router, naming) — it's not a frozen file. Diagram nodes/edges/flows are **sourced
  from the docs** (`docs/layers/` + `ARCHITECTURE.md` + `DIAGRAM_PLAN.md`), **never** carried over from
  another project or invented; the integrity check must pass before building.
- **Right-sized** — interactivity must teach; no animation/flash that doesn't aid understanding.
- **Serve and verify before declaring done** — a site that doesn't load isn't done.
- **Requires `docs/layers/`** — if it's missing, send the user to **`/layer-docs`** first; don't reverse-
  engineer the architecture here.

---

## Output & handoff

> **learn-site** — **Built from:** `docs/layers/` (`<N>` layers). **Stack:** `<static | React-via-CDN | React app>`.
> **Pages:** `<overview + N layers + flow + glossary>`. **Interactions:** `<clickable map · flow walkthrough · plain/deep · search · …>`.
> **Diagrams:** `<Architecture · Infrastructure · + the extras built — or "none (static tier)">`.
> **Location:** `docs/learn-site/`. **Open with:** `<double-click index.html | python3 -m http.server>`.
> **Verified:** `<what you smoke-tested — incl. for each diagram: renders · minimap populated · a flow traces · node-click + layer link>`. **Open questions:** `<gaps / docs to extend>`.

Then stop.
