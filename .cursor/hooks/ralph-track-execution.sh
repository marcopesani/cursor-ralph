#!/bin/bash
# Ralph Track Execution Hook - Log shell commands for progress.txt

set -e

# Read JSON input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command')
OUTPUT=$(echo "$INPUT" | jq -r '.output')

# Only track if this is a Ralph session (check if prd.json exists)
if [ ! -f "prd.json" ]; then
  exit 0
fi

# Track quality check commands (typecheck, lint, test)
if echo "$COMMAND" | grep -qE "(typecheck|lint|test|jest|vitest|pytest|mocha)"; then
  TRACK_FILE=".ralph-executions.tmp"
  echo "$COMMAND" >> "$TRACK_FILE" 2>/dev/null || true
fi

# No output needed
exit 0
