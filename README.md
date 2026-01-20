# Ralph for Cursor

**Ralph** is an autonomous coding agent that lives inside Cursor. Give it a list of tasks, and it will implement them one by one—automatically continuing until everything is done.

Think of Ralph as a junior developer who:
- Reads your task list
- Implements one task at a time
- Runs tests to make sure nothing broke
- Commits the work
- Moves on to the next task
- Keeps notes about what it learned

> **Inspiration**: This project adapts [snarktank/ralph](https://github.com/snarktank/ralph) (originally built for the Amp CLI) to work natively with Cursor's Agent mode and hooks system. The planning approach is informed by research on Model-First Reasoning—see [Theory](#theory-model-first-reasoning) below.

## Why Use Ralph?

Instead of prompting the AI over and over, you define your tasks once in a `prd.json` file, and Ralph works through them systematically. This is especially useful for:

- **Feature development**: Break a feature into user stories, let Ralph implement each one
- **Refactoring**: Define the steps, Ralph executes them in order
- **Repetitive tasks**: Same pattern across multiple files? Ralph handles it
- **Learning a codebase**: Ralph documents patterns it discovers in `AGENTS.md` files

---

## Quick Start

### 1. Copy Ralph into your project

Copy the `.cursor/` folder from this repo into your project's root directory.

### 2. Make the hooks executable

```bash
chmod +x .cursor/hooks/*.sh
```

### 3. Install jq (if you don't have it)

Ralph's hooks use `jq` to parse JSON. Install it via Homebrew:

```bash
brew install jq
```

### 4. Create your task list

Copy the example and edit it for your project:

```bash
cp prd.json.example prd.json
```

Then edit `prd.json` to describe your tasks (see format below).

### 5. Start Ralph

Open Cursor's Composer (`Cmd+I`), make sure you're in **Agent mode**, and type:

> **Run Ralph**

That's it! Ralph will start working through your tasks.

---

## The Task File: `prd.json`

This is where you define what Ralph should do. Here's the structure:

```json
{
  "project": "MyApp",
  "branchName": "ralph/add-user-auth",
  "description": "Add user authentication to the app",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add user model",
      "description": "Create a User model with email and password fields",
      "acceptanceCriteria": [
        "User model exists with email and hashed_password fields",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Add login endpoint",
      "description": "Create POST /login that returns a JWT",
      "acceptanceCriteria": [
        "Endpoint accepts email and password",
        "Returns JWT on success, 401 on failure",
        "Tests pass"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    }
  ]
}
```

**Key fields:**
- `priority`: Lower number = higher priority. Ralph picks the highest-priority incomplete task.
- `passes`: Ralph sets this to `true` when the task is complete.
- `acceptanceCriteria`: Ralph uses these to verify the task is done correctly.

---

## How Ralph Works

### The Loop

When you say "Run Ralph", here's what happens:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   1. READ STATE                                             │
│      └── Load prd.json, find next incomplete task           │
│                                                             │
│   2. IMPLEMENT                                              │
│      └── Write code to complete the task                    │
│                                                             │
│   3. VERIFY                                                 │
│      └── Run typecheck, lint, tests                         │
│                                                             │
│   4. COMMIT                                                 │
│      └── Commit changes, mark task as passed                │
│                                                             │
│   5. CONTINUE (automatic!)                                  │
│      └── Hook detects remaining tasks, triggers next loop   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Automatic Continuation

The magic is in the **hooks**. After Ralph finishes a task, a hook script checks if there are more tasks. If yes, it automatically tells Ralph to continue with the next one.

This means you start Ralph once, and it keeps going until:
- All tasks are complete ✅
- It hits the 5-iteration limit (Cursor's safeguard—just say "Continue" to keep going)
- An error occurs that it can't fix

---

## Available Commands

Ralph comes with shortcut commands you can type in Composer:

| Command | What it does |
|---------|--------------|
| **Run Ralph** | Start/continue the task loop |
| **ralph-model** | Analyze a problem and define its model (entities, states, actions) |
| **ralph-plan** | Generate a task plan based on the model you defined |
| **ralph-debug** | Read the Flight Recorder logs to diagnose failures |

---

## Theory: Model-First Reasoning

Ralph's planning approach is inspired by the **Model-First Reasoning (MFR)** paradigm from recent AI research ([Kumar & Rana, 2025](https://arxiv.org/abs/2512.14474)).

### The Problem with "Just Ask the AI"

When you ask an LLM to solve a complex problem directly, it often:
- Skips critical steps
- Makes unstated assumptions
- Violates constraints it wasn't tracking
- Produces plans that look reasonable but break in practice

The research shows these failures are **representational, not inferential**—the AI isn't bad at reasoning, it just doesn't have a clear picture of *what* it's reasoning about.

### The Solution: Model First, Then Plan

MFR separates problem-solving into two distinct phases:

```
┌─────────────────────────────────────────────────────────────┐
│  PHASE 1: MODEL CONSTRUCTION (ralph-model)                  │
│                                                             │
│  "Before solving, define the problem explicitly:"           │
│   • What entities exist?                                    │
│   • What state variables matter?                            │
│   • What actions are possible? (with preconditions/effects) │
│   • What constraints must always hold?                      │
│                                                             │
│  DO NOT propose a solution yet.                             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  PHASE 2: REASONING & PLANNING (ralph-plan)                 │
│                                                             │
│  "Using ONLY the model above, generate a plan:"             │
│   • Actions must respect stated preconditions               │
│   • State transitions must match defined effects            │
│   • Constraints must be satisfied at every step             │
└─────────────────────────────────────────────────────────────┘
```

### How Ralph Uses This

The `ralph-model` and `ralph-plan` commands implement MFR directly:

1. **ralph-model**: You describe what you want to build. The AI defines entities, states, actions, and constraints—without jumping to solutions.

2. **ralph-plan**: Using that model, the AI generates a structured `prd.json` with user stories that respect the defined constraints.

This two-phase approach produces better task breakdowns because:
- Constraints are explicit, not assumed
- Dependencies between tasks are visible
- The AI can't "hallucinate" steps that violate the model
- You can review the model before committing to the plan

### When to Use This Workflow

Use the model-first approach when:
- The feature touches multiple parts of the system
- There are non-obvious constraints (permissions, state machines, etc.)
- Previous attempts at the task failed or produced brittle code
- You want to review the AI's understanding before it starts coding

For simple, well-defined tasks, you can skip straight to editing `prd.json` manually.

---

## Flight Recorder: Debugging Failures

Ralph keeps a "flight recorder"—a log of everything it does during a session. If something goes wrong, you can review:

- **Command output**: What did that `npm test` actually print?
- **File changes**: What edits were made before the error?
- **MCP results**: What did the browser tool see?

Logs are stored in `.cursor/logs/sessions/{session_id}/`:

```
.cursor/logs/sessions/abc123/
├── 001_cmd.txt          # First command: "npm run typecheck"
├── 001_out.log          # Its output (errors included)
├── 002_edit_User.ts.diff # Changes made to User.ts
├── 003_mcp_browser.json # Browser snapshot result
└── ...
```

**To debug a failure:**

1. Type `ralph-debug` in Composer, or
2. Manually check the logs:
   ```bash
   ls -la .cursor/logs/sessions/*/
   cat .cursor/logs/sessions/*/*.log | tail -50
   ```

---

## Progress Tracking: `progress.txt`

Ralph keeps a running log of what it accomplished in `progress.txt`. This serves two purposes:

1. **Context for future tasks**: Ralph reads this to understand what's already done
2. **Audit trail**: You can see exactly what was implemented and when

Example entry:
```
## 2026-01-20 10:30 - US-001
- Implemented User model with email and hashed_password fields
- Files changed: src/models/User.ts, src/db/migrations/001_users.sql
- **Learnings for future iterations:**
  - Project uses Drizzle ORM, not Prisma
  - Password hashing uses bcrypt
---
```

---

## Branch Management

Ralph is designed for feature branches. The `branchName` in `prd.json` tells Ralph which branch this work belongs to.

**Automatic archiving**: If you switch to a different branch and start a new `prd.json`, Ralph automatically archives the previous run to `archive/YYYY-MM-DD-feature-name/`.

---

## Tips for Success

### Write good acceptance criteria

The clearer your criteria, the better Ralph performs:

```json
// ❌ Vague
"acceptanceCriteria": ["User authentication works"]

// ✅ Specific
"acceptanceCriteria": [
  "POST /login returns JWT with user_id claim",
  "Invalid credentials return 401 with error message",
  "JWT expires after 24 hours",
  "Tests cover happy path and error cases"
]
```

### Start small

Begin with 2-3 simple tasks to see how Ralph works with your codebase before tackling larger features.

### Check progress.txt

If Ralph seems confused, check `progress.txt`—it might have noted something important about your codebase that explains its decisions.

### Use ralph-debug when stuck

If Ralph fails repeatedly, use `ralph-debug` to see the actual error messages instead of guessing.

---

## Troubleshooting

### "Hooks not running"

1. Make sure scripts are executable: `chmod +x .cursor/hooks/*.sh`
2. Restart Cursor (hooks load on startup)
3. Verify `jq` is installed: `jq --version`
4. Check Cursor Settings → Hooks for error messages

### "Loop stops after one task"

- Confirm you're in **Agent mode** (not regular chat)
- Check that `prd.json` has tasks with `passes: false`
- Look for errors in the Cursor Hooks settings panel

### "Ralph keeps failing on the same task"

1. Use `ralph-debug` to see the actual error
2. Check `.cursor/logs/sessions/` for detailed output
3. Consider simplifying the task or adding hints to the `notes` field

### "Context seems wrong"

- Start a new chat (`Cmd+N`) for a fresh context
- Ralph will reload state from `prd.json` and `progress.txt`

---

## How Hooks Work (Technical Details)

Ralph uses [Cursor Hooks](https://docs.cursor.com/context/hooks) to automate the loop:

| Hook | Script | Purpose |
|------|--------|---------|
| `beforeSubmitPrompt` | `ralph-session-start.sh` | Initialize session, archive old runs |
| `stop` | `ralph-stop.sh` | Auto-continue if tasks remain |
| `afterFileEdit` | `ralph-track-changes.sh` | Log file changes (Flight Recorder) |
| `afterShellExecution` | `ralph-track-execution.sh` | Log command output (Flight Recorder) |
| `afterMCPExecution` | `ralph-track-mcp.sh` | Log MCP tool results (Flight Recorder) |

Configuration is in `.cursor/hooks.json`.

---

## References & Credits

### Original Ralph

This project is an adaptation of [**snarktank/ralph**](https://github.com/snarktank/ralph), created by Ryan Carson based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/). The original Ralph uses a bash script loop with the Amp CLI; this version reimplements the same concepts using Cursor's native Agent mode and hooks system.

Key ideas inherited from the original:
- The `prd.json` / user story structure
- The `progress.txt` append-only memory
- One task at a time, fresh context each iteration
- `AGENTS.md` files for discovered patterns
- Automatic archiving when switching branches

### Model-First Reasoning

The `ralph-model` and `ralph-plan` commands implement the **Model-First Reasoning (MFR)** paradigm from:

> Kumar, G., & Rana, A. (2025). *Model-First Reasoning LLM Agents: Reducing Hallucinations through Explicit Problem Modeling*. arXiv:2512.14474. [https://arxiv.org/abs/2512.14474](https://arxiv.org/abs/2512.14474)

The paper demonstrates that many LLM planning failures are **representational rather than inferential**—the model doesn't fail at reasoning, it fails because it never explicitly defined what it's reasoning about. MFR addresses this by separating problem modeling from problem solving:

1. **Phase 1** (Model Construction): Define entities, state variables, actions with preconditions/effects, and constraints
2. **Phase 2** (Reasoning): Generate plans that strictly respect the constructed model

This separation provides "soft symbolic grounding" that reduces constraint violations, eliminates unstated assumptions, and produces more verifiable plans—exactly what's needed for reliable autonomous coding.

---

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
