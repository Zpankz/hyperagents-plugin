#!/bin/bash
# HyperAgents Fitness Scorer
# CLI utility for computing and comparing fitness scores
#
# Usage:
#   fitness-scorer.sh compute <genid> <domain>  — Compute fitness for a generation
#   fitness-scorer.sh compare <genid1> <genid2>  — Compare two generations
#   fitness-scorer.sh rank                        — Rank all generations
#   fitness-scorer.sh trend                       — Show fitness trend over time

set -euo pipefail

HYPERAGENTS_DIR=".hyperagents"

get_score() {
  local GENID="$1"
  local DOMAIN="${2:-}"

  if [ -n "$DOMAIN" ]; then
    local REPORT="${HYPERAGENTS_DIR}/gen_${GENID}/${DOMAIN}_eval/report.json"
    if [ ! -f "$REPORT" ]; then
      echo "null"
      return
    fi
    jq -r '
      .overall_accuracy //
      .pass_rate //
      .accuracy //
      .accuracy_score //
      .average_fitness //
      .average_progress //
      .points_percentage //
      "null"
    ' "$REPORT" 2>/dev/null || echo "null"
  else
    # Try to find any report.json
    local FOUND=0
    local TOTAL=0
    local SUM=0

    for REPORT in "${HYPERAGENTS_DIR}/gen_${GENID}"/*_eval/report.json; do
      if [ -f "$REPORT" ]; then
        local SCORE
        SCORE=$(jq -r '
          .overall_accuracy //
          .pass_rate //
          .accuracy //
          .accuracy_score //
          .average_fitness //
          .average_progress //
          .points_percentage //
          "null"
        ' "$REPORT" 2>/dev/null || echo "null")

        if [ "$SCORE" != "null" ]; then
          SUM=$(echo "$SUM + $SCORE" | bc -l 2>/dev/null || echo "$SUM")
          TOTAL=$((TOTAL + 1))
        fi
        FOUND=1
      fi
    done

    if [ $TOTAL -gt 0 ]; then
      echo "$SUM / $TOTAL" | bc -l 2>/dev/null || echo "$SUM"
    else
      echo "null"
    fi
  fi
}

COMMAND="${1:-rank}"

case "$COMMAND" in
  compute)
    GENID="${2:?Usage: fitness-scorer.sh compute <genid> [domain]}"
    DOMAIN="${3:-}"
    SCORE=$(get_score "$GENID" "$DOMAIN")
    echo "gen_${GENID}: ${SCORE}"
    ;;

  compare)
    GENID1="${2:?Usage: fitness-scorer.sh compare <genid1> <genid2>}"
    GENID2="${3:?Usage: fitness-scorer.sh compare <genid1> <genid2>}"
    SCORE1=$(get_score "$GENID1")
    SCORE2=$(get_score "$GENID2")
    echo "gen_${GENID1}: ${SCORE1}"
    echo "gen_${GENID2}: ${SCORE2}"

    if [ "$SCORE1" != "null" ] && [ "$SCORE2" != "null" ]; then
      DELTA=$(echo "$SCORE2 - $SCORE1" | bc -l 2>/dev/null || echo "?")
      if [ "$(echo "$DELTA > 0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
        echo "Delta: +${DELTA} (gen_${GENID2} is better)"
      elif [ "$(echo "$DELTA < 0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
        echo "Delta: ${DELTA} (gen_${GENID1} is better)"
      else
        echo "Delta: 0 (tied)"
      fi
    fi
    ;;

  rank)
    echo "=== Generation Ranking ==="
    ARCHIVE_FILE="${HYPERAGENTS_DIR}/archive.jsonl"
    if [ ! -f "$ARCHIVE_FILE" ]; then
      echo "No archive found."
      exit 1
    fi

    LATEST=$(tail -1 "$ARCHIVE_FILE")
    GENIDS=$(echo "$LATEST" | jq -r '.archive[]')

    # Collect scores into a temp file for sorting
    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT

    for GENID in $GENIDS; do
      SCORE=$(get_score "$GENID")
      echo "${SCORE} gen_${GENID}" >> "$TMPFILE"
    done

    # Sort descending by score
    sort -t' ' -k1 -nr "$TMPFILE" | while read -r LINE; do
      echo "$LINE"
    done
    ;;

  trend)
    echo "=== Fitness Trend ==="
    ARCHIVE_FILE="${HYPERAGENTS_DIR}/archive.jsonl"
    if [ ! -f "$ARCHIVE_FILE" ]; then
      echo "No archive found."
      exit 1
    fi

    LATEST=$(tail -1 "$ARCHIVE_FILE")
    GENIDS=$(echo "$LATEST" | jq -r '.archive[]')

    PREV_SCORE=""
    for GENID in $GENIDS; do
      SCORE=$(get_score "$GENID")
      if [ "$SCORE" != "null" ] && [ -n "$PREV_SCORE" ] && [ "$PREV_SCORE" != "null" ]; then
        DELTA=$(echo "$SCORE - $PREV_SCORE" | bc -l 2>/dev/null || echo "0")
        if [ "$(echo "$DELTA > 0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
          ARROW="▲"
        elif [ "$(echo "$DELTA < 0" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
          ARROW="▼"
        else
          ARROW="─"
        fi
        echo "gen_${GENID}: ${SCORE} ${ARROW}"
      else
        echo "gen_${GENID}: ${SCORE}"
      fi
      PREV_SCORE="$SCORE"
    done
    ;;

  *)
    echo "Usage: fitness-scorer.sh {compute|compare|rank|trend} [args]"
    exit 1
    ;;
esac
