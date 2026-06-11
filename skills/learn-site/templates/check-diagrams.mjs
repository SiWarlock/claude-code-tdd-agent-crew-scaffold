#!/usr/bin/env node
// learn-site — diagram integrity check. Run BEFORE building, against the generated content.json:
//   node templates/check-diagrams.mjs docs/learn-site/content.json
// Fails loudly (non-zero exit) on a dangling reference — a bad edge endpoint or an
// edge.flows entry with no matching flow silently breaks a trace, so catch it here.
import { readFileSync } from 'node:fs';

const path = process.argv[2] || 'docs/learn-site/content.json';
const c = JSON.parse(readFileSync(path, 'utf8'));
const diagrams = [c.architecture, c.infrastructure, ...(c.diagrams ?? [])].filter(Boolean);

let failures = 0;
const fail = (msg) => { console.error('  ✗ ' + msg); failures++; };

for (const d of diagrams) {
  const nodeIds = new Set(d.nodes.map((n) => n.id));
  const flowIds = new Set(d.flows.map((f) => f.id));
  if (nodeIds.size !== d.nodes.length) fail(`[${d.id}] duplicate node id`);
  for (const e of d.edges) {
    if (!nodeIds.has(e.source)) fail(`[${d.id}] edge ${e.id}: source "${e.source}" is not a node`);
    if (!nodeIds.has(e.target)) fail(`[${d.id}] edge ${e.id}: target "${e.target}" is not a node`);
    for (const f of e.flows) if (!flowIds.has(f)) fail(`[${d.id}] edge ${e.id}: flow "${f}" is not declared`);
  }
  if (failures === 0) {
    console.log(`  ✓ [${d.id}] ${d.nodes.length} nodes, ${d.edges.length} edges, ${d.flows.length} flows`);
  }
}

if (failures > 0) {
  console.error(`\nINTEGRITY: ${failures} failure(s) — fix content.json before building.`);
  process.exit(1);
}
console.log('\nINTEGRITY: PASS');
