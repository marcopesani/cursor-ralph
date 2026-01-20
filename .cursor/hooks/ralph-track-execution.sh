#!/bin/bash
# Ralph Track Execution Hook - Flight Recorder
# Stores full command output to session logs for debugging

INPUT=$(cat)
[ ! -f "prd.json" ] && exit 0

TIMESTAMP=$(date +%s)
SESSION=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')
CMD=$(echo "$INPUT" | jq -r '.command')
OUT=$(echo "$INPUT" | jq -r '.output')

LOG_DIR=".cursor/logs/sessions/$SESSION"
mkdir -p "$LOG_DIR"

# Atomic counter for ordering
COUNT=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
COUNT=$((COUNT + 1))
PREFIX=$(printf "%03d" $COUNT)

echo "$CMD" > "$LOG_DIR/${PREFIX}_cmd.txt"
echo "$OUT" > "$LOG_DIR/${PREFIX}_out.log"

exit 0
