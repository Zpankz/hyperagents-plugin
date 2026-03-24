#!/bin/bash
# HyperAgents: Detect evolution state on session start
# SessionStart hook — fires on startup/resume
#
# Checks if a HyperAgents evolution loop was in progress and
# injects context about the current state.

set -euo pipefail

HYPERAGENTS_DIR=".hyperagents"

# Only run if hyperagents is initialized
if [ ! -d "$HYPERAGENTS_DIR" ]; then
  exit 0
fi

# Check for active evolution
if [ ! -f "${HYPERAGENTS_DIR}/archive.jsonl" ]; then
  exit 0
fi

# Read archive state
ARCHIVE_SIZE=$(wc -l < "${HYPERAGENTS_DIR}/archive.jsonl" | tr -d ' ')
LATEST_LINE=$(tail -1 "${HYPERAGENTS_DIR}/archive.jsonl")
LATEST_GEN=$(echo "$LATEST_LINE" | jq -r '.current_genid // "unknown"' 2>/dev/null || echo "unknown")
ARCHIVE_LEN=$(echo "$LATEST_LINE" | jq -r '.archive | length // 0' 2>/dev/null || echo "0")

# Read config for max generations
MAX_GEN="unknown"
if [ -f "${HYPERAGENTS_DIR}/config.json" ]; then
  MAX_GEN=$(jq -r '.max_generation // "unknown"' "${HYPERAGENTS_DIR}/config.json" 2>/dev/null || echo "unknown")
fi

# Output context for the session
echo "HyperAgents evolution state detected: ${ARCHIVE_LEN} generations (latest: gen_${LATEST_GEN}, max: ${MAX_GEN}). Run /hyperagents:status for details or /hyperagents:evolve --resume to continue."
