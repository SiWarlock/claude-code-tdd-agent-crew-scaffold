#!/bin/bash
#
# Reference status line script — renders the status bar AND writes a heartbeat
# for team-mode sessions. Solo sessions render the bar only (no heartbeat write).
#
# INSTALL: copy to ~/.claude/statusline-command.sh and reference it from
# ~/.claude/settings.json:
#   {
#     "statusLine": { "type": "command", "command": "bash /Users/<you>/.claude/statusline-command.sh" }
#   }
#
# If you already have a custom status line script, merge the HEARTBEAT block
# (clearly marked below) into your existing script. Heartbeat write is conditional
# on a team-registry file existing for the current session_id — solo sessions
# are NEVER monitored.
#
# DESIGN: agent-team scoping.
#   - Team-mode sessions: each teammate's first action (via the /team-start
#     spawn prompt) writes ~/.claude/team-registry/<session_id>.json with
#     {session_id, name, team, cwd, ts}. The status line checks for this file's
#     existence; if present, writes a heartbeat. If absent, skips entirely.
#   - Solo sessions: no registry file is ever written for them, so the status
#     line never writes a heartbeat. Zero pollution of the monitoring system.
#
# The /context-check slash command reads heartbeats + registry to surface
# per-team context state. Multiple teams in parallel are isolated by the
# `team` field in each registry entry.

input=$(cat)

# ─── Parse status line stdin ────────────────────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# ─── ▼ HEARTBEAT BLOCK — team-mode only ─────────────────────────────────────
# Writes ~/.claude/heartbeats/<session_id>.json IFF a team-registry entry exists
# for this session (i.e., this session is a registered team member). Solo
# sessions skip entirely.
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
REGISTRY_FILE="$HOME/.claude/team-registry/${SESSION_ID}.json"
if [ -n "$SESSION_ID" ] && [ -f "$REGISTRY_FILE" ]; then
  HB_DIR="$HOME/.claude/heartbeats"
  mkdir -p "$HB_DIR" 2>/dev/null

  # Extract rich context data from the same stdin JSON.
  INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
  OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
  WINDOW_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
  REMAINING_PCT=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')
  COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
  API_MS=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
  RL_5H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
  RL_7D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')

  # Atomic write via tmp + mv (avoids /context-check reading a half-written file).
  TMP_HB="$HB_DIR/.${SESSION_ID}.json.tmp"
  jq -n \
    --arg sid "$SESSION_ID" \
    --argjson ctx_pct "${PCT:-0}" \
    --argjson remaining_pct "${REMAINING_PCT:-100}" \
    --argjson input_tokens "${INPUT_TOKENS:-0}" \
    --argjson output_tokens "${OUTPUT_TOKENS:-0}" \
    --argjson window_size "${WINDOW_SIZE:-0}" \
    --argjson cost_usd "${COST_USD:-0}" \
    --argjson api_ms "${API_MS:-0}" \
    --argjson rl_5h "${RL_5H:-0}" \
    --argjson rl_7d "${RL_7D:-0}" \
    --arg cwd "$DIR" \
    --arg model "$MODEL" \
    --arg ts "$(date -u +%s)" \
    '{
       session_id: $sid,
       ctx_pct: $ctx_pct,
       remaining_pct: $remaining_pct,
       input_tokens: $input_tokens,
       output_tokens: $output_tokens,
       window_size: $window_size,
       cost_usd: $cost_usd,
       api_ms: $api_ms,
       rate_limit_5h_pct: $rl_5h,
       rate_limit_7d_pct: $rl_7d,
       cwd: $cwd,
       model: $model,
       ts: ($ts | tonumber)
     }' > "$TMP_HB" 2>/dev/null && mv -f "$TMP_HB" "$HB_DIR/${SESSION_ID}.json" 2>/dev/null
fi
# ─── ▲ END HEARTBEAT BLOCK ──────────────────────────────────────────────────

# ─── Render the status bar ──────────────────────────────────────────────────
CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH=" | 🌿 $(git branch --show-current 2>/dev/null)"

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}$BRANCH"
COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% | ${YELLOW}${COST_FMT}${RESET} | ⏱️ ${MINS}m ${SECS}s"
