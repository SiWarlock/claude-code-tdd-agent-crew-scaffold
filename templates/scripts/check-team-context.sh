#!/bin/bash
#
# check-team-context.sh — joins team-registry + heartbeats, outputs per-track
# context state with WARN/ACTION tier markers + trajectory estimate.
#
# "Track" here is OUR OWN scaffolding-internal bookkeeping label (the one
# /team-start assigns and every teammate registers under) — it is NOT Claude
# Code's actual team identity. Claude Code's agent-teams feature is itself
# experimental and OFF by default (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1);
# without it, /team-start never spawns real teammates and this registry stays
# empty. A session's real team is auto-formed and named `session-<first 8
# chars of the session ID>` — not something this script or /team-start can
# choose; this script never reads or relies on that real team's config.
#
# Used by:
#   - /context-check slash command (manual or automatic invocation)
#   - Orchestrator's per-slice post-Step-10 step
#   - Team lead's evaluation when receiving the orch's per-slice ping
#
# INSTALL: copy to ~/.claude/scripts/check-team-context.sh
#
# USAGE:
#   check-team-context.sh                          # auto-detect track (from $TRACK_NAME env, else all tracks)
#   check-team-context.sh <track-name>              # specific track
#   check-team-context.sh <track> --brief           # one-line per-track aggregate (orch's per-slice ping form)
#   check-team-context.sh <track> --snapshot <h>    # append this slice's ctx to trajectory history, then print --brief
#   check-team-context.sh --json                    # JSON output instead of human-readable
#   check-team-context.sh --history                 # include trajectory data (per-slice growth)
#
# DESIGN: data sources
#   - ~/.claude/team-registry/<session_id>.json — written by team-mode sessions
#     at startup (via /team-start spawn prompts). Contains {session_id, name,
#     track_label, cwd, ts}.
#   - ~/.claude/heartbeats/<session_id>.json — written continuously by the
#     status line script (only when registry entry exists). Contains ctx_pct,
#     tokens, cost, rate limits, ts.
#   - ~/.claude/track-history/<track>/<name>.jsonl — per-slice ctx snapshots,
#     appended by `check-team-context.sh --snapshot <hash>`. Each line:
#     {ts, ctx_pct, slice_hash}. Used for the 3-slice rolling trajectory.
#
# THRESHOLDS (configurable via env):
#   CLAUDE_TEAM_CTX_WARN   default 70   one-line surface; trajectory shown
#   CLAUDE_TEAM_CTX_ACTION default 75   auto close-out cycle triggered
#   CLAUDE_TEAM_CTX_HARD   default 80   hard-stop dispatch + immediate cycle

set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
REGISTRY_DIR="$HOME/.claude/team-registry"
HEARTBEAT_DIR="$HOME/.claude/heartbeats"
HISTORY_DIR="$HOME/.claude/track-history"
STALE_SECONDS=600  # 10 minutes — heartbeats older than this are treated as dead sessions

WARN="${CLAUDE_TEAM_CTX_WARN:-70}"
ACTION="${CLAUDE_TEAM_CTX_ACTION:-75}"
HARD="${CLAUDE_TEAM_CTX_HARD:-80}"

# ─── Args ────────────────────────────────────────────────────────────────────
TRACK_FILTER=""
OUTPUT="human"
INCLUDE_HISTORY="false"
SNAPSHOT_HASH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json)     OUTPUT="json" ;;
    --brief)    OUTPUT="brief" ;;
    --history)  INCLUDE_HISTORY="true" ;;
    --snapshot) SNAPSHOT_HASH="${2:?--snapshot needs a <slice-hash>}"; shift ;;
    --*)        echo "Unknown flag: $1" >&2; exit 2 ;;
    *)          TRACK_FILTER="$1" ;;
  esac
  shift
done

# --snapshot implies: append per-slice history first, then emit the --brief line
# (with trajectory). One call does the orchestrator's whole per-slice context step.
if [ -n "$SNAPSHOT_HASH" ]; then
  OUTPUT="brief"
  INCLUDE_HISTORY="true"
fi

# Auto-detect: if no track filter, try $TRACK_NAME env (set by /team-start);
# otherwise scan all tracks.
if [ -z "$TRACK_FILTER" ] && [ -n "${TRACK_NAME:-}" ]; then
  TRACK_FILTER="$TRACK_NAME"
fi

# ─── Early exit if no registry ──────────────────────────────────────────────
if [ ! -d "$REGISTRY_DIR" ] || [ -z "$(ls -A "$REGISTRY_DIR" 2>/dev/null)" ]; then
  if [ "$OUTPUT" = "json" ]; then echo '{"tracks": []}'
  else echo "No team registry entries found. Are any team sessions active? (Agent teams are experimental/off by default — confirm CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 is set.)"
  fi
  exit 0
fi

NOW=$(date -u +%s)

# ─── Snapshot mode: append this slice's ctx to per-member trajectory history ──
if [ -n "$SNAPSHOT_HASH" ]; then
  for reg_file in "$REGISTRY_DIR"/*.json; do
    [ -f "$reg_file" ] || continue
    track=$(jq -r '.track_label // empty' "$reg_file" 2>/dev/null)
    [ -n "$TRACK_FILTER" ] && [ "$track" != "$TRACK_FILTER" ] && continue
    name=$(jq -r '.name // empty' "$reg_file" 2>/dev/null)
    sid=$(jq -r '.session_id // empty' "$reg_file" 2>/dev/null)
    [ -z "$name" ] && continue
    [ -z "$sid" ] && continue
    hb="$HEARTBEAT_DIR/${sid}.json"
    [ -f "$hb" ] || continue
    ctx=$(jq -r '.ctx_pct // empty' "$hb" 2>/dev/null)
    [ -z "$ctx" ] && continue
    mkdir -p "$HISTORY_DIR/$track"
    jq -nc --argjson ts "$NOW" --argjson ctx "$ctx" --arg hash "$SNAPSHOT_HASH" \
      '{ts:$ts, ctx_pct:$ctx, slice_hash:$hash}' >> "$HISTORY_DIR/$track/$name.jsonl"
  done
fi

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
    track=$(jq -r '.track_label // empty' "$reg_file" 2>/dev/null)
    name=$(jq -r '.name // empty' "$reg_file" 2>/dev/null)

    [ -z "$sid" ] && continue
    [ -n "$TRACK_FILTER" ] && [ "$track" != "$TRACK_FILTER" ] && continue

    hb_file="$HEARTBEAT_DIR/${sid}.json"
    if [ ! -f "$hb_file" ]; then
      # Registry entry but no heartbeat yet — session just started or status
      # line hasn't refreshed. Emit a sentinel.
      jq -n --arg sid "$sid" --arg track "$track" --arg name "$name" \
        '{session_id:$sid, track:$track, name:$name, ctx_pct:null, status:"no-heartbeat"}'
      continue
    fi

    hb_ts=$(jq -r '.ts // 0' "$hb_file" 2>/dev/null)
    hb_age=$((NOW - hb_ts))
    if [ "$hb_age" -gt "$STALE_SECONDS" ]; then
      jq -n --arg sid "$sid" --arg track "$track" --arg name "$name" --argjson age "$hb_age" \
        '{session_id:$sid, track:$track, name:$name, ctx_pct:null, status:"stale", stale_age_sec:$age}'
      continue
    fi

    # Live entry — merge registry name/track + heartbeat data + recent history.
    history=""
    if [ "$INCLUDE_HISTORY" = "true" ] && [ -f "$HISTORY_DIR/$track/$name.jsonl" ]; then
      # Last 4 snapshots → up to 3 pairwise deltas for the rolling trajectory.
      history=$(tail -n 4 "$HISTORY_DIR/$track/$name.jsonl" 2>/dev/null | jq -s '.')
    fi

    jq --arg name "$name" --arg track "$track" \
       --argjson hb_age "$hb_age" \
       --argjson history "${history:-null}" \
       '{
          session_id: .session_id,
          name: $name,
          track: $track,
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
  # Group by track for JSON consumers.
  echo "$enriched" | jq '
    group_by(.track)
    | map({track: .[0].track, members: .})
    | {tracks: ., generated_at: now | floor}
  '
  exit 0
fi

if [ "$OUTPUT" = "brief" ]; then
  # Single-line aggregate per track — for orchestrator's per-slice ping to lead.
  # Surfaces: max ctx%, tier classification, and any tier-crossed teammates.
  echo "$enriched" | jq -r '
    group_by(.track)[]
    | {
        track: .[0].track,
        max_ctx: ([.[] | select(.status == "live") | .ctx_pct] | max // 0),
        max_name: ([.[] | select(.status == "live")] | sort_by(.ctx_pct) | last.name // "?"),
        hard:   ([.[] | select(.tier == "hard")] | length),
        action: ([.[] | select(.tier == "action")] | length),
        warn:   ([.[] | select(.tier == "warn")] | length),
        crossed_names: ([.[] | select(.tier == "hard" or .tier == "action" or .tier == "warn") | "\(.name)=\(.ctx_pct)%"] | join(", "))
      }
    | if .hard > 0 then
        "Track \(.track): HARD-STOP (\(.crossed_names)). Halt dispatch + cycle immediately."
      elif .action > 0 then
        "Track \(.track): ACTION (\(.crossed_names)). Initiate close-out cycle now."
      elif .warn > 0 then
        "Track \(.track): WARN (\(.crossed_names)). Cycle approaching."
      else
        "Track \(.track): OK — max ctx \(.max_ctx)% (\(.max_name))"
      end
  '
  exit 0
fi

# Human-readable output.
echo
echo "Track context state — $(date -u +'%Y-%m-%d %H:%M:%S UTC'):"
echo "$enriched" | jq -r '
  def tier_label(t):
    if t == "hard" then "HARD-STOP"
    elif t == "action" then "ACTION"
    elif t == "warn" then "WARN"
    elif t == "ok" then "OK"
    else "—" end;

  (group_by(.track) | sort_by(.[0].track))[] as $g |
  "\n  Track: \($g[0].track)",
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
echo "$enriched" | jq -r --argjson warn "$WARN" --argjson action "$ACTION" --argjson hard "$HARD" '
  group_by(.track)[]
  | {
      track: .[0].track,
      hard:   ([.[] | select(.tier == "hard")] | length),
      action: ([.[] | select(.tier == "action")] | length),
      warn:   ([.[] | select(.tier == "warn")] | length)
    }
  | if .hard > 0 then
      "Track \(.track): HARD-STOP — \(.hard) teammate(s) ≥ \($hard)%. Halt dispatch + cycle immediately."
    elif .action > 0 then
      "Track \(.track): ACTION — \(.action) teammate(s) ≥ \($action)%. Initiate close-out cycle at next clean break."
    elif .warn > 0 then
      "Track \(.track): WARN — \(.warn) teammate(s) ≥ \($warn)%. Approaching cycle threshold."
    else
      "Track \(.track): OK — all teammates < \($warn)%."
    end
'
