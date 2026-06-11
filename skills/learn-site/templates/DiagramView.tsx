// learn-site — interactive-diagram renderer (the canonical PATTERN, not a drop-in file).
//
// This component is intentionally project-INDEPENDENT: it renders whatever Diagram you feed
// it from content.json. Adapt it to MESH with the site you're generating — its theme tokens,
// its router, its content model, its naming — but PRESERVE the mechanics, because each is a
// bug that bit the prototype if done differently:
//   • useNodesState/useEdgesState + onNodesChange/onEdgesChange  → or the MiniMap renders empty
//   • CSS-only React-Flow theming (never read dataset.theme in render)  → or it flashes/miscolors
//   • an explicit canvas height  → or React Flow renders nothing
//   • theme-INDEPENDENT colors for anything set from JS (kind colors, the mask)
// What's reproduced is the FUNCTIONALITY: clickable nodes → an info panel, animated flowing
// edges, trace-a-flow highlighting, a populated minimap, a legend, pan/zoom. The nodes/edges/
// flows themselves are entirely the specific project's data. See the playbook for the why.
//
// Depends on three sibling files the generated React app provides (rename to match yours):
//   ../router   → navigate(path)
//   ../content  → layerById (the layer lookup, so a node click can open its layer page)
//   ../types    → Diagram, DiagramNode
import { useEffect, useMemo, useState } from 'react';
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  Handle,
  Position,
  MarkerType,
  useNodesState,
  useEdgesState,
  type Node,
  type Edge,
  type NodeProps,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import { navigate } from '../router';
import { layerById } from '../content';
import type { Diagram, DiagramNode } from '../types';

const KIND_LABEL: Record<string, string> = {
  client: 'Client',
  frontend: 'Frontend',
  api: 'API',
  authz: 'Auth / Audit',
  service: 'Service',
  data: 'Data',
  async: 'Messaging',
  worker: 'Worker',
  external: 'External',
  job: 'Batch',
  edge: 'Edge / DNS',
  storage: 'Storage',
  compute: 'Compute',
  messaging: 'Messaging',
  security: 'Security',
  cicd: 'CI / CD',
};

// matches the --k accent colors in styles.css (used for the minimap node previews).
// THESE ARE THEME-INDEPENDENT ON PURPOSE — never read document.documentElement.dataset.theme
// to pick them; the attribute isn't set on first paint, so doing so flashes + miscolors.
const KIND_COLOR: Record<string, string> = {
  client: '#64748b',
  frontend: '#6366f1',
  api: '#0891b2',
  authz: '#e11d48',
  service: '#7c3aed',
  data: '#d97706',
  async: '#9333ea',
  worker: '#16a34a',
  external: '#6b7280',
  job: '#b45309',
  edge: '#0284c7',
  storage: '#ca8a04',
  compute: '#2563eb',
  messaging: '#9333ea',
  security: '#dc2626',
  cicd: '#db2777',
};

const EDGE_ON = '#6366f1'; // indigo — reads in both themes
const EDGE_OFF = '#94a3b8'; // slate

type DgNodeData = DiagramNode & { dim: boolean; active: boolean };

// Custom node: ONE target Handle (top) + ONE source Handle (bottom) → unambiguous routing.
function DgNode(props: NodeProps) {
  const d = props.data as unknown as DgNodeData;
  const cls = `dgn dgn-${d.kind}${d.dim ? ' dim' : ''}${d.active ? ' active' : ''}`;
  return (
    <div className={cls} title={d.detail}>
      <Handle type="target" position={Position.Top} className="dgn-h" />
      <span className="dgn-label">{d.label}</span>
      {d.sub && <span className="dgn-sub">{d.sub}</span>}
      <Handle type="source" position={Position.Bottom} className="dgn-h" />
    </div>
  );
}

const nodeTypes = { dg: DgNode };

function buildNodes(diagram: Diagram): Node[] {
  return diagram.nodes.map((n) => ({
    id: n.id,
    type: 'dg',
    position: { x: n.x, y: n.y },
    data: { ...n, dim: false, active: false } as unknown as Record<string, unknown>,
  }));
}

function buildEdges(diagram: Diagram, flow: string | null): Edge[] {
  const activeEdgeIds = flow
    ? new Set(diagram.edges.filter((e) => e.flows.includes(flow)).map((e) => e.id))
    : null;
  return diagram.edges.map((e) => {
    const on = !activeEdgeIds || activeEdgeIds.has(e.id);
    const traced = !!(activeEdgeIds && activeEdgeIds.has(e.id));
    const color = traced ? EDGE_ON : EDGE_OFF;
    return {
      id: e.id,
      source: e.source,
      target: e.target,
      label: e.label || undefined,
      type: 'smoothstep',
      // animate when traced, or when intrinsically async even with no flow selected
      animated: flow ? traced : e.kind === 'async' || e.kind === 'publish',
      style: { stroke: color, strokeWidth: traced ? 2.6 : 1.4, opacity: on ? 1 : 0.12 },
      labelBgPadding: [4, 2] as [number, number],
      labelBgStyle: { fill: 'var(--bg-elev)', fillOpacity: 0.9 },
      markerEnd: { type: MarkerType.ArrowClosed, color, width: 15, height: 15 },
    };
  });
}

export interface DiagramViewProps {
  diagram: Diagram;
  eyebrow: string;
  title: string;
  tagline: string;
}

export function DiagramView({ diagram, eyebrow, title, tagline }: DiagramViewProps) {
  const [flow, setFlow] = useState<string | null>(null);
  const [selId, setSelId] = useState<string | null>(null);

  const initialNodes = useMemo(() => buildNodes(diagram), [diagram]);
  const initialEdges = useMemo(() => buildEdges(diagram, null), [diagram]);
  // CRITICAL: useNodesState/useEdgesState + the onNodesChange/onEdgesChange props below.
  // Passing `nodes` as a plain controlled prop with no change handler stops React Flow
  // from propagating MEASURED node sizes → the MiniMap renders EMPTY. (That was the bug.)
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);

  // re-tint nodes/edges when the traced flow changes (preserves measured sizes + drag positions)
  useEffect(() => {
    const activeNodeIds = flow ? new Set<string>() : null;
    if (flow && activeNodeIds) {
      diagram.edges
        .filter((e) => e.flows.includes(flow))
        .forEach((e) => {
          activeNodeIds.add(e.source);
          activeNodeIds.add(e.target);
        });
    }
    setNodes((nds) =>
      nds.map((n) => {
        const dim = !!(activeNodeIds && !activeNodeIds.has(n.id));
        const active = !!(activeNodeIds && activeNodeIds.has(n.id));
        return { ...n, data: { ...n.data, dim, active } };
      }),
    );
    setEdges(buildEdges(diagram, flow));
  }, [flow, diagram, setNodes, setEdges]);

  const sel = selId ? (diagram.nodes.find((n) => n.id === selId) ?? null) : null;
  const kindsPresent = useMemo(
    () => Array.from(new Set(diagram.nodes.map((n) => n.kind))),
    [diagram],
  );

  return (
    <article className="view view-wide">
      <header className="view-head">
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="tagline">{tagline}</p>
      </header>

      <div className="dg-controls" role="group" aria-label="Trace a flow">
        <span className="dg-controls-label">Trace a flow:</span>
        <button
          type="button"
          className={`lc-pill${!flow ? ' on' : ''}`}
          onClick={() => setFlow(null)}
        >
          Show all
        </button>
        {diagram.flows.map((f) => (
          <button
            key={f.id}
            type="button"
            className={`lc-pill${flow === f.id ? ' on' : ''}`}
            onClick={() => setFlow((cur) => (cur === f.id ? null : f.id))}
          >
            {f.name}
          </button>
        ))}
      </div>
      {flow && (
        <p className="dg-flow-desc">{diagram.flows.find((f) => f.id === flow)?.desc}</p>
      )}

      {/* The canvas NEEDS an explicit height (set in styles.css: .dg-canvas { height: 74vh }) —
          React Flow renders nothing in a 0-height box. */}
      <div className="dg-canvas">
        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          nodeTypes={nodeTypes}
          fitView
          fitViewOptions={{ padding: 0.12 }}
          minZoom={0.3}
          maxZoom={1.75}
          nodesConnectable={false}
          edgesFocusable={false}
          proOptions={{ hideAttribution: true }}
          onNodeClick={(_, node) => setSelId(node.id)}
          onPaneClick={() => setSelId(null)}
        >
          <Background gap={22} size={1} color="#64748b" />
          <Controls showInteractive={false} />
          <MiniMap
            pannable
            zoomable
            ariaLabel="Diagram minimap"
            maskColor="rgba(127,127,127,0.16)"
            nodeColor={(n) => KIND_COLOR[(n.data as { kind?: string }).kind ?? ''] ?? '#94a3b8'}
            nodeStrokeColor={(n) => KIND_COLOR[(n.data as { kind?: string }).kind ?? ''] ?? '#94a3b8'}
            nodeStrokeWidth={3}
            nodeBorderRadius={3}
          />
        </ReactFlow>

        {sel && (
          <aside className="dg-detail" aria-label={`${sel.label} detail`}>
            <button
              type="button"
              className="dg-detail-close"
              onClick={() => setSelId(null)}
              aria-label="Close detail"
            >
              ×
            </button>
            <span className={`dg-detail-kind dgk-${sel.kind}`}>
              {KIND_LABEL[sel.kind] ?? sel.kind}
            </span>
            <h3>{sel.label}</h3>
            {sel.sub && <p className="dg-detail-sub">{sel.sub}</p>}
            <p className="dg-detail-body">{sel.detail}</p>
            {sel.layer && layerById[sel.layer] && (
              <button
                type="button"
                className="layer-chip"
                onClick={() => navigate(`/layer/${sel.layer}`)}
              >
                Open {layerById[sel.layer].name} →
              </button>
            )}
          </aside>
        )}
      </div>

      <div className="dg-legend" aria-label="Legend">
        {kindsPresent.map((k) => (
          <span key={k} className="dg-legend-item">
            <span className={`dg-legend-dot dgk-${k}`} />
            {KIND_LABEL[k] ?? k}
          </span>
        ))}
      </div>

      <p className="provenance">
        Click a box for detail (and a link to its layer doc); use “Trace a flow” to animate a path;
        drag boxes to rearrange. Derived from <code>docs/layers/</code> + <code>ARCHITECTURE.md</code>.
      </p>
    </article>
  );
}
