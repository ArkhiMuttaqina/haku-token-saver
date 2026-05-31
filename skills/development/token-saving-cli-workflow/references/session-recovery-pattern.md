# Session Recovery Pattern

This reference captures a pragmatic recovery workflow for resuming multi-phase work when the user says "execute" and the prior plan/session context exists elsewhere.

## When This Applies

User signals:
- "Execute"
- "Phase N execute bro"
- "Continue from where we left off"
- "Run the plan"

And you know or can discover that:
- A prior session had a structured plan with phases/steps
- A repo or codebase was already touched or established in that prior session
- User does NOT want you to restart discovery or re-prompt for basics

## Recovery Workflow

### 1. Recover Prior Plan/Session Context

Use `session_search` to find the earlier session with the plan:

```python
session_search(query="keyword from plan OR project name", limit=5, sort="newest")
```

Look for:
- todo lists with multi-step tasks
- user prompts like "Make a devplan" or "Phase 1: X"
- session IDs that match project/topic recollection

### 2. Recover Repo Path from Session or Filesystem

Options:
- Use `search_files(pattern='*repo-name*')` under user home
- Use `search_files(pattern='*partial-name*')` to find clues
- Use prior session output if it contains absolute paths or installation commands

Pitfall:
- Do NOT use `ls ~/.hermes/plans/` as primary method; it may not exist.
- Do NOT prompt the user for path if you can find it from session history or filesystem.

### 3. Inspect Current Repo State

Read key files to understand where execution left off:
- `README.md`
- `install.sh`
- core scripts/config files
- `.bak` files that indicate recent changes

### 4. Execute Remaining Phases

Identify pending phases from the plan and execute them directly.

Example:
- Phase 1: Initial repo setup and file creation — already done
- Phase 2: Merge terse policy into skill/docs — do this
- Phase 3: Harden wrapper fallbacks — do this
- Validation: Run syntax/smoke tests — do this

After each step:
- Mark completion
- Verify with targeted tests

## What NOT To Do

- Do NOT ask "which repo" or "what plan" if session_search can surface prior context.
- Do NOT re-prompt for project structure that prior session already documented.
- Do NOT assume fresh install is needed if state shows files already modified.
- Do NOT create a fresh plan when the user explicitly wants an earlier one executed.

## When To Ask Clarification

Only when recovery genuinely fails:
- `session_search` returns nothing relevant
- repo cannot be located in plausible places
- plan is ambiguous or conflicting across multiple sessions

Even then:
- show what you found
- ask for only the missing piece

## Key Takeaway

User's "execute" signal after prior planning work is a **continue** request, not a **start-from-scratch** request. Recovery should be proactive and implicit, not a re-interview.