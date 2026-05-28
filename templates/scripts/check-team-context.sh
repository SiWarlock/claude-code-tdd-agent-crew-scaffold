#!/bin/bash
#
# check-team-context.sh — joins team-registry + heartbeats, outputs per-team
# context state with WARN/ACTION tier markers + trajectory estimate.
#
# Used by:
#   - /context-check slash command (manual or automatic invocation)
#   - Orchestrator's per-slice post-Step-10 step
#   - Team lead's evaluation when receiving the orch's per-slice ping
#
# INSTALL: copy to ~/.claude/scripts/check-team-context.sh
#
# USAGE:
#   check-team-context.sh                  # auto-detect team (from $TEAM env, current cwd's team, or all teams)
#   check-team-context.sh <team-name>      # specific team
#   check-team-context.sh --json           # JSON output instead of human-readable
#   check-team-context.sh --history        # include trajectory data (per-slice growth)
#
# DESIGN: data sources
#   - ~/.claude/team-registry/<session_id>.json — written by team-mode sessions
#     at startup (via /team-start spawn prompts). Contains {session_id, name,
#     team, cwd, ts}.
#   - ~/.claude/heartbeats/<session_id>.json — written continuously by the
#     status line script (only when registry entry exists). Contains ctx_pct,
#     tokens, cost, rate limits, ts.
#   - ~/.claude/team-history/<team>/<name>.jsonl — per-slice ctx snapshots
#     appended by the orchestrator's /context-check call. Each line:
#     {ts, ctx_pct, slice_hash}. Used for 3-slice rolling trajectory.
#
# THRESHOLDS (configurable via env):
#   CLAUDE_TEAM_CTX_WARN   default 70   one-line surface; trajectory shown
#   CLAUDE_TEAM_CTX_ACTION default 75   auto close-out cycle triggered
#   CLAUDE_TEAM_CTX_HARD   default 80   hard-stop dispatch + immediate cycle

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
REGISTRY_DIR="$HOME/.claude/team-registry"
HEARTBEAT_DIR="$HOME/.claude/heartbeats"
HISTORY_DIR="$HOME/.claude/team-history"
STALE_SECONDS=600  # 10 minutes — heartbeats older than this are treated as dead sessions

WARN="${CLAUDE_TEAM_CTX_WARN:-70}"
ACTION="${CLAUDE_TEAM_CTX_ACTION:-75}"
HARD="${CLAUDE_TEAM_CTX_HARD:-80}"

# ─── Args ────────────────────────────────────────────────────────────────────
TEAM_FILTER=""
OUTPUT="human"
INCLUDE_HISTORY="false"
for arg in "$@"; do
  case "$arg" in
    --json)    OUTPUT="json" ;;
    --brief)   OUTPUT="brief" ;;
    --history) INCLUDE_HISTORY="true" ;;
    --*)       echo "Unknown flag: $arg" >&2; exit 2 ;;
    *)         TEAM_FILTER="$arg" ;;
  esac
done

# Auto-detect: if no team filter, try $TEAM_NAME env (set by /team-start);
# otherwise scan all teams.
if [ -z "$TEAM_FILTER" ] && [ -n "${TEAM_NAME:-}" ]; then
  TEAM_FILTER="$TEAM_NAME"
fi

# ─── Early exit if no registry ──────────────────────────────────────────────
if [ ! -d "$REGISTRY_DIR" ] || [ -z "$(ls -A "$REGISTRY_DIR" 2>/dev/null)" ]; then
  if [ "$OUTPUT" = "json" ]; then echo '{"teams": []}'
  else echo "No team registry entries found. Are any team sessions active?"
  fi
  exit 0
fi

NOW=$(date -u +%s)

# ─── Join: registry → heartbeats → optionally history ───────────────────────
# Output one JSON object per teammate.
joined=$(
  for reg_file in "$REGISTRY_DIR"/*.json; do
    [ -f "$reg_file" ] || continue

    # NOTE: registry entries are written ONCE at session start and never updated;
    # their `ts` is session-start time, not last-activity time. Don't filter by
    # registry age. Staleness applies to HEARTBEATS only (status line updates
    # those continuously; a stale heartbeat = session ended). Registry entries
    # get explicit cleanup at /team-end (per template).

    sid=$(jq -r '.session_id // empty' "$reg_file" 2>/dev/null)
    team=$(jq -r '.team // empty' "$reg_file" 2>/dev/null)
    name=$(jq -r '.name // empty' "$reg_file" 2>/dev/null)

    [ -z "$sid" ] && continue
    [ -n "$TEAM_FILTER" ] && [ "$team" != "$TEAM_FILTER" ] && continue

    hb_file="$HEARTBEAT_DIR/${sid}.json"
    if [ ! -f "$hb_file" ]; then
      # Registry entry but no heartbeat yet — session just started or status
      # line hasn't refreshed. Emit a sentinel.
      jq -n --arg sid "$sid" --arg team "$team" --arg name "$name" \
        '{session_id:$sid, team:$team, name:$name, ctx_pct:null, status:"no-heartbeat"}'
      continue
    fi

    hb_ts=$(jq -r '.ts // 0' "$hb_file" 2>/dev/null)
    hb_age=$((NOW - hb_ts))
    if [ "$hb_age" -gt "$STALE_SECONDS" ]; then
      jq -n --arg sid "$sid" --arg team "$team" --arg name "$name" --argjson age "$hb_age" \
        '{session_id:$sid, team:$team, name:$name, ctx_pct:null, status:"stale", stale_age_sec:$age}'
      continue
    fi

    # Live entry — merge registry name/team + heartbeat data + recent history.
    history=""
    if [ "$INCLUDE_HISTORY" = "true" ] && [ -f "$HISTORY_DIR/$team/$name.jsonl" ]; then
      # Last 3 entries → trajectory delta.
      history=$(tail -n 4 "$HISTORY_DIR/$team/$name.jsonl" 2>/dev/null | jq -s '.')
    fi

    jq --arg name "$name" --arg team "$team" \
       --argjson hb_age "$hb_age" \
       --argjson history "${history:-null}" \
       '{
          session_id: .session_id,
          name: $name,
          team: $team,
          ctx_pct: .ctx_pct,
          remaining_pct: .remaining_pct,
          input_tokens: .input_tokens,
          window_size: .window_size,
          cost_usd: .cost_usd,
          rate_limit_5h_pct: .rate_limit_5h_pct,
          rate_limit_7d_pct: .rate_limit_7d_pct,
          cwd: .cwd,
          model: .model,
          heartbeat_age_sec: $hb_age,
          status: "live",
          history: $history
        }' "$hb_file"
  done | jq -s '.'
)

# ─── Compute trajectory + tier per teammate ─────────────────────────────────
enriched=$(echo "$joined" | jq --argjson warn "$WARN" --argjson action "$ACTION" --argjson hard "$HARD" '
  map(
    . as $m |
    if .status != "live" or .ctx_pct == null then
      . + {tier: "unknown", trajectory: null}
    else
      # Tier classification.
      (if .ctx_pct >= $hard then "hard"
       elif .ctx_pct >= $action then "action"
       elif .ctx_pct >= $warn then "warn"
       else "ok" end) as $tier |

      # Trajectory: rolling growth-per-slice over last 3 slices, if history present.
      (if .history == null or (.history | length) < 2 then null
       else
         (.history | map(.ctx_pct)) as $pcts |
         ($pcts | length) as $n |
         # Pairwise deltas of last (n-1) slices.
         [range(1; $n) | $pcts[.] - $pcts[. - 1]] as $deltas |
         ($deltas | add / length) as $avg_growth |
         {
           avg_growth_per_slice: $avg_growth,
           slices_until_action: (
             if $avg_growth <= 0 then null
             else (($action - .ctx_pct) / $avg_growth) | (. * 10 | round) / 10
             end
           )
         }
       end) as $traj |

      $m + {tier: $tier, trajectory: $traj}
    end
  )
')

# ─── Output ─────────────────────────────────────────────────────────────────
if [ "$OUTPUT" = "json" ]; then
  # Group by team for JSON consumers.
  echo "$enriched" | jq '
    group_by(.team)
    | map({team: .[0].team, members: .})
    | {teams: ., generated_at: now | floor}
  '
  exit 0
fi

if [ "$OUTPUT" = "brief" ]; then
  # Single-line aggregate per team — for orchestrator's per-slice ping to lead.
  # Surfaces: max ctx%, tier classification, and any tier-crossed teammates.
  echo "$enriched" | jq -r '
    group_by(.team)[]
    | {
        team: .[0].team,
        max_ctx: ([.[] | select(.status == "live") | .ctx_pct] | max // 0),
        max_name: ([.[] | select(.status == "live")] | sort_by(.ctx_pct) | last.name // "?"),
        hard:   ([.[] | select(.tier == "hard")] | length),
        action: ([.[] | select(.tier == "action")] | length),
        warn:   ([.[] | select(.tier == "warn")] | length),
        crossed_names: ([.[] | select(.tier == "hard" or .tier == "action" or .tier == "warn") | "\(.name)=\(.ctx_pct)%"] | join(", "))
      }
    | if .hard > 0 then
        "Team \(.team): HARD-STOP (\(.crossed_names)). Halt dispatch + cycle immediately."
      elif .action > 0 then
        "Team \(.team): ACTION (\(.crossed_names)). Initiate close-out cycle now."
      elif .warn > 0 then
        "Team \(.team): WARN (\(.crossed_names)). Cycle approaching."
      else
        "Team \(.team): OK — max ctx \(.max_ctx)% (\(.max_name))"
      end
  '
  exit 0
fi

# Human-readable output.
echo
echo "Team context state — $(date -u +'%Y-%m-%d %H:%M:%S UTC'):"
echo "$enriched" | jq -r '
  def tier_label(t):
    if t == "hard" then "HARD-STOP"
    elif t == "action" then "ACTION"
    elif t == "warn" then "WARN"
    elif t == "ok" then "OK"
    else "—" end;

  (group_by(.team) | sort_by(.[0].team))[] as $g |
  "\n  Team: \($g[0].team)",
  ( $g | sort_by(.name)[] |
      if .status != "live" then
        "    \(.name) (\(.status))"
      else
        "    \(.name): \(.ctx_pct)% [\(tier_label(.tier))]" +
        (if .trajectory and .trajectory.slices_until_action then
           " · ~\(.trajectory.slices_until_action) slices to ACTION"
         else "" end) +
        " · last update \(.heartbeat_age_sec)s ago"
      end
  )
'

# ─── Surface aggregate recommendation (one-line) ────────────────────────────
echo
echo "$enriched" | jq -r '
  group_by(.team)[]
  | {
      team: .[0].team,
      hard:   ([.[] | select(.tier == "hard")] | length),
      action: ([.[] | select(.tier == "action")] | length),
      warn:   ([.[] | select(.tier == "warn")] | length)
    }
  | if .hard > 0 then
      "Team \(.team): HARD-STOP — \(.hard) teammate(s) ≥ 80%. Halt dispatch + cycle immediately."
    elif .action > 0 then
      "Team \(.team): ACTION — \(.action) teammate(s) ≥ 75%. Initiate close-out cycle at next clean break."
    elif .warn > 0 then
      "Team \(.team): WARN — \(.warn) teammate(s) ≥ 70%. Approaching cycle threshold."
    else
      "Team \(.team): OK — all teammates < 70%."
    end
'
