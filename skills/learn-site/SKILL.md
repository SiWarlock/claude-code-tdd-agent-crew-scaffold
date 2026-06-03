---
name: learn-site
description: >-
  Build an interactive educational WEBSITE that teaches how a project works — sourced from docs/layers/ (the
  /layer-docs output) plus the real code. The site explains the whole system and each layer and how they fit
  together, and every topic offers a PLAIN-ENGLISH view and a DEEPER-DIVE view you can toggle. Interactivity
  and depth scale to the project (a CLI library and a web platform get different sites). Defaults to plain,
  ZERO-BUILD static HTML/JS/CSS (double-click index.html to open); escalates to a zero-build React-via-CDN
  page, or a full React app, only when richer interactivity genuinely aids learning — with your sign-off.
  Content is generated data-first (a content model derived from the layer docs) so it stays faithful and
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
the zero-build React-via-CDN pattern, and the content schema — is in **`references/learn-site-playbook.md`**.
Read it first.

---

## 0. Asking the user questions (host-neutral — read first)

This skill has a scope/stack gate. Ask via:
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

State the recommendation + why, list the scope (pages, interactions), and **pause for sign-off** before building.

## 4. Generate the content model

> *Goal: separate content from presentation so the site stays faithful and editable.*

Write **`docs/learn-site/content.json`** (schema in the playbook): the project meta, the layer map + flow, and
per topic a **`plain`** field (from the layer doc's executive summary) and a **`deep`** field (from the depth
sections), plus code references, glossary terms, and the inter-layer connections. Derive it from the docs —
don't paraphrase loosely; preserve the docs' meaning and their `path:line` anchors.

## 5. Build the site

> *Goal: render the content model into the chosen stack.*

Scaffold under **`docs/learn-site/`**: `index.html`, `assets/styles.css`, `assets/app.js` (and `content.json`).
Implement the planned pages and interactions from the content model. Every topic shows a **Plain / Deep
toggle**. Keep it accessible and readable (the playbook has the patterns and the zero-build React-via-CDN
snippet). Do **not** hardcode content into markup — render it from `content.json` so it stays in sync.

## 6. Serve and verify

> *Goal: prove it actually works before declaring done.*

1. **Serve it:** `python3 -m http.server` (or open `index.html` directly for the pure-static build) and load
   the site. If browser tools are available, smoke-test; otherwise fetch pages and check they render.
2. **Check:** pages load, nav/links resolve, the **Plain/Deep toggle** works on each topic, the clickable map
   + walkthrough behave, search returns hits, no console errors.
3. **Faithfulness pass:** spot-check that what the site says matches the layer docs (and thus the code).

⏸ **Check-in:** show the user how to open/serve it; confirm it meets the learning goal.

---

## Hard rules (forbidden)

- **Content comes from `docs/layers/` (+ code)** — **never invent** explanations; if the docs don't cover
  something, say so or go read the code, don't fabricate.
- **Every topic gets BOTH a Plain-English and a Deeper-Dive view** — that dual register is the point.
- **Default to zero-build static**; escalate to React-via-CDN or a React app only when interactivity
  genuinely aids learning, and only with the user's sign-off (§3).
- **Data-driven** — render from `content.json`; don't bake content into HTML/JSX so the docs and site can't
  drift.
- **Right-sized** — interactivity must teach; no animation/flash that doesn't aid understanding.
- **Serve and verify before declaring done** — a site that doesn't load isn't done.
- **Requires `docs/layers/`** — if it's missing, send the user to **`/layer-docs`** first; don't reverse-
  engineer the architecture here.

---

## Output & handoff

> **learn-site** — **Built from:** `docs/layers/` (`<N>` layers). **Stack:** `<static | React-via-CDN | React app>`.
> **Pages:** `<overview + N layers + flow + glossary>`. **Interactions:** `<clickable map · flow walkthrough · plain/deep · search · …>`.
> **Location:** `docs/learn-site/`. **Open with:** `<double-click index.html | python3 -m http.server>`.
> **Verified:** `<what you smoke-tested>`. **Open questions:** `<gaps / docs to extend>`.

Then stop.
