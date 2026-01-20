#!/bin/bash
# Ralph Track Changes Hook - Log file edits for progress.txt

set -e

# Read JSON input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path')
EDITS=$(echo "$INPUT" | jq -r '.edits')

# Only track if this is a Ralph session (check if prd.json exists)
if [ ! -f "prd.json" ]; then
  exit 0
fi

# Track edited files in a temp file for later use in progress.txt
TRACK_FILE=".ralph-changes.tmp"
echo "$FILE_PATH" >> "$TRACK_FILE" 2>/dev/null || true

# No output needed
exit 0
