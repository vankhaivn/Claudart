---
description: Create a persistent implementation plan as a markdown document in .claude/tasks/. Replaces native plan mode with a cross-session task file the agent maintains until completion.
---

You are about to create a persistent task document. The file you produce — not this chat session — is the source of truth for the plan. A future session (yours or another agent's) must be able to resume work from that file alone.

Before doing anything, read `.claude/rules/task-management.md`. That rule defines the file schema, status state machine, planning lock, approval signals, progress update protocol, and completion flow. This command does not duplicate that contract; it only orchestrates creation.

## Inputs

- The user's request after `/plan` is the task description. If the user typed `/plan` with no argument, ask one short clarifying question: "What's the task?"
- If the request is ambiguous (multiple reasonable interpretations) or missing critical detail (target files, success criteria), ask up to 3 clarifying questions BEFORE writing the file. Better to ask than to write a useless plan.

## Procedure

### Step 1 — Confirm a task file is the right tool

Skip `/plan` and answer in chat if any of these apply:

- Pure question or explanation (no code change)
- One-line fix or rename
- Trivial change (<3 files, <30 minutes, no decisions to record)

Use `/plan` when the work crosses sessions, touches multiple files, requires decisions worth recording, or the user explicitly asked for one.

### Step 2 — Read project context

In parallel:

- Read `.claude/CONTEXT.md` (current state of work).
- Read `.claude/tasks/index.md` if it exists. If an active task already covers this request, surface it and ask whether to continue that one instead of starting a new file.
- Read any `docs/` directory the project provides for architectural context.
- Run `git log -5 --oneline` to know recent direction.

### Step 3 — Explore the codebase (READ-ONLY)

You are in planning lock from this point. **Do not write or edit any file other than the task file itself and `index.md`.**

Use `Read`, `Grep`, `Glob`, and read-only `Bash` (`ls`, `cat`, `git status/log/diff`, `find`) to:

- Locate every file your plan will touch.
- Identify existing patterns and helpers to reuse (avoid rewriting what already exists).
- Surface constraints: linters, type checkers, framework idioms, naming conventions in the relevant area.
- Note non-obvious context you'll want a future-session agent to know.
- If the task may parallelize, record a delegation _strategy_ (decomposition, ownership) in the `delegation:` field + Plan of Work — the field's semantics live in `.claude/rules/agent-delegation.md`. Write-scope subagents must wait for `in-progress`; read-only explorers are fine during the planning lock.

Explore to de-risk the plan's decisions, not to pre-solve the implementation — findings enter the file as decisions, constraints, and `verify:` checks, never as code (see "Plan Altitude" in the rule file).

If you need clarification from the user before the plan is sensible, ask now. Do not invent answers.

### Step 4 — Generate the slug and filename

- Slug: 2-5 lowercase kebab-case words derived from the task. Example: `add-jwt-middleware`, `refactor-payment-retry`, `fix-cors-on-api`.
- Sequence number: scan `.claude/tasks/` and `.claude/tasks/done/` for existing files whose name starts with today's UTC date (`YYYY-MM-DD-`). The next sequence number is the highest existing NNN for that date + 1, zero-padded to 3 digits (e.g. `001`, `002`). If no files exist for today, start at `001`.
- Filename: `YYYY-MM-DD-NNN-<slug>.md` using today's UTC date and the computed sequence number.
- Path: `.claude/tasks/<filename>`.

No slug suffix (`-v2`, `-v3`) is needed — the sequence number already guarantees uniqueness per day.

### Step 5 — Write the task file

Use the exact skeleton in `.claude/rules/task-management.md`. Fill every section:

- **Frontmatter**: `status: planning`, today's date in `created` and `updated`, `agent: claude`, `delegation:` (`none` | `strategy-only` | `authorized` — semantics per `.claude/rules/agent-delegation.md`; record the choice in the Decision Log), 1-5 lowercase kebab tags.
- **Purpose**: open with the user's original request quoted verbatim (paraphrase is where intent bends), then 2-3 sentences answering "who gains what, how do they verify it works".
- **Context & Orientation**: this is your handoff to future-self. Fill all three subsections:
  - _Related Code_: every file path the plan touches or reads, with one-line reason.
  - _Related Docs_: project docs (`docs/...`) AND external references (URLs, RFCs).
  - _Memory Hints_: free-form notes — every non-obvious thing you discovered during exploration that a fresh agent would otherwise re-discover. This section is the lifeline against "memory loss" across sessions. Be generous. If a hint is a **project-wide durable fact** (not specific to this task), flag it as a `.claude/knowledge/` graduation candidate — on completion, `/checkpoint` or `/learn` can promote it so it survives task archival.
- **Plan of Work**: 1-3 paragraphs of prose narrating the sequence and rationale.
- **Concrete Steps**: ordered checklist. Each step is one self-contained action with target file, expected outcome, and a `(verify: <observable check>)`. Steps should be small enough that completing one is a meaningful save point, and written at plan altitude — decisions and verification, never code.
- **Validation & Acceptance**: observable success criteria — tests to pass, commands to run, behaviors to verify.
- **Decision Log**: any non-obvious choice you made while planning (library, approach, trade-off). Include rationale.
- **Surprises & Discoveries**: anything unexpected found during exploration that informed the plan.
- **Outcomes & Retrospective**: leave empty (filled at completion).

### Step 6 — Update `index.md`

If `.claude/tasks/index.md` does not exist, create it with the canonical header (see rule file). Then add the new task under `## Active`:

```
- [<slug>](<YYYY-MM-DD-NNN-slug>.md) — planning — updated <YYYY-MM-DD>
```

Keep `index.md` under 100 lines.

### Step 7 — Fresh-eyes check, then report

Before reporting, re-read the task file as if this conversation never happened. Any step that needs conversation context to execute has an **information gap** — move that context into Memory Hints now. Do not "fix" skill gaps: the executor is expected to derive the how; missing information is a defect, a missing solution is not.

Output a short summary:

```
## Plan Created

**File**: `.claude/tasks/<filename>`
**Status**: planning (no code edits will happen until you approve)
**Steps**: <n> concrete steps + <m> validation checks
**Open questions**: <list any clarifications still needed, or "none">

Review the file, request changes by editing it directly or telling me what to change.
When ready, say "go" / "approved" / "implement" and I'll flip status to `in-progress` and start executing.
```

Do NOT begin implementing. Wait for the approval signal defined in `.claude/rules/task-management.md`.

## After Approval

Once the user gives an approval signal, the contract in `.claude/rules/task-management.md` takes over — this command adds nothing to it. Flip `status: planning → in-progress`, execute Concrete Steps while maintaining the task file per "Progress Updates During Implementation", honor the `delegation:` field per `.claude/rules/agent-delegation.md`, and finish through the **Two-Phase Completion Gate**: report at `awaiting-review` and stop; the user — not you — confirms `done`.

## Anti-Patterns

- Do not write code while `status: planning` or `status: awaiting-review` — both are read-only locks (see `.claude/rules/task-management.md`).
- Do not put the plan body into chat instead of the file. The file IS the plan.
- Do not skip Memory Hints. A plan with no Memory Hints is a plan that won't survive a context reset.
- Do not call `ExitPlanMode`. This workflow does not use it.
- Do not treat enthusiasm ("great idea!") or questions as approval — wait for an explicit signal at each gate.
