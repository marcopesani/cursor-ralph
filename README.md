# Ralph for Cursor

This is a tailored version of the Ralph agent loop, optimized for Cursor's Agent mode and Composer, using **Cursor Hooks** to enable true autonomous iteration.

## Setup

1.  **Rules**: The core logic is in `.cursor/rules/ralph.mdc`. Cursor automatically applies these rules when you work in this repo.
2.  **Hooks**: The autonomous loop is powered by `.cursor/hooks.json` and hook scripts in `.cursor/hooks/`.
3.  **State Files**: Ensure `prd.json` and `progress.txt` exist (same as original Ralph).

## How It Works: Hooks-Powered Autonomous Loop

The magic happens through **Cursor Hooks**, which observe and extend the agent loop:

### The `stop` Hook (Auto-Continue)
After each agent iteration completes, the `stop` hook:
1. Checks if `prd.json` exists (Ralph session active)
2. Counts incomplete stories (`passes: false`)
3. If tasks remain, automatically sends a followup message: `"Continue with the next task in prd.json"`
4. The agent picks up the next story and continues

This creates a **true autonomous loop** - you start it once, and it runs until all tasks are complete (up to 5 auto-iterations per conversation, then you can manually continue).

### The `sessionStart` Hook (Initialization)
When a new agent session starts:
1. Initializes `progress.txt` if missing
2. Checks if the branch changed (compares `prd.json` `branchName` with `.last-branch`)
3. If branch changed, archives previous run to `archive/YYYY-MM-DD-feature-name/`
4. Resets `progress.txt` for the new feature

### Other Hooks (Tracking)
- `afterFileEdit`: Tracks which files were modified (for progress logging)
- `afterShellExecution`: Tracks quality check commands (typecheck, lint, test)

## Workflow

### 1. Start the Loop
Open Composer (Cmd+I) in **Agent mode** and type:

> **"Run Ralph"** or **"Execute the next item in prd.json"**

### 2. The Autonomous Cycle
Once started, the loop runs automatically:

1.  **Read State**: Agent reads `prd.json` to find the next incomplete story.
2.  **Implement**: Agent writes code to satisfy the story.
3.  **Verify**: Agent runs lints/tests.
4.  **Update**: Agent commits changes, updates `prd.json` (marking task as passed), and appends to `progress.txt`.
5.  **Auto-Continue**: The `stop` hook detects remaining tasks and automatically continues.

### 3. Completion
The loop stops when:
- All stories in `prd.json` have `passes: true` ✅
- Max auto-iterations reached (5 per conversation) - you can manually continue
- Agent outputs `<promise>COMPLETE</promise>` (explicit completion signal)

## Key Differences from CLI Ralph

| Feature | CLI Ralph (`ralph.sh`) | Cursor Ralph (with Hooks) |
| :--- | :--- | :--- |
| **Driver** | Bash script loop | Cursor Agent + Hooks |
| **Loop Control** | Bash `for` loop | `stop` hook auto-continue |
| **Context** | Fresh `amp` instance per loop | Continuous chat context (can be cleared manually) |
| **Instructions** | `prompt.md` passed every time | `.cursor/rules/ralph.mdc` auto-applied |
| **Archiving** | Bash script logic | `sessionStart` hook |
| **Tools** | CLI tools | Cursor native tools + Terminal |
| **Autonomy** | Fully autonomous (bash loop) | Fully autonomous (hooks auto-continue) |

## Hook Configuration

The hooks are configured in `.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{"command": "./.cursor/hooks/ralph-session-start.sh"}],
    "stop": [{"command": "./.cursor/hooks/ralph-stop.sh"}],
    "afterFileEdit": [{"command": "./.cursor/hooks/ralph-track-changes.sh"}],
    "afterShellExecution": [{"command": "./.cursor/hooks/ralph-track-execution.sh"}]
  }
}
```

### Customizing Hooks

You can modify the hook scripts in `.cursor/hooks/` to:
- Change the auto-continue message
- Add custom validation before continuing
- Track additional metrics
- Integrate with external systems

## Tips for Cursor Users

*   **Agent Mode Required**: Hooks only work in Agent mode (Cmd+I → Agent), not in regular chat.
*   **Max Auto-Iterations**: Cursor limits auto-followups to 5 per conversation. After that, manually type "Continue" to proceed.
*   **Fresh Context**: If the chat gets too long, click "New Chat" and type "Run Ralph" again. The state is saved in `prd.json` and `progress.txt`, so Ralph picks up exactly where he left off.
*   **Browser Testing**: Use Cursor's browser tools or ask Ralph to "Verify this in the browser" if you have browser integration set up.
*   **Debugging Hooks**: Check Cursor Settings → Hooks tab to see hook execution status and errors.

## Troubleshooting

**Hooks not running?**
- Restart Cursor to ensure hooks service is running
- Check that hook scripts are executable: `chmod +x .cursor/hooks/*.sh`
- Verify `jq` is installed (required for JSON parsing in hooks)
- Check Cursor Settings → Hooks for execution logs

**Loop not continuing?**
- Verify `prd.json` exists and has stories with `passes: false`
- Check that you're in Agent mode (not regular chat)
- Review `.cursor/hooks/ralph-stop.sh` for any errors
- Max 5 auto-iterations reached - manually continue with "Next task"
