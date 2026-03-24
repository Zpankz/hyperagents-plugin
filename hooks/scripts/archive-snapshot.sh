#!/bin/bash
# HyperAgents: Snapshot archive state on session end
# Stop hook — fires when a Claude Code session ends
#
# Captures the final state of the archive and any uncommitted
# changes to the evolution tracking files. This ensures continuity
# across sessions.

set -euo pipefail

HYPERAGENTS_DIR=".hyperagents"

# Only run if hyperagents is initialized
if [ ! -d "$HYPERAGENTS_DIR" ]; then
  exit 0
fi

# Create session snapshot
SNAPSHOT_DIR="${HYPERAGENTS_DIR}/snapshots"
mkdir -p "$SNAPSHOT_DIR"

TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
SNAPSHOT_FILE="${SNAPSHOT_DIR}/session_${TIMESTAMP}.json"

# Gather state
ARCHIVE_SIZE=0
BEST_SCORE="N/A"
LATEST_GEN="N/A"

if [ -f "${HYPERAGENTS_DIR}/archive.jsonl" ]; then
  ARCHIVE_SIZE=$(wc -l < "${HYPERAGENTS_DIR}/archive.jsonl" | tr -d ' ')
  LATEST_LINE=$(tail -1 "${HYPERAGENTS_DIR}/archive.jsonl")
  LATEST_GEN=$(echo "$LATEST_LINE" | jq -r '.current_genid // "N/A"' 2>/dev/null || echo "N/A")
fi

# Write snapshot
cat > "$SNAPSHOT_FILE" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "archive_generations": $ARCHIVE_SIZE,
  "latest_generation": "$LATEST_GEN",
  "session_type": "stop"
}
EOF

# Clean up active evolution marker if present
rm -f "${HYPERAGENTS_DIR}/.evolution_active"
rm -f "${HYPERAGENTS_DIR}/current_generation_edits.jsonl"
