#!/bin/bash
# HyperAgents Archive Manager
# CLI utility for querying and managing the evolutionary archive
#
# Usage:
#   archive-manager.sh show              — Display archive overview
#   archive-manager.sh best              — Show best generation
#   archive-manager.sh lineage <genid>   — Trace ancestry
#   archive-manager.sh fitness           — Show fitness trajectory
#   archive-manager.sh export <genid>    — Export generation's diff
#   archive-manager.sh validate          — Check archive integrity

set -euo pipefail

HYPERAGENTS_DIR=".hyperagents"
ARCHIVE_FILE="${HYPERAGENTS_DIR}/archive.jsonl"

if [ ! -f "$ARCHIVE_FILE" ]; then
  echo "Error: No archive found at ${ARCHIVE_FILE}"
  echo "Run /hyperagents:evolve to start an evolution loop first."
  exit 1
fi

COMMAND="${1:-show}"

case "$COMMAND" in
  show)
    echo "=== HyperAgents Archive ==="
    echo ""
    TOTAL=$(wc -l < "$ARCHIVE_FILE" | tr -d ' ')
    echo "Total generations: $TOTAL"
    echo ""
    echo "GenID | Parent | Valid | Score"
    echo "------|--------|-------|------"

    # Read latest archive state
    LATEST=$(tail -1 "$ARCHIVE_FILE")
    GENIDS=$(echo "$LATEST" | jq -r '.archive[]')

    for GENID in $GENIDS; do
      META_FILE="${HYPERAGENTS_DIR}/gen_${GENID}/metadata.json"
      if [ -f "$META_FILE" ]; then
        PARENT=$(jq -r '.parent_genid // "none"' "$META_FILE")
        VALID=$(jq -r '.valid_parent // false' "$META_FILE")
        echo "$GENID | $PARENT | $VALID | -"
      else
        echo "$GENID | - | - | -"
      fi
    done
    ;;

  best)
    echo "=== Best Generation ==="
    LATEST=$(tail -1 "$ARCHIVE_FILE")
    GENIDS=$(echo "$LATEST" | jq -r '.archive[]')

    BEST_GEN=""
    BEST_SCORE=-1

    for GENID in $GENIDS; do
      # Find report.json files for this generation
      for REPORT in "${HYPERAGENTS_DIR}/gen_${GENID}"/*_eval/report.json; do
        if [ -f "$REPORT" ]; then
          # Try to extract score (check common keys)
          SCORE=$(jq -r '
            .overall_accuracy //
            .pass_rate //
            .accuracy //
            .accuracy_score //
            .average_fitness //
            .average_progress //
            .points_percentage //
            0
          ' "$REPORT" 2>/dev/null || echo "0")

          if [ "$(echo "$SCORE > $BEST_SCORE" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            BEST_SCORE="$SCORE"
            BEST_GEN="$GENID"
          fi
        fi
      done
    done

    if [ -n "$BEST_GEN" ]; then
      echo "Generation: $BEST_GEN"
      echo "Score: $BEST_SCORE"

      DIFF="${HYPERAGENTS_DIR}/gen_${BEST_GEN}/agent_output/model_patch.diff"
      if [ -f "$DIFF" ]; then
        echo ""
        echo "Diff summary:"
        diffstat "$DIFF" 2>/dev/null || wc -l "$DIFF"
      fi
    else
      echo "No scored generations found."
    fi
    ;;

  lineage)
    GENID="${2:?Usage: archive-manager.sh lineage <genid>}"
    echo "=== Lineage of gen_${GENID} ==="

    CURRENT="$GENID"
    DEPTH=0
    while [ "$CURRENT" != "null" ] && [ "$CURRENT" != "none" ] && [ -n "$CURRENT" ]; do
      INDENT=$(printf '%*s' $((DEPTH * 2)) '')
      echo "${INDENT}gen_${CURRENT}"

      META_FILE="${HYPERAGENTS_DIR}/gen_${CURRENT}/metadata.json"
      if [ -f "$META_FILE" ]; then
        CURRENT=$(jq -r '.parent_genid // "null"' "$META_FILE")
      else
        break
      fi
      DEPTH=$((DEPTH + 1))

      # Safety: prevent infinite loops
      if [ $DEPTH -gt 100 ]; then
        echo "Warning: lineage depth exceeded 100, stopping."
        break
      fi
    done
    ;;

  fitness)
    echo "=== Fitness Trajectory ==="
    LATEST=$(tail -1 "$ARCHIVE_FILE")
    GENIDS=$(echo "$LATEST" | jq -r '.archive[]')

    for GENID in $GENIDS; do
      for REPORT in "${HYPERAGENTS_DIR}/gen_${GENID}"/*_eval/report.json; do
        if [ -f "$REPORT" ]; then
          DOMAIN=$(basename "$(dirname "$REPORT")" | sed 's/_eval$//')
          SCORE=$(jq -r '
            .overall_accuracy //
            .pass_rate //
            .accuracy //
            .accuracy_score //
            .average_fitness //
            .average_progress //
            .points_percentage //
            "N/A"
          ' "$REPORT" 2>/dev/null || echo "N/A")
          echo "gen_${GENID} [${DOMAIN}]: ${SCORE}"
        fi
      done
    done
    ;;

  validate)
    echo "=== Archive Validation ==="
    ERRORS=0

    LATEST=$(tail -1 "$ARCHIVE_FILE")
    GENIDS=$(echo "$LATEST" | jq -r '.archive[]')

    for GENID in $GENIDS; do
      GEN_DIR="${HYPERAGENTS_DIR}/gen_${GENID}"
      if [ ! -d "$GEN_DIR" ]; then
        echo "ERROR: Missing directory for gen_${GENID}"
        ERRORS=$((ERRORS + 1))
        continue
      fi

      META_FILE="${GEN_DIR}/metadata.json"
      if [ ! -f "$META_FILE" ]; then
        echo "WARNING: Missing metadata.json for gen_${GENID}"
        continue
      fi

      PARENT=$(jq -r '.parent_genid // "null"' "$META_FILE")
      if [ "$PARENT" != "null" ] && [ ! -d "${HYPERAGENTS_DIR}/gen_${PARENT}" ]; then
        echo "ERROR: gen_${GENID} references missing parent gen_${PARENT}"
        ERRORS=$((ERRORS + 1))
      fi
    done

    if [ $ERRORS -eq 0 ]; then
      echo "Archive is valid. No integrity issues found."
    else
      echo ""
      echo "Found $ERRORS integrity issues."
    fi
    ;;

  export)
    GENID="${2:?Usage: archive-manager.sh export <genid>}"
    DIFF="${HYPERAGENTS_DIR}/gen_${GENID}/agent_output/model_patch.diff"

    if [ ! -f "$DIFF" ]; then
      echo "Error: No diff found for gen_${GENID}"
      exit 1
    fi

    EXPORT_FILE="${HYPERAGENTS_DIR}/export_gen_${GENID}.diff"
    cp "$DIFF" "$EXPORT_FILE"
    echo "Exported to: $EXPORT_FILE"
    ;;

  *)
    echo "Usage: archive-manager.sh {show|best|lineage|fitness|validate|export} [args]"
    exit 1
    ;;
esac
