#!/bin/bash
# HyperAgents: Track file modifications during evolution
# PostToolUse hook — fires after Write/Edit operations
#
# When an evolution loop is active, this hook records which files
# are being modified by the meta-agent. This data feeds into the
# archive metadata and helps analyze what kinds of changes improve fitness.

set -euo pipefail

HYPERAGENTS_DIR=".hyperagents"
TRACKING_FILE="${HYPERAGENTS_DIR}/current_generation_edits.jsonl"

# Only track if evolution is active
if [ ! -f "${HYPERAGENTS_DIR}/.evolution_active" ]; then
  exit 0
fi

# Read tool input from stdin (hook protocol)
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Record the edit
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")

echo "{\"timestamp\":\"${TIMESTAMP}\",\"tool\":\"${TOOL_NAME}\",\"file\":\"${FILE_PATH}\"}" >> "$TRACKING_FILE"
