#!/bin/bash
# Ralph Stop Hook - Auto-continue loop if tasks remain
# This hook implements the autonomous loop by checking prd.json state

set -e

# Read JSON input from stdin
INPUT=$(cat)
PRD_FILE="prd.json"
MAX_LOOPS=5  # Cursor enforces max 5 auto-followups per conversation

# Extract loop_count from input
LOOP_COUNT=$(echo "$INPUT" | jq -r '.loop_count // 0')

# Check if prd.json exists
if [ ! -f "$PRD_FILE" ]; then
  # No PRD file, don't auto-continue (not a Ralph session)
  echo '{}'
  exit 0
fi

# Check if all stories are complete
INCOMPLETE_COUNT=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE")

if [ "$INCOMPLETE_COUNT" -eq 0 ]; then
  # All tasks complete, don't continue
  echo '{}'
  exit 0
fi

# Check if we've exceeded max loops (Cursor's limit)
if [ "$LOOP_COUNT" -ge "$MAX_LOOPS" ]; then
  # Reached max loops, stop auto-continuing
  # User can manually continue if needed
  echo '{}'
  exit 0
fi

# Check status - don't continue on errors
STATUS=$(echo "$INPUT" | jq -r '.status // "completed"')
if [ "$STATUS" = "error" ] || [ "$STATUS" = "aborted" ]; then
  echo '{}'
  exit 0
fi

# Auto-continue with next task
# The agent will read prd.json and pick the next incomplete story
echo '{"followup_message": "Continue with the next task in prd.json"}'
