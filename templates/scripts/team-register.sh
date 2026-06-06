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
# INSTALL: copy to ~/.claude/scripts/team-register.sh (alongside
#          check-team-context.sh) and chmod +x. Installed once per machine.
#
# USAGE: team-register.sh <name> <role> <team> [area]
#   <name>  the teammate's name, e.g. backend-orchestrator (or <track>-<area>-<role>)
#   <role>  lead | orchestrator | implementer
#   <team>  the team name from TeamCreate
#   [area]  the code-area dir for an implementer (optional)

set -euo pipefail

name="${1:?usage: team-register.sh <name> <role> <team> [area]}"
role="${2:?usage: team-register.sh <name> <role> <team> [area]}"
team="${3:?usage: team-register.sh <name> <role> <team> [area]}"
area="${4:-}"
sid="${CLAUDE_CODE_SESSION_ID:?CLAUDE_CODE_SESSION_ID is not set — run inside a Claude Code session}"

mkdir -p ~/.claude/team-registry
jq -n --arg sid "$sid" --arg name "$name" --arg team "$team" --arg role "$role" \
      --arg area "$area" --arg cwd "$(pwd)" --arg ts "$(date -u +%s)" \
  '{session_id:$sid, name:$name, team:$team, role:$role, cwd:$cwd, ts:($ts|tonumber)}
   + (if $area == "" then {} else {area:$area} end)' \
  > ~/.claude/team-registry/"$sid".json

echo "registered $name ($role) on team $team"
