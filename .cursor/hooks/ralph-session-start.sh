#!/bin/bash
# Ralph Session Start Hook - Initialize and archive if needed

set -e

# Read JSON input from stdin
INPUT=$(cat)
PRD_FILE="prd.json"
PROGRESS_FILE="progress.txt"
ARCHIVE_DIR="archive"
LAST_BRANCH_FILE=".last-branch"

# Extract session info
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
COMPOSER_MODE=$(echo "$INPUT" | jq -r '.composer_mode // "agent"')

# Check if this is an agent session (not just a regular chat)
if [ "$COMPOSER_MODE" != "agent" ]; then
  # Not an agent session, skip Ralph initialization
  echo '{}'
  exit 0
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Initialize session log directory (Flight Recorder)
LOG_DIR=".cursor/logs/sessions/$SESSION_ID"
mkdir -p "$LOG_DIR"

# Store current story ID for context
if [ -f "$PRD_FILE" ]; then
  STORY_ID=$(jq -r '[.userStories[] | select(.passes == false)][0].id // "none"' "$PRD_FILE" 2>/dev/null || echo "none")
  echo "$STORY_ID" > "$LOG_DIR/story_id.txt"
fi

# Check for archiving if prd.json exists
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/" 2>/dev/null || true
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/" 2>/dev/null || true
    
    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Return empty response (no additional context needed)
echo '{}'
