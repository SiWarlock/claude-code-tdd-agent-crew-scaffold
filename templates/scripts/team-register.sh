#!/bin/bash
#
# team-register.sh — write a teammate's team-registry entry. This is the FIRST
# action of every team-mode session (the lead self-registers in /team-start
# Step 1; teammates register via the /team-start spawn prompt).
#
# It is the on/off switch for context monitoring: the status line writes a
# heartbeat ONLY when this registry entry exists, so solo sessions (which never
# call this) are never monitored. /context-check reads these entries.
#
# Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (agent teams are experimental
# / disabled by default) — without it, /team-start never spawns real
# teammates, so this registry is never populated in practice regardless.
#
# INSTALL: copy to ~/.claude/scripts/team-register.sh (alongside
#          check-team-context.sh) and chmod +x. Installed once per machine.
#
# USAGE: team-register.sh <name> <role> <track-label> [area] [track] [branch]
#   <name>        the teammate's name, e.g. backend-orchestrator (or <track>-<area>-<role>)
#   <role>        lead | orchestrator | implementer
#   <track-label> OUR OWN scaffolding-internal context-monitoring group key — the
#                 track name, or session-<first8 of the lead's session id>. This is
#                 NOT and cannot become Claude Code's actual team name (that team is
#                 auto-formed and named session-<first8>, outside our control; passing
#                 anything to the Agent tool's team_name param has no effect on it —
#                 TeamCreate no longer exists either). Use the SAME string across every
#                 teammate's registration so our /context-check grouping is consistent.
#   [area]        the code-area dir for an implementer (optional; pass "" to skip it when setting [track])
#   [track]       the parallel track this teammate belongs to (optional; from the IMPLEMENTATION_PLAN
#                 Track map — usually the same value as <track-label>, but kept as a separate field since
#                 <track-label> always has a value (session-derived fallback) while this is sparse/optional)
#   [branch]      the track's worktree branch, e.g. track/<track> (optional; cwd already records the worktree path)

set -euo pipefail

name="${1:?usage: team-register.sh <name> <role> <track-label> [area]}"
role="${2:?usage: team-register.sh <name> <role> <track-label> [area]}"
track_label="${3:?usage: team-register.sh <name> <role> <track-label> [area]}"
area="${4:-}"
track="${5:-}"
branch="${6:-}"
sid="${CLAUDE_CODE_SESSION_ID:?CLAUDE_CODE_SESSION_ID is not set — run inside a Claude Code session}"

mkdir -p ~/.claude/team-registry
jq -n --arg sid "$sid" --arg name "$name" --arg track_label "$track_label" --arg role "$role" \
      --arg area "$area" --arg track "$track" --arg branch "$branch" \
      --arg cwd "$(pwd)" --arg ts "$(date -u +%s)" \
  '{session_id:$sid, name:$name, track_label:$track_label, role:$role, cwd:$cwd, ts:($ts|tonumber)}
   + (if $area == ""   then {} else {area:$area}     end)
   + (if $track == ""  then {} else {track:$track}   end)
   + (if $branch == "" then {} else {branch:$branch} end)' \
  > ~/.claude/team-registry/"$sid".json

echo "registered $name ($role) under track-label $track_label"
