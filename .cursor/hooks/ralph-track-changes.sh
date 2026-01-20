#!/bin/bash
# Ralph Track Changes Hook - Flight Recorder
# Stores git diff of edited files for debugging

INPUT=$(cat)
[ ! -f "prd.json" ] && exit 0

SESSION=$(echo "$INPUT" | jq -r '.conversation_id // "unknown"')
FILE=$(echo "$INPUT" | jq -r '.file_path')
FILENAME=$(basename "$FILE")

LOG_DIR=".cursor/logs/sessions/$SESSION"
mkdir -p "$LOG_DIR"

COUNT=$(ls -1 "$LOG_DIR" 2>/dev/null | wc -l | tr -d ' ')
COUNT=$((COUNT + 1))
PREFIX=$(printf "%03d" $COUNT)

# Use git diff if tracked, otherwise store the edits JSON
if git ls-files --error-unmatch "$FILE" > /dev/null 2>&1; then
  git diff "$FILE" > "$LOG_DIR/${PREFIX}_edit_${FILENAME}.diff" 2>/dev/null || true
else
  echo "$INPUT" | jq '.edits' > "$LOG_DIR/${PREFIX}_edit_${FILENAME}.json"
fi

exit 0
