#!/bin/bash
# Ralph Track MCP Hook - Flight Recorder
# Captures MCP tool results (browser snapshots, API responses)

INPUT=$(cat)
[ ! -f "prd.json" ] && exit 0

SESSION=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
RESULT=$(echo "$INPUT" | jq -r '.result_json')

LOG_DIR=".cursor/logs/sessions/$SESSION"
mkdir -p "$LOG_DIR"

COUNT=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
COUNT=$((COUNT + 1))
PREFIX=$(printf "%03d" $COUNT)

echo "$RESULT" > "$LOG_DIR/${PREFIX}_mcp_${TOOL}.json"

exit 0
