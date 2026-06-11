// learn-site — diagram data model. Merge these into the generated app's src/types.ts.
// The pages render from content.json; nothing about a diagram is hardcoded in JSX.

export type DiagramNodeKind =
  | 'client'
  | 'frontend'
  | 'api'
  | 'authz'
  | 'service'
  | 'data'
  | 'async'
  | 'worker'
  | 'external'
  | 'job'
  | 'edge'
  | 'storage'
  | 'compute'
  | 'messaging'
  | 'security'
  | 'cicd';

export interface DiagramNode {
  id: string;
  label: string;
  /** Small mono sub-label (the concrete component / service name). */
  sub?: string;
  kind: DiagramNodeKind;
  /** Sentence shown in the click-detail panel. */
  detail: string;
  /** Layout coordinates (top-down: clients small y, infra/DB large y). */
  x: number;
  y: number;
  /** Optional layer id this node maps to (click → "Open <layer> →" links to that layer page). */
  layer?: string;
}

export interface DiagramEdge {
  id: string;
  source: string;
  target: string;
  label?: string;
  /** Visual/semantic kind (request, call, write, read, authz, async, publish, external, deploy, …).
   *  'async' | 'publish' edges animate even with no flow selected. */
  kind: string;
  /** Flow ids this edge participates in (the "trace a flow" highlight set). */
  flows: string[];
}

export interface DiagramFlow {
  id: string;
  name: string;
  /** One-sentence narration shown when this flow is traced. */
  desc: string;
}

export interface Diagram {
  /** Stable id — used by the sidebar Diagrams dropdown + the /diagram/<id> route. */
  id: string;
  /** Display name in the dropdown + the page title. */
  name: string;
  nodes: DiagramNode[];
  edges: DiagramEdge[];
  flows: DiagramFlow[];
}

// On the Content interface, add:
//   architecture: Diagram;      // always built (id: "architecture")
//   infrastructure: Diagram;    // always built (id: "infrastructure")
//   diagrams: Diagram[];        // the user-opted-in extras, each with its own id
